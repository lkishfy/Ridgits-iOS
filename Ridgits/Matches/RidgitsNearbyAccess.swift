import Foundation

/// Tier-aware nearby search rules (mirrors ridgits-api `ridgits-products.ts`).
struct RidgitsNearbySearchAccess: Equatable {
    let tier: RidgitsSubscriptionTier
    let hasMembership: Bool

    @MainActor
    static func from(store: RidgitsStore) -> RidgitsNearbySearchAccess {
        RidgitsNearbySearchAccess(
            tier: store.isMembershipActive ? store.membershipTier : .free,
            hasMembership: store.isMembershipActive
        )
    }

    /// Cache key for the nearby match pool.
    var poolCacheKey: String {
        hasMembership ? tier.rawValue : "free"
    }

    /// Minimum search radius on the slider (mi).
    var minRadiusMiles: Int {
        guard hasMembership else { return RidgitsNearbyAccess.unsubscribedMinRadiusMiles }
        switch tier {
        case .plus:
            return RidgitsNearbyAccess.plusMinRadiusMiles
        case .premium, .ultra:
            return 0
        default:
            return RidgitsNearbyAccess.unsubscribedMinRadiusMiles
        }
    }

    /// Hide matches closer than this distance (mi). Zero = no floor.
    var closeMatchFloorMiles: Int {
        guard hasMembership else { return RidgitsNearbyAccess.closeMatchesThresholdMiles }
        switch tier {
        case .plus:
            return RidgitsNearbyAccess.plusMinRadiusMiles
        case .premium, .ultra:
            return 0
        default:
            return RidgitsNearbyAccess.closeMatchesThresholdMiles
        }
    }

    var showsCloseMatchTeaser: Bool {
        !hasMembership
    }
}

enum RidgitsNearbyAccess {
    /// Free users cannot see matches closer than this.
    static let closeMatchesThresholdMiles = 25

    /// Ridgits+ search floor (mi).
    static let plusMinRadiusMiles = 25

    /// Badge count: "N within 25 mi" — upsell for free users.
    static let closeMatchesBadgeMiles = 25

    static let unsubscribedMinRadiusMiles = 25
    static let unsubscribedMaxRadiusMiles = 150

    static let subscribedMaxRadiusMiles = 150

    static let defaultRadiusMiles = 50

    /// Quick-select and slider snap points (mi).
    static let radiusPresetMiles = [25, 50, 100, 150]

    static func snapToPresetMiles(_ radius: Int) -> Int {
        radiusPresetMiles.min(by: { abs($0 - radius) < abs($1 - radius) }) ?? radius
    }

    static func minRadiusMiles(access: RidgitsNearbySearchAccess) -> Int {
        access.minRadiusMiles
    }

    static func maxRadiusMiles(access: RidgitsNearbySearchAccess) -> Int {
        access.hasMembership ? subscribedMaxRadiusMiles : unsubscribedMaxRadiusMiles
    }

    static func clampRadius(_ radius: Int, access: RidgitsNearbySearchAccess) -> Int {
        let snapped = snapToPresetMiles(radius)
        return min(
            maxRadiusMiles(access: access),
            max(minRadiusMiles(access: access), snapped)
        )
    }

    /// Free users hitting a radius below 25 mi should see the paywall.
    static func isCloseRadiusAttempt(_ radius: Int, access: RidgitsNearbySearchAccess) -> Bool {
        !access.hasMembership && radius < closeMatchesThresholdMiles
    }

    static func closeMatches(from matches: [RidgitsMatch]) -> [RidgitsMatch] {
        matches.filter { match in
            guard let miles = match.distanceMiles else { return false }
            return miles >= 0 && miles < Double(closeMatchesBadgeMiles)
        }
    }

    static func poolFetchRadius(access: RidgitsNearbySearchAccess) -> Int {
        maxRadiusMiles(access: access)
    }

    static func displayedMatches(
        from pool: [RidgitsMatch],
        within radius: Int,
        access: RidgitsNearbySearchAccess
    ) -> [RidgitsMatch] {
        let clamped = clampRadius(radius, access: access)
        let floor = access.closeMatchFloorMiles
        return pool.filter { match in
            guard let miles = match.distanceMiles else {
                return access.hasMembership && floor == 0
            }
            if floor > 0 && miles > 0 && miles < Double(floor) {
                return false
            }
            return miles <= Double(clamped)
        }
    }
}

extension RidgitsStore {
    /// Active membership with server-confirmed nearby access.
    @MainActor
    var hasExtendedNearbyRadius: Bool {
        hasNearbyAccess && isMembershipActive
    }
}
