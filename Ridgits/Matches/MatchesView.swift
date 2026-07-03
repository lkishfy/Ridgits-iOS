import SwiftUI
import FirebaseAuth

struct MatchesView: View {
    @EnvironmentObject private var ridgitsStore: RidgitsStore
    @EnvironmentObject private var nearbyPresence: RidgitsNearbyPresenceService
    @EnvironmentObject private var pokeInbox: RidgitsPokeInbox
    @ObservedObject var viewModel: MatchesViewModel
    @State private var showSubscriptionPaywall = false
    @State private var composeMatch: RidgitsMatch?
    @State private var selectedMatch: RidgitsMatch?
    @State private var composeMessage = ""
    @State private var showCompatibilityFilter = false

    private var hasExtendedNearby: Bool {
        ridgitsStore.hasExtendedNearbyRadius
    }

    private var sliderMin: Double {
        Double(RidgitsNearbyAccess.subscribedMinRadiusMiles)
    }

    private var sliderMax: Double {
        Double(RidgitsNearbyAccess.maxRadiusMiles(hasExtendedRadius: hasExtendedNearby))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if nearbyPresence.isActive, nearbyPresence.nearbyPeerCount > 0 {
                    nearbyBluetoothBanner
                }
                if pokeInbox.unseenCount > 0 {
                    pokeInboxBanner
                }
                nearbySection
                RidgitsSectionHeader(title: "Top nationwide", subtitle: "Preview compatibility scores")
                matchSection(viewModel.nationwideMatches, locked: false, allowInteraction: true)
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
            await viewModel.load(hasExtendedNearby: hasExtendedNearby, forceRefresh: true)
        }
        .task(id: hasExtendedNearby) {
            viewModel.maxDistance = RidgitsNearbyAccess.clampRadius(
                viewModel.maxDistance,
                hasExtendedRadius: hasExtendedNearby
            )
            if let uid = Auth.auth().currentUser?.uid {
                viewModel.hydrateFromCache(uid: uid, hasExtendedNearby: hasExtendedNearby)
            }
            await ridgitsStore.refreshAccessInBackground()
            await viewModel.load(hasExtendedNearby: hasExtendedNearby)
        }
        .onChange(of: viewModel.maxDistance) { _, newValue in
            let minAllowed = RidgitsNearbyAccess.minRadiusMiles(hasExtendedRadius: hasExtendedNearby)
            guard newValue >= minAllowed else { return }
            viewModel.onRadiusChanged(hasExtendedNearby: hasExtendedNearby)
        }
        .onChange(of: viewModel.compatibilityFilter) { _, _ in
            viewModel.onCompatibilityFilterChanged(hasExtendedNearby: hasExtendedNearby)
        }
        .ridgitsBlockingLoader(
            isPresented: viewModel.isLoadingNearby,
            title: "Finding matches",
            subtitle: "Scanning compatible people near you"
        )
        .navigationDestination(item: $selectedMatch) { match in
            MatchProfileView(
                match: match,
                onMessage: { composeMatch = match },
                onPoke: {
                    if let pokeId = pokeInbox.sentPokeIdsByUser[match.userId] {
                        Task { await viewModel.unpoke(match: match, pokeId: pokeId) }
                    } else {
                        guard ridgitsStore.hasPlusMembership else {
                            showSubscriptionPaywall = true
                            return
                        }
                        Task { await viewModel.sendPoke(to: match) }
                    }
                }
            )
        }
        .sheet(isPresented: $showSubscriptionPaywall) {
            SubscriptionPaywallView(preferredBilling: .yearly)
        }
        .sheet(item: $composeMatch) { match in
            composeSheet(for: match)
        }
        .onChange(of: viewModel.showPaywallPrompt) { _, showPaywall in
            guard showPaywall else { return }
            viewModel.showPaywallPrompt = false
            showSubscriptionPaywall = true
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { viewModel.errorMessage != nil && !viewModel.showPaywallPrompt },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private func attemptRadiusChange(to rawValue: Double) {
        let stepped = Int((rawValue / 5.0).rounded() * 5)

        if RidgitsNearbyAccess.isCloseRadiusAttempt(stepped, hasExtendedRadius: hasExtendedNearby) {
            showSubscriptionPaywall = true
            return
        }

        viewModel.maxDistance = RidgitsNearbyAccess.clampRadius(stepped, hasExtendedRadius: hasExtendedNearby)
    }

    @ViewBuilder
    private var pokeInboxBanner: some View {
        RidgitsCard {
            VStack(alignment: .leading, spacing: 6) {
                Text("\(pokeInbox.unseenCount) new \(pokeInbox.unseenCount == 1 ? "poke" : "pokes")")
                    .font(RidgitsTypography.label(14))
                if let latest = pokeInbox.receivedPokes.first(where: \.isActionable) {
                    Text("\(latest.fromName) is interested. Tap their profile below.")
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
                    Text("Detected via Bluetooth while the app is open")
                        .font(RidgitsTypography.caption(11))
                        .foregroundStyle(RidgitsColors.textSecondary)
                }
            }
        }
    }

    private var nearbySection: some View {
        Group {
            distanceSlider

            if viewModel.isLoading && viewModel.nearbyMatches.isEmpty {
                ProgressView().padding(.vertical, 12)
            } else {
                nearbyMatchesSection
            }
        }
    }

    private var nearbyMatchesSection: some View {
        Group {
            if viewModel.nearbyMatches.isEmpty && !viewModel.isLoading && !viewModel.isLoadingNearby {
                if viewModel.compatibilityFilter.isActive,
                   viewModel.unfilteredNearbyCount(hasExtendedNearby: hasExtendedNearby) > 0 {
                    filteredEmptyCard
                } else {
                    noNearbyCard
                }
            } else {
                matchSection(viewModel.nearbyMatches, locked: false, allowInteraction: true)
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
                    viewModel.resetCompatibilityFilter(hasExtendedNearby: hasExtendedNearby)
                }
            }
        }
    }

