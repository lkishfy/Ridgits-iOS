import SwiftUI

struct NotificationPreferencesView: View {
    @State private var preferences = RidgitsNotificationPreferences()
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var statusMessage: String?
    @State private var hasLoaded = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                RidgitsDashboardCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Push notifications")
                            .font(RidgitsTypography.headline(20))
                            .foregroundStyle(RidgitsColors.textHeadline)
                        Text("Control which Ridgits alerts you receive. We send high-intent pings for pokes, messages, expiring chats, and nearby discovery.")
                            .font(RidgitsTypography.body(13))
                            .foregroundStyle(RidgitsColors.textSecondary)
                    }
                    .padding(16)
                }

                if isLoading {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    preferenceCard
                }

                if let statusMessage {
                    Text(statusMessage)
                        .font(RidgitsTypography.caption(12))
                        .foregroundStyle(RidgitsColors.textSecondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(RidgitsColors.feedBackground)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .onChange(of: preferences) { _, _ in
            guard hasLoaded else { return }
            Task { await save() }
        }
    }

    private var preferenceCard: some View {
        RidgitsDashboardCard {
            VStack(spacing: 0) {
                toggleRow("All push notifications", keyPath: \.pushEnabled)
                RidgitsSectionDivider()
                toggleRow("Pokes", keyPath: \.pokes)
                RidgitsSectionDivider()
                toggleRow("New messages", keyPath: \.messages)
                RidgitsSectionDivider()
                toggleRow("Message requests", keyPath: \.messageRequests)
                RidgitsSectionDivider()
                toggleRow("Chat expiring soon", keyPath: \.conversationExpiring)
                RidgitsSectionDivider()
                toggleRow("Conversation approved", keyPath: \.conversationApproved)
                RidgitsSectionDivider()
                toggleRow("Nearby Ridgits", keyPath: \.nearby)
                RidgitsSectionDivider()
                toggleRow("Ridgit quiz updates", keyPath: \.ridgits)
                RidgitsSectionDivider()
                toggleRow("Profile reminders", keyPath: \.reEngagement)
                RidgitsSectionDivider()
                toggleRow("Marketing & announcements", keyPath: \.marketing)
            }
            .padding(.vertical, 4)
        }
    }

    private func toggleRow(_ title: String, keyPath: WritableKeyPath<RidgitsNotificationPreferences, Bool>) -> some View {
        Toggle(isOn: binding(for: keyPath)) {
            Text(title)
                .font(RidgitsTypography.label(14))
                .foregroundStyle(RidgitsColors.textHeadline)
        }
        .tint(RidgitsColors.ctaBlack)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .disabled(isSaving)
    }

    private func binding(for keyPath: WritableKeyPath<RidgitsNotificationPreferences, Bool>) -> Binding<Bool> {
        Binding(
            get: { preferences[keyPath: keyPath] },
            set: { preferences[keyPath: keyPath] = $0 }
        )
    }

    @MainActor
    private func load() async {
        isLoading = true
        defer {
            isLoading = false
            hasLoaded = true
        }
        preferences = (try? await RidgitsAPIClient.shared.fetchNotificationPreferences()) ?? RidgitsNotificationPreferences()
    }

    @MainActor
    private func save() async {
        isSaving = true
        defer { isSaving = false }
        do {
            preferences = try await RidgitsAPIClient.shared.updateNotificationPreferences(preferences)
            statusMessage = "Saved"
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}
