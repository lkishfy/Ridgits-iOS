import Foundation

struct RidgitsIdentityStatus: Decodable {
    let identityVerificationStatus: String
    let identityVerifiedAt: String?
    let phoneVerificationStatus: String?
    let phoneVerifiedAt: String?
    let phoneVerificationRequired: Bool?
    let profilePhotoIdentityMatchStatus: String
    let profilePhotoIdentityMatchAt: String?
    let profilePhotoIdentityMatchScore: Double?
    let canSubscribe: Bool
    let canMessage: Bool

    var isIdentityVerified: Bool {
        identityVerificationStatus == "verified"
    }

    var isProfilePhotoMatched: Bool {
        profilePhotoIdentityMatchStatus == "verified"
    }

    var isPhoneVerified: Bool {
        phoneVerificationStatus == "verified"
    }

    var isFullyVerifiedForSubscribe: Bool {
        isIdentityVerified && isPhoneVerified
    }

    /// True when Stripe ID (+ phone when required) is complete; profile photo is separate.
    var isStripeIdentityFlowComplete: Bool {
        guard isIdentityVerified else { return false }
        if phoneVerificationStatus == "failed" { return false }
        let phoneRequired = phoneVerificationRequired ?? true
        if phoneRequired { return isPhoneVerified }
        return true
    }
}

struct RidgitsIdentitySessionResponse: Decodable {
    let verificationUrl: String
    let sessionId: String
}

struct RidgitsProfilePhotoMatchResult: Decodable {
    let status: String
    let score: Double?
    let threshold: Double
    let message: String?
    let reason: String?

    var isVerified: Bool {
        status == "verified"
    }

    var userFacingFailureMessage: String? {
        if isVerified { return nil }
        if let message, !message.isEmpty { return message }
        return RidgitsProfilePhotoIdentityMatch.fallbackMismatchMessage(
            score: score,
            threshold: threshold
        )
    }
}

struct RidgitsRegisterPhotoMatchError: Decodable {
    let error: String
    let code: String
}

struct RidgitsRegisterProfilePhotoResult: Decodable {
    let ok: Bool
    let identityMatch: RidgitsProfilePhotoMatchResult?
    let identityMatchError: RidgitsRegisterPhotoMatchError?
}
