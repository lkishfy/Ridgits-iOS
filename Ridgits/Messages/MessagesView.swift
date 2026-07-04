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
    @Published var isFlagging = false
    @Published var flagSuccessMessage: String?

    private var conversationsListener: ListenerRegistration?
    private var messagesListener: ListenerRegistration?
    private var conversationListener: ListenerRegistration?
    private var countdownTimer: Timer?

    var pendingIncoming: [RidgitsConversation] {
        sortedByRecency(conversations.filter(\.isIncomingPending))
    }

    var awaitingApproval: [RidgitsConversation] {
        sortedByRecency(conversations.filter(\.isOutgoingPending))
    }

    var activeConversations: [RidgitsConversation] {
        sortedByRecency(
            conversations.filter { conversation in
                !conversation.isIncomingPending && !conversation.isOutgoingPending
                    && (conversation.status == .active || conversation.status == .pending)
            }
        )
    }

    var incomingRequestCount: Int {
        pendingIncoming.count
    }

    var canSendMonthlyMessage: Bool { true }

    func startListening() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        if conversations.isEmpty, let cached = RidgitsConversationsCache.shared.conversations(for: uid) {
            conversations = cached
        }

        guard conversationsListener == nil else { return }

        conversationsListener = RidgitsFirebaseClient.shared.listenConversations(userId: uid) { [weak self] convos in
            Task { @MainActor in
                self?.conversations = convos
                RidgitsConversationsCache.shared.save(convos, uid: uid)
            }
        }
    }

    func refresh() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            let convos = try await RidgitsFirebaseClient.shared.fetchConversations(
                userId: uid,
                forceRefreshProfiles: true
            )
            conversations = convos
            RidgitsConversationsCache.shared.save(convos, uid: uid)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func handleMessagingError(_ ridgitsError: RidgitsError) {
        if ridgitsError.code == "SUBSCRIPTION_REQUIRED" {
            showPaywallPrompt = true
        } else if ridgitsError.code == "AGE_VERIFICATION_REQUIRED" || ridgitsError.code == "UNDERAGE" {
            showBirthYearPrompt = true
            return
        }
        errorMessage = ridgitsError.localizedDescription
    }

    func selectConversation(_ conversation: RidgitsConversation) {
        selectedConversation = conversation
        messagesListener?.remove()
        conversationListener?.remove()
        messages = []
        messagesListener = RidgitsFirebaseClient.shared.listenMessages(conversationId: conversation.id) { [weak self] msgs in
            Task { @MainActor in self?.messages = msgs }
        }
        conversationListener = RidgitsFirebaseClient.shared.listenConversation(conversationId: conversation.id) { [weak self] convo in
            Task { @MainActor in
                guard let convo else {
                    self?.selectedConversation = nil
                    return
                }
                self?.selectedConversation = convo
                self?.updateCountdown()
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

    func sendMessage() async {
        guard let conversation = selectedConversation else { return }
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, conversation.canSendMessage, canSendMonthlyMessage else { return }
        isSending = true
        defer { isSending = false }
        do {
            try await RidgitsFirebaseClient.shared.sendMessage(conversationId: conversation.id, message: trimmed)
            messageText = ""
        } catch let ridgitsError as RidgitsError {
            handleMessagingError(ridgitsError)
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
    @State private var showBirthYearPrompt = false
    @State private var composeMatch: RidgitsMatch?
    @State private var composeMessage = ""
    @State private var pokeProfileMatch: RidgitsMatch?
    @State private var showPokePackPaywall = false
    @State private var pokeConfirmMatch: RidgitsMatch?

    var body: some View {
        NavigationStack {
            Group {
                if let selected = viewModel.selectedConversation {
                    ConversationDetailView(viewModel: viewModel, conversation: selected)
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
                            showSubscriptionPaywall = true
                            return
                        }
                        composeMatch = match
                        pokeProfileMatch = nil
                    },
                    onPoke: {
                        Task { await requestPoke(for: match) }
                    }
                )
            }
            .toolbar {
                if viewModel.selectedConversation != nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            viewModel.selectedConversation = nil
                            viewModel.messagesListenerCleanup()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(RidgitsColors.textHeadline)
                        }
                    }
                } else {
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
            SubscriptionPaywallView(preferredBilling: .yearly)
        }
        .fullScreenCover(isPresented: $showBirthYearPrompt) {
            BirthYearPromptView {
                showBirthYearPrompt = false
            }
            .environmentObject(authManager)
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
                Text("Send a poke to \(match.name)? This uses 1 credit and can't be undone.")
            }
        }
        .onChange(of: viewModel.showPaywallPrompt) { _, showPaywall in
            guard showPaywall else { return }
            viewModel.showPaywallPrompt = false
            showSubscriptionPaywall = true
        }
        .onChange(of: viewModel.showBirthYearPrompt) { _, showPrompt in
            guard showPrompt else { return }
            viewModel.showBirthYearPrompt = false
            showBirthYearPrompt = true
        }
        .task(id: incomingPokeProfile?.id) {
            await openIncomingPokeIfNeeded()
        }
        .alert("Couldn't send message", isPresented: Binding(
            get: { viewModel.errorMessage != nil && !viewModel.showPaywallPrompt && !viewModel.showBirthYearPrompt },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
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
                    HStack(spacing: 6) {
                        Text("Requests")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(RidgitsColors.textSecondary)

                        if viewModel.incomingRequestCount + pokeInbox.unseenCount > 0 {
                            Text("\(viewModel.incomingRequestCount + pokeInbox.unseenCount)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(minWidth: 18, minHeight: 18)
                                .background(RidgitsColors.destructive)
                                .clipShape(Circle())
                        }
                    }
                }
                .buttonStyle(RidgitsHapticPlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .background(Color.white)
    }

    private var conversationList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                if !pokeInbox.receivedPokesSorted.isEmpty {
                    pokesInboxSection
                }

                if viewModel.activeConversations.isEmpty && pokeInbox.receivedPokesSorted.isEmpty {
                    emptyInbox
                } else {
                    ForEach(viewModel.activeConversations) { convo in
                        DMConversationRow(conversation: convo) {
                            viewModel.selectConversation(convo)
                        }
                    }
                }
            }
            .ridgitsTabBarScrollTracking()
            .ridgitsFloatingTabBarPadding()
        }
        .coordinateSpace(name: "ridgitsTabScroll")
        .refreshable {
            await viewModel.refresh()
        }
    }

    private var pokesInboxSection: some View {
        VStack(spacing: 0) {
            Text("Pokes")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(RidgitsColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

            ForEach(pokeInbox.receivedPokesSorted) { poke in
                PokeInboxRow(
                    poke: poke,
                    sentPokeBack: pokeInbox.sentPokeIdsByUser[poke.fromUserId] != nil,
                    onViewProfile: {
                        Task { await openPokeProfile(poke) }
                    },
                    onPokeBack: {
                        Task { await pokeBack(poke) }
                    }
                )
            }

            if !viewModel.activeConversations.isEmpty {
                Divider()
                    .padding(.top, 8)
                Text("Chats")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(RidgitsColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
            }
        }
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
            showSubscriptionPaywall = true
            return
        }
        let text = composeMessage
        do {
            _ = try await RidgitsFirebaseClient.shared.startConversation(
                toUserId: match.userId,
                message: text
            )
            composeMessage = ""
            composeMatch = nil
        } catch let ridgitsError as RidgitsError {
            composeMatch = nil
            if ridgitsError.code == "SUBSCRIPTION_REQUIRED" || ridgitsError.code == "MONTHLY_MESSAGE_LIMIT_REACHED" {
                showSubscriptionPaywall = true
            } else if ridgitsError.code == "AGE_VERIFICATION_REQUIRED" || ridgitsError.code == "UNDERAGE" {
                showBirthYearPrompt = true
            } else {
                viewModel.errorMessage = ridgitsError.localizedDescription
            }
        } catch {
            composeMatch = nil
            viewModel.errorMessage = error.localizedDescription
        }
    }

    private var emptyInbox: some View {
        VStack(spacing: 8) {
            Text("No messages yet")
                .font(RidgitsTypography.headline(17))
                .foregroundStyle(RidgitsColors.textHeadline)
            Text("Send a message to a match to start chatting")
                .font(RidgitsTypography.body(15))
                .foregroundStyle(RidgitsColors.textSecondary)
                .multilineTextAlignment(.center)
            Text("When someone pokes you, they'll show up here — tap their name to view their profile or poke back.")
                .font(RidgitsTypography.caption(13))
                .foregroundStyle(RidgitsColors.textMuted)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
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
    @Environment(\.dismiss) private var dismiss
    @State private var showSubscriptionPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    if pokeInbox.receivedPokesSorted.isEmpty
                        && viewModel.pendingIncoming.isEmpty
                        && viewModel.awaitingApproval.isEmpty {
                        Text("No message or poke requests")
                            .font(RidgitsTypography.body(15))
                            .foregroundStyle(RidgitsColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 48)
                    }

                    if !pokeInbox.receivedPokesSorted.isEmpty {
                        requestsSectionHeader("Pokes")
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
                                }
                            )
                        }
                    }

                    if !viewModel.pendingIncoming.isEmpty {
                        requestsSectionHeader("Message requests")
                        ForEach(viewModel.pendingIncoming) { convo in
                            DMConversationRow(
                                conversation: convo,
                                subtitleOverride: convo.lastMessage ?? "Sent you a message",
                                showsApprove: true,
                                onApprove: {
                                    guard ridgitsStore.hasPlusMembership else {
                                        viewModel.showPaywallPrompt = true
                                        return
                                    }
                                    Task { await viewModel.approve(convo) }
                                }
                            ) {
                                viewModel.selectConversation(convo)
                                dismiss()
                            }
                        }
                    }

                    if !viewModel.awaitingApproval.isEmpty {
                        requestsSectionHeader("Awaiting approval")
                        ForEach(viewModel.awaitingApproval) { convo in
                            DMConversationRow(
                                conversation: convo,
                                subtitleOverride: convo.lastMessage ?? "Waiting for them to approve",
                                statusLabel: "Pending"
                            ) {
                                viewModel.selectConversation(convo)
                                dismiss()
                            }
                        }
                    }
                }
                .padding(.bottom, 24)
            }
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
            SubscriptionPaywallView(preferredBilling: .yearly)
        }
    }

    private func requestsSectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(RidgitsColors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 8)
    }
}

