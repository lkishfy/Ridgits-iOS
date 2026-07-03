import Foundation
import FirebaseFirestore

struct RidgitsUserProfile: Identifiable, Equatable, Codable {
    let id: String
    var name: String
    var location: String
    var age: Int?
    var image: String
    var about: String
    var interests: [String]
    var aspirations: String
    var additionalImages: [String]
    var socialHandle: String
    var ageRangeMin: Int?
    var ageRangeMax: Int?
    var subscriptionTier: String
    /// When false, the user is hidden from discovery and cannot send pokes or messages.
    var visibleInCommunity: Bool

    var isCompleteForMatching: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && age != nil
            && !image.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !about.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !interests.isEmpty
            && !aspirations.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var hasBasicProfile: Bool {
        !name.isEmpty && !location.isEmpty && age != nil
    }

    static func empty(uid: String) -> RidgitsUserProfile {
        RidgitsUserProfile(
            id: uid, name: "", location: "", age: nil, image: "",
            about: "", interests: [], aspirations: "", additionalImages: [],
            socialHandle: "", ageRangeMin: nil, ageRangeMax: nil, subscriptionTier: "free",
            visibleInCommunity: true
        )
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
            additionalImages: data["additionalImages"] as? [String] ?? [],
            socialHandle: data["socialHandle"] as? String ?? "",
            ageRangeMin: data["ageRangeMin"] as? Int ?? (data["ageRangeMin"] as? String).flatMap(Int.init),
            ageRangeMax: data["ageRangeMax"] as? Int ?? (data["ageRangeMax"] as? String).flatMap(Int.init),
            subscriptionTier: data["subscriptionTier"] as? String ?? "free",
            visibleInCommunity: data["visibleInCommunity"] as? Bool ?? true
        )
    }

    func ridgitSnapshot() -> [String: Any] {
        [
            "name": name,
            "location": location,
            "image": image,
            "socialHandle": socialHandle,
            "about": about,
            "interests": interests,
            "age": age as Any,
        ]
    }
}

struct RidgitQuestion: Identifiable, Equatable {
    var id: String { question }
    var question: String
    var options: [String]
    var correctAnswer: Int
    var numOptions: Int

    static func fromDictionary(_ data: [String: Any]) -> RidgitQuestion? {
        guard let question = data["question"] as? String else { return nil }
        let options = data["options"] as? [String] ?? []
        let numOptions = data["numOptions"] as? Int ?? options.count
        return RidgitQuestion(
            question: question,
            options: options,
            correctAnswer: data["correctAnswer"] as? Int ?? 0,
            numOptions: max(2, min(numOptions, options.count))
        )
    }

    func firestorePayload() -> [String: Any] {
        [
            "question": question,
            "options": options,
            "correctAnswer": correctAnswer,
            "numOptions": numOptions,
        ]
    }

    var activeOptions: [String] {
        Array(options.prefix(numOptions))
    }
}

struct RidgitChallenge: Identifiable, Equatable {
    let id: String
    var title: String
    var userId: String
    var questions: [RidgitQuestion]
    var profile: RidgitsUserProfile
    var shareableLink: String?
    var createdAt: Date?

    static func from(id: String, data: [String: Any]) -> RidgitChallenge? {
        guard let userId = data["userId"] as? String else { return nil }
        let profileData = data["profile"] as? [String: Any] ?? [:]
        let questions = (data["questions"] as? [[String: Any]] ?? [])
            .compactMap(RidgitQuestion.fromDictionary)

        return RidgitChallenge(
            id: id,
            title: data["title"] as? String ?? "Untitled Ridgit",
            userId: userId,
            questions: questions,
            profile: RidgitsUserProfile.from(uid: userId, data: profileData),
            shareableLink: data["shareableLink"] as? String,
            createdAt: (data["createdAt"] as? Timestamp)?.ridgitsDate
        )
    }

    var resolvedShareLink: String {
        if let shareableLink, shareableLink.hasPrefix("ridgits://") {
            return shareableLink
        }
        return RidgitsAppLinks.ridgitURL(id: id).absoluteString
    }
}

