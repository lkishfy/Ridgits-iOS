import Foundation

enum RidgitsProductID {
    /// Non-renewing yearly access to nearby matches — $29.99/year in App Store Connect.
    static let nearbyYearly = "RidgitsNearbyYear2999"
    /// All 10 archetype packs — $49.99 in App Store Connect.
    static let archetypeBundle = "RidgitsArchetypeBundle5000"

    // MARK: - Auto-renewable subscriptions (single subscription group in App Store Connect)
    static let plusMonthly = "RidgitsPlusMonthly999" // $9.99/mo in App Store Connect
    static let plusYearly = "RidgitsPlusYearly6000" // $29.99/year in App Store Connect
    static let premiumMonthly = "RidgitsPremiumMonthly1499"
    static let premiumYearly = "RidgitsPremiumYearly9900" // $53.99/yr in App Store Connect
    static let ultraMonthly = "RidgitsUltraMonthly1999"
    static let ultraYearly99 = "RidgitsUltraYearly9900" // $69.99/yr in App Store Connect
    static let ultraYearly149 = "RidgitsUltraYearly14900"

    private static let packProductIds: [String: String] = [
        "situationship": "RidgitsPackSituationship999",
        "self-sabotage": "RidgitsPackSelfSabotage999",
        "social-battery": "RidgitsPackSocialBattery999",
        "messaging": "RidgitsPackMessaging999",
        "boundaries": "RidgitsPackBoundaries999",
        "attraction": "RidgitsPackAttraction999",
        "desire-logic": "RidgitsPackDesireLogic999",
        "dealbreaker-map": "RidgitsPackDealbreakerMap999",
        "identity-performance": "RidgitsPackIdentityPerformance999",
    ]

    static func packProductId(for packId: String) -> String? {
        packProductIds[packId]
    }

    static func packId(for productId: String) -> String? {
        packProductIds.first(where: { $0.value == productId })?.key
    }

    static var allPackProductIds: [String] {
        Array(packProductIds.values)
    }

    static var allSubscriptionProductIds: [String] {
        RidgitsSubscriptionCatalog.allSubscriptionProductIds
    }

    static var all: [String] {
        [nearbyYearly, archetypeBundle]
            + allSubscriptionProductIds
            + allPackProductIds
    }
}

enum RidgitsMessagingLimits {
    static let maxMessages = 16
    static let expirationHours = 24
}

enum RidgitsError: LocalizedError {
    case notAuthenticated
    case configuration(String)
    case server(String)
    /// A server error with a machine-readable `code` (e.g. "SUBSCRIPTION_REQUIRED",
    /// "EMAIL_NOT_VERIFIED", "ACCOUNT_TOO_NEW", "RATE_LIMITED") so callers can react
    /// specifically (show a paywall, a verify-email prompt, etc.) instead of just
    /// displaying the message.
    case serverCoded(message: String, code: String)
    case decoding

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Please sign in to continue."
        case .configuration(let message): return message
        case .server(let message): return message
        case .serverCoded(let message, _): return message
        case .decoding: return "Could not read server response."
        }
    }

    /// Machine-readable error code from the server, if any.
    var code: String? {
        if case .serverCoded(_, let code) = self { return code }
        return nil
    }
}
