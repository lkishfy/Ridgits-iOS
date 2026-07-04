import Foundation

enum RidgitsSubscriptionTier: String, CaseIterable, Identifiable {
    case free
    case plus
    case premium
    case ultra

    var id: String { rawValue }

    var rank: Int {
        switch self {
        case .free: return 0
        case .plus: return 1
        case .premium: return 2
        case .ultra: return 3
        }
    }

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .plus: return "Ridgits+"
        case .premium: return "Ridgits Premium"
        case .ultra: return "Ridgits Ultra"
        }
    }

    var badgeLabel: String? {
        switch self {
        case .plus: return "+ Badge"
        case .premium: return "Premium Badge"
        case .ultra: return "Ultra Badge"
        default: return nil
        }
    }

    static func from(stored value: String?) -> RidgitsSubscriptionTier {
        guard let value, let tier = RidgitsSubscriptionTier(rawValue: value) else { return .free }
        return tier
    }
}

enum RidgitsSubscriptionBilling: String, CaseIterable, Identifiable {
    case monthly
    case yearly

    var id: String { rawValue }

    var label: String {
        switch self {
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }
}

struct RidgitsSubscriptionFeature: Identifiable {
    let id = UUID()
    let title: String
    let detail: String?
    let badgeTier: RidgitsSubscriptionTier?

    init(title: String, detail: String? = nil, badgeTier: RidgitsSubscriptionTier? = nil) {
        self.title = title
        self.detail = detail
        self.badgeTier = badgeTier
    }
}

enum RidgitsSubscriptionCatalog {
    /// App Store Connect subscription group display name: "Yearly" (ID 22207786).
    static let subscriptionGroupId = "Yearly"

    /// Paywall and new purchases use yearly only; monthly SKUs may still renew for existing subscribers.
    static let offersMonthlySubscriptions = false

    static let showsYearlySavingsBadges = false

    static var purchaseBillingOptions: [RidgitsSubscriptionBilling] {
        offersMonthlySubscriptions ? RidgitsSubscriptionBilling.allCases : [.yearly]
    }

    private static func nearbyFeature(for tier: RidgitsSubscriptionTier) -> RidgitsSubscriptionFeature {
        switch tier {
        case .plus:
            return RidgitsSubscriptionFeature(
                title: "Nearby matches",
                detail: "Search from 25 to 150 miles"
            )
        case .premium, .ultra:
            return RidgitsSubscriptionFeature(
                title: "Nearby matches",
                detail: "Full nearby search from 0 to 150 miles"
            )
        default:
            return RidgitsSubscriptionFeature(title: "Nearby matches")
        }
    }

    private static let coreMembershipFeatures: [RidgitsSubscriptionFeature] = [
        RidgitsSubscriptionFeature(
            title: "Unlimited Quick Tools",
            detail: "Analyze Profile Photos, Analyze Messages, Compatibility Reports"
        ),
    ]

    private static func ridgitsFeature(for tier: RidgitsSubscriptionTier) -> RidgitsSubscriptionFeature {
        let count = maxRidgits(tier: tier, isMembershipActive: true)
        return RidgitsSubscriptionFeature(
            title: count == 1 ? "1 Ridgit" : "\(count) Ridgits",
            detail: "Custom quizzes that reveal your socials"
        )
    }

    private static func messagingFeature(for tier: RidgitsSubscriptionTier) -> RidgitsSubscriptionFeature {
        switch tier {
        case .plus, .premium, .ultra:
            return RidgitsSubscriptionFeature(
                title: "Message other users",
                detail: "Included with membership"
            )
        case .free:
            return RidgitsSubscriptionFeature(title: "Message other users")
        }
    }

    /// App Store Connect product IDs — yearly group ranked Plus → Premium → Ultra.
    static let productIds: [String: (tier: RidgitsSubscriptionTier, billing: RidgitsSubscriptionBilling)] = [
        RidgitsProductID.plusYearly: (.plus, .yearly),
        RidgitsProductID.premiumYearly: (.premium, .yearly),
        RidgitsProductID.ultraYearly: (.ultra, .yearly),
        // Legacy SKUs — existing subscribers only
        RidgitsProductID.plusMonthly: (.plus, .monthly),
        RidgitsProductID.plusYearlyLegacy: (.plus, .yearly),
        RidgitsProductID.premiumMonthly: (.premium, .monthly),
        RidgitsProductID.premiumYearlyLegacy: (.premium, .yearly),
        RidgitsProductID.ultraMonthly: (.ultra, .monthly),
        RidgitsProductID.ultraYearly99Legacy: (.ultra, .yearly),
        RidgitsProductID.ultraYearly149Legacy: (.ultra, .yearly),
    ]

    /// Products fetched from StoreKit for the paywall (yearly group only).
    static var storeKitSubscriptionProductIds: [String] {
        [
            RidgitsProductID.plusYearly,
            RidgitsProductID.premiumYearly,
            RidgitsProductID.ultraYearly,
        ]
    }

    static var allSubscriptionProductIds: [String] {
        Array(productIds.keys)
    }

    static func tier(for productId: String) -> RidgitsSubscriptionTier? {
        productIds[productId]?.tier
    }

    static func billing(for productId: String) -> RidgitsSubscriptionBilling? {
        productIds[productId]?.billing
    }