struct RidgitsMatch: Identifiable, Equatable, Codable, Hashable {
    let id: String
    let userId: String
    let name: String
    let image: String
    let location: String
    let distanceMiles: Double?
    let compatibility: RidgitsCompatibility
    let about: String?
    let subscriptionTier: String?
}

struct RidgitsCompatibility: Equatable, Codable, Hashable {
    let overall: Int
    let communication: Int
    let intimacy: Int
    let values: Int
    let social: Int
    let commitment: Int

    func withDerivedOverallIfNeeded() -> RidgitsCompatibility {
        guard overall == 0 else { return self }
        let dimensionAverage = (communication + intimacy + values + social + commitment) / 5
        guard dimensionAverage > 0 else { return self }
        return RidgitsCompatibility(
            overall: dimensionAverage,
            communication: communication,
            intimacy: intimacy,
            values: values,
            social: social,
            commitment: commitment
        )
    }

    static func fromDictionary(_ dict: [String: Any]) -> RidgitsCompatibility {
        if let compatDict = dict["compatibility"] as? [String: Any] {
            let nestedOverall = parsedInt(compatDict["overall"])
            let topOverall = parsedInt(dict["overall"], fallback: parsedInt(dict["compatibilityScore"]))
            let resolvedOverall = nestedOverall > 0 ? nestedOverall : (topOverall > 0 ? topOverall : 0)

            return RidgitsCompatibility(
                overall: resolvedOverall,
                communication: parsedInt(compatDict["communication"], fallback: parsedInt(dict["communication"])),
                intimacy: parsedInt(compatDict["intimacy"], fallback: parsedInt(dict["intimacy"])),
                values: parsedInt(compatDict["values"], fallback: parsedInt(dict["values"])),
                social: parsedInt(compatDict["social"], fallback: parsedInt(dict["social"])),
                commitment: parsedInt(compatDict["commitment"], fallback: parsedInt(dict["commitment"]))
            )
        }

        var legacyOverall = parsedInt(dict["compatibility"])
        if legacyOverall == 0 {
            legacyOverall = parsedInt(dict["overall"], fallback: parsedInt(dict["compatibilityScore"]))
        }

        return RidgitsCompatibility(
            overall: legacyOverall,
            communication: parsedInt(dict["communication"]),
            intimacy: parsedInt(dict["intimacy"]),
            values: parsedInt(dict["values"]),
            social: parsedInt(dict["social"]),
            commitment: parsedInt(dict["commitment"])
        )
    }

    private static func parsedInt(_ value: Any?, fallback: Int = 0) -> Int {
        switch value {
        case let number as Int:
            return number
        case let number as Double:
            return Int(number.rounded())
        case let number as Float:
            return Int(number.rounded())
        case let number as NSNumber:
            return number.intValue
        case let string as String:
            return Int(string) ?? fallback
        case .none:
            return fallback
        default:
            return fallback
        }
    }
}

enum ConversationStatus: String, Codable {
    case pending
    case active
    case expired
    case blocked
}

struct RidgitsConversation: Identifiable, Equatable, Codable {
    let id: String
    let participantIds: [String]
    let status: ConversationStatus
    let expiresAt: Date?
    let messageCount: Int
    let maxMessages: Int
    let lastMessage: String?
    let lastMessageAt: Date?
    let otherUserId: String
    let otherUserName: String
    let otherUserImage: String
    let otherUserSubscriptionTier: String?
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

