import Foundation
import FirebaseAuth
import FirebaseFunctions
import FirebaseStorage
import UIKit

struct RidgitsMessageAnalysisResult: Equatable {
    let insights: [String]
    let preview: String?
    let isLocked: Bool
}

struct RidgitsCompatibilityReadout: Equatable {
    let matchName: String
    let about: String
    let interests: [String]
    let archetypeName: String
    let compatibility: RidgitsCompatibility
    let summary: String?
    let dealbreakerQuestions: [String]
    let isLocked: Bool
    let lockedConversationTopicsCount: Int?
    let lockedDealbreakerQuestionsCount: Int?
}

@MainActor
final class RidgitsQuickToolsService {
    static let shared = RidgitsQuickToolsService()

    private let functions = Functions.functions()
    private let storage = Storage.storage()

    private init() {}

    func uploadImages(_ images: [Data], folder: String) async throws -> [String] {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw RidgitsError.notAuthenticated
        }

        var urls: [String] = []
        for (index, data) in images.enumerated() {
            let path = "\(folder)/\(uid)/\(Int(Date().timeIntervalSince1970 * 1000))_\(index).jpg"
            let ref = storage.reference().child(path)
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            _ = try await ref.putDataAsync(data, metadata: metadata)
            let url = try await ref.downloadURL()
            urls.append(url.absoluteString)
        }
        return urls
    }

    func analyzeMessages(imageURLs: [String], prompt: String) async throws -> RidgitsMessageAnalysisResult {
        let callable = functions.httpsCallable("analyzeMessagesV2")
        let result = try await callable.call([
            "imageUrls": imageURLs,
            "prompt": prompt.trimmingCharacters(in: .whitespacesAndNewlines),
        ])
        return try parseMessageAnalysis(result.data)
    }

    func analyzeCompatibilityContext(
        contextText: String,
        partnerName: String?,
        imageURLs: [String]
    ) async throws -> RidgitsCompatibilityReadout {
        var payload: [String: Any] = [
            "contextText": contextText.trimmingCharacters(in: .whitespacesAndNewlines),
            "imageUrls": imageURLs,
        ]
        if let partnerName, !partnerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            payload["partnerName"] = partnerName.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let callable = functions.httpsCallable("analyzeVibeContextV2")
        let result = try await callable.call(payload)
        return try parseCompatibilityReadout(result.data)
    }

    private func parseMessageAnalysis(_ value: Any?) throws -> RidgitsMessageAnalysisResult {
        guard let dict = value as? [String: Any] else {
            throw RidgitsError.decoding
        }

        if dict["isLocked"] as? Bool == true {
            return RidgitsMessageAnalysisResult(
                insights: [],
                preview: dict["preview"] as? String,
                isLocked: true
            )
        }

        if let insights = dict["insights"] as? [String] {
            return RidgitsMessageAnalysisResult(insights: insights, preview: nil, isLocked: false)
        }

        if let nested = dict["analysis"] as? [String: Any],
           let insights = nested["insights"] as? [String] {
            return RidgitsMessageAnalysisResult(
                insights: insights,
                preview: dict["preview"] as? String,
                isLocked: dict["isLocked"] as? Bool ?? false
            )
        }

        throw RidgitsError.decoding
    }

    private func parseCompatibilityReadout(_ value: Any?) throws -> RidgitsCompatibilityReadout {
        guard let dict = value as? [String: Any],
              let matchData = dict["matchData"] as? [String: Any],
              let compatibility = dict["compatibility"] as? [String: Any] else {
            throw RidgitsError.decoding
        }

        let archetype = matchData["archetype"] as? [String: Any]
        let isLocked = dict["isLocked"] as? Bool ?? false

        return RidgitsCompatibilityReadout(
            matchName: matchData["name"] as? String ?? "Your Match",
            about: matchData["about"] as? String ?? "",
            interests: matchData["interests"] as? [String] ?? [],
            archetypeName: archetype?["name"] as? String ?? "",
            compatibility: RidgitsCompatibility(
                overall: Self.intValue(compatibility["overall"]),
                communication: Self.intValue(compatibility["communication"]),
                intimacy: Self.intValue(compatibility["intimacy"]),
                values: Self.intValue(compatibility["values"]),
                social: Self.intValue(compatibility["social"]),
                commitment: Self.intValue(compatibility["commitment"])
            ),
            summary: dict["summary"] as? String,
            dealbreakerQuestions: dict["dealbreakerQuestions"] as? [String] ?? [],
            isLocked: isLocked,
            lockedConversationTopicsCount: dict["conversationTopicsCount"] as? Int,
            lockedDealbreakerQuestionsCount: dict["dealbreakerQuestionsCount"] as? Int
        )
    }

    private static func intValue(_ value: Any?) -> Int {
        if let int = value as? Int { return int }
        if let double = value as? Double { return Int(double.rounded()) }
        if let number = value as? NSNumber { return number.intValue }
        if let string = value as? String, let int = Int(string) { return int }
        return 0
    }
}
