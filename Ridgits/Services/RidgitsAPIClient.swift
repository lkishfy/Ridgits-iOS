import Foundation
import FirebaseAuth

struct RidgitsAccountAccess: Decodable {
    let hasNearbyAccess: Bool
    let subscriptionExpiresAt: String?
    let subscriptionSource: String?
    let subscriptionTier: String?
}

struct RidgitsLinkPurchaseResult: Decodable {
    let linked: Bool
    let idempotent: Bool
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
            subscriptionTier: data["subscriptionTier"] as? String
        )
    }

    func linkPurchase(
        transactionId: String,
        productId: String,
        signedTransactionInfo: String
    ) async throws -> RidgitsLinkPurchaseResult {
        let data = try await authorizedRequest(
            path: "/api/iap/link-purchase",
            method: "POST",
            body: [
                "transactionId": transactionId,
                "productId": productId,
                "signedTransactionInfo": signedTransactionInfo,
            ]
        )
        return RidgitsLinkPurchaseResult(
            linked: data["linked"] as? Bool ?? false,
            idempotent: data["idempotent"] as? Bool ?? false
        )
    }

    func findMatches(maxDistance: Int) async throws -> [RidgitsMatch] {
        let data = try await authorizedRequest(
            path: "/api/matches/nearby",
            method: "POST",
            body: ["maxDistance": maxDistance]
        )
        return parseMatches(data["matches"])
    }

    func getTopNationwideMatches(limit: Int = 10) async throws -> [RidgitsMatch] {
        let data = try await authorizedRequest(
            path: "/api/matches/nationwide",
            method: "POST",
            body: ["limit": limit]
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

    private func parseMatches(_ value: Any?) -> [RidgitsMatch] {
        guard let matches = value as? [[String: Any]] else { return [] }
        return matches.compactMap(RidgitsMatch.fromDictionary)
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
            throw RidgitsError.server(message)
        }
        return json
    }
}
