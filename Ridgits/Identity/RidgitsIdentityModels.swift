import Foundation

struct RidgitsIdentityStatus: Decodable {
    let identityVerificationStatus: String
    let identityVerifiedAt: String?
    let phoneVerificationStatus: String?
    let phoneVerifiedAt: String?
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
}

struct RidgitsIdentitySessionResponse: Decodable {
    let verificationUrl: String
    let sessionId: String
}

struct RidgitsProfilePhotoMatchResult: Decodable {
    let status: String
    let score: Double?
    let threshold: Double

    var isVerified: Bool {
        status == "verified"
    }
}
