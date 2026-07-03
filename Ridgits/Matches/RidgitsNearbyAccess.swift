import Foundation

enum RidgitsNearbyAccess {
    /// Free users cannot see matches closer than this.
    static let closeMatchesThresholdMiles = 30

    /// Badge count: "N within 25 mi" — the radius subscribers unlock.
    static let closeMatchesBadgeMiles = 25

    static let unsubscribedMinRadiusMiles = 30
    static let unsubscribedMaxRadiusMiles = 150

    static let subscribedMinRadiusMiles = 5
    static let subscribedMaxRadiusMiles = 150

    static let defaultRadiusMiles = 50

    static func minRadiusMiles(hasExtendedRadius: Bool) -> Int {
        hasExtendedRadius ? subscribedMinRadiusMiles : unsubscribedMinRadiusMiles
    }

    static func maxRadiusMiles(hasExtendedRadius: Bool) -> Int {
        hasExtendedRadius ? subscribedMaxRadiusMiles : unsubscribedMaxRadiusMiles
    }

    static func clampRadius(_ radius: Int, hasExtendedRadius: Bool) -> Int {
        let stepped = Int((Double(radius) / 5.0).rounded() * 5)
        return min(maxRadiusMiles(hasExtendedRadius: hasExtendedRadius),
                   max(minRadiusMiles(hasExtendedRadius: hasExtendedRadius), stepped))
    }

    static func isCloseRadiusAttempt(_ radius: Int, hasExtendedRadius: Bool) -> Bool {
        !hasExtendedRadius && radius < closeMatchesThresholdMiles
    }

    static func closeMatches(from matches: [RidgitsMatch]) -> [RidgitsMatch] {
        matches.filter { match in
            guard let miles = match.distanceMiles else { return false }
            return miles >= 0 && miles < Double(closeMatchesBadgeMiles)
        }
    }

    /// Fetch once at the user's max radius, then filter locally when the slider moves.
    static func poolFetchRadius(hasExtendedRadius: Bool) -> Int {
        maxRadiusMiles(hasExtendedRadius: hasExtendedRadius)
    }

    static func displayedMatches(
        from pool: [RidgitsMatch],
        within radius: Int,
        hasExtendedRadius: Bool
    ) -> [RidgitsMatch] {
        let clamped = clampRadius(radius, hasExtendedRadius: hasExtendedRadius)
        return pool.filter { match in
            guard let miles = match.distanceMiles else {
                return hasExtendedRadius
            }
            if !hasExtendedRadius && miles < Double(closeMatchesThresholdMiles) {
                return false
            }
            return miles <= Double(clamped)
        }
    }
}

extension RidgitsStore {
    /// Close-radius search requires active server-confirmed subscription access.
    var hasExtendedNearbyRadius: Bool {
        hasNearbyAccess
    }
}
