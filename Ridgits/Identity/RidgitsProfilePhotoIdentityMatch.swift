import Foundation

enum RidgitsProfilePhotoIdentityMatch {
    @MainActor
    static func matchAfterProfileSaveIfNeeded() async -> String? {
        do {
            let identity = try await RidgitsAPIClient.shared.fetchIdentityStatus()
            guard identity.isIdentityVerified else { return nil }
            guard !identity.isProfilePhotoMatched else { return nil }

            let result = try await RidgitsAPIClient.shared.matchProfilePhotoToIdentity()
            if result.isVerified {
                return nil
            }
            return "Your profile photo didn't match your verified ID selfie. Use a clear photo of your face, similar to your ID verification selfie, then try again from your profile."
        } catch let error as RidgitsError {
            if error.code == "FACE_MATCH_FAILED" || error.code == "PROFILE_PHOTO_IDENTITY_MISMATCH" {
                return error.localizedDescription
            }
            return nil
        } catch {
            return nil
        }
    }
}
