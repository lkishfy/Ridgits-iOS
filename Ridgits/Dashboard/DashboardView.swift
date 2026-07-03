import SwiftUI
import UIKit
import FirebaseAuth
import FirebaseFirestore

struct DashboardView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var ridgitsStore: RidgitsStore
    @EnvironmentObject private var deepLinkRouter: RidgitsDeepLinkRouter
    @EnvironmentObject private var nearbyPresence: RidgitsNearbyPresenceService
    @EnvironmentObject private var pokeInbox: RidgitsPokeInbox
    @EnvironmentObject private var referralStore: RidgitsReferralStore
    @State private var profile: RidgitsUserProfile?
    @State private var packProfile = RidgitsPackProfile()
    @State private var archetypeName = "Your Archetype"
    @State private var archetypeDescription = "Complete your quiz to unlock your Ridgits archetype."
    @State private var profileCode: String?
    @State private var nationwideMatches: [RidgitsMatch] = []
    @State private var showAllArchetypes = false
    @State private var selectedTab = 0
    @State private var showMessageAnalysis = false
    @State private var showCompatibilityReadout = false
    @State private var showModifyQuiz = false
    @State private var showCompareProfiles = false
    @State private var fullResultsPresentation: QuizFullResultsPresentation?
    @State private var showSubscriptionPaywall = false
    @State private var subscriptionPaywallHeadline = "Choose your plan"
    @State private var subscriptionPaywallSubheadline = "Upgrade anytime."
    @State private var subscriptionPaywallHighlight: RidgitsSubscriptionTier?
    @State private var quizIncompleteAlert = false
    @State private var packAnalysisPresentation: PackAnalysisPresentation?
    @State private var packQuizPresentation: PackQuizPresentation?
    @State private var referralGatePresentation: ReferralQuizGatePresentation?
    @State private var incomingRidgit: IncomingRidgit?
    @State private var showNearbyShareReceiver = false
    @StateObject private var messagingViewModel = MessagingViewModel()
    @StateObject private var matchesViewModel = MatchesViewModel()
    @StateObject private var tabBarScroll = RidgitsTabBarScrollState()

    private var unreadCount: Int {
        messagingViewModel.conversations.reduce(0) { $0 + $1.unreadCount }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            tabContent
                .environmentObject(tabBarScroll)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            RidgitsGlassTabBar(
                selectedTab: RidgitsTab(rawValue: selectedTab) ?? .home,
                onSelect: { tab in
                    selectedTab = tab.rawValue
                    tabBarScroll.reset()
                },
                compactProgress: tabBarScroll.compactProgress,
                profileImageURL: profile?.image,
                matchesBadge: pokeInbox.unseenCount,
                messagesBadge: unreadCount
            )
            .padding(.bottom, 6)
        }
        .background(RidgitsColors.feedBackground)
        .onChange(of: selectedTab) { _, _ in
            tabBarScroll.reset()
        }
        .onAppear { hydrateCachedProfile() }
        .onAppear { hydrateCachedNationwideMatches() }
        .onAppear {
            if let uid = authManager.currentUser?.uid {
                matchesViewModel.hydrateFromCache(
                    uid: uid,
                    hasExtendedNearby: ridgitsStore.hasExtendedNearbyRadius
                )
            }
        }
        .task {
            hydrateCachedProfile()
            messagingViewModel.startListening()
            await loadDashboardData()
            await referralStore.loadReferral()
            refreshNearbyPresence()
            if let uid = authManager.currentUser?.uid {
                pokeInbox.startListening(userId: uid)
            }
            RidgitsPushNotificationService.shared.requestAuthorizationAndRegister()
            await RidgitsPushNotificationService.shared.syncTokenWithBackend()
        }
        .onChange(of: deepLinkRouter.pendingRidgitId) { _, ridgitId in
            guard let ridgitId else { return }
            incomingRidgit = IncomingRidgit(id: ridgitId)
            deepLinkRouter.clearPendingRidgit()
        }
        .onChange(of: deepLinkRouter.pendingRoute) { _, route in
            guard let route else { return }
            switch route {
            case .home:
                selectedTab = RidgitsTab.home.rawValue
            case .matches:
                selectedTab = RidgitsTab.matches.rawValue
            case .messages:
                selectedTab = RidgitsTab.messages.rawValue
            case .ridgit(let id):
                incomingRidgit = IncomingRidgit(id: id)
            case .pack(let id):
                selectedTab = RidgitsTab.home.rawValue
                openPackFromDeepLink(packId: id)
            }
            deepLinkRouter.clearPendingRoute()
        }
        .onChange(of: ridgitsStore.hasExtendedNearbyRadius) { _, _ in
            refreshNearbyPresence()
        }
        .sheet(item: $packAnalysisPresentation) { presentation in
            PackAnalysisView(pack: presentation.pack, result: presentation.result)
        }
        .sheet(item: $packQuizPresentation) { presentation in
            NavigationStack {
                PackQuizView(
                    pack: presentation.pack,
                    forceRetake: presentation.forceRetake,
                    onCompleted: {
                        Task { await reloadPackProfile() }
                    },
                    onDismiss: {
                        packQuizPresentation = nil
                    }
                )
            }
        }
        .sheet(item: $referralGatePresentation) { presentation in
            ReferralQuizGateSheet(slot: presentation.slot, pack: presentation.pack)
                .environmentObject(referralStore)
        }
        .onChange(of: nearbyPresence.sharePhase) { _, phase in
            switch phase {
            case .incomingInvite, .received:
                showNearbyShareReceiver = true
            case .idle, .failed:
                showNearbyShareReceiver = false
            default:
                break
            }
        }
        .fullScreenCover(isPresented: $showNearbyShareReceiver) {
            RidgitNearbyShareReceiverOverlay(
                onOpenRidgit: { ridgitId in
                    incomingRidgit = IncomingRidgit(id: ridgitId)
                    showNearbyShareReceiver = false
                },
                onDismiss: {
                    showNearbyShareReceiver = false
                }
            )
            .environmentObject(nearbyPresence)
        }
        .sheet(item: $incomingRidgit) { route in
            NavigationStack {
                RidgitQuizView(ridgitId: route.id)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { incomingRidgit = nil }
                        }
                    }
            }
        }
        .onDisappear {
            pokeInbox.stopListening()
            messagingViewModel.stopListening()
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch RidgitsTab(rawValue: selectedTab) ?? .home {
        case .home:
            homeTab
        case .matches:
            NavigationStack { MatchesView(viewModel: matchesViewModel) }
        case .ridgit:
            NavigationStack { MakeRidgitView() }
        case .messages:
            NavigationStack { MessagesView(viewModel: messagingViewModel) }
        case .profile:
            NavigationStack { ProfileView() }
        }
    }

    private var homeTab: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    quickToolsSection
                    archetypesCard
                    CommunitySection()
                    if !ridgitsStore.hasExtendedNearbyRadius && !ridgitsStore.hasWebSubscription {
                        membershipCard
                    }
                    if !nationwideMatches.isEmpty {
                        topMatchesSection
                    }
                }
                .ridgitsTabBarScrollTracking()
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .ridgitsFloatingTabBarPadding()
            }
            .coordinateSpace(name: "ridgitsTabScroll")
            .background(RidgitsColors.feedBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    RidgitsLogoView.onLight(size: 22)
                }
            }
            .sheet(isPresented: $showSubscriptionPaywall) {
                SubscriptionPaywallView(
                    preferredBilling: .yearly,
                    highlightTier: subscriptionPaywallHighlight,
                    headline: subscriptionPaywallHeadline,
                    subheadline: subscriptionPaywallSubheadline
                )
            }
            .sheet(item: $fullResultsPresentation) { presentation in
                QuizFullResultsView(
                    archetypeName: presentation.archetypeName,
                    archetypeDescription: presentation.archetypeDescription,
                    scores: presentation.scores,
                    profile: presentation.profile,
                    insights: presentation.insights
                )
            }
            .sheet(isPresented: $showCompareProfiles) {
                CompareProfilesView()
            }
            .sheet(isPresented: $showMessageAnalysis) {
                MessageAnalysisView()
            }
            .sheet(isPresented: $showCompatibilityReadout) {
                CompatibilityReadoutView()
            }
            .alert("Complete your quiz first", isPresented: $quizIncompleteAlert) {
                Button("Take Quiz") { showModifyQuiz = true }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Finish your personality quiz to view full results and compare profiles.")
            }
            .sheet(isPresented: $showModifyQuiz) {
                QuizView(mode: .modify) {
                    Task { await loadDashboardData() }
                } onDismiss: {
                    showModifyQuiz = false
                }
            }
        }
    }

    private var ownsArchetypeBundle: Bool {
        RidgitsArchetypePack.paidPackIds.allSatisfy { id in
            packProfile.purchasedPacks.contains(id) || packProfile.unlockedPacks.contains(id)
        }
    }

    private var quickToolsSection: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            quickToolCard(icon: "message", title: "Messages", subtitle: "Analyze chats") {
                showMessageAnalysis = true
            }
            quickToolCard(icon: "waveform.path.ecg", title: "Compatibility", subtitle: "Get a readout before you meet") {
                showCompatibilityReadout = true
            }
        }
    }

    private func quickToolCard(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                RoundedRectangle(cornerRadius: RidgitsRadius.lg)
                    .fill(RidgitsColors.hoverSurface)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(RidgitsColors.textHeadline)
                    )
                Text(title)
                    .font(RidgitsTypography.label(13))
                    .foregroundStyle(RidgitsColors.textHeadline)
                    .lineLimit(1)
                Text(subtitle)
                    .font(RidgitsTypography.caption(11))
                    .foregroundStyle(RidgitsColors.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, minHeight: 32, alignment: .topLeading)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 116, alignment: .topLeading)
            .padding(14)
            .background(RidgitsColors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: RidgitsRadius.lg)
                    .stroke(RidgitsColors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.lg))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var archetypesCard: some View {
        RidgitsDashboardCard {
            VStack(alignment: .leading, spacing: 0) {
                Text("Your Archetypes")
                    .font(RidgitsTypography.label(15))
                    .foregroundStyle(RidgitsColors.textHeadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(RidgitsColors.border).frame(height: 1)
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text(archetypeName)
                        .font(RidgitsTypography.headline(20))
                        .foregroundStyle(RidgitsColors.textHeadline)

                    if !archetypeDescription.isEmpty {
                        Text(archetypeDescription)
                            .font(RidgitsTypography.body(14))
                            .foregroundStyle(RidgitsColors.textSecondary)
                            .lineSpacing(3)
                    }

                    RidgitsSquareButton(title: "View Full Results", style: .filled) {
                        Task { await openFullResults() }
                    }
                    RidgitsSquareButton(title: "Compare Profiles", style: .outlined) {
                        showCompareProfiles = true
                    }

                    VStack(spacing: 4) {
                        Text("Your Profile Code")
                            .font(RidgitsTypography.caption(11))
                            .foregroundStyle(RidgitsColors.textMuted)
                            .tracking(0.8)
                        Text(profileCode ?? "Generating code…")
                            .font(RidgitsTypography.mono(18))
                            .foregroundStyle(RidgitsColors.textHeadline)
                        Text("Share this code to compare")
                            .font(RidgitsTypography.caption(11))
                            .foregroundStyle(RidgitsColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RidgitsColors.feedBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: RidgitsRadius.md)
                            .stroke(RidgitsColors.dashboardBorder, lineWidth: 1)
                    )

                    RidgitsSquareButton(title: "Modify Quiz Answers", style: .ghost) {
                        showModifyQuiz = true
                    }

                    ReferralQuizzesSection(
                        packProfile: packProfile,
                        onSelectPack: handlePackSelection,
                        onViewAnalysis: handleViewPackAnalysis
                    )

                    AdditionalArchetypesSection(
                        packProfile: packProfile,
                        ownsBundle: ownsArchetypeBundle,
                        showAll: $showAllArchetypes,
                        onSelectPack: handlePackSelection,
                        onViewAnalysis: handleViewPackAnalysis
                    )
                }
                .padding(16)
            }
        }
    }

    private func hasPackAccess(_ pack: RidgitsArchetypePack) -> Bool {
        packProfile.hasAccess(
            to: pack,
            ownsBundle: ownsArchetypeBundle,
            membershipTier: ridgitsStore.membershipTier,
            referralsCompleted: referralStore.referralProfile?.referralsCompleted ?? 0
        )
    }

    private func referralGateSlot(for pack: RidgitsArchetypePack) -> Int? {
        guard pack.isReferralOnly, !hasPackAccess(pack), let slot = pack.referralSlot else { return nil }
        let completed = referralStore.referralProfile?.referralsCompleted ?? 0
        guard completed < slot else { return nil }
        return slot
    }

    private func handlePackSelection(_ pack: RidgitsArchetypePack) {
        if hasPackAccess(pack) {
            openPackQuiz(pack)
            return
        }
        if let slot = referralGateSlot(for: pack) {
            referralGatePresentation = ReferralQuizGatePresentation(id: slot, slot: slot, pack: pack)
            return
        }
        guard !pack.isReferralOnly else { return }
        presentArchetypeSubscriptionPaywall(for: pack)
    }

    private func handleViewPackAnalysis(_ pack: RidgitsArchetypePack) {
        guard hasPackAccess(pack) else {
            if let slot = referralGateSlot(for: pack) {
                referralGatePresentation = ReferralQuizGatePresentation(id: slot, slot: slot, pack: pack)
                return
            }
            guard !pack.isReferralOnly else { return }
            presentArchetypeSubscriptionPaywall(for: pack)
            return
        }
        guard let result = packProfile.result(for: pack) else {
            openPackQuiz(pack)
            return
        }
        packAnalysisPresentation = PackAnalysisPresentation(
            id: pack.id,
            pack: pack,
            result: result
        )
    }

    private func openPackFromDeepLink(packId: String) {
        let pack = RidgitsArchetypePack.catalog.first(where: { $0.id == packId })
            ?? RidgitsArchetypePack.referralCatalog.first(where: { $0.id == packId })
        guard let pack else { return }
        if hasPackAccess(pack) {
            openPackQuiz(pack)
        } else if let slot = referralGateSlot(for: pack) {
            referralGatePresentation = ReferralQuizGatePresentation(id: slot, slot: slot, pack: pack)
        } else if !pack.isReferralOnly {
            presentArchetypeSubscriptionPaywall(for: pack)
        }
    }

    private func presentNearbySubscriptionPaywall() {
        subscriptionPaywallHighlight = .plus
        subscriptionPaywallHeadline = "Unlock close matches"
        subscriptionPaywallSubheadline = "Ridgits+ yearly lets you search within 25 miles — \(ridgitsStore.plusYearlyPriceLine)/year."
        showSubscriptionPaywall = true
    }

    private func presentArchetypeSubscriptionPaywall(for pack: RidgitsArchetypePack) {
        if pack.ultraOnly {
            subscriptionPaywallHighlight = .ultra
            subscriptionPaywallHeadline = "Take \(pack.title)"
            subscriptionPaywallSubheadline = "Ultra unlocks exclusive archetype quizzes — \(ridgitsStore.priceLine(tier: .ultra, billing: .yearly))/year."
        } else {
            subscriptionPaywallHighlight = .premium
            subscriptionPaywallHeadline = "Take \(pack.title)"
            subscriptionPaywallSubheadline = "Premium unlocks additional archetype quizzes — \(ridgitsStore.priceLine(tier: .premium, billing: .yearly))/year."
        }
        showSubscriptionPaywall = true
    }

    private func openPackQuiz(_ pack: RidgitsArchetypePack, forceRetake: Bool = false) {
        packQuizPresentation = PackQuizPresentation(
            id: pack.id,
            pack: pack,
            forceRetake: forceRetake
        )
    }

    @MainActor
    private func openFullResults() async {
        guard let uid = authManager.currentUser?.uid else { return }
        do {
            guard let progress = try await RidgitsFirebaseClient.shared.fetchQuizProgress(uid: uid),
                  progress.completed else {
                quizIncompleteAlert = true
                return
            }
            fullResultsPresentation = QuizFullResultsPresentation(
                archetypeName: archetypeName,
                archetypeDescription: archetypeDescription,
                scores: RidgitsQuizCompatibility.dimensionAverages(from: progress),
                profile: profile,
                insights: RidgitsQuizCompatibility.insights(from: progress)
            )
        } catch {
            quizIncompleteAlert = true
        }
    }

    private var membershipCard: some View {
        RidgitsDashboardCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Unlock close matches")
                    .font(RidgitsTypography.label(15))
                    .foregroundStyle(RidgitsColors.textHeadline)
                Text("Free search starts at 30 miles. Ridgits+ yearly unlocks matches within 25 mi — \(ridgitsStore.plusYearlyPriceLine)/year.")
                    .font(RidgitsTypography.body(13))
                    .foregroundStyle(RidgitsColors.textSecondary)
                RidgitsSquareButton(title: "Get Ridgits+ yearly", style: .filled) {
                    presentNearbySubscriptionPaywall()
                }
            }
            .padding(16)
        }
    }

    private var topMatchesSection: some View {
        RidgitsDashboardCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Top matches")
                    .font(RidgitsTypography.label(15))
                    .foregroundStyle(RidgitsColors.textHeadline)
                Text("Nationwide compatibility preview")
                    .font(RidgitsTypography.caption(12))
                    .foregroundStyle(RidgitsColors.textSecondary)

                ForEach(nationwideMatches.prefix(5)) { match in
                    HStack(spacing: 10) {
                        RidgitsCachedProfileImage(remoteURL: match.image.isEmpty ? nil : match.image) {
                            Circle()
                                .fill(RidgitsColors.hoverSurface)
                                .overlay {
                                    Text(match.name.prefix(1).uppercased())
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(RidgitsColors.textMuted)
                                }
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())

                        Text(match.name)
                            .font(RidgitsTypography.label(14))
                        RidgitsVerifiedBadge(tier: match.subscriptionTier, size: 14)
                        Spacer()
                        Text("\(match.compatibility.overall)%")
                            .font(RidgitsTypography.label(13))
                            .foregroundStyle(RidgitsColors.textHeadline)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(RidgitsColors.contextBar)
                            .overlay(
                                RoundedRectangle(cornerRadius: RidgitsRadius.sm)
                                    .stroke(RidgitsColors.border, lineWidth: 1)
                            )
                    }
                    if match.id != nationwideMatches.prefix(5).last?.id {
                        Divider()
                    }
                }
            }
            .padding(16)
        }
    }

    @MainActor
    private func loadDashboardData() async {
        await loadProfile()
        await ridgitsStore.refreshAccessInBackground()
        guard let uid = authManager.currentUser?.uid else { return }

        if let archetype = await RidgitsFirebaseClient.shared.fetchQuizArchetype(uid: uid) {
            archetypeName = archetype.name
            if !archetype.description.isEmpty {
                archetypeDescription = archetype.description
            }
        }

        profileCode = await RidgitsFirebaseClient.shared.fetchProfileCode(uid: uid)
        packProfile = await RidgitsFirebaseClient.shared.fetchPackProfile(uid: uid)

        do {
            if nationwideMatches.isEmpty,
               let uid = authManager.currentUser?.uid,
               let cached = RidgitsMatchesCache.shared.nationwide(for: uid, limit: 5) {
                nationwideMatches = cached
            }
            nationwideMatches = try await RidgitsFirebaseClient.shared.getTopNationwideMatches(limit: 5)
        } catch {
            if nationwideMatches.isEmpty {
                nationwideMatches = []
            }
        }

        refreshNearbyPresence()
    }

    private func refreshNearbyPresence() {
        let displayName = profile?.name ?? authManager.currentUser?.displayName ?? ""
        nearbyPresence.updateShareListening(
            isSignedIn: authManager.userIsLoggedIn,
            displayName: displayName,
            profileCode: profileCode
        )
        let hasAccess = ridgitsStore.hasExtendedNearbyRadius || ridgitsStore.hasWebSubscription
        nearbyPresence.updateEligibility(
            isSignedIn: authManager.userIsLoggedIn,
            profileComplete: profile?.isCompleteForMatching ?? false,
            hasNearbyAccess: hasAccess,
            displayName: displayName,
            profileCode: profileCode
        )
    }

    private func hydrateCachedNationwideMatches() {
        guard let uid = authManager.currentUser?.uid, nationwideMatches.isEmpty else { return }
        if let cached = RidgitsMatchesCache.shared.nationwide(for: uid, limit: 5) {
            nationwideMatches = cached
        }
    }

    private func hydrateCachedProfile() {
        guard let uid = authManager.currentUser?.uid else { return }
        if profile == nil, let cached = RidgitsProfileCache.shared.profile(for: uid) {
            profile = cached
        }
    }

    private func loadProfile() async {
        guard let uid = authManager.currentUser?.uid else { return }
        if profile == nil, let cached = RidgitsProfileCache.shared.profile(for: uid) {
            profile = cached
        }
        if let loaded = try? await RidgitsFirebaseClient.shared.fetchUserProfile(uid: uid) {
            profile = loaded
        }
    }

    private func reloadPackProfile() async {
        guard let uid = authManager.currentUser?.uid else { return }
        packProfile = await RidgitsFirebaseClient.shared.fetchPackProfile(uid: uid)
    }
}

private struct IncomingRidgit: Identifiable {
    let id: String
}