    var subtitle: String {
        switch self {
        case .irrelevant: return "Doesn't matter"
        case .aLittle: return "Nice to have"
        case .somewhat: return "Matters to me"
        case .very: return "Important"
        case .mandatory: return "Must match"
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

struct LoadedQuizProgress: Equatable {
    var answers: [String: QuizAnswerRecord]
    var currentQuestion: Int
    var completed: Bool
    var freePassesRemaining: Int
}

extension Timestamp {
    var ridgitsDate: Date { dateValue() }
}

extension RidgitsConversation {
    static func from(id: String, data: [String: Any], currentUserId: String) -> RidgitsConversation? {
        guard let participantIds = data["participantIds"] as? [String] else { return nil }
        let otherUserId = participantIds.first { $0 != currentUserId } ?? ""
        guard !otherUserId.isEmpty else { return nil }

        let deletedBy = data["deletedBy"] as? [String] ?? []
        if deletedBy.contains(otherUserId) { return nil }

        let participants = data["participants"] as? [String: [String: Any]] ?? [:]
        let other = participants[otherUserId] ?? [:]
        let statusRaw = data["status"] as? String ?? "pending"
        let status = ConversationStatus(rawValue: statusRaw) ?? .pending
        let approvals = data["approvals"] as? [String: Bool] ?? [:]
        let approvedByMe = approvals[currentUserId] == true
        let approvedByOther = approvals[otherUserId] == true
        let initiatorId = data["initiatorId"] as? String ?? participantIds.first ?? ""

        let otherUserName = participantString(other, keys: ["displayName", "name"]) ?? ""
        let otherUserImage = participantString(other, keys: ["imageUrl", "image", "photoUrl", "photoURL", "avatarUrl", "avatar"]) ?? ""
        let otherUserSubscriptionTier = other["subscriptionTier"] as? String

        return RidgitsConversation(
            id: id,
            participantIds: participantIds,
            status: status,
            expiresAt: (data["expiresAt"] as? Timestamp)?.ridgitsDate,
            messageCount: data["messageCount"] as? Int ?? 0,
            maxMessages: data["maxMessages"] as? Int ?? RidgitsMessagingLimits.maxMessages,
            lastMessage: data["lastMessagePreview"] as? String,
            lastMessageAt: (data["lastMessageAt"] as? Timestamp)?.ridgitsDate
                ?? (data["updatedAt"] as? Timestamp)?.ridgitsDate,
            otherUserId: otherUserId,
            otherUserName: otherUserName,
            otherUserImage: otherUserImage,
            otherUserSubscriptionTier: otherUserSubscriptionTier,
            unreadCount: (data["unreadCounts"] as? [String: Int])?[currentUserId] ?? 0,
            isIncomingPending: status == .pending && initiatorId != currentUserId && !approvedByMe,
            isOutgoingPending: status == .pending && initiatorId == currentUserId && !approvedByOther
        )
    }

    func updatingOtherUser(name: String, image: String, subscriptionTier: String? = nil) -> RidgitsConversation {
        RidgitsConversation(
            id: id,
            participantIds: participantIds,
            status: status,
            expiresAt: expiresAt,
            messageCount: messageCount,
            maxMessages: maxMessages,
            lastMessage: lastMessage,
            lastMessageAt: lastMessageAt,
            otherUserId: otherUserId,
            otherUserName: name,
            otherUserImage: image,
            otherUserSubscriptionTier: subscriptionTier ?? otherUserSubscriptionTier,
            unreadCount: unreadCount,
            isIncomingPending: isIncomingPending,
            isOutgoingPending: isOutgoingPending
        )
    }

    private static func participantString(_ participant: [String: Any], keys: [String]) -> String? {
        for key in keys {
            let value = (participant[key] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !value.isEmpty { return value }
        }
        return nil
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
        let name = (dict["name"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let image = (dict["image"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let about = (dict["about"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name.lowercased() != "anonymous", !image.isEmpty, !about.isEmpty else { return nil }

        let parsedCompatibility = RidgitsCompatibility.fromDictionary(dict).withDerivedOverallIfNeeded()
        return RidgitsMatch(
            id: userId,
            userId: userId,
            name: name,
            image: image,
            location: dict["location"] as? String ?? "",
            distanceMiles: parsedDouble(dict["distance"]),
            compatibility: parsedCompatibility,
            about: about,
            subscriptionTier: dict["subscriptionTier"] as? String
        )
    }

    private static func parsedInt(_ value: Any?, fallback: Int = 0) -> Int {
        switch value {
        case let number as Int:
            return number
        case let number as Double:
            return Int(number.rounded())
        case let number as Float:
            return Int(number.rounded())
        case let number as NSNumber:
            return number.intValue
        case let string as String:
            return Int(string) ?? fallback
        case .none:
            return fallback
        default:
            return fallback
        }
    }

    private static func parsedDouble(_ value: Any?) -> Double? {
        switch value {
        case let number as Double:
            return number
        case let number as Int:
            return Double(number)
        case let number as NSNumber:
            return number.doubleValue
        case let string as String:
            return Double(string)
        default:
            return nil
        }
    }
}
