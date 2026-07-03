import SwiftUI
import FirebaseAuth

@MainActor
final class MatchesViewModel: ObservableObject {
    @Published var nearbyMatches: [RidgitsMatch] = []
    @Published var nationwideMatches: [RidgitsMatch] = []
    @Published var maxDistance = RidgitsNearbyAccess.defaultRadiusMiles
    @Published var compatibilityFilter = RidgitsCompatibilityFilter()
    @Published var closeMatchCount = 0
    @Published var isLoading = false
    @Published var isLoadingNearby = false
    @Published var errorMessage: String?
    /// Set when a poke failed because the account isn't subscribed — the view should
    /// present `SubscriptionPaywallView` in addition to (or instead of) the alert.
    @Published var showPaywallPrompt = false

    private var nearbyPool: [RidgitsMatch] = []
    private var rawNationwideMatches: [RidgitsMatch] = []
    private var lastPoolAccessExtended: Bool?
    private var nearbyLoadTask: Task<Void, Never>?

    func fetchRadius(hasExtendedNearby: Bool) -> Int {
        RidgitsNearbyAccess.clampRadius(maxDistance, hasExtendedRadius: hasExtendedNearby)
    }

    func hydrateFromCache(uid: String, hasExtendedNearby: Bool) {
        if let cached = RidgitsMatchesCache.shared.nationwide(for: uid, limit: 10) {
            rawNationwideMatches = cached
            nationwideMatches = compatibilityFilter.filtered(cached)
        }

        guard let pool = RidgitsMatchesCache.shared.nearbyPool(for: uid),
              pool.hasExtendedRadius == hasExtendedNearby else {
            return
        }

        nearbyPool = pool.matches
        closeMatchCount = pool.closeMatchCount
        applyDisplayedRadius(hasExtendedNearby: hasExtendedNearby)
    }

    func applyDisplayedRadius(hasExtendedNearby: Bool) {
        let radiusMatches = RidgitsNearbyAccess.displayedMatches(
            from: nearbyPool,
            within: fetchRadius(hasExtendedNearby: hasExtendedNearby),
            hasExtendedRadius: hasExtendedNearby
        )
        nearbyMatches = compatibilityFilter.filtered(radiusMatches)
    }

    func onRadiusChanged(hasExtendedNearby: Bool) {
        applyDisplayedRadius(hasExtendedNearby: hasExtendedNearby)
    }

    func onCompatibilityFilterChanged(hasExtendedNearby: Bool) {
        applyDisplayedRadius(hasExtendedNearby: hasExtendedNearby)
        nationwideMatches = compatibilityFilter.filtered(rawNationwideMatches)
    }

    func resetCompatibilityFilter(hasExtendedNearby: Bool) {
        compatibilityFilter.reset()
        onCompatibilityFilterChanged(hasExtendedNearby: hasExtendedNearby)
    }

    func unfilteredNearbyCount(hasExtendedNearby: Bool) -> Int {
        RidgitsNearbyAccess.displayedMatches(
            from: nearbyPool,
            within: fetchRadius(hasExtendedNearby: hasExtendedNearby),
            hasExtendedRadius: hasExtendedNearby
        ).count
    }

