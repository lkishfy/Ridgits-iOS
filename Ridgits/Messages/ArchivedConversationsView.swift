import SwiftUI
import FirebaseAuth

struct ArchivedConversationsView: View {
    @StateObject private var viewModel = MessagingViewModel()
    @State private var selectedConversation: RidgitsConversation?

    var body: some View {
        Group {
            if viewModel.archivedConversations.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "archivebox")
                        .font(.system(size: 28))
                        .foregroundStyle(RidgitsColors.textMuted)
                    Text("No archived conversations")
                        .font(RidgitsTypography.headline(17))
                        .foregroundStyle(RidgitsColors.textHeadline)
                    Text("Expired conversations you archive will appear here.")
                        .font(RidgitsTypography.body(14))
                        .foregroundStyle(RidgitsColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(24)
            } else {
                List {
                    ForEach(viewModel.archivedConversations) { convo in
                        DMConversationRow(
                            conversation: convo,
                            subtitleOverride: convo.inboxSubtitle
                        ) {
                            selectedConversation = convo
                            viewModel.selectConversation(convo)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button {
                                Task { await viewModel.unarchive(convo) }
                            } label: {
                                Label("Unarchive", systemImage: "arrow.uturn.backward")
                            }
                            .tint(RidgitsColors.textSecondary)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.white)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(RidgitsColors.feedBackground)
        .navigationTitle("Archived Conversations")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.startListening() }
        .onDisappear { viewModel.stopListening() }
        .navigationDestination(item: $selectedConversation) { conversation in
            ConversationDetailView(
                viewModel: viewModel,
                conversation: conversation,
                onBack: {
                    selectedConversation = nil
                    viewModel.closeConversation()
                }
            )
        }
    }
}
