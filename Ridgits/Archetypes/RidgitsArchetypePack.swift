import SwiftUI

struct RidgitsPackArchetypeResult: Equatable {
    let name: String
    let description: String
    let characteristics: [String]
    let suggestions: [String]
    let idealMatch: String?
    let growthTip: String?

    init(
        name: String,
        description: String,
        characteristics: [String] = [],
        suggestions: [String] = [],
        idealMatch: String? = nil,
        growthTip: String? = nil
    ) {
        self.name = name
        self.description = description
        self.characteristics = characteristics
        self.suggestions = suggestions
        self.idealMatch = idealMatch
        self.growthTip = growthTip
    }
}

struct RidgitsPackProfile: Equatable {
    var purchasedPacks: [String] = []
    var unlockedPacks: [String] = []
    var subscriptionTier: String = "free"
    var packResults: [String: RidgitsPackArchetypeResult] = [:]

    func hasAccess(
        to pack: RidgitsArchetypePack,
        ownsBundle: Bool,
        membershipTier: RidgitsSubscriptionTier = .free,
        referralsCompleted: Int = 0
    ) -> Bool {
        if pack.isFree { return true }
        if pack.isReferralOnly {
            if unlockedPacks.contains(pack.id) { return true }
            if let slot = pack.referralSlot, referralsCompleted >= slot { return true }
            return false
        }
        if pack.ultraOnly { return membershipTier == .ultra || subscriptionTier == "ultra" }
        if membershipTier.rank >= RidgitsSubscriptionTier.premium.rank { return true }
        if subscriptionTier == "premium" || subscriptionTier == "ultra" { return true }
        if ownsBundle { return true }
        if purchasedPacks.contains(pack.id) || unlockedPacks.contains(pack.id) { return true }
        return false
    }

    func result(for pack: RidgitsArchetypePack) -> RidgitsPackArchetypeResult? {
        packResults[pack.resultKey]
    }
}

