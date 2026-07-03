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

    private var conversationsListener: ListenerRegistration?
    private var messagesListener: ListenerRegistration?
    private var conversationListener: ListenerRegistration?
    private var countdownTimer: Timer?

    var pendingIncoming: [RidgitsConversation] {
        conversations.filter(\.isIncomingPending)
    }

    var awaitingApproval: [RidgitsConversation] {
        conversations.filter(\.isOutgoingPending)
    }

    var activeConversations: [RidgitsConversation] {
        conversations.filter { $0.status == .active || ($0.status == .pending && !$0.isIncomingPending && !$0.isOutgoingPending) }
            .filter { !$0.isIncomingPending && !$0.isOutgoingPending }
    }

    func startListening() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        conversationsListener?.remove()
        conversationsListener = RidgitsFirebaseClient.shared.listenConversations(userId: uid) { [weak self] convos in
            Task { @MainActor in self?.conversations = convos }
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
    @StateObject private var viewModel = MessagingViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if let selected = viewModel.selectedConversation {
                    ConversationDetailView(viewModel: viewModel, conversation: selected)
                } else {
                    conversationList
                }
            }
            .background(RidgitsColors.feedBackground)
            .navigationTitle(viewModel.selectedConversation == nil ? "Messages" : "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if viewModel.selectedConversation != nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Back") {
                            viewModel.selectedConversation = nil
                            viewModel.messagesListenerCleanup()
                        }
                    }
                }
            }
        }
        .onAppear { viewModel.startListening() }
        .onDisappear { viewModel.stopListening() }
    }

    private var conversationList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if !viewModel.pendingIncoming.isEmpty {
                    section(title: "Pending requests", conversations: viewModel.pendingIncoming, pending: true)
                }
                if !viewModel.awaitingApproval.isEmpty {
                    section(title: "Awaiting approval", conversations: viewModel.awaitingApproval, pending: true)
                }
                section(title: "Active", conversations: viewModel.activeConversations, pending: false)
            }
            .padding(20)
        }
    }

    private func section(title: String, conversations: [RidgitsConversation], pending: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(RidgitsTypography.headline(16))
                .foregroundStyle(RidgitsColors.textHeadline)
            if conversations.isEmpty {
                Text("None")
                    .font(RidgitsTypography.body(14))
                    .foregroundStyle(RidgitsColors.textSecondary)
            } else {
                ForEach(conversations) { convo in
                    ConversationRow(conversation: convo, pending: pending) {
                        viewModel.selectConversation(convo)
                    } onApprove: {
                        Task { await viewModel.approve(convo) }
                    }
                }
            }
        }
    }
}

private struct ConversationRow: View {
    let conversation: RidgitsConversation
    let pending: Bool
    let onTap: () -> Void
    let onApprove: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: conversation.otherUserImage)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    RidgitsColors.border
                }
                .frame(width: 48, height: 48)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(conversation.otherUserName)
                        .font(RidgitsTypography.headline(15))
                        .foregroundStyle(RidgitsColors.textHeadline)
                    Text(conversation.lastMessage ?? "No messages yet")
                        .font(RidgitsTypography.body(13))
                        .foregroundStyle(RidgitsColors.textSecondary)
                        .lineLimit(1)
                }
                Spacer()
                if conversation.unreadCount > 0 {
                    Text("\(conversation.unreadCount)")
                        .font(RidgitsTypography.caption(11))
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(RidgitsColors.ctaBlack)
                        .clipShape(Circle())
                }
            }
            .padding(12)
            .background(pending ? RidgitsColors.pendingYellow : RidgitsColors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: RidgitsRadius.lg)
                    .stroke(pending ? RidgitsColors.pendingBorder : RidgitsColors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.lg))
        }
        .overlay(alignment: .bottomTrailing) {
            if conversation.isIncomingPending {
                Button("Approve", action: onApprove)
                    .font(RidgitsTypography.label(12))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(RidgitsColors.ctaBlack)
                    .clipShape(Capsule())
                    .padding(8)
            }
        }
    }
}

struct ConversationDetailView: View {
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
                    Task { await viewModel.approve(conversation) }
                }
                .padding()
            }
        }
        .navigationTitle(conversation.otherUserName)
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