    static func productId(tier: RidgitsSubscriptionTier, billing: RidgitsSubscriptionBilling, ultraYearlyVariant: UltraYearlyVariant = .standard) -> String? {
        switch (tier, billing) {
        case (.plus, .monthly): return RidgitsProductID.plusMonthly
        case (.plus, .yearly): return RidgitsProductID.plusYearly
        case (.premium, .monthly): return RidgitsProductID.premiumMonthly
        case (.premium, .yearly): return RidgitsProductID.premiumYearly
        case (.ultra, .monthly): return RidgitsProductID.ultraMonthly
        case (.ultra, .yearly):
            if offersMonthlySubscriptions || ultraYearlyVariant == .standard {
                return RidgitsProductID.ultraYearly
            }
            return RidgitsProductID.ultraYearly149Legacy
        default: return nil
        }
    }

    enum UltraYearlyVariant {
        case standard
        case premium
    }

    static func features(for tier: RidgitsSubscriptionTier) -> [RidgitsSubscriptionFeature] {
        switch tier {
        case .free:
            return []
        case .plus:
            return [messagingFeature(for: .plus), nearbyFeature(for: .plus), ridgitsFeature(for: .plus)] + coreMembershipFeatures + [
                RidgitsSubscriptionFeature(title: "Ridgits+ Badge", badgeTier: .plus),
            ]
        case .premium:
            return [messagingFeature(for: .premium), nearbyFeature(for: .premium), ridgitsFeature(for: .premium)] + coreMembershipFeatures + [
                RidgitsSubscriptionFeature(title: "Additional archetype quizzes"),
                RidgitsSubscriptionFeature(title: "Premium Badge", badgeTier: .premium),
            ]
        case .ultra:
            return [messagingFeature(for: .ultra), nearbyFeature(for: .ultra), ridgitsFeature(for: .ultra)] + coreMembershipFeatures + [
                RidgitsSubscriptionFeature(title: "Additional archetype quizzes"),
                RidgitsSubscriptionFeature(title: "Exclusive archetype quizzes"),
                RidgitsSubscriptionFeature(title: "Special access to new features"),
                RidgitsSubscriptionFeature(title: "Ultra Badge", badgeTier: .ultra),
            ]
        }
    }

    static func fallbackPrice(
        tier: RidgitsSubscriptionTier,
        billing: RidgitsSubscriptionBilling,
        ultraYearlyVariant: UltraYearlyVariant = .standard
    ) -> String {
        switch (tier, billing) {
        case (.plus, .monthly): return "$9.99"
        case (.plus, .yearly): return "$29.99"
        case (.premium, .monthly): return "$12.99"
        case (.premium, .yearly): return "$49.99"
        case (.ultra, .monthly): return "$19.99"
        case (.ultra, .yearly):
            return ultraYearlyVariant == .premium ? "$149" : "$69.99"
        default: return ""
        }
    }

    static func yearlyMonthlyEquivalent(
        for tier: RidgitsSubscriptionTier,
        ultraYearlyVariant: UltraYearlyVariant = .standard
    ) -> String {
        switch tier {
        case .plus: return "$2.50"
        case .premium: return "$4.17"
        case .ultra:
            return ultraYearlyVariant == .premium ? "$12.42" : "$5.83"
        default: return ""
        }
    }

    /// Percent saved vs paying monthly for 12 months (for yearly plan badge).
    static func yearlyDiscountBadge(for tier: RidgitsSubscriptionTier) -> String? {
        guard showsYearlySavingsBadges else { return nil }
        guard let percent = yearlyDiscountPercent(for: tier), percent > 0 else { return nil }
        return "Save \(percent)%"
    }

    static func yearlyDiscountPercent(for tier: RidgitsSubscriptionTier) -> Int? {
        let monthly: Double
        let yearly: Double
        switch tier {
        case .plus:
            monthly = 9.99
            yearly = 29.99
        case .premium:
            monthly = 12.99
            yearly = 49.99
        case .ultra:
            monthly = 19.99
            yearly = 69.99
        default:
            return nil
        }
        let annualizedMonthly = monthly * 12
        guard annualizedMonthly > yearly else { return nil }
        return Int(((annualizedMonthly - yearly) / annualizedMonthly * 100).rounded())
    }

    static func maxYearlyDiscountBadge() -> String? {
        guard showsYearlySavingsBadges else { return nil }
        let percents = [RidgitsSubscriptionTier.plus, .premium, .ultra]
            .compactMap { yearlyDiscountPercent(for: $0) }
        guard let maxPercent = percents.max(), maxPercent > 0 else { return nil }
        return "Save up to \(maxPercent)%"
    }

    static func canUpgrade(from current: RidgitsSubscriptionTier, to target: RidgitsSubscriptionTier, isActive: Bool) -> Bool {
        guard isActive else { return true }
        if current == .free { return true }
        return target.rank > current.rank
    }

    /// Max active custom Ridgits by membership tier.
    static func maxRidgits(tier: RidgitsSubscriptionTier, isMembershipActive: Bool) -> Int {
        guard isMembershipActive else { return 1 }
        switch tier {
        case .free: return 1
        case .plus: return 2
        case .premium: return 3
        case .ultra: return 5
        }
    }

    static func ridgitLimitPaywallTier(current: RidgitsSubscriptionTier, isMembershipActive: Bool) -> RidgitsSubscriptionTier {
        if !isMembershipActive { return .plus }
        switch current {
        case .free, .plus: return .premium
        case .premium: return .ultra
        case .ultra: return .ultra
        }
    }
}
