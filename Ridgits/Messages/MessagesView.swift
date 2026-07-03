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
            if ridgitsError.code == "SUBSCRIPTION_REQUIRED" {
                showPaywallPrompt = true
            }
            errorMessage = ridgitsError.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func sendMessage() async {
        guard let conversation = selectedConversation else { return }
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, conversation.canSendMessage else { return }
        isSending = true
        defer { isSending = false }
        do {
            try await RidgitsFirebaseClient.shared.sendMessage(conversationId: conversation.id, message: trimmed)
            messageText = ""
        } catch let ridgitsError as RidgitsError {
            if ridgitsError.code == "SUBSCRIPTION_REQUIRED" {
                showPaywallPrompt = true
            }
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
    @EnvironmentObject private var ridgitsStore: RidgitsStore
    @ObservedObject var viewModel: MessagingViewModel
    @State private var showRequests = false
    @State private var showSubscriptionPaywall = false

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
            MessageRequestsView(viewModel: viewModel)
        }
        .sheet(isPresented: $showSubscriptionPaywall) {
            SubscriptionPaywallView(preferredBilling: .yearly)
        }
        .onChange(of: viewModel.showPaywallPrompt) { _, showPaywall in
            guard showPaywall else { return }
            viewModel.showPaywallPrompt = false
            showSubscriptionPaywall = true
        }
        .alert("Couldn't send message", isPresented: Binding(
            get: { viewModel.errorMessage != nil && !viewModel.showPaywallPrompt },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var inboxHeader: some View {
        HStack(alignment: .center) {
            Text("Messages")
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

                    if viewModel.incomingRequestCount > 0 {
                        Text("\(viewModel.incomingRequestCount)")
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
        .background(Color.white)
    }

    private var conversationList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                if viewModel.activeConversations.isEmpty {
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

    private var emptyInbox: some View {
        VStack(spacing: 8) {
            Text("No messages yet")
                .font(RidgitsTypography.headline(17))
                .foregroundStyle(RidgitsColors.textHeadline)
            Text("Send a message to a match to start chatting")
                .font(RidgitsTypography.body(15))
                .foregroundStyle(RidgitsColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
        .padding(.top, 80)
    }
}

private struct MessageRequestsView: View {
    @EnvironmentObject private var ridgitsStore: RidgitsStore
    @ObservedObject var viewModel: MessagingViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    if viewModel.pendingIncoming.isEmpty && viewModel.awaitingApproval.isEmpty {
                        Text("No message requests")
                            .font(RidgitsTypography.body(15))
                            .foregroundStyle(RidgitsColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 48)
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
        Group {
            if let url = URL(string: conversation.otherUserImage), !conversation.otherUserImage.isEmpty {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        initialsAvatar
                    }
                }
            } else {
                initialsAvatar
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(Circle())
    }

    private var initialsAvatar: some View {
        Circle()
            .fill(RidgitsColors.contextBar)
            .overlay {
                Text(conversation.otherUserName.prefix(1).uppercased())
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(RidgitsColors.textSecondary)
            }
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
                            MessageBubble(
                                message: message,
                                isMine: message.senderId == Auth.auth().currentUser?.uid
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
        .padding(.bottom, 72)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Text(conversation.otherUserName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(RidgitsColors.textHeadline)
                        .lineLimit(1)
                    RidgitsVerifiedBadge(tier: conversation.otherUserSubscriptionTier, size: 16)
                }
            }
        }
    }
}

private struct MessageBubble: View {
    let message: RidgitsMessage
    let isMine: Bool

    var body: some View {
        HStack {
            if isMine { Spacer(minLength: 40) }
            Text(message.text)
                .font(RidgitsTypography.body(14))
                .foregroundStyle(isMine ? .white : RidgitsColors.textHeadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isMine ? RidgitsColors.ctaBlack : RidgitsColors.contextBar)
                .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.lg))
            if !isMine { Spacer(minLength: 40) }
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
