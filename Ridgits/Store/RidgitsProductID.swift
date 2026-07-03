import Foundation

enum RidgitsProductID {
    /// Non-renewing yearly access to nearby matches — $29.99/year in App Store Connect.
    static let nearbyYearly = "RidgitsNearbyYear2999"
    static let all = [nearbyYearly]
}

enum RidgitsMessagingLimits {
    static let maxMessages = 16
    static let expirationHours = 24
}

enum RidgitsError: LocalizedError {
    case notAuthenticated
    case configuration(String)
    case server(String)
    case decoding

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Please sign in to continue."
        case .configuration(let message): return message
        case .server(let message): return message
        case .decoding: return "Could not read server response."
        }
    }
}
