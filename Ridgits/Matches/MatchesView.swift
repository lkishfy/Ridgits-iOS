import SwiftUI
import FirebaseAuth

struct MatchesView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var ridgitsStore: RidgitsStore
    @EnvironmentObject private var nearbyPresence: RidgitsNearbyPresenceService
    @EnvironmentObject private var pokeInbox: RidgitsPokeInbox
    @EnvironmentObject private var messagingViewModel: MessagingViewModel
    @ObservedObject var viewModel: MatchesViewModel
    @Binding var incomingPokeProfile: IncomingPokeProfile?
    var onOpenConversation: ((String, String?) -> Void)? = nil
    @State private var showSubscriptionPaywall = false
    @State private var subscriptionPaywallHighlight: RidgitsSubscriptionTier = .plus
    @State private var paywallMembershipTierAtOpen: RidgitsSubscriptionTier = .free
    @State private var paywallHeadline: String?
    @State private var paywallSubheadline: String?
    @State private var showPokePackPaywall = false
    @State private var showBirthYearPrompt = false
    @State private var composeMatch: RidgitsMatch?
    @State private var selectedMatch: RidgitsMatch?
    @State private var composeMessage = ""
    @State private var showCompatibilityFilter = false
    @State private var pokeConfirmMatch: RidgitsMatch?
    @State private var unpokeConfirmMatch: RidgitsMatch?
    @State private var messagingBlockedMessage: String?
    @State private var identityVerificationGate: IdentityVerificationMessagingGate?
    @State private var showProfilePhotoMatchAlert = false

    private var nearbyAccess: RidgitsNearbySearchAccess {
        RidgitsNearbySearchAccess.from(store: ridgitsStore)
    }

    var body: some View {
        applyMatchesAlerts(to: applyMatchesPresentation(to: matchesCore))
    }

    private var matchesCore: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if nearbyPresence.isActive, nearbyPresence.nearbyPeerCount > 0 {
                    nearbyBluetoothBanner
                }
                if pokeInbox.unseenCount > 0 {
                    pokeInboxBanner
                }
                nearbySection
                RidgitsSectionHeader(title: "Top nationwide")
                paginatedMatchSection(
                    matches: viewModel.visibleNationwideMatches,
                    totalCount: viewModel.nationwideMatches.count,
                    canLoadMore: viewModel.canLoadMoreNationwide,
                    onLoadMore: { viewModel.loadMoreNationwide() },
                    locked: false,
                    allowInteraction: true,
                    emptyMessage: "No nationwide matches right now. Update match preferences in Profile, then pull to refresh."
                )
            }
            .ridgitsTabBarScrollTracking()
            .padding(20)
            .ridgitsFloatingTabBarPadding()
        }
        .coordinateSpace(name: "ridgitsTabScroll")
        .background(RidgitsColors.feedBackground)
        .navigationTitle("Matches")
        .refreshable {
            await ridgitsStore.refreshAccessInBackground()
            await viewModel.load(access: nearbyAccess, forceRefresh: true)
        }
        .onReceive(NotificationCenter.default.publisher(for: .ridgitsMatchPreferencesDidChange)) { _ in
            Task {
                await viewModel.load(access: nearbyAccess, forceRefresh: true)
            }
        }
        .task {
            await ridgitsStore.refreshAccessInBackground()
        }
        .task(id: nearbyAccess.poolCacheKey) {
            viewModel.maxDistance = RidgitsNearbyAccess.clampRadius(
                viewModel.maxDistance,
                access: nearbyAccess
            )
            if let uid = Auth.auth().currentUser?.uid {
                viewModel.hydrateFromCache(uid: uid, access: nearbyAccess)
            }
            await viewModel.load(access: nearbyAccess)
        }
        .task(id: incomingPokeProfile?.id) {
            await openIncomingPokeProfileIfNeeded()
        }
        .onChange(of: viewModel.maxDistance) { _, _ in
            viewModel.onRadiusChanged(access: nearbyAccess)
        }
        .onChange(of: viewModel.compatibilityFilter) { _, _ in
            viewModel.onCompatibilityFilterChanged(access: nearbyAccess)
        }
        .onChange(of: viewModel.sortOrder) { _, _ in
            viewModel.onSortOrderChanged(access: nearbyAccess)
        }
        .ridgitsBlockingLoader(
            isPresented: viewModel.isLoadingNearby,
            title: "Finding matches near you",
            subtitle: "Scanning compatible people in your radius"
        )
        .navigationDestination(item: $selectedMatch) { match in
            MatchProfileView(
                match: match,
                onMessage: { requestMessage(to: match) },
                onPoke: {
                    Task { await requestPoke(for: match) }
                },
                onUnpoke: {
                    unpokeConfirmMatch = match
                }
            )
        }
    }

    @ViewBuilder
    private func applyMatchesPresentation<Content: View>(to content: Content) -> some View {
        content
            .task(id: visibleMatchUserIds) {
                await messagingViewModel.prefetchConversationStatus(for: visibleMatchUserIds)
            }
            .sheet(isPresented: $showSubscriptionPaywall) {
                SubscriptionPaywallView(
                    preferredBilling: .yearly,
                    highlightTier: subscriptionPaywallHighlight,
                    headline: paywallHeadline,
                    subheadline: paywallSubheadline
                )
                .onDisappear {
                    paywallHeadline = nil
                    paywallSubheadline = nil
                }
            }
            .onChange(of: ridgitsStore.membershipTier) { _, newTier in
                viewModel.maxDistance = RidgitsNearbyAccess.clampRadius(
                    viewModel.maxDistance,
                    access: nearbyAccess
                )
                Task { await viewModel.load(access: nearbyAccess, forceRefresh: true) }
                guard showSubscriptionPaywall else { return }
                guard ridgitsStore.isMembershipActive else { return }
                guard newTier.rank > paywallMembershipTierAtOpen.rank else { return }
                guard newTier.rank >= subscriptionPaywallHighlight.rank else { return }
                showSubscriptionPaywall = false
            }
            .onChange(of: ridgitsStore.isMembershipActive) { _, _ in
                viewModel.maxDistance = RidgitsNearbyAccess.clampRadius(
                    viewModel.maxDistance,
                    access: nearbyAccess
                )
                Task { await viewModel.load(access: nearbyAccess, forceRefresh: true) }
            }
            .sheet(isPresented: $showPokePackPaywall) {
                PokePackPaywallView {
                    Task { await viewModel.refreshPokeCredits() }
                }
            }
            .fullScreenCover(isPresented: $showBirthYearPrompt) {
                BirthYearPromptView {
                    showBirthYearPrompt = false
                }
                .environmentObject(authManager)
            }
            .identityVerificationMessagingGate($identityVerificationGate)
            .sheet(item: $composeMatch) { match in
                composeSheet(for: match)
            }
            .onChange(of: viewModel.showPokePackPaywall) { _, showPaywall in
                guard showPaywall else { return }
                viewModel.showPokePackPaywall = false
                showPokePackPaywall = true
            }
            .onChange(of: viewModel.showBirthYearPrompt) { _, showPrompt in
                guard showPrompt else { return }
                viewModel.showBirthYearPrompt = false
                showBirthYearPrompt = true
            }
    }

    private var showsGenericErrorAlert: Bool {
        viewModel.errorMessage != nil && !viewModel.showPokePackPaywall && !viewModel.showBirthYearPrompt
    }

    @ViewBuilder
    private func applyMatchesAlerts<Content: View>(to content: Content) -> some View {
        content
            .alert("Something went wrong", isPresented: genericErrorAlertPresented) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .alert("Can't send message", isPresented: messagingBlockedAlertPresented) {
                Button("OK") { messagingBlockedMessage = nil }
            } message: {
                Text(messagingBlockedMessage ?? "")
            }
            .alert(
                "It's a bit too early for a phone number, no?",
                isPresented: $messagingViewModel.showEarlyPhoneNumberPrompt
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Let's get to know each other a bit more!")
            }
            .alert("Send poke?", isPresented: pokeConfirmAlertPresented) {
                Button("Send poke") {
                    guard let match = pokeConfirmMatch else { return }
                    pokeConfirmMatch = nil
                    Task { await viewModel.sendPoke(to: match) }
                }
                Button("Cancel", role: .cancel) {
                    pokeConfirmMatch = nil
                }
            } message: {
                if let match = pokeConfirmMatch {
                    Text(viewModel.pokeConfirmationMessage(for: match.displayFirstName))
                }
            }
            .alert("Delete poke?", isPresented: unpokeConfirmAlertPresented) {
                Button("Delete", role: .destructive) {
                    guard let match = unpokeConfirmMatch,
                          let pokeId = pokeInbox.sentPokeIdsByUser[match.userId] else {
                        unpokeConfirmMatch = nil
                        return
                    }
                    unpokeConfirmMatch = nil
                    Task { await viewModel.unpoke(pokeId: pokeId) }
                }
                Button("Cancel", role: .cancel) {
                    unpokeConfirmMatch = nil
                }
            } message: {
                if let match = unpokeConfirmMatch {
                    Text("Delete your poke to \(match.displayFirstName)?")
                }
            }
            .alert("Profile photo must match your ID", isPresented: $showProfilePhotoMatchAlert) {
                Button("Retry verification") {
                    Task {
                        if let message = await ridgitsStore.retryProfilePhotoIdentityMatch() {
                            viewModel.errorMessage = message
                        }
                    }
                }
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your profile photo must match your verified ID selfie before you can chat. Update your photo in Profile, or tap Retry verification to try again with your current photo.")
            }
    }

    private var genericErrorAlertPresented: Binding<Bool> {
        Binding(
            get: { showsGenericErrorAlert },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }

    private var messagingBlockedAlertPresented: Binding<Bool> {
        Binding(
            get: { messagingBlockedMessage != nil },
            set: { if !$0 { messagingBlockedMessage = nil } }
        )
    }

    private var pokeConfirmAlertPresented: Binding<Bool> {
        Binding(
            get: { pokeConfirmMatch != nil },
            set: { if !$0 { pokeConfirmMatch = nil } }
        )
    }

    private var unpokeConfirmAlertPresented: Binding<Bool> {
        Binding(
            get: { unpokeConfirmMatch != nil },
            set: { if !$0 { unpokeConfirmMatch = nil } }
        )
    }

    @MainActor
    private func requestPoke(for match: RidgitsMatch) async {
        let alreadySent = pokeInbox.sentPokeIdsByUser[match.userId] != nil
        switch await viewModel.preflightPoke(alreadySent: alreadySent) {
        case .alreadySent:
            return
        case .noCredits:
            showPokePackPaywall = true
        case .ready:
            pokeConfirmMatch = match
        }
    }

    private func attemptRadiusChange(to rawValue: Double) {
        let requested = Int(rawValue.rounded())

        if RidgitsNearbyAccess.isLockedPreset(requested, access: nearbyAccess) {
            presentRadiusPaywall(for: requested)
            return
        }

        let snapped = RidgitsNearbyAccess.snapToPresetMiles(requested, access: nearbyAccess)
        let clamped = RidgitsNearbyAccess.clampRadius(snapped, access: nearbyAccess)
        guard clamped != viewModel.maxDistance else { return }
        viewModel.maxDistance = clamped
    }

    private func presentRadiusPaywall(for preset: Int) {
        guard RidgitsNearbyAccess.isLockedPreset(preset, access: nearbyAccess) else {
            let clamped = RidgitsNearbyAccess.clampRadius(preset, access: nearbyAccess)
            guard clamped != viewModel.maxDistance else { return }
            viewModel.maxDistance = clamped
            return
        }
        let requiredTier = nearbyAccess.lockedRadiusPaywallTier(for: preset)
        guard shouldPresentSubscriptionPaywall(requiredTier: requiredTier) else { return }
        let copy = RidgitsNearbyAccess.radiusPaywallCopy(
            for: preset,
            access: nearbyAccess,
            closeMatchCount: viewModel.closeMatchCount
        )
        subscriptionPaywallHighlight = copy.requiredTier
        paywallHeadline = copy.headline
        paywallSubheadline = copy.subheadline
        Task { await viewModel.refreshCloseMatchPreview(at: preset, access: nearbyAccess) }
        openSubscriptionPaywallSheet()
    }

    private func shouldPresentSubscriptionPaywall(requiredTier: RidgitsSubscriptionTier) -> Bool {
        guard ridgitsStore.isMembershipActive else { return true }
        return ridgitsStore.canUpgrade(to: requiredTier)
    }

    private func presentSubscriptionPaywall(
        requiredTier: RidgitsSubscriptionTier,
        headline: String,
        subheadline: String
    ) {
        guard shouldPresentSubscriptionPaywall(requiredTier: requiredTier) else { return }
        subscriptionPaywallHighlight = requiredTier
        paywallHeadline = headline
        paywallSubheadline = subheadline
        openSubscriptionPaywallSheet()
    }

    private func openSubscriptionPaywallSheet() {
        paywallMembershipTierAtOpen = ridgitsStore.membershipTier
        showSubscriptionPaywall = true
    }

    private var subscriptionPaywallSubheadline: String {
        switch subscriptionPaywallHighlight {
        case .plus:
            return "Free members search 30–150 mi. Ridgits+ unlocks 10–150 mi by distance."
        case .premium:
            return RidgitsNearbyAccess.premiumMetroTeaserSubheadline() + " Upgrade to Premium to unlock metro search and messaging."
        case .ultra:
            return "Ultra includes metro search and the full 0–150 mile range."
        default:
            return "Upgrade to search closer."
        }
    }

    private func gateMessagingAccess() -> Bool {
        if ridgitsStore.needsProfilePhotoMatchForMessaging {
            showProfilePhotoMatchAlert = true
            return false
        }
        guard ridgitsStore.isVerifiedForMessaging else {
            identityVerificationGate = .requiredPrompt
            return false
        }
        return true
    }

    private func requestMessage(to match: RidgitsMatch) {
        if RidgitsNearbyAccess.requiresUpgradeToMessage(
            personAtDistanceMiles: match.distanceMiles,
            access: nearbyAccess
        ) {
            let copy = RidgitsNearbyAccess.messagingPaywallCopy(forDistanceMiles: match.distanceMiles)
            let requiredTier = RidgitsNearbyAccess.messagingUpsellTier(forDistanceMiles: match.distanceMiles)
            presentSubscriptionPaywall(
                requiredTier: requiredTier,
                headline: copy.headline,
                subheadline: copy.subheadline
            )
            return
        }
        guard gateMessagingAccess() else { return }
        if let closedMessage = messagingViewModel.messagingClosedMessage(for: match) {
            messagingBlockedMessage = closedMessage
            return
        }
        Task {
            await messagingViewModel.prefetchConversationStatus(for: [match.userId])
            if let closedMessage = messagingViewModel.messagingClosedMessage(for: match) {
                messagingBlockedMessage = closedMessage
            } else {
                composeMatch = match
            }
        }
    }

    private var visibleMatchUserIds: [String] {
        (viewModel.visibleNearbyMatches + viewModel.visibleNationwideMatches).map(\.userId)
    }

    @MainActor
    private func openIncomingPokeProfileIfNeeded() async {
        guard let incomingPokeProfile else { return }
        defer { self.incomingPokeProfile = nil }

        let userId = incomingPokeProfile.userId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userId.isEmpty else { return }

        if let match = await viewModel.resolveMatch(for: userId) {
            selectedMatch = match
        }

        if let pokeId = incomingPokeProfile.pokeId?.trimmingCharacters(in: .whitespacesAndNewlines),
           !pokeId.isEmpty {
            Task {
                try? await RidgitsAPIClient.shared.markPokeSeen(
                    pokeId: pokeId,
                    profileVisited: true
                )
            }
        }
    }

    @ViewBuilder
    private var pokeInboxBanner: some View {
        RidgitsCard {
            VStack(alignment: .leading, spacing: 6) {
                Text("\(pokeInbox.unseenCount) new \(pokeInbox.unseenCount == 1 ? "poke" : "pokes")")
                    .font(RidgitsTypography.label(14))
                if let latest = pokeInbox.receivedPokes.first(where: \.isActionable) {
                    Text("\(latest.fromName) poked you — open Inbox to poke back or view their profile.")
                        .font(RidgitsTypography.caption(12))
                        .foregroundStyle(RidgitsColors.textSecondary)
                }
            }
        }
    }

    private var nearbyBluetoothBanner: some View {
        RidgitsCard {
            HStack(spacing: 10) {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color(hex: 0x059669))
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(nearbyPresence.nearbyPeerCount) Ridgits \(nearbyPresence.nearbyPeerCount == 1 ? "person" : "people") nearby")
                        .font(RidgitsTypography.label(14))
                    Text("Detected nearby via Bluetooth — alerts work in the background")
                        .font(RidgitsTypography.caption(11))
                        .foregroundStyle(RidgitsColors.textSecondary)
                }
            }
        }
    }

    private var nearbySection: some View {
        Group {
            if nearbyAccess.showsCloseMatchTeaser {
                closeMatchesTeaser
            } else if nearbyAccess.showsPremiumCloseTeaser, viewModel.closeMatchCount > 0 {
                premiumCloseMatchesTeaser
            }
            distanceSlider
            nearbyMatchesSection
        }
    }

    private var nearbyMatchesSection: some View {
        Group {
            if viewModel.isLoadingNearby && viewModel.nearbyMatches.isEmpty {
                EmptyView()
            } else if viewModel.nearbyMatches.isEmpty && !viewModel.isLoading && !viewModel.isLoadingNearby {
                if viewModel.compatibilityFilter.isActive,
                   viewModel.unfilteredNearbyCount(access: nearbyAccess) > 0 {
                    filteredEmptyCard
                } else {
                    noNearbyCard
                }
            } else {
                paginatedMatchSection(
                    matches: viewModel.visibleNearbyMatches,
                    totalCount: viewModel.nearbyMatches.count,
                    canLoadMore: viewModel.canLoadMoreNearby,
                    onLoadMore: { viewModel.loadMoreNearby() },
                    locked: false,
                    allowInteraction: true
                )
            }
        }
    }

    private var filteredEmptyCard: some View {
        RidgitsCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("No matches for these filters")
                    .font(RidgitsTypography.headline())
                Text("People are nearby, but none meet your minimum compatibility scores. Lower a slider or reset filters.")
                    .font(RidgitsTypography.body(14))
                    .foregroundStyle(RidgitsColors.textSecondary)
                RidgitsSquareButton(title: "Reset filters", style: .outlined) {
                    viewModel.resetCompatibilityFilter(access: nearbyAccess)
                }
            }
        }
    }

    private var closeMatchesTeaser: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                if !viewModel.closeMatchPreviews.isEmpty {
                    closeMatchAvatarStack
                }

                Text(closeMatchesTeaserMessage)
                    .font(RidgitsTypography.caption(13))
                    .foregroundStyle(RidgitsColors.forestGreenDark.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Button("See nearby matches") {
                guard shouldPresentSubscriptionPaywall(requiredTier: .plus) else { return }
                presentSubscriptionPaywall(
                    requiredTier: .plus,
                    headline: "See nearby matches",
                    subheadline: "Free members search 30–150 mi. Ridgits+ unlocks 10–150 mi by distance."
                )
            }
            .font(RidgitsTypography.caption(13))
            .fontWeight(.semibold)
            .foregroundStyle(RidgitsColors.forestGreenDark)
            .buttonStyle(RidgitsHapticPlainButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(RidgitsColors.forestGreenLight)
        .overlay(
            RoundedRectangle(cornerRadius: RidgitsRadius.md)
                .stroke(RidgitsColors.forestGreen.opacity(0.35), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.md))
    }

    private var closeMatchAvatarStack: some View {
        HStack(spacing: -8) {
            ForEach(viewModel.closeMatchPreviews.prefix(5)) { preview in
                RidgitsCachedProfileImage(remoteURL: preview.image.isEmpty ? nil : preview.image) {
                    RidgitsColors.border
                }
                .frame(width: 28, height: 28)
                .clipShape(Circle())
                .overlay(Circle().stroke(RidgitsColors.forestGreenLight, lineWidth: 2))
            }
        }
        .accessibilityLabel("Nearby match photos")
    }

    private var closeMatchesTeaserMessage: String {
        let radius = viewModel.closeMatchPreviewRadiusMiles
        if viewModel.closeMatchCount > 0 {
            let noun = viewModel.closeMatchCount == 1 ? "match" : "matches"
            return "\(viewModel.closeMatchCount) \(noun) within \(radius) mi by distance."
        }
        return "Subscribe to see matches from 10 miles and closer by distance."
    }

    private var premiumCloseMatchesTeaser: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                if !viewModel.closeMatchPreviews.isEmpty {
                    closeMatchAvatarStack
                }

                Text(premiumCloseMatchesTeaserMessage)
                    .font(RidgitsTypography.caption(13))
                    .foregroundStyle(RidgitsSubscriptionTier.premium.accentColorDark.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Button("Unlock metro") {
                presentSubscriptionPaywall(
                    requiredTier: .premium,
                    headline: "Unlock metro search",
                    subheadline: RidgitsNearbyAccess.premiumMetroTeaserSubheadline() + " Upgrade to Premium to see and message metro matches."
                )
            }
            .font(RidgitsTypography.caption(13))
            .fontWeight(.semibold)
            .foregroundStyle(RidgitsSubscriptionTier.premium.accentColorDark)
            .buttonStyle(RidgitsHapticPlainButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(RidgitsSubscriptionTier.premium.accentColorLight)
        .overlay(
            RoundedRectangle(cornerRadius: RidgitsRadius.md)
                .stroke(RidgitsSubscriptionTier.premium.accentColor.opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.md))
    }

    private var premiumCloseMatchesTeaserMessage: String {
        let noun = viewModel.closeMatchCount == 1 ? "match is" : "matches are"
        return "\(viewModel.closeMatchCount) \(noun) in your metro area — \(RidgitsNearbyAccess.premiumMetroTeaserSubheadline())"
    }

    private var nearbyRadiusRangeLabel: String {
        RidgitsNearbyAccess.radiusRangeLabel(maxRadius: viewModel.maxDistance, access: nearbyAccess)
    }

    private var distanceSliderSubtitle: String {
        let total = viewModel.nearbyMatches.count
        let visible = viewModel.visibleNearbyMatches.count
        let inRange = viewModel.unfilteredNearbyCount(access: nearbyAccess)
        var parts: [String] = []

        if total > 0 {
            if total > visible {
                parts.append("Showing \(visible) of \(total)")
            } else {
                let noun = total == 1 ? "person" : "people"
                parts.append("\(total) \(noun)")
            }
        }

        if viewModel.compatibilityFilter.isActive, inRange > total, total > 0 {
            parts.append("\(inRange) in range before filters")
        }

        parts.append(nearbyRadiusRangeLabel)
        return parts.joined(separator: " · ")
    }

    private var distanceSlider: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                Text(distanceSliderSubtitle)
                    .font(RidgitsTypography.caption(11))
                    .foregroundStyle(RidgitsColors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.6)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 8)

                sortMenu

                Button {
                    showCompatibilityFilter.toggle()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "line.3.horizontal.decrease")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Filter")
                            .font(RidgitsTypography.label(11))
                        if viewModel.compatibilityFilter.isActive {
                            Circle()
                                .fill(RidgitsColors.ctaBlack)
                                .frame(width: 6, height: 6)
                        }
                    }
                    .foregroundStyle(RidgitsColors.textHeadline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(RidgitsColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: RidgitsRadius.sm)
                            .stroke(RidgitsColors.border, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.sm))
                }
                .buttonStyle(RidgitsHapticPlainButtonStyle())
                .popover(isPresented: $showCompatibilityFilter, arrowEdge: .top) {
                    CompatibilityFilterPopover(
                        filter: $viewModel.compatibilityFilter,
                        onReset: {
                            viewModel.resetCompatibilityFilter(access: nearbyAccess)
                        }
                    )
                    .presentationCompactAdaptation(.popover)
                }
            }

            HStack(spacing: 6) {
                ForEach(radiusPresets, id: \.self) { preset in
                    radiusPresetChip(preset)
                }
            }
        }
        .padding(16)
        .background(RidgitsColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: RidgitsRadius.lg).stroke(RidgitsColors.border, lineWidth: 1))
    }

    private var radiusPresets: [Int] {
        RidgitsNearbyAccess.radiusPresetMiles
    }

    @ViewBuilder
    private func radiusPresetChip(_ preset: Int) -> some View {
        let isLocked = RidgitsNearbyAccess.isLockedPreset(preset, access: nearbyAccess)
        let isSelected = !isLocked && viewModel.maxDistance == preset
        let isMetro = RidgitsNearbyAccess.isMetroPreset(preset)

        Button {
            attemptRadiusChange(to: Double(preset))
        } label: {
            HStack(spacing: 4) {
                Text(isMetro ? "Metro" : "\(preset)")
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 8, weight: .semibold))
                }
            }
            .font(RidgitsTypography.caption(11))
            .foregroundStyle(isSelected ? .white : RidgitsColors.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity)
            .background(isSelected ? RidgitsColors.ctaBlack : RidgitsColors.hoverSurface)
            .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.sm))
        }
        .buttonStyle(RidgitsHapticPlainButtonStyle())
        .disabled(viewModel.isLoadingNearby)
        .accessibilityHint(isLocked ? "Requires upgrade" : "")
    }

    private var sortMenu: some View {
        Menu {
            Picker("Sort", selection: $viewModel.sortOrder) {
                ForEach(MatchesSortOrder.allCases) { order in
                    Text(order.label).tag(order)
                }
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 11, weight: .semibold))
                Text("Sort")
                    .font(RidgitsTypography.label(11))
            }
            .foregroundStyle(RidgitsColors.textHeadline)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(RidgitsColors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: RidgitsRadius.sm)
                    .stroke(RidgitsColors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.sm))
        }
    }

    private var noNearbyCard: some View {
        RidgitsCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("No one nearby yet")
                    .font(RidgitsTypography.headline())
                Text("There aren't compatible people in the \(nearbyRadiusRangeLabel) range right now. Try a wider radius or browse nationwide matches below.")
                    .font(RidgitsTypography.body(14))
                    .foregroundStyle(RidgitsColors.textSecondary)
            }
        }
    }

    private func paginatedMatchSection(
        matches: [RidgitsMatch],
        totalCount: Int,
        canLoadMore: Bool,
        onLoadMore: @escaping () -> Void,
        locked: Bool,
        allowInteraction: Bool,
        emptyMessage: String? = nil
    ) -> some View {
        VStack(spacing: 12) {
            matchSection(
                matches,
                locked: locked,
                allowInteraction: allowInteraction,
                emptyMessage: emptyMessage
            )

            if canLoadMore {
                RidgitsSquareButton(
                    title: "Load more (\(totalCount - matches.count) remaining)",
                    style: .outlined
                ) {
                    onLoadMore()
                }
            }
        }
    }

    private func matchSection(
        _ matches: [RidgitsMatch],
        locked: Bool,
        allowInteraction: Bool,
        emptyMessage: String? = nil
    ) -> some View {
        VStack(spacing: 12) {
            if matches.isEmpty {
                if let emptyMessage, !viewModel.isLoading, !viewModel.isLoadingNearby {
                    Text(emptyMessage)
                        .font(RidgitsTypography.caption(12))
                        .foregroundStyle(RidgitsColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                } else {
                    EmptyView()
                }
            } else {
                ForEach(matches) { match in
                    MatchCard(
                        match: match,
                        locked: locked,
                        sentPoke: pokeInbox.sentPokeIdsByUser[match.userId] != nil,
                        messageClosedLabel: messagingViewModel.messagingClosedLabel(for: match),
                        hidePoke: messagingViewModel.messagingIsExpired(for: match),
                        onOpenProfile: {
                            guard allowInteraction, !locked else { return }
                            selectedMatch = match
                        },
                        onMessage: {
                            guard allowInteraction else { return }
                            requestMessage(to: match)
                        },
                        onPoke: {
                            guard allowInteraction else { return }
                            Task { await requestPoke(for: match) }
                        },
                        onUnpoke: {
                            guard allowInteraction else { return }
                            unpokeConfirmMatch = match
                        }
                    )
                }
            }
        }
    }

    private func composeSheet(for match: RidgitsMatch) -> some View {
        VStack(spacing: 0) {
            composeSheetDragIndicator

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    HStack {
                        Spacer()
                        Button("Cancel") {
                            composeMessage = ""
                            composeMatch = nil
                        }
                        .font(RidgitsTypography.label(14))
                        .foregroundStyle(RidgitsColors.textSecondary)
                    }

                    composeSheetHeader(for: match)

                    composeMessageField

                    RidgitsPrimaryButton(
                        title: "Send request",
                        isDisabled: composeMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ) {
                        if RidgitsNearbyAccess.requiresUpgradeToMessage(
                            personAtDistanceMiles: match.distanceMiles,
                            access: nearbyAccess
                        ) {
                            let copy = RidgitsNearbyAccess.messagingPaywallCopy(forDistanceMiles: match.distanceMiles)
                            let requiredTier = RidgitsNearbyAccess.messagingUpsellTier(forDistanceMiles: match.distanceMiles)
                            presentSubscriptionPaywall(
                                requiredTier: requiredTier,
                                headline: copy.headline,
                                subheadline: copy.subheadline
                            )
                            return
                        }
                        Task {
                            guard gateMessagingAccess() else { return }
                            let trimmed = composeMessage.trimmingCharacters(in: .whitespacesAndNewlines)
                            if RidgitsMessagingValidation.blocksEarlyPhoneNumber(text: trimmed, messageCount: 0) {
                                messagingViewModel.showEarlyPhoneNumberPrompt = true
                                return
                            }
                            do {
                                let conversationId = try await RidgitsFirebaseClient.shared.startConversation(
                                    toUserId: match.userId,
                                    message: trimmed
                                )
                                composeMessage = ""
                                composeMatch = nil
                                onOpenConversation?(match.userId, conversationId)
                            } catch let ridgitsError as RidgitsError {
                                composeMatch = nil
                                if ridgitsError.code == "EARLY_PHONE_NUMBER" {
                                    messagingViewModel.showEarlyPhoneNumberPrompt = true
                                } else if ridgitsError.code == "SUBSCRIPTION_REQUIRED" || ridgitsError.code == "MONTHLY_MESSAGE_LIMIT_REACHED" {
                                    openSubscriptionPaywallSheet()
                                } else if ridgitsError.code == "AGE_VERIFICATION_REQUIRED" || ridgitsError.code == "UNDERAGE" {
                                    showBirthYearPrompt = true
                                } else if ridgitsError.code == "IDENTITY_VERIFICATION_REQUIRED" {
                                    identityVerificationGate = .requiredPrompt
                                } else if ridgitsError.code == "PROFILE_PHOTO_IDENTITY_MISMATCH" {
                                    showProfilePhotoMatchAlert = true
                                } else if handleExistingConversationError(ridgitsError, match: match) {
                                    return
                                } else {
                                    viewModel.errorMessage = ridgitsError.localizedDescription
                                }
                            } catch {
                                composeMatch = nil
                                if handleExistingConversationError(error, match: match) {
                                    return
                                }
                                viewModel.errorMessage = error.localizedDescription
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .safeAreaPadding(.bottom, 16)
            }
        }
        .background(RidgitsColors.feedBackground)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }

    private var composeSheetDragIndicator: some View {
        Capsule()
            .fill(RidgitsColors.textMuted.opacity(0.35))
            .frame(width: 36, height: 5)
            .padding(.top, 10)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity)
    }

    private func composeSheetHeader(for match: RidgitsMatch) -> some View {
        VStack(spacing: 12) {
            RidgitsCachedProfileImage(remoteURL: match.image.isEmpty ? nil : match.image) {
                RidgitsColors.border
            }
            .frame(width: 88, height: 88)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(RidgitsColors.border, lineWidth: 1)
            )

            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Text("Message \(match.displayFirstName)")
                        .font(RidgitsTypography.headline(22))
                        .foregroundStyle(RidgitsColors.textHeadline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    RidgitsProfileTrustBadges(
                        subscriptionTier: match.subscriptionTier,
                        profilePhotoVerified: match.isProfilePhotoVerified,
                        showPhotoVerified: false,
                        badgeSize: 16
                    )
                }

                if let miles = match.distanceMiles {
                    Text(String(format: "%.0f mi away", miles))
                        .font(RidgitsTypography.caption(13))
                        .foregroundStyle(RidgitsColors.textSecondary)
                } else if !match.location.isEmpty {
                    Text(match.location)
                        .font(RidgitsTypography.caption(13))
                        .foregroundStyle(RidgitsColors.textSecondary)
                        .lineLimit(1)
                }

                Text("Once they accept, you have 24 hours and \(RidgitsMessagingLimits.maxMessages) messages total.")
                    .font(RidgitsTypography.body(14))
                    .foregroundStyle(RidgitsColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var composeMessageField: some View {
        RidgitsMultilineTextEditor(
            text: $composeMessage,
            placeholder: "Say something to start the conversation…"
        )
    }

    private func handleExistingConversationError(_ error: Error, match: RidgitsMatch) -> Bool {
        let message = (error as? RidgitsError)?.localizedDescription ?? error.localizedDescription
        let normalized = message.lowercased()

        if normalized.contains("message limit reached")
            || normalized.contains("\(RidgitsMessagingLimits.maxMessages)-message") {
            messagingBlockedMessage =
                "You can't message them — you've already hit the \(RidgitsMessagingLimits.maxMessages)-message limit for this conversation."
            return true
        }
        if normalized.contains("expired") {
            messagingBlockedMessage = "You can't message them — this conversation has already expired."
            return true
        }
        guard normalized.contains("conversation already exists")
            || normalized.contains("awaiting approval") else {
            return false
        }
        onOpenConversation?(match.userId, nil)
        return true
    }
}

struct IncomingPokeProfile: Identifiable, Equatable {
    let userId: String
    let pokeId: String?

    var id: String {
        "\(userId):\(pokeId ?? "")"
    }
}

private struct CompatibilityFilterPopover: View {
    @Binding var filter: RidgitsCompatibilityFilter
    let onReset: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Filter by compatibility")
                    .font(RidgitsTypography.caption(11))
                    .foregroundStyle(RidgitsColors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.8)
                Spacer()
                Button("Reset") { onReset() }
                    .font(RidgitsTypography.label(12))
                    .foregroundStyle(RidgitsColors.textHeadline)
            }

            ForEach(RidgitsCompatibilityFilterDimension.allCases) { dimension in
                compatibilitySlider(for: dimension)
            }
        }
        .padding(16)
        .frame(width: 320)
        .background(RidgitsColors.surface)
    }

    private func compatibilitySlider(for dimension: RidgitsCompatibilityFilterDimension) -> some View {
        let value = dimension.minimum(from: filter)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(dimension.title)
                    .font(RidgitsTypography.body(13))
                    .foregroundStyle(RidgitsColors.textHeadline)
                Spacer()
                Text("\(value)%")
                    .font(RidgitsTypography.label(13))
                    .foregroundStyle(RidgitsColors.textHeadline)
                    .monospacedDigit()
            }

            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { newValue in
                        dimension.setMinimum(Int(newValue), on: &filter)
                    }
                ),
                in: 0...150,
                step: 5
            )
            .tint(RidgitsColors.ctaBlack)
        }
    }
}

