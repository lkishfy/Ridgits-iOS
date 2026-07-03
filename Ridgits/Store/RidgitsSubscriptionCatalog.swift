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
    static let subscriptionGroupId = "ridgits_membership"

    /// App Store Connect product IDs — configure in one auto-renewable subscription group (ranked for upgrades).
    static let productIds: [String: (tier: RidgitsSubscriptionTier, billing: RidgitsSubscriptionBilling)] = [
        RidgitsProductID.plusMonthly: (.plus, .monthly),
        RidgitsProductID.plusYearly: (.plus, .yearly),
        RidgitsProductID.premiumMonthly: (.premium, .monthly),
        RidgitsProductID.premiumYearly: (.premium, .yearly),
        RidgitsProductID.ultraMonthly: (.ultra, .monthly),
        RidgitsProductID.ultraYearly99: (.ultra, .yearly),
        RidgitsProductID.ultraYearly149: (.ultra, .yearly),
    ]

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
            return ultraYearlyVariant == .premium ? RidgitsProductID.ultraYearly149 : RidgitsProductID.ultraYearly99
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
            return [
                RidgitsSubscriptionFeature(
                    title: "Unlimited Quick Tools",
                    detail: "Analyze Profile Photos, Analyze Messages, Compatibility Reports"
                ),
                RidgitsSubscriptionFeature(
                    title: "Nearby matches",
                    detail: "See compatible people within 25 miles"
                ),
                RidgitsSubscriptionFeature(title: "Ridgits+ Badge", badgeTier: .plus),
            ]
        case .premium:
            return [
                RidgitsSubscriptionFeature(
                    title: "Unlimited Quick Tools",
                    detail: "Analyze Profile Photos, Analyze Messages, Compatibility Reports"
                ),
                RidgitsSubscriptionFeature(title: "Additional archetype quizzes"),
                RidgitsSubscriptionFeature(title: "Premium Badge", badgeTier: .premium),
            ]
        case .ultra:
            return [
                RidgitsSubscriptionFeature(
                    title: "Unlimited Quick Tools",
                    detail: "Analyze Profile Photos, Analyze Messages, Compatibility Reports"
                ),
                RidgitsSubscriptionFeature(title: "Additional archetype quizzes"),
                RidgitsSubscriptionFeature(title: "Exclusive archetype quizzes"),
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
        case (.plus, .monthly): return "$7.99"
        case (.plus, .yearly): return "$29.99"
        case (.premium, .monthly): return "$12.99"
        case (.premium, .yearly): return "$49.99"
        case (.ultra, .monthly): return "$19.99"
        case (.ultra, .yearly):
            return ultraYearlyVariant == .premium ? "$149" : "$79.99"
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
            return ultraYearlyVariant == .premium ? "$12.42" : "$6.67"
        default: return ""
        }
    }

    /// Percent saved vs paying monthly for 12 months (for yearly plan badge).
    static func yearlyDiscountBadge(for tier: RidgitsSubscriptionTier) -> String? {
        guard let percent = yearlyDiscountPercent(for: tier), percent > 0 else { return nil }
        return "Save \(percent)%"
    }

    static func yearlyDiscountPercent(for tier: RidgitsSubscriptionTier) -> Int? {
        let monthly: Double
        let yearly: Double
        switch tier {
        case .plus:
            monthly = 7.99
            yearly = 29.99
        case .premium:
            monthly = 12.99
            yearly = 49.99
        case .ultra:
            monthly = 19.99
            yearly = 79.99
        default:
            return nil
        }
        let annualizedMonthly = monthly * 12
        guard annualizedMonthly > yearly else { return nil }
        return Int(((annualizedMonthly - yearly) / annualizedMonthly * 100).rounded())
    }

    static func maxYearlyDiscountBadge() -> String? {
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

    /// Max custom Ridgits (iOS) by membership tier.
    static func maxRidgits(tier: RidgitsSubscriptionTier, isMembershipActive: Bool) -> Int {
        guard isMembershipActive else { return 1 }
        switch tier {
        case .free, .plus: return 1
        case .premium: return 3
        case .ultra: return 10
        }
    }

    static func ridgitLimitPaywallTier(current: RidgitsSubscriptionTier, isMembershipActive: Bool) -> RidgitsSubscriptionTier {
        let limit = maxRidgits(tier: current, isMembershipActive: isMembershipActive)
        if limit >= 10 { return .ultra }
        if limit >= 3 { return .ultra }
        return .premium
    }
}