    func load(hasExtendedNearby: Bool, forceRefresh: Bool = false) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        nearbyLoadTask?.cancel()
        nearbyLoadTask = Task {
            await performLoad(uid: uid, hasExtendedNearby: hasExtendedNearby, forceRefresh: forceRefresh)
        }
        await nearbyLoadTask?.value
    }

    private func performLoad(uid: String, hasExtendedNearby: Bool, forceRefresh: Bool) async {
        let accessChanged = lastPoolAccessExtended.map { $0 != hasExtendedNearby } ?? false
        lastPoolAccessExtended = hasExtendedNearby

        if !forceRefresh && !accessChanged {
            hydrateFromCache(uid: uid, hasExtendedNearby: hasExtendedNearby)

            let needsNationwide = !RidgitsMatchesCache.shared.hasNationwide(uid: uid, limit: 10)
                || RidgitsMatchesCache.shared.isNationwideStale(uid: uid, limit: 10)
            let needsNearby = nearbyPool.isEmpty
                || RidgitsMatchesCache.shared.nearbyPool(for: uid) == nil
                || RidgitsMatchesCache.shared.isNearbyPoolStale(uid: uid)
                || accessChanged

            if !needsNationwide && !needsNearby {
                return
            }
        }

        let shouldFetchNearby = forceRefresh
            || accessChanged
            || nearbyPool.isEmpty
            || RidgitsMatchesCache.shared.isNearbyPoolStale(uid: uid)
        let showBlockingLoad = nearbyMatches.isEmpty && nearbyPool.isEmpty

        if showBlockingLoad { isLoading = true }
        defer { isLoading = false }

        do {
            if Task.isCancelled { return }

            if forceRefresh
                || !RidgitsMatchesCache.shared.hasNationwide(uid: uid, limit: 10)
                || RidgitsMatchesCache.shared.isNationwideStale(uid: uid, limit: 10) {
                rawNationwideMatches = try await RidgitsFirebaseClient.shared.getTopNationwideMatches(
                    limit: 10,
                    forceRefresh: forceRefresh
                )
                nationwideMatches = compatibilityFilter.filtered(rawNationwideMatches)
            }

            if Task.isCancelled { return }

            if shouldFetchNearby {
                await refreshNearbyPool(
                    uid: uid,
                    hasExtendedNearby: hasExtendedNearby,
                    forceRefresh: forceRefresh || accessChanged,
                    blocking: showBlockingLoad
                )
            } else {
                applyDisplayedRadius(hasExtendedNearby: hasExtendedNearby)
            }
        } catch is CancellationError {
            return
        } catch {
            if !Task.isCancelled {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func refreshNearbyPool(
        uid: String,
        hasExtendedNearby: Bool,
        forceRefresh: Bool,
        blocking: Bool
    ) async {
        let poolRadius = RidgitsNearbyAccess.poolFetchRadius(hasExtendedRadius: hasExtendedNearby)

        if !forceRefresh,
           let cached = RidgitsMatchesCache.shared.nearbyPool(for: uid),
           cached.poolRadius >= poolRadius,
           cached.hasExtendedRadius == hasExtendedNearby,
           !RidgitsMatchesCache.shared.isNearbyPoolStale(uid: uid) {
            nearbyPool = cached.matches
            closeMatchCount = hasExtendedNearby ? 0 : cached.closeMatchCount
            applyDisplayedRadius(hasExtendedNearby: hasExtendedNearby)
            return
        }

        let shouldShowBlockingLoader = blocking && nearbyMatches.isEmpty
        if shouldShowBlockingLoader {
            isLoadingNearby = true
        }
        defer {
            if shouldShowBlockingLoader {
                isLoadingNearby = false
            }
        }

        do {
            let result = try await RidgitsFirebaseClient.shared.findNearbyPool(
                poolRadius: poolRadius,
                hasExtendedRadius: hasExtendedNearby,
                forceRefresh: forceRefresh
            )
            guard !Task.isCancelled else { return }
            nearbyPool = result.matches
            if !hasExtendedNearby {
                closeMatchCount = result.closeMatchCount
            } else {
                closeMatchCount = 0
            }
            applyDisplayedRadius(hasExtendedNearby: hasExtendedNearby)
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            if !Task.isCancelled {
                errorMessage = error.localizedDescription
            }
        }
    }

    func sendPoke(to match: RidgitsMatch) async {
        do {
            _ = try await RidgitsAPIClient.shared.sendPoke(toUserId: match.userId)
        } catch let ridgitsError as RidgitsError {
            if ridgitsError.code == "SUBSCRIPTION_REQUIRED" {
                showPaywallPrompt = true
            }
            errorMessage = ridgitsError.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func unpoke(match: RidgitsMatch, pokeId: String) async {
        do {
            try await RidgitsAPIClient.shared.unpoke(pokeId: pokeId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