private struct PokeInboxRow: View {
    let poke: RidgitsPoke
    let sentPokeBack: Bool
    let onViewProfile: () -> Void
    let onPokeBack: () -> Void

    @State private var imageURL = ""
    @State private var subscriptionTier: String?

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
                            RidgitsVerifiedBadge(tier: subscriptionTier, size: 16)
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
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .task(id: poke.fromUserId) {
            if let cached = RidgitsPublicProfileCache.shared.profile(for: poke.fromUserId) {
                imageURL = cached.image
                subscriptionTier = cached.subscriptionTier
            } else if let profile = await RidgitsFirebaseClient.shared.fetchPublicProfile(uid: poke.fromUserId) {
                imageURL = profile.image
                subscriptionTier = profile.subscriptionTier
                RidgitsPublicProfileCache.shared.save(profile)
            }
        }
    }
}

private struct DMConversationRow: View {
    let conversation: RidgitsConversation
    var subtitleOverride: String?
    var statusLabel: String?
    var showsApprove: Bool = false
    var onApprove: (() -> Void)?
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

                RidgitsVerifiedBadge(tier: conversation.otherUserSubscriptionTier, size: 16)

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
    @State private var showFlagSheet = false
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
                        .padding(10)
                        .background(RidgitsColors.inputSurface)
                        .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.md))
                    Button {
                        guard ridgitsStore.hasPlusMembership else {
                            viewModel.showPaywallPrompt = true
                            return
                        }
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
            } else if conversation.status == .active {
                Text("This conversation has expired or reached the 16-message limit.")
                    .font(RidgitsTypography.body(13))
                    .foregroundStyle(RidgitsColors.textSecondary)
                    .padding()
            } else if conversation.isIncomingPending {
                RidgitsPrimaryButton(title: "Approve conversation") {
                    guard ridgitsStore.hasPlusMembership else {
                        viewModel.showPaywallPrompt = true
                        return
                    }
                    Task { await viewModel.approve(conversation) }
                }
                .padding()
            }
        }
        .padding(.bottom, 98)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
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
                        RidgitsVerifiedBadge(tier: conversation.otherUserSubscriptionTier, size: 16)
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
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
        .sheet(isPresented: $showFlagSheet) {
            NavigationStack {
                VStack(alignment: .leading, spacing: 16) {
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
                        .background(RidgitsColors.inputSurface)
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

                    Spacer()
                }
                .padding(20)
                .navigationTitle("Report conversation")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") {
                            showFlagSheet = false
                            flagReason = ""
                        }
                    }
                }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
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

extension MessagingViewModel {
    fileprivate func messagesListenerCleanup() {
        messagesListener?.remove()
        conversationListener?.remove()
        countdownTimer?.invalidate()
        messages = []
        timeRemaining = nil
    }
}