    private var distanceSlider: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                Text("\(viewModel.nearbyMatches.count) \(viewModel.nearbyMatches.count == 1 ? "person" : "people") · within \(viewModel.maxDistance) miles")
                    .font(RidgitsTypography.caption(11))
                    .foregroundStyle(RidgitsColors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.6)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 8)

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
                            viewModel.resetCompatibilityFilter(hasExtendedNearby: hasExtendedNearby)
                        }
                    )
                    .presentationCompactAdaptation(.popover)
                }
            }

            Slider(value: Binding(
                get: { Double(viewModel.maxDistance) },
                set: { attemptRadiusChange(to: $0) }
            ), in: sliderMin...sliderMax, step: 5)
            .tint(RidgitsColors.ctaBlack)
            .disabled(viewModel.isLoadingNearby)

            HStack(spacing: 6) {
                ForEach(radiusPresets, id: \.self) { preset in
                    Button {
                        attemptRadiusChange(to: Double(preset))
                    } label: {
                        Text("\(preset)")
                            .font(RidgitsTypography.caption(11))
                            .foregroundStyle(viewModel.maxDistance == preset ? .white : RidgitsColors.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(viewModel.maxDistance == preset ? RidgitsColors.ctaBlack : RidgitsColors.hoverSurface)
                            .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.sm))
                    }
                    .buttonStyle(RidgitsHapticPlainButtonStyle())
                    .disabled(viewModel.isLoadingNearby)
                }
            }
        }
        .padding(16)
        .background(RidgitsColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.lg))
        .overlay(RoundedRectangle(cornerRadius: RidgitsRadius.lg).stroke(RidgitsColors.border, lineWidth: 1))
    }

    private var radiusPresets: [Int] {
        hasExtendedNearby ? [10, 25, 50, 100] : [25, 50, 100]
    }

    private var noNearbyCard: some View {
        RidgitsCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("No one nearby yet")
                    .font(RidgitsTypography.headline())
                Text("There aren't compatible people within \(viewModel.maxDistance) miles right now. Try a wider radius or browse nationwide matches below.")
                    .font(RidgitsTypography.body(14))
                    .foregroundStyle(RidgitsColors.textSecondary)
            }
        }
    }

    private func matchSection(_ matches: [RidgitsMatch], locked: Bool, allowInteraction: Bool) -> some View {
        VStack(spacing: 12) {
            if viewModel.isLoading && matches.isEmpty {
                ProgressView().padding()
            } else if matches.isEmpty {
                EmptyView()
            } else {
                ForEach(matches) { match in
                    MatchCard(
                        match: match,
                        locked: locked,
                        sentPoke: pokeInbox.sentPokeIdsByUser[match.userId] != nil,
                        onOpenProfile: {
                            guard allowInteraction, !locked else { return }
                            selectedMatch = match
                        },
                        onMessage: {
                            guard allowInteraction else { return }
                            composeMatch = match
                        },
                        onPoke: {
                            guard allowInteraction else { return }
                            if let pokeId = pokeInbox.sentPokeIdsByUser[match.userId] {
                                Task { await viewModel.unpoke(match: match, pokeId: pokeId) }
                            } else {
                                Task { await viewModel.sendPoke(to: match) }
                            }
                        }
                    )
                }
            }
        }
    }

    private func composeSheet(for match: RidgitsMatch) -> some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Message \(match.name)")
                    .font(RidgitsTypography.headline())
                Text("Once they accept, you have 24 hours and 16 messages total.")
                    .font(RidgitsTypography.body(14))
                    .foregroundStyle(RidgitsColors.textHeadline.opacity(0.72))
                TextEditor(text: $composeMessage)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(RidgitsColors.inputSurface)
                    .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.md))
                    .overlay(RoundedRectangle(cornerRadius: RidgitsRadius.md).stroke(RidgitsColors.inputBorder, lineWidth: 1))
                RidgitsPrimaryButton(title: "Send request", isDisabled: composeMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                    guard ridgitsStore.hasPlusMembership else {
                        showSubscriptionPaywall = true
                        return
                    }
                    Task {
                        do {
                            _ = try await RidgitsFirebaseClient.shared.startConversation(
                                toUserId: match.userId,
                                message: composeMessage
                            )
                            composeMessage = ""
                            composeMatch = nil
                        } catch let ridgitsError as RidgitsError {
                            composeMatch = nil
                            if ridgitsError.code == "SUBSCRIPTION_REQUIRED" || ridgitsError.code == "MONTHLY_MESSAGE_LIMIT_REACHED" {
                                showSubscriptionPaywall = true
                            } else {
                                viewModel.errorMessage = ridgitsError.localizedDescription
                            }
                        } catch {
                            composeMatch = nil
                            viewModel.errorMessage = error.localizedDescription
                        }
                    }
                }
                Spacer()
            }
            .padding(20)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { composeMatch = nil }
                }
            }
        }
        .presentationDetents([.medium])
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
    let onOpenProfile: () -> Void
    let onMessage: () -> Void
    let onPoke: () -> Void

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
                            Text(locked ? "Someone nearby" : match.name)
                                .font(RidgitsTypography.headline(16))
                            if !locked {
                                RidgitsVerifiedBadge(tier: match.subscriptionTier, size: 16)
                            }
                            Spacer()
                            RidgitsCompatibilityBadge(percent: match.compatibility.overall)
                        }
                        if !locked, !match.location.isEmpty {
                            Text(match.location)
                                .font(RidgitsTypography.caption())
                                .foregroundStyle(RidgitsColors.textSecondary)
                        }
                        if let about = match.about, !locked {
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
                    Button("Message", action: onMessage)
                        .font(RidgitsTypography.label(13))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(RidgitsColors.ctaBlack)
                        .clipShape(Capsule())
                    Button(sentPoke ? "Unpoke" : "Poke", action: onPoke)
                        .font(RidgitsTypography.label(13))
                        .foregroundStyle(RidgitsColors.textHeadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .overlay(Capsule().stroke(RidgitsColors.border, lineWidth: 1))
                }
                .padding(.top, 10)
                .blur(radius: locked ? 6 : 0)
            }
        }
    }
}
