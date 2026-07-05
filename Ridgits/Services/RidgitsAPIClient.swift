import Foundation
import FirebaseAuth

struct RidgitsAccountAccess: Decodable {
    let hasNearbyAccess: Bool
    let subscriptionExpiresAt: String?
    let subscriptionSource: String?
    let subscriptionTier: String?
    let identityVerificationStatus: String?
    let identityVerifiedAt: String?
    let phoneVerificationStatus: String?
    let phoneVerifiedAt: String?
    let profilePhotoIdentityMatchStatus: String?
    let profilePhotoIdentityMatchAt: String?
    let profilePhotoIdentityMatchScore: Double?
    let canSubscribe: Bool?
    let canMessage: Bool?
}

struct RidgitsLinkPurchaseResult: Decodable {
    let linked: Bool
    let idempotent: Bool
}

struct RidgitsNearbyMatchesResult {
    let matches: [RidgitsMatch]
    let closeMatchCount: Int
    let closeMatches: [RidgitsCloseMatchPreview]
}

struct RidgitsCloseMatchPreview: Identifiable, Equatable, Codable, Hashable {
    let userId: String
    let name: String
    let image: String

    var id: String { userId }

    static func fromDictionary(_ dict: [String: Any]) -> RidgitsCloseMatchPreview? {
        guard let userId = dict["userId"] as? String else { return nil }
        let name = (dict["name"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let image = (dict["image"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name.lowercased() != "anonymous", !image.isEmpty else { return nil }
        return RidgitsCloseMatchPreview(userId: userId, name: name, image: image)
    }
}

struct RidgitsSignupValidation {
    let ok: Bool
    let error: String?
    let code: String?
}

@MainActor
final class RidgitsAPIClient {
    static let shared = RidgitsAPIClient()

    private init() {}

    private var baseURL: URL {
        for name in ["Secrets", "Secrets.example"] {
            if let path = Bundle.main.path(forResource: name, ofType: "plist"),
               let secrets = NSDictionary(contentsOfFile: path) as? [String: Any],
               let urlString = secrets["ridgitsApiBaseURL"] as? String,
               let url = URL(string: urlString) {
                return url
            }
        }
        return URL(string: "https://ridgits-api.vercel.app")!
    }

    func fetchAccountAccess() async throws -> RidgitsAccountAccess {
        let data = try await authorizedRequest(path: "/api/account/access", method: "GET", body: nil)
        return RidgitsAccountAccess(
            hasNearbyAccess: data["hasNearbyAccess"] as? Bool ?? false,
            subscriptionExpiresAt: data["subscriptionExpiresAt"] as? String,
            subscriptionSource: data["subscriptionSource"] as? String,
            subscriptionTier: data["subscriptionTier"] as? String,
            identityVerificationStatus: data["identityVerificationStatus"] as? String,
            identityVerifiedAt: data["identityVerifiedAt"] as? String,
            phoneVerificationStatus: data["phoneVerificationStatus"] as? String,
            phoneVerifiedAt: data["phoneVerifiedAt"] as? String,
            profilePhotoIdentityMatchStatus: data["profilePhotoIdentityMatchStatus"] as? String,
            profilePhotoIdentityMatchAt: data["profilePhotoIdentityMatchAt"] as? String,
            profilePhotoIdentityMatchScore: data["profilePhotoIdentityMatchScore"] as? Double,
            canSubscribe: data["canSubscribe"] as? Bool,
            canMessage: data["canMessage"] as? Bool
        )
    }

    func fetchIdentityStatus() async throws -> RidgitsIdentityStatus {
        let data = try await authorizedRequest(path: "/api/identity/status", method: "GET", body: nil)
        let json = try JSONSerialization.data(withJSONObject: data)
        return try JSONDecoder().decode(RidgitsIdentityStatus.self, from: json)
    }

    func createIdentityVerificationSession() async throws -> RidgitsIdentitySessionResponse {
        let data = try await authorizedRequest(path: "/api/identity/session", method: "POST", body: [:])
        let json = try JSONSerialization.data(withJSONObject: data)
        return try JSONDecoder().decode(RidgitsIdentitySessionResponse.self, from: json)
    }

    func matchProfilePhotoToIdentity() async throws -> RidgitsProfilePhotoMatchResult {
        let data = try await authorizedRequest(path: "/api/identity/match-profile-photo", method: "POST", body: [:])
        let json = try JSONSerialization.data(withJSONObject: data)
        return try JSONDecoder().decode(RidgitsProfilePhotoMatchResult.self, from: json)
    }

    func registerProfilePhoto(imageUrl: String) async throws {
        _ = try await authorizedRequest(
            path: "/api/profile/register-photo",
            method: "POST",
            body: ["imageUrl": imageUrl]
        )
    }

    func linkPurchase(
        transactionId: String,
        productId: String,
        signedTransactionInfo: String,
        restoring: Bool = false
    ) async throws -> RidgitsLinkPurchaseResult {
        var body: [String: Any] = [
            "transactionId": transactionId,
            "productId": productId,
            "signedTransactionInfo": signedTransactionInfo,
        ]
        if restoring {
            body["restoring"] = true
        }
        let data = try await authorizedRequest(
            path: "/api/iap/link-purchase",
            method: "POST",
            body: body
        )
        return RidgitsLinkPurchaseResult(
            linked: data["linked"] as? Bool ?? false,
            idempotent: data["idempotent"] as? Bool ?? false
        )
    }

    func findMatches(
        maxDistance: Int,
        previewCloseMatches: Bool = false
    ) async throws -> RidgitsNearbyMatchesResult {
        var body: [String: Any] = ["maxDistance": maxDistance]
        if previewCloseMatches {
            body["previewCloseMatches"] = true
        }
        let data = try await authorizedRequest(
            path: "/api/matches/nearby",
            method: "POST",
            body: body
        )
        return RidgitsNearbyMatchesResult(
            matches: parseMatches(data["matches"]),
            closeMatchCount: data["closeMatchCount"] as? Int ?? data["hiddenNearbyCount"] as? Int ?? 0,
            closeMatches: parseCloseMatchPreviews(data["closeMatches"])
        )
    }

    func getTopNationwideMatches(limit: Int = 10, forceRefresh: Bool = false) async throws -> [RidgitsMatch] {
        var body: [String: Any] = ["limit": limit]
        if forceRefresh {
            body["forceRefresh"] = true
        }
        let data = try await authorizedRequest(
            path: "/api/matches/nationwide",
            method: "POST",
            body: body
        )
        return parseMatches(data["matches"])
    }

    func startConversation(toUserId: String, message: String) async throws -> String {
        let data = try await authorizedRequest(
            path: "/api/messaging/start",
            method: "POST",
            body: ["toUserId": toUserId, "message": message]
        )
        guard let conversationId = data["conversationId"] as? String else {
            throw RidgitsError.server("Could not start conversation.")
        }
        return conversationId
    }

    func approveConversation(conversationId: String) async throws {
        _ = try await authorizedRequest(
            path: "/api/messaging/approve",
            method: "POST",
            body: ["conversationId": conversationId]
        )
    }

    func declineConversation(conversationId: String) async throws {
        _ = try await authorizedRequest(
            path: "/api/messaging/decline",
            method: "POST",
            body: ["conversationId": conversationId]
        )
    }

    func withdrawConversation(conversationId: String) async throws {
        _ = try await authorizedRequest(
            path: "/api/messaging/withdraw",
            method: "POST",
            body: ["conversationId": conversationId]
        )
    }

    func sendMessage(conversationId: String, message: String) async throws {
        _ = try await authorizedRequest(
            path: "/api/messaging/send",
            method: "POST",
            body: ["conversationId": conversationId, "message": message]
        )
    }

    func markConversationRead(conversationId: String) async throws {
        _ = try await authorizedRequest(
            path: "/api/messaging/read",
            method: "POST",
            body: ["conversationId": conversationId]
        )
    }

    func flagConversation(conversationId: String, reason: String) async throws {
        _ = try await authorizedRequest(
            path: "/api/messaging/flag",
            method: "POST",
            body: ["conversationId": conversationId, "reason": reason]
        )
    }

    func fetchMessagingQuota() async throws -> RidgitsMonthlyMessageQuota {
        let data = try await authorizedRequest(path: "/api/messaging/quota", method: "GET", body: nil)
        let quota = data["quota"] as? [String: Any] ?? [:]
        guard let parsed = RidgitsMonthlyMessageQuota.fromDictionary(quota) else {
            throw RidgitsError.decoding
        }
        return parsed
    }

    func fetchPokeCredits() async throws -> RidgitsPokeCredits {
        let data = try await authorizedRequest(path: "/api/pokes/quota", method: "GET", body: nil)
        let credits = data["credits"] as? [String: Any] ?? [:]
        guard let parsed = RidgitsPokeCredits.fromDictionary(credits) else {
            throw RidgitsError.decoding
        }
        return parsed
    }

    func registerDevice(deviceId: String, fcmToken: String, appVersion: String?, deviceModel: String?) async throws {
        var body: [String: Any] = [
            "deviceId": deviceId,
            "fcmToken": fcmToken,
            "platform": "ios",
        ]
        if let appVersion { body["appVersion"] = appVersion }
        if let deviceModel { body["deviceModel"] = deviceModel }
        _ = try await authorizedRequest(path: "/api/notifications/register-device", method: "POST", body: body)
    }

    func unregisterDevice(deviceId: String) async throws {
        _ = try await authorizedRequest(
            path: "/api/notifications/register-device",
            method: "DELETE",
            body: ["deviceId": deviceId]
        )
    }

    func fetchNotificationPreferences() async throws -> RidgitsNotificationPreferences {
        let data = try await authorizedRequest(path: "/api/notifications/preferences", method: "GET", body: nil)
        let prefs = data["preferences"] as? [String: Any] ?? [:]
        return RidgitsNotificationPreferences.fromDictionary(prefs)
    }

    func updateNotificationPreferences(_ preferences: RidgitsNotificationPreferences) async throws -> RidgitsNotificationPreferences {
        let data = try await authorizedRequest(
            path: "/api/notifications/preferences",
            method: "PATCH",
            body: preferences.asDictionary()
        )
        let prefs = data["preferences"] as? [String: Any] ?? [:]
        return RidgitsNotificationPreferences.fromDictionary(prefs)
    }

    func recordNotificationOpened(type: String, metadata: [String: String]) async throws {
        _ = try await authorizedRequest(
            path: "/api/notifications/preferences",
            method: "POST",
            body: ["type": type, "metadata": metadata]
        )
    }

    func sendPoke(toUserId: String) async throws -> String {
        let data = try await authorizedRequest(
            path: "/api/pokes/send",
            method: "POST",
            body: ["toUserId": toUserId]
        )
        guard let pokeId = data["pokeId"] as? String else {
            throw RidgitsError.server("Could not send poke.")
        }
        return pokeId
    }

    func unpoke(pokeId: String) async throws {
        _ = try await authorizedRequest(
            path: "/api/pokes/unpoke",
            method: "POST",
            body: ["pokeId": pokeId]
        )
    }

    func dismissReceivedPoke(pokeId: String) async throws {
        _ = try await authorizedRequest(
            path: "/api/pokes/dismiss",
            method: "POST",
            body: ["pokeId": pokeId]
        )
    }

    func markPokeSeen(pokeId: String, profileVisited: Bool = false) async throws {
        _ = try await authorizedRequest(
            path: "/api/pokes/seen",
            method: "POST",
            body: ["pokeId": pokeId, "profileVisited": profileVisited]
        )
    }

    func deleteAccount() async throws {
        _ = try await authorizedRequest(path: "/api/account/delete", method: "DELETE", body: nil)
    }

    func fetchReferralProfile() async throws -> RidgitsReferralProfileResponse {
        let data = try await authorizedRequest(path: "/api/referrals/profile", method: "GET", body: nil)
        let json = try JSONSerialization.data(withJSONObject: data)
        let decoder = JSONDecoder()
        return try decoder.decode(RidgitsReferralProfileResponse.self, from: json)
    }

    func redeemReferralCode(_ referralCode: String, source: String = "profile") async throws -> RidgitsReferralRedeemResponse {
        let data = try await authorizedRequest(
            path: "/api/referrals/redeem",
            method: "POST",
            body: ["referralCode": referralCode, "source": source]
        )
        let json = try JSONSerialization.data(withJSONObject: data)
        return try JSONDecoder().decode(RidgitsReferralRedeemResponse.self, from: json)
    }

    func qualifyReferral() async throws -> RidgitsReferralQualifyResponse {
        let data = try await authorizedRequest(path: "/api/referrals/qualify", method: "POST", body: [:])
        let json = try JSONSerialization.data(withJSONObject: data)
        return try JSONDecoder().decode(RidgitsReferralQualifyResponse.self, from: json)
    }

    /// Authoritative pre-signup / post-OAuth check (disposable email, 18+ birth year).
    /// Unauthenticated — safe to call before a Firebase Auth account exists.
    func validateSignup(email: String? = nil, birthYear: Int? = nil) async throws -> RidgitsSignupValidation {
        var body: [String: Any] = [:]
        if let email { body["email"] = email }
        if let birthYear { body["birthYear"] = birthYear }

        var request = URLRequest(url: baseURL.appendingPathComponent("/api/auth/validate-signup"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 20
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (responseData, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw RidgitsError.server("Invalid response")
        }
        let json = (try? JSONSerialization.jsonObject(with: responseData) as? [String: Any]) ?? [:]

        guard (200...299).contains(http.statusCode) else {
            let message = json["error"] as? String ?? "Could not validate signup (\(http.statusCode))"
            if let code = json["code"] as? String {
                throw RidgitsError.serverCoded(message: message, code: code)
            }
            throw RidgitsError.server(message)
        }

        return RidgitsSignupValidation(
            ok: json["ok"] as? Bool ?? true,
            error: json["error"] as? String,
            code: json["code"] as? String
        )
    }

    private func parseMatches(_ value: Any?) -> [RidgitsMatch] {
        guard let matches = value as? [[String: Any]] else { return [] }
        return matches.compactMap(RidgitsMatch.fromDictionary)
    }

    private func parseCloseMatchPreviews(_ value: Any?) -> [RidgitsCloseMatchPreview] {
        guard let matches = value as? [[String: Any]] else { return [] }
        return matches.compactMap(RidgitsCloseMatchPreview.fromDictionary)
    }

    private func authorizedRequest(
        path: String,
        method: String,
        body: [String: Any]?
    ) async throws -> [String: Any] {
        guard let user = Auth.auth().currentUser else {
            throw RidgitsError.notAuthenticated
        }

        let token = try await user.getIDToken()
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 300

        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let (responseData, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw RidgitsError.server("Invalid response")
        }

        let json = (try? JSONSerialization.jsonObject(with: responseData) as? [String: Any]) ?? [:]
        guard (200...299).contains(http.statusCode) else {
            let message = json["error"] as? String ?? "Request failed (\(http.statusCode))"
            if let code = json["code"] as? String {
                throw RidgitsError.serverCoded(message: message, code: code)
            }
            throw RidgitsError.server(message)
        }
        return json
    }
}
