import Foundation

/// Tier-aware nearby search rules (mirrors ridgits-api `ridgits-products.ts`).
struct RidgitsNearbySearchAccess: Equatable {
    let tier: RidgitsSubscriptionTier
    let hasMembership: Bool

    @MainActor
    static func from(store: RidgitsStore) -> RidgitsNearbySearchAccess {
        RidgitsNearbySearchAccess(
            tier: store.membershipTier,
            hasMembership: store.isMembershipActive
        )
    }

    /// Cache key for the nearby match pool.
    var poolCacheKey: String {
        hasMembership ? tier.rawValue : "free"
    }

    /// Minimum search radius (mi) for the selected tier.
    var minRadiusMiles: Int {
        guard hasMembership else { return RidgitsNearbyAccess.freeMinRadiusMiles }
        switch tier {
        case .plus:
            return RidgitsNearbyAccess.plusMinRadiusMiles
        case .premium, .ultra:
            return 0
        default:
            return RidgitsNearbyAccess.freeMinRadiusMiles
        }
    }

    /// Hide matches closer than this distance (mi). Zero = no floor.
    var closeMatchFloorMiles: Int {
        minRadiusMiles
    }

    var showsCloseMatchTeaser: Bool {
        !hasMembership
    }

    /// Ridgits+ can search 10mi+ but 0mi (metro) is hidden until Premium.
    var showsPremiumCloseTeaser: Bool {
        hasMembership && tier == .plus
    }

    /// Subscription tier to upsell when a locked radius preset is tapped.
    func lockedRadiusPaywallTier(for preset: Int) -> RidgitsSubscriptionTier {
        RidgitsNearbyAccess.paywallTier(forLockedPreset: preset, access: self)
    }
}

enum RidgitsNearbyAccess {
    /// Free users cannot see matches closer than this.
    static let closeMatchesThresholdMiles = 30

    /// Free members search from 30 to 150 miles.
    static let freeMinRadiusMiles = 30

    /// Ridgits+ searches from 10 to 150 miles.
    static let plusMinRadiusMiles = 10

    /// Only the 0 mi metro preset requires Premium (10mi is Ridgits+).
    static let premiumOnlyPresetMiles: Set<Int> = [0]

    static let maxRadiusMiles = 150

    static let defaultRadiusMiles = 50

    /// Quick-select chips (mi). Tier rules gate which values are selectable.
    static let radiusPresetMiles = [0, 10, 25, 30, 50, 150]

    static func snapToPresetMiles(_ radius: Int, access: RidgitsNearbySearchAccess) -> Int {
        radiusPresetMiles.min(by: { abs($0 - radius) < abs($1 - radius) }) ?? radius
    }

    static func selectablePresets(for access: RidgitsNearbySearchAccess) -> [Int] {
        radiusPresetMiles.filter { !isLockedPreset($0, access: access) }
    }

    static func isLockedPreset(_ preset: Int, access: RidgitsNearbySearchAccess) -> Bool {
        preset < access.minRadiusMiles
    }

    /// Which subscription tier unlocks a locked preset.
    static func paywallTier(forLockedPreset preset: Int, access: RidgitsNearbySearchAccess) -> RidgitsSubscriptionTier {
        if premiumOnlyPresetMiles.contains(preset) {
            return .premium
        }
        return .plus
    }

    static func minRadiusMiles(access: RidgitsNearbySearchAccess) -> Int {
        access.minRadiusMiles
    }

    static func maxRadiusMiles(access: RidgitsNearbySearchAccess) -> Int {
        maxRadiusMiles
    }

    static func clampRadius(_ radius: Int, access: RidgitsNearbySearchAccess) -> Int {
        let snapped = snapToPresetMiles(radius, access: access)
        if isLockedPreset(snapped, access: access) {
            return max(defaultRadiusMiles, access.minRadiusMiles)
        }
        return min(
            maxRadiusMiles(access: access),
            max(access.minRadiusMiles, snapped)
        )
    }

    static func isLockedRadius(_ radius: Int, access: RidgitsNearbySearchAccess) -> Bool {
        isLockedPreset(radius, access: access)
    }

    /// Human-readable search band for the active radius chip.
    static func radiusRangeLabel(maxRadius: Int, access: RidgitsNearbySearchAccess) -> String {
        let capped = clampRadius(maxRadius, access: access)
        let floor = access.closeMatchFloorMiles

        if capped == 0 {
            return "Same metro area"
        }
        if floor > 0, capped > floor {
            return "\(floor)–\(capped) mi"
        }
        return "Within \(capped) mi"
    }

    static func poolFetchRadius(access: RidgitsNearbySearchAccess) -> Int {
        maxRadiusMiles
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
                return floor == 0
            }
            if floor > 0 && miles < Double(floor) {
                return false
            }
            return miles <= Double(clamped)
        }
    }

    /// Minimum distance (mi) the user's tier can message.
    static func messageDistanceFloor(for tier: RidgitsSubscriptionTier) -> Int {
        switch tier {
        case .premium, .ultra:
            return 0
        case .plus:
            return plusMinRadiusMiles
        default:
            return freeMinRadiusMiles
        }
    }

    /// Subscription tier to upsell when messaging someone at this distance.
    static func messagingUpsellTier(forDistanceMiles miles: Double?) -> RidgitsSubscriptionTier {
        guard let miles else { return .plus }
        if miles < Double(plusMinRadiusMiles) { return .premium }
        if miles < Double(freeMinRadiusMiles) { return .plus }
        return .plus
    }

    static func requiresUpgradeToMessage(
        personAtDistanceMiles miles: Double?,
        access: RidgitsNearbySearchAccess
    ) -> Bool {
        if !access.hasMembership { return true }
        guard let miles else { return false }
        return miles < Double(messageDistanceFloor(for: access.tier))
    }

    static func messagingPaywallCopy(forDistanceMiles miles: Double?) -> (headline: String, subheadline: String) {
        let tier = messagingUpsellTier(forDistanceMiles: miles)
        let headline = "Upgrade to message this person"
        let subheadline: String
        if tier == .premium {
            subheadline = "Premium unlocks messaging for matches in your metro area (0 mi)."
        } else if let miles, miles < Double(freeMinRadiusMiles) {
            subheadline = "Ridgits+ lets you message matches from 10 miles and closer."
        } else {
            subheadline = "Subscribe to send message requests on Ridgits."
        }
        return (headline, subheadline)
    }
}

extension RidgitsStore {
    /// Active membership with server-confirmed nearby access.
    @MainActor
    var hasExtendedNearbyRadius: Bool {
        hasNearbyAccess && isMembershipActive
    }
}