struct RidgitsArchetypePack: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let resultKey: String
    let icon: String
    let gradientStart: UInt32
    let gradientEnd: UInt32
    var isFree = false
    var ultraOnly = false
    /// Referral-exclusive quiz — not sold via IAP or subscription bundle.
    var isReferralOnly = false
    /// Unlocked after N successful referrals (1–3). Only used when `isReferralOnly`.
    var referralSlot: Int? = nil

    var productId: String? {
        if isFree || isReferralOnly { return nil }
        return RidgitsProductID.packProductId(for: id)
    }

    /// Firestore key for in-progress / saved answers (matches web: `{packType}Answers`).
    var answersKey: String { "\(id)Answers" }

    /// Firestore key for completion timestamp.
    var completedAtKey: String { "\(id)CompletedAt" }

    var requiredMembershipTier: RidgitsSubscriptionTier? {
        if isFree || isReferralOnly { return nil }
        return ultraOnly ? .ultra : .premium
    }

    static let catalog: [RidgitsArchetypePack] = [
        RidgitsArchetypePack(
            id: "love-language",
            title: "Love Language",
            description: "Discover your romantic communication style, intimacy preferences, and what you need in a partner.",
            resultKey: "loveLanguageResult",
            icon: "heart.fill",
            gradientStart: 0xE11D48,
            gradientEnd: 0xBE123C,
            isFree: true
        ),
        RidgitsArchetypePack(
            id: "situationship",
            title: "Situationship Pattern",
            description: "Uncover your relationship patterns and understand why you might be stuck in undefined connections.",
            resultKey: "situationshipResult",
            icon: "heart",
            gradientStart: 0xFF6B9D,
            gradientEnd: 0xC2185B
        ),
        RidgitsArchetypePack(
            id: "self-sabotage",
            title: "Self-Sabotage",
            description: "Identify behaviors that hold you back and discover strategies to break free.",
            resultKey: "selfSabotageResult",
            icon: "exclamationmark.circle",
            gradientStart: 0x9C27B0,
            gradientEnd: 0x6A1B9A
        ),
        RidgitsArchetypePack(
            id: "social-battery",
            title: "Social Battery",
            description: "Learn your social energy levels and how to recharge effectively.",
            resultKey: "socialBatteryResult",
            icon: "battery.100",
            gradientStart: 0x00BCD4,
            gradientEnd: 0x0097A7
        ),
        RidgitsArchetypePack(
            id: "messaging",
            title: "Messaging Style",
            description: "Understand how your texting habits shape attraction—your tone, pacing, and signals.",
            resultKey: "messagingResult",
            icon: "message",
            gradientStart: 0x4F46E5,
            gradientEnd: 0x3730A3
        ),
        RidgitsArchetypePack(
            id: "boundaries",
            title: "Boundary Patterns",
            description: "See how you set, hold, or break your standards in connections.",
            resultKey: "boundaryResult",
            icon: "shield",
            gradientStart: 0xF59E0B,
            gradientEnd: 0xD97706
        ),
        RidgitsArchetypePack(
            id: "attraction",
            title: "Attraction Signals",
            description: "Learn what draws people to you and how others interpret your presence.",
            resultKey: "attractionResult",
            icon: "bolt.fill",
            gradientStart: 0xEC4899,
            gradientEnd: 0xBE185D
        ),
        RidgitsArchetypePack(
            id: "desire-logic",
            title: "Desire Logic",
            description: "What triggers your attraction — mentally, emotionally, and socially.",
            resultKey: "desireLogicResult",
            icon: "scope",
            gradientStart: 0x8B5CF6,
            gradientEnd: 0x6D28D9,
            ultraOnly: true
        ),
        RidgitsArchetypePack(
            id: "dealbreaker-map",
            title: "Dealbreaker Map",
            description: "Your hard lines, soft lines, blind spots, and contradictions.",
            resultKey: "dealbreakerMapResult",
            icon: "exclamationmark.triangle",
            gradientStart: 0xEF4444,
            gradientEnd: 0xDC2626,
            ultraOnly: true
        ),
        RidgitsArchetypePack(
            id: "identity-performance",
            title: "Identity Performance",
            description: "How you perform your identity on dates, apps, and IRL — consciously and unconsciously.",
            resultKey: "identityPerformanceResult",
            icon: "person.fill",
            gradientStart: 0x10B981,
            gradientEnd: 0x059669,
            ultraOnly: true
        ),
    ]

    static let referralCatalog: [RidgitsArchetypePack] = [
        RidgitsArchetypePack(
            id: "referral-first-spark",
            title: "First Spark",
            description: "How you feel chemistry on early dates — and what actually pulls you in.",
            resultKey: "referralFirstSparkResult",
            icon: "sparkles",
            gradientStart: 0xF97316,
            gradientEnd: 0xEA580C,
            isReferralOnly: true,
            referralSlot: 1
        ),
        RidgitsArchetypePack(
            id: "referral-slow-burn",
            title: "Slow Burn vs Fast Flame",
            description: "Your connection pace — how fast you build trust, labels, and momentum.",
            resultKey: "referralSlowBurnResult",
            icon: "flame",
            gradientStart: 0x8B5CF6,
            gradientEnd: 0x6D28D9,
            isReferralOnly: true,
            referralSlot: 2
        ),
        RidgitsArchetypePack(
            id: "referral-trust-line",
            title: "Trust Timeline",
            description: "What earns your trust, where you draw lines, and how you spot red flags early.",
            resultKey: "referralTrustLineResult",
            icon: "lock.shield",
            gradientStart: 0x0EA5E9,
            gradientEnd: 0x0284C7,
            isReferralOnly: true,
            referralSlot: 3
        ),
    ]

    static func referralPack(for slot: Int) -> RidgitsArchetypePack? {
        referralCatalog.first { $0.referralSlot == slot }
    }

    static let paidPackIds: [String] = catalog.filter { !$0.isFree && !$0.isReferralOnly }.map(\.id)
}
