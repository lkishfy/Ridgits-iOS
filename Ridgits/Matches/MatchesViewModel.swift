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
    /// Set when a poke failed for missing credits — present `PokePackPaywallView`.
    @Published var showPokePackPaywall = false
    /// Set when the server requires birth year on file — present `BirthYearPromptView`.
    @Published var showBirthYearPrompt = false
    @Published var pokeCredits: RidgitsPokeCredits?

    private var nearbyPool: [RidgitsMatch] = []
    private var rawNationwideMatches: [RidgitsMatch] = []
    private var lastPoolAccessKey: String?
    private var nearbyLoadTask: Task<Void, Never>?
    private var resolvedMatchCache: [String: RidgitsMatch] = [:]

    func fetchRadius(access: RidgitsNearbySearchAccess) -> Int {
        RidgitsNearbyAccess.clampRadius(maxDistance, access: access)
    }

    private func enrichDistances(_ matches: [RidgitsMatch]) -> [RidgitsMatch] {
        matches.map { match in
            guard match.distanceMiles == nil else { return match }
            guard let pooled = nearbyPool.first(where: { $0.userId == match.userId }),
                  let miles = pooled.distanceMiles else { return match }
            return match.withDistanceMiles(miles)
        }
    }

    func hydrateFromCache(uid: String, access: RidgitsNearbySearchAccess) {
        if let cached = RidgitsMatchesCache.shared.nationwide(for: uid, limit: 10) {
            rawNationwideMatches = cached
            nationwideMatches = compatibilityFilter.filtered(enrichDistances(cached))
        }

        guard let pool = RidgitsMatchesCache.shared.nearbyPool(for: uid),
              pool.poolAccessKey == access.poolCacheKey else {
            return
        }

        nearbyPool = pool.matches
        closeMatchCount = access.showsCloseMatchTeaser ? pool.closeMatchCount : 0
        applyDisplayedRadius(access: access)
        refreshNationwideDistances()
    }

    private func refreshNationwideDistances() {
        guard !rawNationwideMatches.isEmpty else { return }
        nationwideMatches = compatibilityFilter.filtered(enrichDistances(rawNationwideMatches))
    }

    func applyDisplayedRadius(access: RidgitsNearbySearchAccess) {
        let radiusMatches = RidgitsNearbyAccess.displayedMatches(
            from: nearbyPool,
            within: fetchRadius(access: access),
            access: access
        )
        nearbyMatches = compatibilityFilter.filtered(radiusMatches)
    }

    func onRadiusChanged(access: RidgitsNearbySearchAccess) {
        applyDisplayedRadius(access: access)
    }

    func onCompatibilityFilterChanged(access: RidgitsNearbySearchAccess) {
        applyDisplayedRadius(access: access)
        nationwideMatches = compatibilityFilter.filtered(enrichDistances(rawNationwideMatches))
    }

    func resetCompatibilityFilter(access: RidgitsNearbySearchAccess) {
        compatibilityFilter.reset()
        onCompatibilityFilterChanged(access: access)
    }

    func unfilteredNearbyCount(access: RidgitsNearbySearchAccess) -> Int {
        RidgitsNearbyAccess.displayedMatches(
            from: nearbyPool,
            within: fetchRadius(access: access),
            access: access
        ).count
    }

    func resolveMatch(for userId: String) async -> RidgitsMatch? {
        if let existing = nearbyPool.first(where: { $0.userId == userId })
            ?? rawNationwideMatches.first(where: { $0.userId == userId }) {
            return enrichDistances([existing]).first ?? existing
        }

        if let cached = resolvedMatchCache[userId] {
            return enrichDistances([cached]).first ?? cached
        }

        var profile = RidgitsPublicProfileCache.shared.profile(for: userId)
        if profile == nil {
            profile = await RidgitsFirebaseClient.shared.fetchPublicProfile(uid: userId)
        }
        guard let profile else { return nil }

        RidgitsPublicProfileCache.shared.save(profile)

        let name = profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let about = profile.about.trimmingCharacters(in: .whitespacesAndNewlines)
        let compatibility = await fetchCompatibility(with: userId) ?? .empty

        let match = RidgitsMatch(
            id: userId,
            userId: userId,
            name: name.isEmpty ? "Ridgits member" : name,
            image: profile.image,
            location: profile.location,
            distanceMiles: nil,
            compatibility: compatibility,
            about: about.isEmpty ? nil : about,
            subscriptionTier: profile.subscriptionTier
        )
        resolvedMatchCache[userId] = match
        return match
    }

    private func fetchCompatibility(with otherUserId: String) async -> RidgitsCompatibility? {
        guard let myUid = Auth.auth().currentUser?.uid else { return nil }
        return await RidgitsQuizCompatibility.compatibilityBetween(
            currentUserId: myUid,
            otherUserId: otherUserId
        )
    }

    func load(access: RidgitsNearbySearchAccess, forceRefresh: Bool = false) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        nearbyLoadTask?.cancel()
        nearbyLoadTask = Task {
            await performLoad(uid: uid, access: access, forceRefresh: forceRefresh)
        }
        await nearbyLoadTask?.value
    }

    private func performLoad(uid: String, access: RidgitsNearbySearchAccess, forceRefresh: Bool) async {
        await refreshPokeCredits()
        await repairQuizCompletionIfNeeded(uid: uid)

        let accessKey = access.poolCacheKey
        let accessChanged = lastPoolAccessKey.map { $0 != accessKey } ?? false
        lastPoolAccessKey = accessKey

        if !forceRefresh && !accessChanged {
            hydrateFromCache(uid: uid, access: access)

            let nationwideLooksBroken = !rawNationwideMatches.isEmpty
                && rawNationwideMatches.allSatisfy { !$0.compatibility.hasScores }
            let needsNationwide = nationwideLooksBroken
                || !RidgitsMatchesCache.shared.hasNationwide(uid: uid, limit: 10)
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
                nationwideMatches = compatibilityFilter.filtered(enrichDistances(rawNationwideMatches))
            }

            if Task.isCancelled { return }

            if shouldFetchNearby {
                await refreshNearbyPool(
                    uid: uid,
                    access: access,
                    forceRefresh: forceRefresh || accessChanged,
                    blocking: showBlockingLoad
                )
            } else {
                applyDisplayedRadius(access: access)
            }
        } catch is CancellationError {
            return
        } catch {
            if !Task.isCancelled {
                await applyMatchingError(error, uid: uid)
            }
        }
    }

    private func refreshNearbyPool(
        uid: String,
        access: RidgitsNearbySearchAccess,
        forceRefresh: Bool,
        blocking: Bool
    ) async {
        let poolRadius = RidgitsNearbyAccess.poolFetchRadius(access: access)
        let accessKey = access.poolCacheKey

        if !forceRefresh,
           let cached = RidgitsMatchesCache.shared.nearbyPool(for: uid),
           cached.poolRadius >= poolRadius,
           cached.poolAccessKey == accessKey,
           !RidgitsMatchesCache.shared.isNearbyPoolStale(uid: uid) {
            nearbyPool = cached.matches
            closeMatchCount = access.showsCloseMatchTeaser ? cached.closeMatchCount : 0
            applyDisplayedRadius(access: access)
            refreshNationwideDistances()
            await refreshCloseMatchCount(access: access, forceRefresh: forceRefresh)
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
            try await fetchNearbyPool(
                uid: uid,
                poolRadius: poolRadius,
                accessKey: accessKey,
                access: access,
                forceRefresh: forceRefresh
            )
        } catch is CancellationError {
            return
        } catch {
            if !Task.isCancelled {
                await applyMatchingError(error, uid: uid)
            }
        }
    }

    private func fetchNearbyPool(
        uid: String,
        poolRadius: Int,
        accessKey: String,
        access: RidgitsNearbySearchAccess,
        forceRefresh: Bool
    ) async throws {
        do {
            try await loadNearbyPool(
                poolRadius: poolRadius,
                accessKey: accessKey,
                access: access,
                forceRefresh: forceRefresh
            )
        } catch {
            guard await shouldRetryMatchingAfterQuizRepair(error, uid: uid) else { throw error }
            await repairQuizCompletionIfNeeded(uid: uid)
            try await loadNearbyPool(
                poolRadius: poolRadius,
                accessKey: accessKey,
                access: access,
                forceRefresh: true
            )
        }
    }

    private func loadNearbyPool(
        poolRadius: Int,
        accessKey: String,
        access: RidgitsNearbySearchAccess,
        forceRefresh: Bool
    ) async throws {
        let result = try await RidgitsFirebaseClient.shared.findNearbyPool(
            poolRadius: poolRadius,
            poolAccessKey: accessKey,
            forceRefresh: forceRefresh
        )
        guard !Task.isCancelled else { return }
        nearbyPool = result.matches
        closeMatchCount = access.showsCloseMatchTeaser ? max(0, result.closeMatchCount) : 0
        applyDisplayedRadius(access: access)
        refreshNationwideDistances()
        await refreshCloseMatchCount(access: access, forceRefresh: forceRefresh)
        errorMessage = nil
    }

    private func repairQuizCompletionIfNeeded(uid: String) async {
        guard (try? await RidgitsFirebaseClient.shared.isQuizCompleted(uid: uid)) == true else { return }
        _ = try? await RidgitsFirebaseClient.shared.ensureQuizCompletionRecorded(uid: uid)
    }

    private func applyMatchingError(_ error: Error, uid: String) async {
        let message = error.localizedDescription
        if message.localizedCaseInsensitiveContains("complete the quiz"),
           (try? await RidgitsFirebaseClient.shared.isQuizCompleted(uid: uid)) == true {
            errorMessage = nil
            return
        }
        errorMessage = message
    }

    private func shouldRetryMatchingAfterQuizRepair(_ error: Error, uid: String) async -> Bool {
        let message = error.localizedDescription.lowercased()
        guard message.contains("complete the quiz") else { return false }
        return (try? await RidgitsFirebaseClient.shared.isQuizCompleted(uid: uid)) == true
    }

    /// Accurate count of compatible matches within the close-match threshold (free-user teaser).
    private func refreshCloseMatchCount(access: RidgitsNearbySearchAccess, forceRefresh: Bool) async {
        guard access.showsCloseMatchTeaser else {
            closeMatchCount = 0
            return
        }

        do {
            let preview = try await RidgitsFirebaseClient.shared.findMatches(
                maxDistance: RidgitsNearbyAccess.closeMatchesThresholdMiles,
                forceRefresh: forceRefresh,
                previewCloseMatches: true
            )
            guard !Task.isCancelled else { return }
            closeMatchCount = max(0, preview.closeMatchCount)
        } catch is CancellationError {
            return
        } catch {
            closeMatchCount = 0
        }
    }

    func refreshPokeCredits() async {
        do {
            pokeCredits = try await RidgitsAPIClient.shared.fetchPokeCredits()
        } catch {
            // Non-fatal — sending is still gated server-side.
        }
    }

    /// Returns whether the user can attempt a new poke (has credits and hasn't already poked).
    func preflightPoke(alreadySent: Bool) async -> PokePreflightResult {
        if alreadySent { return .alreadySent }
        await refreshPokeCredits()
        guard let balance = pokeCredits?.balance, balance > 0 else {
            return .noCredits
        }
        return .ready
    }

    func pokeConfirmationMessage(for matchName: String) -> String {
        let balance = pokeCredits?.balance ?? 0
        let leftLabel = balance == 1 ? "1 poke left" : "\(balance) pokes left"
        return "You have \(leftLabel). Send one to \(matchName)? This can't be undone."
    }

    func sendPoke(to match: RidgitsMatch) async {
        do {
            _ = try await RidgitsAPIClient.shared.sendPoke(toUserId: match.userId)
            await refreshPokeCredits()
        } catch let ridgitsError as RidgitsError {
            if ridgitsError.code == "POKE_CREDITS_REQUIRED" {
                showPokePackPaywall = true
            } else if ridgitsError.code == "AGE_VERIFICATION_REQUIRED" || ridgitsError.code == "UNDERAGE" {
                showBirthYearPrompt = true
                return
            }
            errorMessage = ridgitsError.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func unpoke(pokeId: String) async {
        do {
            try await RidgitsAPIClient.shared.unpoke(pokeId: pokeId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

enum PokePreflightResult {
    case alreadySent
    case noCredits
    case ready
}
