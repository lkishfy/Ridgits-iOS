import SwiftUI
import FirebaseAuth

struct DashboardView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var ridgitsStore: RidgitsStore
    @State private var profile: RidgitsUserProfile?
    @State private var nationwideMatches: [RidgitsMatch] = []
    @State private var unreadCount = 0
    @State private var showPaywall = false
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            homeTab
                .tabItem { Label("Home", systemImage: "house") }
                .tag(0)
            NavigationStack { MatchesView() }
                .tabItem { Label("Matches", systemImage: "heart") }
                .tag(1)
            NavigationStack { MessagesView() }
                .tabItem {
                    Label("Messages", systemImage: unreadCount > 0 ? "envelope.badge" : "envelope")
                }
                .tag(2)
            NavigationStack { ProfileSetupView(onComplete: { Task { await loadProfile() } }) }
                .tabItem { Label("Profile", systemImage: "person") }
                .tag(3)
        }
        .tint(RidgitsColors.ctaBlack)
        .task { await refresh() }
    }

    private var homeTab: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    RidgitsSectionHeader(
                        title: "Welcome back",
                        subtitle: profile?.name.isEmpty == false ? profile!.name : "Complete your profile to match"
                    )

                    if ridgitsStore.hasWebSubscription {
                        RidgitsCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Ridgits member")
                                    .font(RidgitsTypography.headline())
                                Text("Your web subscription includes nearby access in the app.")
                                    .font(RidgitsTypography.body(14))
                                    .foregroundStyle(RidgitsColors.textSecondary)
                            }
                        }
                    } else if !ridgitsStore.hasNearbyAccess {
                        RidgitsCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Unlock nearby matches")
                                    .font(RidgitsTypography.headline())
                                Text("12 months of local discovery for \(ridgitsStore.yearlyPriceLine).")
                                    .font(RidgitsTypography.body(14))
                                    .foregroundStyle(RidgitsColors.textSecondary)
                                RidgitsPrimaryButton(title: "See pricing") { showPaywall = true }
                            }
                        }
                    }

                    RidgitsSectionHeader(
                        title: "Top matches",
                        subtitle: "Nationwide compatibility preview"
                    )

                    ForEach(nationwideMatches.prefix(5)) { match in
                        HStack {
                            Text(match.name)
                                .font(RidgitsTypography.headline(15))
                            Spacer()
                            RidgitsCompatibilityBadge(percent: match.compatibility.overall)
                        }
                        .padding(.vertical, 8)
                        Divider()
                    }

                    RidgitsSectionHeader(
                        title: "Messaging",
                        subtitle: "24 hours · 16 messages max after approval"
                    )
                    Text("Conversations expire the same day they're approved — designed to move things offline.")
                        .font(RidgitsTypography.body(14))
                        .foregroundStyle(RidgitsColors.textSecondary)

                    RidgitsSecondaryButton(title: "Sign out") {
                        try? authManager.signOut()
                        ridgitsStore.reset()
                    }
                }
                .padding(20)
            }
            .background(RidgitsColors.feedBackground)
            .navigationTitle("Ridgits")
            .sheet(isPresented: $showPaywall) {
                NearbyPaywallView()
            }
        }
    }

    private func refresh() async {
        await loadProfile()
        await ridgitsStore.bootstrap()
        do {
            nationwideMatches = try await RidgitsFirebaseClient.shared.getTopNationwideMatches(limit: 5)
        } catch {}
        listenUnread()
    }

    private func loadProfile() async {
        guard let uid = authManager.currentUser?.uid else { return }
        profile = try? await RidgitsFirebaseClient.shared.fetchUserProfile(uid: uid)
    }

    private func listenUnread() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        _ = RidgitsFirebaseClient.shared.listenConversations(userId: uid) { convos in
            Task { @MainActor in
                unreadCount = convos.reduce(0) { $0 + $1.unreadCount }
            }
        }
    }
}
