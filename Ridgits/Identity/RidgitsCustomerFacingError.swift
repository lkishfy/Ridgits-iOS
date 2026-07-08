import Foundation

enum RidgitsCustomerFacingError {
    static let supportEmail = "support@ridgits.com"

    private static let vendorPatterns: [String] = [
        "stripe.com",
        "sensitive verification results",
        "restricted api key",
        "api key",
        "ip restrict",
        "ip-restrict",
        "allowlist",
        "48 hours ago",
        "rekognition",
        "firebase.google.com",
        "failed_precondition",
        "requires an index",
    ]

    static func supportMessage(detail: String = "We couldn't complete this step right now.") -> String {
        "\(detail) Email \(supportEmail) and we'll help you get verified."
    }

    static func message(for code: String) -> String? {
        switch code {
        case "IDENTITY_SELFIE_UNAVAILABLE":
            return supportMessage(detail: "We couldn't verify your profile photo against your ID.")
        case "FACE_MATCH_UNAVAILABLE":
            return supportMessage(detail: "Profile photo verification isn't available right now.")
        case "IDENTITY_UNAVAILABLE":
            return supportMessage(detail: "Identity verification isn't available right now.")
        case "PROFILE_PHOTO_REQUIRED":
            return "Add a profile photo on your profile before starting identity verification. Your photo must match your ID selfie within 48 hours of verifying."
        case "INVALID_PROFILE_PHOTO":
            return "A valid profile photo is required."
        case "IDENTITY_VERIFICATION_REQUIRED":
            return "Verify your identity before messaging."
        case "IDENTITY_REVERIFICATION_REQUIRED":
            return "Re-verify your identity before matching a new profile photo."
        case "PROFILE_PHOTO_IDENTITY_MISMATCH":
            return "Your profile photo must match your verified ID selfie to message."
        default:
            return nil
        }
    }

    static func sanitize(_ message: String, code: String? = nil) -> String {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        if let code, let coded = message(for: code),
           trimmed.isEmpty || looksLikeVendorOrInternalError(trimmed) {
            return coded
        }
        if looksLikeVendorOrInternalError(trimmed) {
            return supportMessage()
        }
        return trimmed.isEmpty ? supportMessage() : trimmed
    }

    static func looksLikeVendorOrInternalError(_ message: String) -> Bool {
        let lower = message.lowercased()
        return vendorPatterns.contains { lower.contains($0) }
    }
}
