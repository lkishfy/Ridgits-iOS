import Foundation
import FirebaseFirestore

struct RidgitsUserProfile: Identifiable, Equatable {
    let id: String
    var name: String
    var location: String
    var age: Int?
    var image: String
    var about: String
    var interests: [String]
    var aspirations: String
    var additionalImages: [String]

    var isCompleteForMatching: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && age != nil
            && !image.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !about.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !interests.isEmpty
            && !aspirations.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static func from(uid: String, data: [String: Any]) -> RidgitsUserProfile {
        RidgitsUserProfile(
            id: uid,
            name: data["name"] as? String ?? "",
            location: data["location"] as? String ?? "",
            age: data["age"] as? Int ?? (data["age"] as? String).flatMap(Int.init),
            image: data["image"] as? String ?? "",
            about: data["about"] as? String ?? "",
            interests: data["interests"] as? [String] ?? [],
            aspirations: data["aspirations"] as? String ?? "",
            additionalImages: data["additionalImages"] as? [String] ?? []
        )
    }
}

struct RidgitsMatch: Identifiable, Equatable {
    let id: String
    let userId: String
    let name: String
    let image: String
    let location: String
    let distanceMiles: Double?
    let compatibility: RidgitsCompatibility
    let about: String?
}

struct RidgitsCompatibility: Equatable {
    let overall: Int
    let communication: Int
    let intimacy: Int
    let values: Int
    let social: Int
    let commitment: Int
}

enum ConversationStatus: String {
    case pending
    case active
    case expired
    case blocked
}

struct RidgitsConversation: Identifiable, Equatable {
    let id: String
    let participantIds: [String]
    let status: ConversationStatus
    let expiresAt: Date?
    let messageCount: Int
    let maxMessages: Int
    let lastMessage: String?
    let otherUserId: String
    let otherUserName: String
    let otherUserImage: String
    let unreadCount: Int
    let isIncomingPending: Bool
    let isOutgoingPending: Bool

    var isExpired: Bool {
        status == .expired || (expiresAt.map { $0 <= Date() } ?? false)
    }

    var messagesRemaining: Int {
        max(0, maxMessages - messageCount)
    }

    var canSendMessage: Bool {
        status == .active && !isExpired && messageCount < maxMessages
    }
}

struct RidgitsMessage: Identifiable, Equatable {
    let id: String
    let senderId: String
    let text: String
    let createdAt: Date
}

struct QuizOption: Identifiable, Equatable, Hashable {
    let value: Int
    let label: String
    var id: Int { value }
}

struct QuizQuestion: Identifiable, Equatable {
    let id: String
    let category: String
    let text: String
    let options: [QuizOption]
    let multiSelect: Bool
    let isSpicy: Bool
}

enum QuizImportance: Int, CaseIterable, Identifiable {
    case irrelevant = 1
    case aLittle = 10
    case somewhat = 50
    case very = 250
    case mandatory = 1000

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .irrelevant: return "Irrelevant"
        case .aLittle: return "A little"
        case .somewhat: return "Somewhat"
        case .very: return "Very"
        case .mandatory: return "Mandatory"
        }
    }
}

struct QuizAnswerRecord: Codable, Equatable {
    var answer: Int?
    var answers: [Int]?
    var preferredAnswers: [Int]
    var importance: Int
    var dealbreaker: Bool
}

struct QuizProgressPayload: Codable {
    var answers: [String: QuizAnswerRecord]
    var completed: Bool
    var currentIndex: Int
}

extension Timestamp {
    var ridgitsDate: Date { dateValue() }
}

extension RidgitsConversation {
    static func from(id: String, data: [String: Any], currentUserId: String) -> RidgitsConversation? {
        guard let participantIds = data["participantIds"] as? [String] else { return nil }
        let otherUserId = participantIds.first { $0 != currentUserId } ?? ""
        let participants = data["participants"] as? [String: [String: Any]] ?? [:]
        let other = participants[otherUserId] ?? [:]
        let statusRaw = data["status"] as? String ?? "pending"
        let status = ConversationStatus(rawValue: statusRaw) ?? .pending
        let approvals = data["approvals"] as? [String: Bool] ?? [:]
        let approvedByMe = approvals[currentUserId] == true
        let approvedByOther = approvals[otherUserId] == true
        let initiatorId = data["initiatorId"] as? String ?? participantIds.first ?? ""

        return RidgitsConversation(
            id: id,
            participantIds: participantIds,
            status: status,
            expiresAt: (data["expiresAt"] as? Timestamp)?.ridgitsDate,
            messageCount: data["messageCount"] as? Int ?? 0,
            maxMessages: data["maxMessages"] as? Int ?? RidgitsMessagingLimits.maxMessages,
            lastMessage: data["lastMessagePreview"] as? String,
            otherUserId: otherUserId,
            otherUserName: other["name"] as? String ?? "Someone",
            otherUserImage: other["image"] as? String ?? "",
            unreadCount: (data["unreadCounts"] as? [String: Int])?[currentUserId] ?? 0,
            isIncomingPending: status == .pending && initiatorId != currentUserId && !approvedByMe,
            isOutgoingPending: status == .pending && initiatorId == currentUserId && !approvedByOther
        )
    }
}

extension RidgitsMessage {
    static func from(id: String, data: [String: Any]) -> RidgitsMessage? {
        guard let senderId = data["senderId"] as? String,
              let text = data["text"] as? String else { return nil }
        let createdAt = (data["createdAt"] as? Timestamp)?.ridgitsDate ?? Date()
        return RidgitsMessage(id: id, senderId: senderId, text: text, createdAt: createdAt)
    }
}

extension RidgitsMatch {
    static func fromDictionary(_ dict: [String: Any]) -> RidgitsMatch? {
        guard let userId = dict["userId"] as? String else { return nil }
        let compat = dict["compatibility"] as? [String: Any] ?? [:]
        return RidgitsMatch(
            id: userId,
            userId: userId,
            name: dict["name"] as? String ?? "Anonymous",
            image: dict["image"] as? String ?? "",
            location: dict["location"] as? String ?? "",
            distanceMiles: dict["distance"] as? Double,
            compatibility: RidgitsCompatibility(
                overall: compat["overall"] as? Int ?? dict["compatibilityScore"] as? Int ?? 0,
                communication: compat["communication"] as? Int ?? 0,
                intimacy: compat["intimacy"] as? Int ?? 0,
                values: compat["values"] as? Int ?? 0,
                social: compat["social"] as? Int ?? 0,
                commitment: compat["commitment"] as? Int ?? 0
            ),
            about: dict["about"] as? String
        )
    }
}
