import Foundation

enum RidgitsProfilePhotoIdentityMatch {
    static let genericMismatchMessage =
        "Your profile photo didn't match your verified ID selfie. Use a clear photo of your face, similar to your ID verification selfie, then try again from your profile."

    @MainActor
    static func message(from registerResult: RidgitsRegisterProfilePhotoResult?) -> String? {
        guard let registerResult else { return nil }
        if let error = registerResult.identityMatchError {
            return userFacingMessage(for: error.code, fallback: error.error)
        }
        if let match = registerResult.identityMatch, !match.isVerified {
            return sanitizedFailureMessage(match)
        }
        return nil
    }

    @MainActor
    static func matchAfterProfileSaveIfNeeded(
        registerResult: RidgitsRegisterProfilePhotoResult? = nil
    ) async -> String? {
        if let registerMessage = message(from: registerResult) {
            return registerMessage
        }

        if registerResult?.identityMatch?.isVerified == true {
            return nil
        }

        do {
            let identity = try await RidgitsAPIClient.shared.fetchIdentityStatus()
            guard identity.isIdentityVerified else { return nil }
            guard !identity.isProfilePhotoMatched else { return nil }

            let result = try await RidgitsAPIClient.shared.matchProfilePhotoToIdentity()
            if result.isVerified {
                return nil
            }
            return sanitizedFailureMessage(result)
        } catch let error as RidgitsError {
            return userFacingMessage(for: error.code ?? "", fallback: error.localizedDescription)
        } catch {
            return nil
        }
    }

    static func userFacingMessage(for code: String, fallback: String) -> String? {
        if let coded = RidgitsCustomerFacingError.message(for: code) {
            return coded
        }

        switch code {
        case "FACE_MATCH_FAILED", "PROFILE_PHOTO_IDENTITY_MISMATCH":
            let sanitized = RidgitsCustomerFacingError.sanitize(fallback)
            return sanitized == RidgitsCustomerFacingError.supportMessage()
                ? genericMismatchMessage
                : sanitized
        case "PROFILE_PHOTO_ALREADY_CLAIMED":
            return "This profile photo is already linked to another Ridgits account."
        default:
            let sanitized = RidgitsCustomerFacingError.sanitize(fallback, code: code.isEmpty ? nil : code)
            return sanitized == RidgitsCustomerFacingError.supportMessage() && fallback.isEmpty ? nil : sanitized
        }
    }

    static func sanitizedFailureMessage(_ result: RidgitsProfilePhotoMatchResult) -> String {
        if let message = result.userFacingFailureMessage {
            return RidgitsCustomerFacingError.sanitize(message)
        }
        return fallbackMismatchMessage(score: result.score, threshold: result.threshold)
    }

    static func fallbackMismatchMessage(score: Double?, threshold: Double) -> String {
        guard let score, score > 0 else { return genericMismatchMessage }
        let scorePct = Int((score * 100).rounded())
        let thresholdPct = Int((threshold * 100).rounded())
        return "Your profile photo only matched your ID selfie at \(scorePct)% (we require at least \(thresholdPct)%). Use a clearer, front-facing photo similar to your verification selfie."
    }
}
