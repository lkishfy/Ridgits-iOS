import Foundation
import FirebaseFirestore

enum RidgitsReferralLimits {
    static let maxReferrals = 3
    static let bonusPacksPerFriend = 1
    static let qualificationWindowDays = 14

    static var referredUserQualificationMotivation: String {
        "Finish your personality quiz within \(qualificationWindowDays) days of signing up and you'll both unlock a free special quiz."
    }

    static func gateTitle(for slot: Int) -> String {
        "Locked · \(referralsRequiredLabel(for: slot))"
    }

    static func referralsRequiredLabel(for slot: Int) -> String {
        switch slot {
        case 1: return "1 referral"
        default: return "\(slot) referrals"
        }
    }

    static func gateMessage(for slot: Int, referralsCompleted: Int) -> String {
        let needed = max(slot - referralsCompleted, 1)
        if needed == 1 {
            return "Refer \(needed) more friend who finishes their quiz to unlock this special quiz. Share your code below."
        }
        return "Refer \(needed) more friends who finish their quiz to unlock this special quiz. Share your code below."
    }
}

enum RidgitsReferralStorage {
    private static func pendingKey(firebaseUid: String) -> String {
        "ridgits_pending_referral_code_\(firebaseUid)"
    }

    private static func welcomeSeenKey(firebaseUid: String) -> String {
        "ridgits_referral_welcome_seen_\(firebaseUid)"
    }

    static func savePendingCode(_ code: String, firebaseUid: String) {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        UserDefaults.standard.set(trimmed.uppercased(), forKey: pendingKey(firebaseUid: firebaseUid))
    }

    static func loadPendingCode(firebaseUid: String) -> String? {
        guard let raw = UserDefaults.standard.string(forKey: pendingKey(firebaseUid: firebaseUid)) else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed.uppercased()
    }

    static func clearPendingCode(firebaseUid: String) {
        UserDefaults.standard.removeObject(forKey: pendingKey(firebaseUid: firebaseUid))
    }

    static func markWelcomeSeen(firebaseUid: String) {
        UserDefaults.standard.set(true, forKey: welcomeSeenKey(firebaseUid: firebaseUid))
    }

    static func hasSeenWelcome(firebaseUid: String) -> Bool {
        UserDefaults.standard.bool(forKey: welcomeSeenKey(firebaseUid: firebaseUid))
    }
}

struct RidgitsReferralProfile: Decodable, Equatable {
    let code: String
    let shareMessage: String
    let referralsCompleted: Int
    let maxReferrals: Int
    let bonusPacksPerFriend: Int
    let canEarnMoreReferrals: Bool
    let hasRedeemedReferralCode: Bool
    let redeemedReferralCode: String?
    let redeemedReferralStatus: String?
}

struct RidgitsReferralProfileResponse: Decodable {
    let referral: RidgitsReferralProfile
}

struct RidgitsReferralRedeemResponse: Decodable {
    let redeemed: Bool
    let alreadyRedeemed: Bool
    let grantedPackId: String?
    let bonusPending: Bool?
}

enum RidgitsReferralLocalService {
    private static let codeAlphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
    private static let codePrefix = "RIDGITS-"

    @MainActor
    static func loadOrCreateProfile(uid: String) async throws -> RidgitsReferralProfile {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)
        let snap = try await userRef.getDocument()
        let data = snap.data() ?? [:]

        var code = (data["referralCode"] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased() ?? ""

        if code.isEmpty {
            code = generateCode()
            try await userRef.setData(["referralCode": code], merge: true)
        }

        let referralsCompleted = data["referralsCompleted"] as? Int ?? 0
        let redeemedCode = (data["redeemedReferralCode"] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let hasRedeemed = !(redeemedCode?.isEmpty ?? true)

        return RidgitsReferralProfile(
            code: code,
            shareMessage: shareMessage(for: code),
            referralsCompleted: referralsCompleted,
            maxReferrals: RidgitsReferralLimits.maxReferrals,
            bonusPacksPerFriend: RidgitsReferralLimits.bonusPacksPerFriend,
            canEarnMoreReferrals: referralsCompleted < RidgitsReferralLimits.maxReferrals,
            hasRedeemedReferralCode: hasRedeemed,
            redeemedReferralCode: hasRedeemed ? redeemedCode : nil,
            redeemedReferralStatus: hasRedeemed ? "pending" : nil
        )
    }

    private static func generateCode() -> String {
        var suffix = ""
        for _ in 0..<6 {
            suffix.append(codeAlphabet.randomElement()!)
        }
        return codePrefix + suffix
    }

    private static func shareMessage(for code: String) -> String {
        "Join me on Ridgits — use my code \(code) when you sign up. Finish your personality quiz within \(RidgitsReferralLimits.qualificationWindowDays) days and you'll both unlock a free special quiz. https://ridgits.com/invite?ref=\(code)"
    }
}

struct RidgitsReferralQualifyResponse: Decodable {
    let granted: Bool
    let grantedPackId: String?
}