private struct MatchCard: View {
    let match: RidgitsMatch
    let locked: Bool
    let sentPoke: Bool
    var messageClosedLabel: String? = nil
    var hidePoke = false
    let onOpenProfile: () -> Void
    let onMessage: () -> Void
    let onPoke: () -> Void
    let onUnpoke: () -> Void

    private var matchLocationSubtitle: String {
        guard let miles = match.distanceMiles else { return match.location }
        return "\(match.location) · \(Int(miles.rounded())) mi"
    }

    var body: some View {
        RidgitsCard {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 12) {
                    RidgitsCachedProfileImage(remoteURL: match.image.isEmpty ? nil : match.image) {
                        RidgitsColors.border
                    }
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.md))

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Text(locked ? "Someone nearby" : match.displayFirstName)
                                .font(RidgitsTypography.headline(16))
                            if !locked {
                                RidgitsProfileTrustBadges(
                                    subscriptionTier: match.subscriptionTier,
                                    profilePhotoVerified: match.isProfilePhotoVerified,
                                    showPhotoVerified: false,
                                    badgeSize: 16
                                )
                            }
                            Spacer()
                            RidgitsCompatibilityBadge(percent: match.compatibility.overall)
                        }
                        if !locked, !match.location.isEmpty {
                            Text(matchLocationSubtitle)
                                .font(RidgitsTypography.caption())
                                .foregroundStyle(RidgitsColors.textSecondary)
                        }
                        if let about = match.sanitizedAbout, !locked {
                            Text(about)
                                .font(RidgitsTypography.body(13))
                                .foregroundStyle(RidgitsColors.textSecondary)
                                .lineLimit(2)
                        }
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    RidgitsHaptics.play(.light)
                    if locked {
                        onMessage()
                    } else {
                        onOpenProfile()
                    }
                }

                HStack(spacing: 8) {
                    if let messageClosedLabel {
                        Text(messageClosedLabel)
                            .font(RidgitsTypography.label(13))
                            .foregroundStyle(RidgitsColors.textMuted)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .overlay(Capsule().stroke(RidgitsColors.border, lineWidth: 1))
                            .accessibilityLabel("Conversation \(messageClosedLabel.lowercased())")
                    } else {
                        Button("Message", action: onMessage)
                            .font(RidgitsTypography.label(13))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(RidgitsColors.ctaBlack)
                            .clipShape(Capsule())
                    }
                    if !hidePoke {
                        Button(sentPoke ? "Poked" : "Poke", action: sentPoke ? onUnpoke : onPoke)
                            .font(RidgitsTypography.label(13))
                            .foregroundStyle(sentPoke ? RidgitsColors.textMuted : RidgitsColors.textHeadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .overlay(Capsule().stroke(RidgitsColors.border, lineWidth: 1))
                    }
                }
                .padding(.top, 10)
                .blur(radius: locked ? 6 : 0)
            }
        }
    }
}
