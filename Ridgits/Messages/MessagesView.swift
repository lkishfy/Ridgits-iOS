import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class MessagingViewModel: ObservableObject {
    @Published var conversations: [RidgitsConversation] = []
    @Published var messages: [RidgitsMessage] = []
    @Published var selectedConversation: RidgitsConversation?
    @Published var messageText = ""
    @Published var isSending = false
    @Published var errorMessage: String?
    @Published var timeRemaining: TimeInterval?
    /// Set when a messaging action failed because the account isn't subscribed.
    @Published var showPaywallPrompt = false
    /// Set when the server requires birth year on file — present `BirthYearPromptView`.
    @Published var showBirthYearPrompt = false
    @Published var showIdentityVerificationPrompt = false
    @Published var showProfilePhotoMatchPrompt = false
    @Published var isFlagging = false
    @Published var flagSuccessMessage: String?
    @Published var showEarlyPhoneNumberPrompt = false

    private var conversationsListener: ListenerRegistration?
    private var messagesListener: ListenerRegistration?
    private var conversationListener: ListenerRegistration?
    private var countdownTimer: Timer?
    private(set) var pendingOpenOtherUserId: String?
    @Published private(set) var matchConversationLookup: [String: RidgitsConversation] = [:]
    private var prefetchingUserIds: Set<String> = []

    var pendingIncoming: [RidgitsConversation] {
        sortedByRecency(conversations.filter(\.isIncomingPending))
    }

    var awaitingApproval: [RidgitsConversation] {
        sortedByRecency(conversations.filter { $0.isOutgoingPending || $0.isOutgoingDeclined })
    }

    var activeConversations: [RidgitsConversation] {
        sortedByRecency(
            conversations.filter { conversation in
                !conversation.isArchived
                    && !conversation.isIncomingPending
                    && !conversation.isOutgoingPending
                    && !conversation.isOutgoingDeclined
                    && conversation.status == .active
                    && !conversation.isMessagingClosed
            }
        )
    }

    var closedConversations: [RidgitsConversation] {
        sortedByRecency(
            conversations.filter { conversation in
                !conversation.isArchived
                    && !conversation.isIncomingPending
                    && !conversation.isOutgoingPending
                    && !conversation.isOutgoingDeclined
                    && conversation.isMessagingClosed
            }
        )
    }

    var archivedConversations: [RidgitsConversation] {
        sortedByRecency(conversations.filter(\.isArchived))
    }

    func messagingClosedMessage(for match: RidgitsMatch) -> String? {
        guard let conversation = resolvedConversation(with: match.userId) else { return nil }
        if conversation.status == .expired || conversation.isMessagingClosed {
            return conversation.messagingClosedUserMessage
        }
        return nil
    }

    func messagingClosedLabel(for match: RidgitsMatch) -> String? {
        guard let conversation = resolvedConversation(with: match.userId) else { return nil }
        if conversation.status == .expired || conversation.isMessagingClosed {
            return conversation.closedStatusLabel
        }
        return nil
    }

    func messagingIsExpired(for match: RidgitsMatch) -> Bool {
        guard let conversation = resolvedConversation(with: match.userId) else { return false }
        return conversation.isConversationExpired
    }

    var incomingRequestCount: Int {
        pendingIncoming.count
    }

    /// Pending incoming + outgoing message requests awaiting action.
    var inactiveRequestCount: Int {
        pendingIncoming.count + awaitingApproval.count
    }

    var canSendMonthlyMessage: Bool { true }

    func startListening() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        if conversations.isEmpty, let cached = RidgitsConversationsCache.shared.conversations(for: uid) {
            conversations = cached
        }

        conversationsListener?.remove()
        conversationsListener = RidgitsFirebaseClient.shared.listenConversations(userId: uid) { [weak self] convos in
            Task { @MainActor in
                self?.applyConversations(convos, uid: uid)
            }
        }
    }

    func conversation(with otherUserId: String) -> RidgitsConversation? {
        conversations.first { $0.otherUserId == otherUserId }
    }

    func resolvedConversation(with otherUserId: String) -> RidgitsConversation? {
        conversation(with: otherUserId) ?? matchConversationLookup[otherUserId]
    }

    func prefetchConversationStatus(for userIds: [String]) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let targets = userIds.filter { userId in
            !userId.isEmpty
                && resolvedConversation(with: userId) == nil
                && !prefetchingUserIds.contains(userId)
        }
        guard !targets.isEmpty else { return }

        prefetchingUserIds.formUnion(targets)
        defer { prefetchingUserIds.subtract(targets) }

        await withTaskGroup(of: (String, RidgitsConversation?).self) { group in
            for userId in targets.prefix(30) {
                group.addTask {
                    let conversationId = RidgitsFirebaseClient.conversationId(for: uid, and: userId)
                    do {
                        let conversation = try await RidgitsFirebaseClient.shared.fetchConversation(
                            conversationId: conversationId,
                            userId: uid
                        )
                        return (userId, conversation)
                    } catch {
                        return (userId, nil)
                    }
                }
            }

            var updates: [String: RidgitsConversation] = [:]
            for await (userId, conversation) in group {
                if let conversation {
                    updates[userId] = conversation
                }
            }

            guard !updates.isEmpty else { return }

            for (userId, conversation) in updates {
                matchConversationLookup[userId] = conversation
                if conversation.isMessagingClosed || conversation.status == .expired {
                    upsertConversation(conversation, uid: uid)
                }
            }
        }
    }

    func closeConversation() {
        messagesListener?.remove()
        conversationListener?.remove()
        messagesListener = nil
        conversationListener = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
        messages = []
        timeRemaining = nil
        messageText = ""
        pendingOpenOtherUserId = nil
        selectedConversation = nil
    }

    func requestOpenConversation(with otherUserId: String, conversationId: String? = nil) {
        if let existing = conversation(with: otherUserId) {
            selectConversation(existing)
            pendingOpenOtherUserId = nil
            return
        }
        pendingOpenOtherUserId = otherUserId
        Task { await loadAndOpenConversation(otherUserId: otherUserId, conversationId: conversationId) }
    }

    private func loadAndOpenConversation(otherUserId: String, conversationId: String?) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let resolvedId = conversationId ?? RidgitsFirebaseClient.conversationId(for: uid, and: otherUserId)

        for attempt in 0..<6 {
            do {
                if let conversation = try await RidgitsFirebaseClient.shared.fetchConversation(
                    conversationId: resolvedId,
                    userId: uid
                ) {
                    upsertConversation(conversation, uid: uid)
                    resolvePendingOpenIfNeeded()
                    return
                }
            } catch {
                reportError(error, context: "MessagingViewModel.loadAndOpenConversation")
            }

            if attempt < 5 {
                try? await Task.sleep(nanoseconds: UInt64(250_000_000 * UInt64(attempt + 1)))
            }
        }

        await refresh()
        resolvePendingOpenIfNeeded()
    }

    private func upsertConversation(_ conversation: RidgitsConversation, uid: String) {
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[index] = conversation
        } else {
            conversations.append(conversation)
        }
        conversations = sortedByRecency(conversations)
        RidgitsConversationsCache.shared.save(conversations, uid: uid)
    }

    private func applyConversations(_ convos: [RidgitsConversation], uid: String) {
        var merged = convos
        let incomingIds = Set(convos.map(\.id))

        for existing in conversations where !incomingIds.contains(existing.id) {
            if existing.id == selectedConversation?.id
                || existing.otherUserId == pendingOpenOtherUserId
                || existing.isMessagingClosed
                || existing.status == .expired {
                merged.append(existing)
            }
        }

        conversations = sortedByRecency(merged)
        RidgitsConversationsCache.shared.save(conversations, uid: uid)
        resolvePendingOpenIfNeeded()
    }

    private func resolvePendingOpenIfNeeded() {
        guard let userId = pendingOpenOtherUserId else { return }
        guard let conversation = conversation(with: userId) else { return }
        selectConversation(conversation)
        pendingOpenOtherUserId = nil
    }

    func refresh() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            let convos = try await RidgitsFirebaseClient.shared.fetchConversations(
                userId: uid,
                forceRefreshProfiles: true
            )
            applyConversations(convos, uid: uid)
        } catch {
            reportError(error, context: "MessagingViewModel.refresh")
        }
    }

    private func reportError(_ error: Error, context: String) {
        RidgitsFirestoreIndexErrorLogging.logIfMissingIndex(error, context: context)
        errorMessage = error.localizedDescription
    }

    private func handleMessagingError(_ ridgitsError: RidgitsError) {
        if ridgitsError.code == "SUBSCRIPTION_REQUIRED" {
            showPaywallPrompt = true
        } else if ridgitsError.code == "AGE_VERIFICATION_REQUIRED" || ridgitsError.code == "UNDERAGE" {
            showBirthYearPrompt = true
            return
        } else if ridgitsError.code == "IDENTITY_VERIFICATION_REQUIRED" {
            showIdentityVerificationPrompt = true
            return
        } else if ridgitsError.code == "PHONE_VERIFICATION_REQUIRED" {
            showIdentityVerificationPrompt = true
            return
        } else if ridgitsError.code == "PROFILE_PHOTO_IDENTITY_MISMATCH" {
            showProfilePhotoMatchPrompt = true
            return
        }
        if let message = ridgitsError.errorDescription {
            RidgitsFirestoreIndexErrorLogging.logIfMissingIndex(message, context: "MessagingViewModel")
        }
        errorMessage = ridgitsError.localizedDescription
    }

    func selectConversation(_ conversation: RidgitsConversation) {
        selectedConversation = conversation
        messagesListener?.remove()
        conversationListener?.remove()
        messages = []
        let conversationId = conversation.id
        messagesListener = RidgitsFirebaseClient.shared.listenMessages(conversationId: conversationId) { [weak self] msgs in
            Task { @MainActor in
                guard let self, self.selectedConversation?.id == conversationId else { return }
                self.messages = msgs
            }
        }
        conversationListener = RidgitsFirebaseClient.shared.listenConversation(conversationId: conversationId) { [weak self] convo in
            Task { @MainActor in
                guard let self, self.selectedConversation?.id == conversationId else { return }
                guard let convo else {
                    self.closeConversation()
                    return
                }
                self.selectedConversation = convo
                self.updateCountdown()
            }
        }
        Task {
            try? await RidgitsFirebaseClient.shared.markConversationRead(conversationId: conversation.id)
        }
        startCountdownTimer()
    }

    func approve(_ conversation: RidgitsConversation) async {
        do {
            try await RidgitsFirebaseClient.shared.approveConversation(conversationId: conversation.id)
        } catch let ridgitsError as RidgitsError {
            handleMessagingError(ridgitsError)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func decline(_ conversation: RidgitsConversation) async {
        do {
            try await RidgitsFirebaseClient.shared.declineConversation(conversationId: conversation.id)
            if selectedConversation?.id == conversation.id {
                closeConversation()
            }
        } catch let ridgitsError as RidgitsError {
            handleMessagingError(ridgitsError)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func withdraw(_ conversation: RidgitsConversation) async {
        do {
            try await RidgitsFirebaseClient.shared.withdrawConversation(conversationId: conversation.id)
            if selectedConversation?.id == conversation.id {
                closeConversation()
            }
        } catch let ridgitsError as RidgitsError {
            handleMessagingError(ridgitsError)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func sendMessage() async {
        guard let conversation = selectedConversation else { return }
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, conversation.canSendMessage, canSendMonthlyMessage else { return }
        if RidgitsMessagingValidation.blocksEarlyPhoneNumber(
            text: trimmed,
            messageCount: conversation.messageCount
        ) {
            showEarlyPhoneNumberPrompt = true
            return
        }
        isSending = true
        defer { isSending = false }
        do {
            try await RidgitsFirebaseClient.shared.sendMessage(conversationId: conversation.id, message: trimmed)
            messageText = ""
        } catch let ridgitsError as RidgitsError {
            if ridgitsError.code == "EARLY_PHONE_NUMBER" {
                showEarlyPhoneNumberPrompt = true
            } else {
                handleMessagingError(ridgitsError)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func flagConversation(_ conversation: RidgitsConversation, reason: String) async {
        let trimmed = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isFlagging = true
        defer { isFlagging = false }
        do {
            try await RidgitsFirebaseClient.shared.flagConversation(conversationId: conversation.id, reason: trimmed)
            flagSuccessMessage = "Thanks — our team will review this conversation with high priority. If multiple members report the same person within 7 days, their messaging may be paused while we investigate."
        } catch let ridgitsError as RidgitsError {
            errorMessage = ridgitsError.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func archive(_ conversation: RidgitsConversation) async {
        do {
            try await RidgitsFirebaseClient.shared.archiveConversation(conversationId: conversation.id)
            updateConversationLocally(conversation.id) { $0.withArchived(true) }
            if selectedConversation?.id == conversation.id {
                closeConversation()
            }
        } catch let ridgitsError as RidgitsError {
            errorMessage = ridgitsError.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func unarchive(_ conversation: RidgitsConversation) async {
        do {
            try await RidgitsFirebaseClient.shared.unarchiveConversation(conversationId: conversation.id)
            updateConversationLocally(conversation.id) { $0.withArchived(false) }
        } catch let ridgitsError as RidgitsError {
            errorMessage = ridgitsError.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func updateConversationLocally(
        _ conversationId: String,
        transform: (RidgitsConversation) -> RidgitsConversation
    ) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let index = conversations.firstIndex(where: { $0.id == conversationId }) else { return }
        conversations[index] = transform(conversations[index])
        conversations = sortedByRecency(conversations)
        RidgitsConversationsCache.shared.save(conversations, uid: uid)
    }

    func stopListening() {
        conversationsListener?.remove()
        messagesListener?.remove()
        conversationListener?.remove()
        countdownTimer?.invalidate()
    }

    private func sortedByRecency(_ conversations: [RidgitsConversation]) -> [RidgitsConversation] {
        conversations.sorted {
            ($0.lastMessageAt ?? .distantPast) > ($1.lastMessageAt ?? .distantPast)
        }
    }

    private func startCountdownTimer() {
        countdownTimer?.invalidate()
        updateCountdown()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.updateCountdown() }
        }
    }

    private func updateCountdown() {
        guard let expiresAt = selectedConversation?.expiresAt else {
            timeRemaining = nil
            return
        }
        timeRemaining = max(0, expiresAt.timeIntervalSinceNow)
    }

    var countdownLabel: String? {
        guard let remaining = timeRemaining, remaining > 0 else {
            if selectedConversation?.status == .active { return "Expired" }
            return nil
        }
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%02d:%02d:%02d left", hours, minutes, seconds)
    }
}

struct MessagesView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var ridgitsStore: RidgitsStore
    @EnvironmentObject private var pokeInbox: RidgitsPokeInbox
    @ObservedObject var viewModel: MessagingViewModel
    @ObservedObject var matchesViewModel: MatchesViewModel
    @Binding var incomingPokeProfile: IncomingPokeProfile?
    @State private var showRequests = false
    @State private var showSubscriptionPaywall = false
    @State private var subscriptionPaywallForMessaging = false
    @State private var showBirthYearPrompt = false
    @State private var showIdentityVerification = false
    @State private var showProfilePhotoMatchAlert = false
    @State private var composeMatch: RidgitsMatch?
    @State private var composeMessage = ""
    @State private var pokeProfileMatch: RidgitsMatch?
    @State private var showPokePackPaywall = false
    @State private var pokeConfirmMatch: RidgitsMatch?
    @State private var unpokeConfirmMatch: RidgitsMatch?

    var body: some View {
        NavigationStack {
            Group {
                if let selected = viewModel.selectedConversation {
                    ConversationDetailView(
                        viewModel: viewModel,
                        conversation: selected,
                        onBack: { viewModel.closeConversation() }
                    )
                } else {
                    VStack(spacing: 0) {
                        inboxHeader
                        conversationList
                    }
                }
            }
            .background(Color.white)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $pokeProfileMatch) { match in
                MatchProfileView(
                    match: match,
                    onMessage: {
                        guard ridgitsStore.hasPlusMembership else {
                            subscriptionPaywallForMessaging = true
                            showSubscriptionPaywall = true
                            return
                        }
                        guard beginCompose(to: match) else { return }
                        pokeProfileMatch = nil
                    },
                    onPoke: {
                        Task { await requestPoke(for: match) }
                    },
                    onUnpoke: {
                        unpokeConfirmMatch = match
                    }
                )
            }
            .toolbar {
                if viewModel.selectedConversation == nil {
                    ToolbarItem(placement: .principal) { EmptyView() }
                }
            }
            .toolbar(viewModel.selectedConversation == nil ? .hidden : .visible, for: .navigationBar)
        }
        .sheet(isPresented: $showRequests) {
            MessageRequestsView(
                viewModel: viewModel,
                matchesViewModel: matchesViewModel,
                composeMatch: $composeMatch,
                onViewPokeProfile: { poke in
                    await openPokeProfile(poke)
                },
                onPokeBack: { poke in
                    await pokeBack(poke)
                },
                onDeletePoke: { poke in
                    await deleteReceivedPoke(poke)
                },
                onDeleteSentPoke: { poke in
                    await deleteSentPoke(poke)
                },
                onViewSentPokeProfile: { poke in
                    await openSentPokeProfile(poke)
                }
            )
        }
        .sheet(item: $composeMatch) { match in
            StartConversationSheet(
                match: match,
                messageText: $composeMessage,
                onSend: { await sendConversationRequest(to: match) },
                onCancel: {
                    composeMessage = ""
                    composeMatch = nil
                }
            )
        }
        .sheet(isPresented: $showSubscriptionPaywall) {
            SubscriptionPaywallView(
                highlightTier: subscriptionPaywallForMessaging ? .plus : nil,
                headline: subscriptionPaywallForMessaging ? "Subscribe to respond" : nil,
                subheadline: subscriptionPaywallForMessaging
                    ? "Ridgits+ lets you accept message requests and keep the conversation going."
                    : nil
            )
        }
        .onChange(of: showSubscriptionPaywall) { _, isPresented in
            if !isPresented {
                subscriptionPaywallForMessaging = false
            }
        }
        .fullScreenCover(isPresented: $showBirthYearPrompt) {
            BirthYearPromptView {
                showBirthYearPrompt = false
            }
            .environmentObject(authManager)
        }
        .sheet(isPresented: $showIdentityVerification) {
            IdentityVerificationView { success in
                showIdentityVerification = false
                if success {
                    Task { await ridgitsStore.refreshAccessInBackground() }
                }
            }
            .environmentObject(ridgitsStore)
        }
        .sheet(isPresented: $showPokePackPaywall) {
            PokePackPaywallView {
                Task { await matchesViewModel.refreshPokeCredits() }
            }
        }
        .onChange(of: matchesViewModel.showPokePackPaywall) { _, showPaywall in
            guard showPaywall else { return }
            matchesViewModel.showPokePackPaywall = false
            showPokePackPaywall = true
        }
        .alert("Send poke?", isPresented: Binding(
            get: { pokeConfirmMatch != nil },
            set: { if !$0 { pokeConfirmMatch = nil } }
        )) {
            Button("Send poke") {
                guard let match = pokeConfirmMatch else { return }
                pokeConfirmMatch = nil
                Task { await matchesViewModel.sendPoke(to: match) }
            }
            Button("Cancel", role: .cancel) {
                pokeConfirmMatch = nil
            }
        } message: {
            if let match = pokeConfirmMatch {
                Text(matchesViewModel.pokeConfirmationMessage(for: match.displayFirstName))
            }
        }
        .alert("Delete poke?", isPresented: Binding(
            get: { unpokeConfirmMatch != nil },
            set: { if !$0 { unpokeConfirmMatch = nil } }
        )) {
            Button("Delete", role: .destructive) {
                guard let match = unpokeConfirmMatch,
                      let pokeId = pokeInbox.sentPokeIdsByUser[match.userId] else {
                    unpokeConfirmMatch = nil
                    return
                }
                unpokeConfirmMatch = nil
                Task { await matchesViewModel.unpoke(pokeId: pokeId) }
            }
            Button("Cancel", role: .cancel) {
                unpokeConfirmMatch = nil
            }
        } message: {
            if let match = unpokeConfirmMatch {
                Text("Delete your poke to \(match.displayFirstName)?")
            }
        }
        .onChange(of: viewModel.showPaywallPrompt) { _, showPaywall in
            guard showPaywall else { return }
            viewModel.showPaywallPrompt = false
            subscriptionPaywallForMessaging = true
            showSubscriptionPaywall = true
        }
        .onChange(of: viewModel.showBirthYearPrompt) { _, showPrompt in
            guard showPrompt else { return }
            viewModel.showBirthYearPrompt = false
            showBirthYearPrompt = true
        }
        .onChange(of: viewModel.showIdentityVerificationPrompt) { _, showPrompt in
            guard showPrompt else { return }
            viewModel.showIdentityVerificationPrompt = false
            showIdentityVerification = true
        }
        .onChange(of: viewModel.showProfilePhotoMatchPrompt) { _, showPrompt in
            guard showPrompt else { return }
            viewModel.showProfilePhotoMatchPrompt = false
            showProfilePhotoMatchAlert = true
        }
        .alert("Profile photo must match your ID", isPresented: $showProfilePhotoMatchAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Update your profile photo in the Profile tab with a clear photo of your face, similar to your ID verification selfie, then try messaging again.")
        }
        .task(id: incomingPokeProfile?.id) {
            await openIncomingPokeIfNeeded()
        }
        .task {
            viewModel.startListening()
            await viewModel.refresh()
        }
        .alert("Couldn't send message", isPresented: Binding(
            get: {
                viewModel.errorMessage != nil
                    && !viewModel.showPaywallPrompt
                    && !viewModel.showBirthYearPrompt
                    && !viewModel.showIdentityVerificationPrompt
                    && !viewModel.showProfilePhotoMatchPrompt
            },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert(
            "It's a bit too early for a phone number, no?",
            isPresented: $viewModel.showEarlyPhoneNumberPrompt
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Let's get to know each other a bit more!")
        }
    }

    private var inactiveRequestCount: Int {
        viewModel.inactiveRequestCount
    }

    private var inboxIsEmpty: Bool {
        viewModel.activeConversations.isEmpty
            && viewModel.closedConversations.isEmpty
            && viewModel.pendingIncoming.isEmpty
            && viewModel.awaitingApproval.isEmpty
            && pokeInbox.receivedPokesSorted.isEmpty
            && pokeInbox.sentPokesSorted.isEmpty
    }

    private var inboxHeader: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Text("Inbox")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(RidgitsColors.textHeadline)

                Spacer()

                Button {
                    showRequests = true
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "tray")
                            .font(.system(size: 21, weight: .regular))
                            .foregroundStyle(RidgitsColors.textHeadline)
                            .frame(width: 32, height: 32)

                        if inactiveRequestCount > 0 {
                            Text(inactiveRequestCount > 99 ? "99+" : "\(inactiveRequestCount)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, inactiveRequestCount > 9 ? 4 : 0)
                                .frame(minWidth: 16, minHeight: 16)
                                .background(RidgitsColors.destructive)
                                .clipShape(Capsule())
                                .offset(x: 6, y: -4)
                        }
                    }
                }
                .buttonStyle(RidgitsHapticPlainButtonStyle())
                .accessibilityLabel("Requests")
                .accessibilityValue(
                    inactiveRequestCount > 0
                        ? "\(inactiveRequestCount) inactive requests"
                        : "No inactive requests"
                )
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .background(Color.white)
    }

    private var conversationList: some View {
        List {
            if !pokeInbox.receivedPokesSorted.isEmpty {
                Section {
                    ForEach(pokeInbox.receivedPokesSorted) { poke in
                        PokeInboxRow(
                            poke: poke,
                            sentPokeBack: pokeInbox.sentPokeIdsByUser[poke.fromUserId] != nil,
                            onViewProfile: { Task { await openPokeProfile(poke) } },
                            onPokeBack: { Task { await pokeBack(poke) } },
                            onDelete: { Task { await deleteReceivedPoke(poke) } }
                        )
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task { await deleteReceivedPoke(poke) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.white)
                    }
                } header: {
                    pokeSectionHeader("Received")
                }
            }

            if !pokeInbox.sentPokesSorted.isEmpty {
                Section {
                    ForEach(pokeInbox.sentPokesSorted) { poke in
                        SentPokeInboxRow(
                            poke: poke,
                            onViewProfile: { Task { await openSentPokeProfile(poke) } },
                            onDelete: { Task { await deleteSentPoke(poke) } }
                        )
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task { await deleteSentPoke(poke) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.white)
                    }
                } header: {
                    pokeSectionHeader("Sent")
                }
            }

            if !viewModel.pendingIncoming.isEmpty {
                Section {
                    ForEach(viewModel.pendingIncoming) { convo in
                        DMConversationRow(
                            conversation: convo,
                            subtitleOverride: convo.lastMessage ?? "Sent you a message",
                            showsApprove: true,
                            onApprove: {
                                guard gateMessagingAccess(
                                    subscriptionPaywall: {
                                        subscriptionPaywallForMessaging = true
                                        showSubscriptionPaywall = true
                                    },
                                    identityVerification: { showIdentityVerification = true }
                                ) else { return }
                                Task { await viewModel.approve(convo) }
                            },
                            showsDecline: true,
                            onDecline: {
                                Task { await viewModel.decline(convo) }
                            }
                        ) {
                            viewModel.selectConversation(convo)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.white)
                    }
                } header: {
                    pokeSectionHeader("Message requests")
                }
            }

            if !viewModel.awaitingApproval.isEmpty {
                Section {
                    ForEach(viewModel.awaitingApproval) { convo in
                        DMConversationRow(
                            conversation: convo,
                            subtitleOverride: convo.lastMessage ?? "Waiting for them to approve",
                            statusLabel: convo.isOutgoingDeclined ? "Declined" : "Pending",
                            showsWithdraw: true,
                            onWithdraw: {
                                Task { await viewModel.withdraw(convo) }
                            }
                        ) {
                            viewModel.selectConversation(convo)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.white)
                    }
                } header: {
                    pokeSectionHeader("Sent requests")
                }
            }

            if inboxIsEmpty {
                Section {
                    emptyInbox
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
            } else {
                if !viewModel.activeConversations.isEmpty {
                    Section {
                        ForEach(viewModel.activeConversations) { convo in
                            DMConversationRow(
                                conversation: convo,
                                subtitleOverride: convo.inboxSubtitle
                            ) {
                                viewModel.selectConversation(convo)
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.white)
                        }
                    } header: {
                        if !viewModel.pendingIncoming.isEmpty
                            || !viewModel.awaitingApproval.isEmpty
                            || !viewModel.closedConversations.isEmpty
                            || !pokeInbox.receivedPokesSorted.isEmpty
                            || !pokeInbox.sentPokesSorted.isEmpty {
                            pokeSectionHeader("Chats")
                        }
                    }
                }

                if !viewModel.closedConversations.isEmpty {
                    Section {
                        ForEach(viewModel.closedConversations) { convo in
                            DMConversationRow(
                                conversation: convo,
                                subtitleOverride: convo.inboxSubtitle
                            ) {
                                viewModel.selectConversation(convo)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button {
                                    Task { await viewModel.archive(convo) }
                                } label: {
                                    Text("Archive")
                                }
                                .tint(RidgitsColors.textSecondary)
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.white)
                        }
                    } header: {
                        pokeSectionHeader("Expired")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.white)
        .coordinateSpace(name: "ridgitsTabScroll")
        .refreshable {
            await viewModel.refresh()
        }
        .ridgitsTabBarScrollTracking()
        .ridgitsFloatingTabBarPadding()
    }

    private func pokeSectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(RidgitsColors.textSecondary)
            .textCase(nil)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
            .padding(.bottom, 4)
    }

    @MainActor
    private func openIncomingPokeIfNeeded() async {
        guard let incoming = incomingPokeProfile else { return }
        defer { incomingPokeProfile = nil }

        let userId = incoming.userId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userId.isEmpty else { return }

        if let poke = pokeInbox.receivedPokes.first(where: { $0.fromUserId == userId }) {
            await openPokeProfile(poke)
            return
        }

        if let pokeId = incoming.pokeId?.trimmingCharacters(in: .whitespacesAndNewlines),
           !pokeId.isEmpty {
            try? await RidgitsAPIClient.shared.markPokeSeen(
                pokeId: pokeId,
                profileVisited: true
            )
        }

        if let match = await matchesViewModel.resolveMatch(for: userId) {
            pokeProfileMatch = match
        }
    }

    @MainActor
    private func openPokeProfile(_ poke: RidgitsPoke) async {
        try? await RidgitsAPIClient.shared.markPokeSeen(
            pokeId: poke.id,
            profileVisited: true
        )

        if let match = await matchesViewModel.resolveMatch(for: poke.fromUserId) {
            pokeProfileMatch = match
        }
    }

    @MainActor
    private func pokeBack(_ poke: RidgitsPoke) async {
        try? await RidgitsAPIClient.shared.markPokeSeen(
            pokeId: poke.id,
            profileVisited: false
        )

        guard let match = await matchesViewModel.resolveMatch(for: poke.fromUserId) else { return }
        await requestPoke(for: match)
    }

    @MainActor
    private func deleteReceivedPoke(_ poke: RidgitsPoke) async {
        do {
            try await RidgitsAPIClient.shared.dismissReceivedPoke(pokeId: poke.id)
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func deleteSentPoke(_ poke: RidgitsPoke) async {
        do {
            try await RidgitsAPIClient.shared.unpoke(pokeId: poke.id)
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func openSentPokeProfile(_ poke: RidgitsPoke) async {
        if let match = await matchesViewModel.resolveMatch(for: poke.toUserId) {
            pokeProfileMatch = match
        }
    }

    @MainActor
    private func requestPoke(for match: RidgitsMatch) async {
        let alreadySent = pokeInbox.sentPokeIdsByUser[match.userId] != nil
        switch await matchesViewModel.preflightPoke(alreadySent: alreadySent) {
        case .alreadySent:
            return
        case .noCredits:
            showPokePackPaywall = true
        case .ready:
            pokeConfirmMatch = match
        }
    }

    @MainActor
    private func sendConversationRequest(to match: RidgitsMatch) async {
        guard ridgitsStore.hasPlusMembership else {
            subscriptionPaywallForMessaging = true
            showSubscriptionPaywall = true
            return
        }
        guard ridgitsStore.isVerifiedForMessaging else {
            showIdentityVerification = true
            return
        }
        let text = composeMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        if RidgitsMessagingValidation.blocksEarlyPhoneNumber(text: text, messageCount: 0) {
            viewModel.showEarlyPhoneNumberPrompt = true
            return
        }
        do {
            let conversationId = try await RidgitsFirebaseClient.shared.startConversation(
                toUserId: match.userId,
                message: text
            )
            composeMessage = ""
            composeMatch = nil
            viewModel.requestOpenConversation(with: match.userId, conversationId: conversationId)
        } catch let ridgitsError as RidgitsError {
            composeMatch = nil
            if ridgitsError.code == "EARLY_PHONE_NUMBER" {
                viewModel.showEarlyPhoneNumberPrompt = true
            } else if ridgitsError.code == "SUBSCRIPTION_REQUIRED" || ridgitsError.code == "MONTHLY_MESSAGE_LIMIT_REACHED" {
                subscriptionPaywallForMessaging = true
                showSubscriptionPaywall = true
            } else if ridgitsError.code == "AGE_VERIFICATION_REQUIRED" || ridgitsError.code == "UNDERAGE" {
                showBirthYearPrompt = true
            } else if handleExistingConversationError(ridgitsError, match: match) {
                return
            } else {
                viewModel.errorMessage = ridgitsError.localizedDescription
            }
        } catch {
            composeMatch = nil
            if handleExistingConversationError(error, match: match) { return }
            viewModel.errorMessage = error.localizedDescription
        }
    }

    private func gateMessagingAccess(
        subscriptionPaywall: () -> Void,
        identityVerification: () -> Void
    ) -> Bool {
        guard ridgitsStore.hasPlusMembership else {
            subscriptionPaywall()
            return false
        }
        guard ridgitsStore.isVerifiedForMessaging else {
            identityVerification()
            return false
        }
        return true
    }

    @discardableResult
    private func beginCompose(to match: RidgitsMatch) -> Bool {
        if let closedMessage = viewModel.messagingClosedMessage(for: match) {
            viewModel.errorMessage = closedMessage
            return false
        }
        composeMatch = match
        return true
    }

    private func handleExistingConversationError(_ error: Error, match: RidgitsMatch) -> Bool {
        let message = (error as? RidgitsError)?.localizedDescription ?? error.localizedDescription
        let normalized = message.lowercased()
        composeMatch = nil

        if normalized.contains("message limit reached")
            || normalized.contains("\(RidgitsMessagingLimits.maxMessages)-message") {
            viewModel.errorMessage =
                "You can't message them — you've already hit the \(RidgitsMessagingLimits.maxMessages)-message limit for this conversation."
            return true
        }
        if normalized.contains("expired") {
            viewModel.errorMessage = "You can't message them — this conversation has already expired."
            return true
        }
        guard normalized.contains("conversation already exists")
            || normalized.contains("awaiting approval") else {
            return false
        }
        viewModel.requestOpenConversation(with: match.userId)
        return true
    }

    private var emptyInbox: some View {
        Text("No messages or pokes yet")
            .font(RidgitsTypography.headline(17))
            .foregroundStyle(RidgitsColors.textHeadline)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 32)
            .padding(.top, 80)
    }
}

private struct MessageRequestsView: View {
    @EnvironmentObject private var ridgitsStore: RidgitsStore
    @EnvironmentObject private var pokeInbox: RidgitsPokeInbox
    @ObservedObject var viewModel: MessagingViewModel
    @ObservedObject var matchesViewModel: MatchesViewModel
    @Binding var composeMatch: RidgitsMatch?
    let onViewPokeProfile: (RidgitsPoke) async -> Void
    let onPokeBack: (RidgitsPoke) async -> Void
    let onDeletePoke: (RidgitsPoke) async -> Void
    let onDeleteSentPoke: (RidgitsPoke) async -> Void
    let onViewSentPokeProfile: (RidgitsPoke) async -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showSubscriptionPaywall = false
    @State private var showIdentityVerification = false

    var body: some View {
        NavigationStack {
            List {
                if pokeInbox.receivedPokesSorted.isEmpty
                    && pokeInbox.sentPokesSorted.isEmpty
                    && viewModel.pendingIncoming.isEmpty
                    && viewModel.awaitingApproval.isEmpty {
                    Section {
                        Text("No message or poke requests")
                            .font(RidgitsTypography.body(15))
                            .foregroundStyle(RidgitsColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 32)
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                }

                if !pokeInbox.receivedPokesSorted.isEmpty {
                    Section {
                        ForEach(pokeInbox.receivedPokesSorted) { poke in
                            PokeInboxRow(
                                poke: poke,
                                sentPokeBack: pokeInbox.sentPokeIdsByUser[poke.fromUserId] != nil,
                                onViewProfile: {
                                    dismiss()
                                    Task { await onViewPokeProfile(poke) }
                                },
                                onPokeBack: {
                                    dismiss()
                                    Task { await onPokeBack(poke) }
                                },
                                onDelete: {
                                    Task { await onDeletePoke(poke) }
                                }
                            )
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task { await onDeletePoke(poke) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.white)
                        }
                    } header: {
                        requestsSectionHeader("Received pokes")
                    }
                }

                if !pokeInbox.sentPokesSorted.isEmpty {
                    Section {
                        ForEach(pokeInbox.sentPokesSorted) { poke in
                            SentPokeInboxRow(
                                poke: poke,
                                onViewProfile: {
                                    dismiss()
                                    Task { await onViewSentPokeProfile(poke) }
                                },
                                onDelete: {
                                    Task { await onDeleteSentPoke(poke) }
                                }
                            )
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task { await onDeleteSentPoke(poke) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.white)
                        }
                    } header: {
                        requestsSectionHeader("Sent pokes")
                    }
                }

                if !viewModel.pendingIncoming.isEmpty {
                    Section {
                        ForEach(viewModel.pendingIncoming) { convo in
                            DMConversationRow(
                                conversation: convo,
                                subtitleOverride: convo.lastMessage ?? "Sent you a message",
                                showsApprove: true,
                                onApprove: {
                                    guard gateMessagingAccess(
                                        subscriptionPaywall: { showSubscriptionPaywall = true },
                                        identityVerification: { showIdentityVerification = true }
                                    ) else { return }
                                    Task { await viewModel.approve(convo) }
                                },
                                showsDecline: true,
                                onDecline: {
                                    Task { await viewModel.decline(convo) }
                                }
                            ) {
                                viewModel.selectConversation(convo)
                                dismiss()
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.white)
                        }
                    } header: {
                        requestsSectionHeader("Message requests")
                    }
                }

                if !viewModel.awaitingApproval.isEmpty {
                    Section {
                        ForEach(viewModel.awaitingApproval) { convo in
                            DMConversationRow(
                                conversation: convo,
                                subtitleOverride: convo.lastMessage ?? "Waiting for them to approve",
                                statusLabel: convo.isOutgoingDeclined ? "Declined" : "Pending",
                                showsWithdraw: true,
                                onWithdraw: {
                                    Task { await viewModel.withdraw(convo) }
                                }
                            ) {
                                viewModel.selectConversation(convo)
                                dismiss()
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.white)
                        }
                    } header: {
                        requestsSectionHeader("Awaiting approval")
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.white)
            .navigationTitle("Requests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showSubscriptionPaywall) {
            SubscriptionPaywallView(
                highlightTier: .plus,
                headline: "Subscribe to accept messages",
                subheadline: "Ridgits+ lets you approve requests and reply to people who reached out."
            )
        }
        .sheet(isPresented: $showIdentityVerification) {
            IdentityVerificationView(autoStart: true) { success in
                showIdentityVerification = false
                if success {
                    Task { await ridgitsStore.refreshAccessInBackground() }
                }
            }
            .environmentObject(ridgitsStore)
        }
    }

    private func gateMessagingAccess(
        subscriptionPaywall: () -> Void,
        identityVerification: () -> Void
    ) -> Bool {
        guard ridgitsStore.hasPlusMembership else {
            subscriptionPaywall()
            return false
        }
        guard ridgitsStore.isVerifiedForMessaging else {
            identityVerification()
            return false
        }
        return true
    }

    private func requestsSectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(RidgitsColors.textSecondary)
            .textCase(nil)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
            .padding(.bottom, 4)
    }
}

private struct PokeInboxRow: View {
    let poke: RidgitsPoke
    let sentPokeBack: Bool
    let onViewProfile: () -> Void
    let onPokeBack: () -> Void
    let onDelete: () -> Void

    @State private var imageURL = ""
    @State private var subscriptionTier: String?
    @State private var profilePhotoVerified = false

    private var isUnread: Bool { poke.isActionable }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Button(action: onViewProfile) {
                HStack(alignment: .center, spacing: 12) {
                    ChatAvatar(
                        imageURL: imageURL,
                        initial: String(poke.fromName.prefix(1)).uppercased(),
                        size: 56
                    )

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(poke.fromName)
                                .font(.system(size: 16, weight: isUnread ? .semibold : .regular))
                                .foregroundStyle(RidgitsColors.textHeadline)
                                .lineLimit(1)
                            RidgitsProfileTrustBadges(
                                subscriptionTier: subscriptionTier,
                                profilePhotoVerified: profilePhotoVerified,
                                badgeSize: 16
                            )
                            Spacer(minLength: 0)
                            if let timestamp = RidgitsMessageFormatting.relativeTimestamp(poke.createdAt) {
                                Text(timestamp)
                                    .font(.system(size: 14))
                                    .foregroundStyle(RidgitsColors.textMuted)
                            }
                        }
                        Text("Poked you")
                            .font(.system(size: 15))
                            .foregroundStyle(isUnread ? RidgitsColors.textHeadline : RidgitsColors.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
            .buttonStyle(RidgitsHapticPlainButtonStyle())

            if sentPokeBack {
                Text("Poked")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(RidgitsColors.textMuted)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .overlay(
                        Capsule()
                            .stroke(RidgitsColors.border, lineWidth: 1)
                    )
            } else {
                Button(action: onPokeBack) {
                    Text("Poke back")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(RidgitsColors.ctaBlack)
                        .clipShape(Capsule())
                }
                .buttonStyle(RidgitsHapticPlainButtonStyle())
            }

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(RidgitsColors.textMuted)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(RidgitsHapticPlainButtonStyle())
            .accessibilityLabel("Delete poke")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .task(id: poke.fromUserId) {
            if let cached = RidgitsPublicProfileCache.shared.profile(for: poke.fromUserId) {
                imageURL = cached.image
                subscriptionTier = cached.subscriptionTier
                profilePhotoVerified = cached.profilePhotoVerified
            } else if let profile = await RidgitsFirebaseClient.shared.fetchPublicProfile(uid: poke.fromUserId) {
                imageURL = profile.image
                subscriptionTier = profile.subscriptionTier
                profilePhotoVerified = profile.profilePhotoVerified
                RidgitsPublicProfileCache.shared.save(profile)
            }
        }
    }
}

private struct SentPokeInboxRow: View {
    let poke: RidgitsPoke
    let onViewProfile: () -> Void
    let onDelete: () -> Void

    @State private var imageURL = ""
    @State private var subscriptionTier: String?
    @State private var profilePhotoVerified = false

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Button(action: onViewProfile) {
                HStack(alignment: .center, spacing: 12) {
                    ChatAvatar(
                        imageURL: imageURL,
                        initial: String(poke.toName.prefix(1)).uppercased(),
                        size: 56
                    )

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(poke.toName)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundStyle(RidgitsColors.textHeadline)
                                .lineLimit(1)
                            RidgitsProfileTrustBadges(
                                subscriptionTier: subscriptionTier,
                                profilePhotoVerified: profilePhotoVerified,
                                badgeSize: 16
                            )
                            Spacer(minLength: 0)
                            if let timestamp = RidgitsMessageFormatting.relativeTimestamp(poke.createdAt) {
                                Text(timestamp)
                                    .font(.system(size: 14))
                                    .foregroundStyle(RidgitsColors.textMuted)
                            }
                        }
                        Text("You poked")
                            .font(.system(size: 15))
                            .foregroundStyle(RidgitsColors.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
            .buttonStyle(RidgitsHapticPlainButtonStyle())

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(RidgitsColors.textMuted)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(RidgitsHapticPlainButtonStyle())
            .accessibilityLabel("Delete poke")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .task(id: poke.toUserId) {
            if let cached = RidgitsPublicProfileCache.shared.profile(for: poke.toUserId) {
                imageURL = cached.image
                subscriptionTier = cached.subscriptionTier
                profilePhotoVerified = cached.profilePhotoVerified
            } else if let profile = await RidgitsFirebaseClient.shared.fetchPublicProfile(uid: poke.toUserId) {
                imageURL = profile.image
                subscriptionTier = profile.subscriptionTier
                profilePhotoVerified = profile.profilePhotoVerified
                RidgitsPublicProfileCache.shared.save(profile)
            }
        }
    }
}

struct DMConversationRow: View {
    let conversation: RidgitsConversation
    var subtitleOverride: String?
    var statusLabel: String?
    var showsApprove: Bool = false
    var onApprove: (() -> Void)?
    var showsDecline: Bool = false
    var onDecline: (() -> Void)?
    var showsWithdraw: Bool = false
    var onWithdraw: (() -> Void)?
    let onTap: () -> Void

    private var isUnread: Bool { conversation.unreadCount > 0 }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Button(action: onTap) {
                HStack(alignment: .center, spacing: 12) {
                    avatar
                    conversationText
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(RidgitsHapticPlainButtonStyle())

            if showsApprove, let onApprove {
                Button(action: onApprove) {
                    Text("Approve")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(RidgitsColors.ctaBlack)
                        .clipShape(Capsule())
                }
                .buttonStyle(RidgitsHapticPlainButtonStyle())
            }

            if showsDecline, let onDecline {
                Button(action: onDecline) {
                    Text("Decline")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(RidgitsColors.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                .buttonStyle(RidgitsHapticPlainButtonStyle())
            }

            if showsWithdraw, let onWithdraw {
                Button(action: onWithdraw) {
                    Text("Withdraw")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(RidgitsColors.destructive)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                .buttonStyle(RidgitsHapticPlainButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var conversationText: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(conversation.otherUserName)
                    .font(.system(size: 16, weight: isUnread ? .semibold : .regular))
                    .foregroundStyle(RidgitsColors.textHeadline)
                    .lineLimit(1)

                RidgitsProfileTrustBadges(
                    subscriptionTier: conversation.otherUserSubscriptionTier,
                    profilePhotoVerified: conversation.otherUserProfilePhotoVerified,
                    badgeSize: 16
                )

                Spacer(minLength: 0)

                if let timestamp = RidgitsMessageFormatting.relativeTimestamp(conversation.lastMessageAt) {
                    Text(timestamp)
                        .font(.system(size: 14))
                        .foregroundStyle(RidgitsColors.textMuted)
                }
            }

            HStack(spacing: 6) {
                Text(previewText)
                    .font(.system(size: 15, weight: isUnread ? .semibold : .regular))
                    .foregroundStyle(isUnread ? RidgitsColors.textHeadline : RidgitsColors.textSecondary)
                    .lineLimit(1)

                if let statusLabel {
                    Text("· \(statusLabel)")
                        .font(.system(size: 15))
                        .foregroundStyle(RidgitsColors.textMuted)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                if isUnread && !showsApprove {
                    Circle()
                        .fill(RidgitsColors.primaryBlue)
                        .frame(width: 8, height: 8)
                }
            }
        }
    }

    private var previewText: String {
        if let subtitleOverride { return subtitleOverride }
        return conversation.lastMessage ?? "No messages yet"
    }

    @ViewBuilder
    private var avatar: some View {
        ChatAvatar(
            imageURL: conversation.otherUserImage,
            initial: String(conversation.otherUserName.prefix(1)).uppercased(),
            size: 56
        )
    }
}

private enum RidgitsMessageFormatting {
    static func relativeTimestamp(_ date: Date?) -> String? {
        guard let date else { return nil }
        let interval = Date().timeIntervalSince(date)
        if interval < 60 { return "now" }
        if interval < 3600 { return "\(Int(interval / 60))m" }
        if interval < 86_400 { return "\(Int(interval / 3600))h" }
        if interval < 604_800 { return "\(Int(interval / 86_400))d" }
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yy"
        return formatter.string(from: date)
    }
}

struct ConversationDetailView: View {
    @EnvironmentObject private var ridgitsStore: RidgitsStore
    @ObservedObject var viewModel: MessagingViewModel
    let conversation: RidgitsConversation
    let onBack: () -> Void
    @State private var showFlagSheet = false
    @State private var showSubscriptionPaywall = false
    @State private var showIdentityVerification = false
    @State private var flagReason = ""
    @State private var currentUserImageURL = ""
    @State private var currentUserInitial = "?"

    private var otherUserInitial: String {
        String(conversation.otherUserName.prefix(1)).uppercased()
    }

    var body: some View {
        VStack(spacing: 0) {
            if let countdown = viewModel.countdownLabel {
                HStack {
                    Image(systemName: "clock")
                    Text(countdown)
                    Text("· \(conversation.messagesRemaining) messages left")
                }
                .font(RidgitsTypography.caption())
                .foregroundStyle(RidgitsColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(RidgitsColors.contextBar)
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.messages) { message in
                            let isMine = message.senderId == Auth.auth().currentUser?.uid
                            MessageBubble(
                                message: message,
                                isMine: isMine,
                                avatarImageURL: isMine ? currentUserImageURL : conversation.otherUserImage,
                                avatarInitial: isMine ? currentUserInitial : otherUserInitial
                            )
                            .id(message.id)
                        }
                    }
                    .padding(16)
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    if let last = viewModel.messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            if conversation.canSendMessage && (viewModel.timeRemaining ?? 1) > 0 {
                HStack(spacing: 8) {
                    TextField("Message", text: $viewModel.messageText, axis: .vertical)
                        .lineLimit(1...4)
                        .foregroundStyle(RidgitsColors.textHeadline)
                        .tint(RidgitsColors.ctaBlack)
                        .colorScheme(.light)
                        .padding(10)
                        .background(RidgitsColors.inputSurface)
                        .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.md))
                    Button {
                        guard gateConversationMessagingAccess() else { return }
                        Task { await viewModel.sendMessage() }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(RidgitsColors.ctaBlack)
                    }
                    .disabled(viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSending)
                }
                .padding(12)
                .background(RidgitsColors.surface)
            } else if conversation.isMessagingClosed {
                Text(conversation.messagingClosedThreadMessage)
                    .font(RidgitsTypography.body(13))
                    .foregroundStyle(RidgitsColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding()
            } else if conversation.isIncomingPending {
                VStack(spacing: 12) {
                    RidgitsPrimaryButton(title: acceptButtonTitle) {
                        guard gateConversationMessagingAccess() else { return }
                        Task { await viewModel.approve(conversation) }
                    }
                    Button("Decline") {
                        Task { await viewModel.decline(conversation) }
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(RidgitsColors.textSecondary)
                }
                .padding()
            } else if conversation.isOutgoingPending || conversation.isOutgoingDeclined {
                VStack(spacing: 8) {
                    Text(
                        conversation.isOutgoingDeclined
                            ? "They declined your message request."
                            : "Waiting for them to approve your message."
                    )
                    .font(RidgitsTypography.body(14))
                    .foregroundStyle(RidgitsColors.textSecondary)
                    .multilineTextAlignment(.center)

                    Button("Withdraw request") {
                        Task { await viewModel.withdraw(conversation) }
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(RidgitsColors.destructive)
                }
                .padding()
            }
        }
        .padding(.bottom, 98)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(RidgitsColors.textHeadline)
                }
                .buttonStyle(RidgitsHapticPlainButtonStyle())
                .accessibilityLabel("Back")
            }
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    ChatAvatar(
                        imageURL: conversation.otherUserImage,
                        initial: otherUserInitial,
                        size: 28
                    )
                    HStack(spacing: 6) {
                        Text(conversation.otherUserName)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(RidgitsColors.textHeadline)
                            .lineLimit(1)
                        RidgitsProfileTrustBadges(
                            subscriptionTier: conversation.otherUserSubscriptionTier,
                            profilePhotoVerified: conversation.otherUserProfilePhotoVerified,
                            badgeSize: 16
                        )
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if conversation.isMessagingClosed {
                        Button {
                            Task {
                                await viewModel.archive(conversation)
                                onBack()
                            }
                        } label: {
                            Label("Archive", systemImage: "archivebox")
                        }
                    }
                    Button(role: .destructive) {
                        showFlagSheet = true
                    } label: {
                        Label("Report conversation", systemImage: "flag")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(RidgitsColors.textHeadline)
                }
            }
        }
        .task(id: conversation.id) {
            await loadCurrentUserAvatar()
            RidgitsProfileCache.shared.scheduleImagePrefetch(remoteURL: conversation.otherUserImage)
        }
        .sheet(isPresented: $showSubscriptionPaywall) {
            SubscriptionPaywallView(
                highlightTier: .plus,
                headline: "Subscribe to respond",
                subheadline: "Ridgits+ lets you accept message requests and keep the conversation going."
            )
        }
        .sheet(isPresented: $showIdentityVerification) {
            IdentityVerificationView(autoStart: true) { success in
                showIdentityVerification = false
                if success {
                    Task { await ridgitsStore.refreshAccessInBackground() }
                }
            }
            .environmentObject(ridgitsStore)
        }
        .sheet(isPresented: $showFlagSheet) {
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Report conversation")
                            .font(RidgitsTypography.headline(20))
                            .foregroundStyle(RidgitsColors.textHeadline)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.bottom, 4)

                        Text("What happens when you report")
                            .font(RidgitsTypography.headline(17))
                            .foregroundStyle(RidgitsColors.textHeadline)

                        VStack(alignment: .leading, spacing: 8) {
                            reportInfoRow("Your report is sent to our moderation team with high priority.")
                            reportInfoRow("We review the conversation and the reported member's account signals.")
                            reportInfoRow("If two or more members report the same person within 7 days, their messaging is paused while we investigate.")
                        }

                        Text("Tell us why you're reporting this conversation.")
                            .font(RidgitsTypography.body(14))
                            .foregroundStyle(RidgitsColors.textSecondary)

                        TextField("Reason for report", text: $flagReason, axis: .vertical)
                            .lineLimit(3...6)
                            .padding(12)
                            .background(RidgitsColors.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: RidgitsRadius.md)
                                    .stroke(RidgitsColors.inputBorder, lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.md))

                        RidgitsPrimaryButton(title: viewModel.isFlagging ? "Submitting…" : "Submit report") {
                            Task {
                                await viewModel.flagConversation(conversation, reason: flagReason)
                                if viewModel.flagSuccessMessage != nil {
                                    showFlagSheet = false
                                    flagReason = ""
                                }
                            }
                        }
                        .disabled(flagReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isFlagging)
                    }
                    .padding(20)
                    .padding(.bottom, 8)
                }
            }
            .background(RidgitsColors.feedBackground.ignoresSafeArea())
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .onChange(of: showFlagSheet) { _, isPresented in
                if !isPresented {
                    flagReason = ""
                }
            }
        }
        .alert("Report submitted", isPresented: Binding(
            get: { viewModel.flagSuccessMessage != nil },
            set: { if !$0 { viewModel.flagSuccessMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.flagSuccessMessage ?? "")
        }
    }

    private var acceptButtonTitle: String {
        if !ridgitsStore.hasPlusMembership { return "Subscribe to accept" }
        if !ridgitsStore.isVerifiedForMessaging { return "Verify to accept" }
        return "Accept message"
    }

    private func gateConversationMessagingAccess() -> Bool {
        guard ridgitsStore.hasPlusMembership else {
            showSubscriptionPaywall = true
            return false
        }
        guard ridgitsStore.isVerifiedForMessaging else {
            showIdentityVerification = true
            return false
        }
        return true
    }

    @MainActor
    private func loadCurrentUserAvatar() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        if let cached = RidgitsProfileCache.shared.profile(for: uid) {
            currentUserImageURL = cached.image
            let name = cached.name.trimmingCharacters(in: .whitespacesAndNewlines)
            if !name.isEmpty {
                currentUserInitial = String(name.prefix(1)).uppercased()
            }
            RidgitsProfileCache.shared.scheduleImagePrefetch(remoteURL: cached.image)
            return
        }

        if let profile = await RidgitsFirebaseClient.shared.fetchPublicProfile(uid: uid) {
            currentUserImageURL = profile.image
            let name = profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
            if !name.isEmpty {
                currentUserInitial = String(name.prefix(1)).uppercased()
            }
            RidgitsProfileCache.shared.save(profile)
        }
    }

    private func reportInfoRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(RidgitsTypography.body(14))
                .foregroundStyle(RidgitsColors.textSecondary)
            Text(text)
                .font(RidgitsTypography.body(14))
                .foregroundStyle(RidgitsColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct ChatAvatar: View {
    let imageURL: String
    let initial: String
    var size: CGFloat = 32

    var body: some View {
        Group {
            if imageURL.isEmpty {
                initialsAvatar
            } else {
                RidgitsCachedProfileImage(remoteURL: imageURL) {
                    initialsAvatar
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(RidgitsColors.border.opacity(0.6), lineWidth: 0.5)
        )
    }

    private var initialsAvatar: some View {
        Circle()
            .fill(RidgitsColors.contextBar)
            .overlay {
                Text(initial.isEmpty ? "?" : initial)
                    .font(.system(size: size * 0.38, weight: .semibold))
                    .foregroundStyle(RidgitsColors.textSecondary)
            }
    }
}

private struct MessageBubble: View {
    let message: RidgitsMessage
    let isMine: Bool
    let avatarImageURL: String
    let avatarInitial: String

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isMine { Spacer(minLength: 24) }

            if !isMine {
                ChatAvatar(imageURL: avatarImageURL, initial: avatarInitial, size: 32)
            }

            Text(message.text)
                .font(RidgitsTypography.body(14))
                .foregroundStyle(isMine ? .white : RidgitsColors.textHeadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isMine ? RidgitsColors.ctaBlack : RidgitsColors.contextBar)
                .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.lg))

            if isMine {
                ChatAvatar(imageURL: avatarImageURL, initial: avatarInitial, size: 32)
            }

            if !isMine { Spacer(minLength: 24) }
        }
    }
}
