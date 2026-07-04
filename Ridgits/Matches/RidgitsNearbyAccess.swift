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

    /// Subscription tier to upsell when a locked radius preset is tapped.
    func lockedRadiusPaywallTier(for preset: Int) -> RidgitsSubscriptionTier {
        RidgitsNearbyAccess.paywallTier(forLockedPreset: preset, access: self)
    }
}

enum RidgitsNearbyAccess {
    /// Free users cannot see matches closer than this.
    static let closeMatchesThresholdMiles = 30

    /// Ridgits+ minimum search radius (mi).
    static let plusMinRadiusMiles = 25

    /// Ridgits Premium unlocks these closer presets (mi).
    static let premiumRadiusPresetMiles: Set<Int> = [0, 10]

    /// Free users can search between 50 and 150 miles without subscribing.
    static let unsubscribedMinRadiusMiles = 50
    static let unsubscribedMaxRadiusMiles = 150

    static let subscribedMaxRadiusMiles = 150

    static let defaultRadiusMiles = 50

    /// Quick-select chips (mi). Tier rules gate which values are selectable.
    static let radiusPresetMiles = [0, 10, 25, 50, 150]

    static func snapToPresetMiles(_ radius: Int, access: RidgitsNearbySearchAccess) -> Int {
        radiusPresetMiles.min(by: { abs($0 - radius) < abs($1 - radius) }) ?? radius
    }

    static func selectablePresets(for access: RidgitsNearbySearchAccess) -> [Int] {
        radiusPresetMiles.filter { !isLockedPreset($0, access: access) }
    }

    static func isLockedPreset(_ preset: Int, access: RidgitsNearbySearchAccess) -> Bool {
        if !access.hasMembership {
            return preset <= plusMinRadiusMiles
        }
        if access.tier == .plus {
            return premiumRadiusPresetMiles.contains(preset)
        }
        return false
    }

    /// Which subscription tier unlocks a locked preset.
    static func paywallTier(forLockedPreset preset: Int, access: RidgitsNearbySearchAccess) -> RidgitsSubscriptionTier {
        if premiumRadiusPresetMiles.contains(preset) {
            return .premium
        }
        return .plus
    }

    static func minRadiusMiles(access: RidgitsNearbySearchAccess) -> Int {
        access.minRadiusMiles
    }

    static func maxRadiusMiles(access: RidgitsNearbySearchAccess) -> Int {
        access.hasMembership ? subscribedMaxRadiusMiles : unsubscribedMaxRadiusMiles
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

    /// Human-readable search band, e.g. "30–50 miles" when a close-match floor applies.
    static func radiusRangeLabel(maxRadius: Int, access: RidgitsNearbySearchAccess) -> String {
        let capped = clampRadius(maxRadius, access: access)
        let floor = access.closeMatchFloorMiles
        if floor > 0, capped > floor {
            return "\(floor)–\(capped) miles"
        }
        return "within \(capped) miles"
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
            return closeMatchesThresholdMiles
        }
    }

    /// Subscription tier to upsell when messaging someone at this distance.
    static func messagingUpsellTier(forDistanceMiles miles: Double?) -> RidgitsSubscriptionTier {
        guard let miles else { return .plus }
        if miles < Double(plusMinRadiusMiles) { return .premium }
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
            subheadline = "Premium unlocks messaging for matches within 10 and 0 miles."
        } else if let miles, miles < Double(closeMatchesThresholdMiles) {
            subheadline = "Ridgits+ lets you message matches within \(closeMatchesThresholdMiles) miles."
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
