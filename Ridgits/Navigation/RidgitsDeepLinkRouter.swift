import Foundation
import FirebaseAuth

@MainActor
final class RidgitsDeepLinkRouter: ObservableObject {
    @Published private(set) var pendingRidgitId: String?
    @Published private(set) var pendingRoute: RidgitsEngagementRoute?

    func handle(_ url: URL) -> Bool {
        if let referralCode = RidgitsAppLinks.parseReferralCode(from: url) {
            if let uid = FirebaseAuth.Auth.auth().currentUser?.uid {
                RidgitsReferralStorage.savePendingCode(referralCode, firebaseUid: uid)
            } else {
                UserDefaults.standard.set(referralCode, forKey: "ridgits_pending_referral_code_anonymous")
            }
            return true
        }
        if let id = RidgitsAppLinks.parseRidgitId(from: url) {
            pendingRidgitId = id
            pendingRoute = .ridgit(id: id)
            return true
        }
        if let packId = RidgitsAppLinks.parsePackId(from: url) {
            pendingRoute = .pack(id: packId)
            return true
        }
        return false
    }

    func route(to engagementRoute: RidgitsEngagementRoute) {
        pendingRoute = engagementRoute
        switch engagementRoute {
        case .ridgit(let id):
            pendingRidgitId = id
        case .pack, .home, .matches, .messages:
            break
        }
    }

    func clearPendingRidgit() {
        pendingRidgitId = nil
    }

    func clearPendingRoute() {
        pendingRoute = nil
    }
}
