import Foundation
import FirebaseFirestore

enum RidgitsSocialPlatform: String, CaseIterable, Equatable, Codable {
    case instagram
    case tiktok

    var displayName: String {
        switch self {
        case .instagram: return "Instagram"
        case .tiktok: return "TikTok"
        }
    }

    static func from(storageValue: String?) -> RidgitsSocialPlatform? {
        guard let storageValue else { return nil }
        return RidgitsSocialPlatform(rawValue: storageValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
    }
}

struct RidgitsSocialInfo: Equatable {
    let platform: RidgitsSocialPlatform?
    let handle: String

    var displayText: String {
        let trimmed = handle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        if let platform {
            return "\(platform.displayName) · \(trimmed)"
        }
        return trimmed
    }

    var isEmpty: Bool {
        handle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct RidgitsUserProfile: Identifiable, Equatable, Codable {
    let id: String
    var name: String
    var location: String
    var locationCity: String
    var locationStateCode: String
    var age: Int?
    var image: String
    var about: String
    var interests: [String]
    var aspirations: String
    var additionalImages: [String]
    var socialHandle: String
    var socialPlatform: RidgitsSocialPlatform?
    var ageRangeMin: Int?
    var ageRangeMax: Int?
    var subscriptionTier: String
    var profilePhotoVerified: Bool
    /// When false, the user is hidden from discovery and cannot send pokes or messages.
    var visibleInCommunity: Bool
    var completedQuizBadges: [RidgitsQuizBadge]

    var isCompleteForMatching: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && hasNormalizedLocation
            && age != nil
            && !image.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !about.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !interests.isEmpty
            && !aspirations.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var hasBasicProfile: Bool {
        !name.isEmpty && hasNormalizedLocation && age != nil
    }

    var hasNormalizedLocation: Bool {
        RidgitsUSLocations.normalize(city: locationCity, stateCode: locationStateCode) != nil
            || !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var socialInfo: RidgitsSocialInfo {
        RidgitsSocialInfo(platform: socialPlatform, handle: socialHandle)
    }

    mutating func normalizeSocialFields() {
        socialHandle = socialHandle.trimmingCharacters(in: .whitespacesAndNewlines)
        if socialHandle.isEmpty {
            socialPlatform = nil
            socialHandle = ""
        } else if socialPlatform == nil {
            socialHandle = ""
        }
    }

    static func empty(uid: String) -> RidgitsUserProfile {
        RidgitsUserProfile(
            id: uid, name: "", location: "", locationCity: "", locationStateCode: "", age: nil, image: "",
            about: "", interests: [], aspirations: "", additionalImages: [],
            socialHandle: "", socialPlatform: nil, ageRangeMin: nil, ageRangeMax: nil, subscriptionTier: "free",
            profilePhotoVerified: false,
            visibleInCommunity: true,
            completedQuizBadges: []
        )
    }

    static func from(uid: String, data: [String: Any]) -> RidgitsUserProfile {
        var location = data["location"] as? String ?? ""
        var locationCity = data["locationCity"] as? String ?? ""
        var locationStateCode = data["locationStateCode"] as? String ?? ""

        if locationCity.isEmpty || locationStateCode.isEmpty, !location.isEmpty {
            let parsed = RidgitsUSLocations.parse(location, city: locationCity, stateCode: locationStateCode)
            if locationCity.isEmpty { locationCity = parsed.city }
            if locationStateCode.isEmpty { locationStateCode = parsed.stateCode }
        }

        if let normalized = RidgitsUSLocations.normalize(city: locationCity, stateCode: locationStateCode) {
            locationCity = normalized.city
            locationStateCode = normalized.stateCode
            location = normalized.display
        }

        return RidgitsUserProfile(
            id: uid,
            name: data["name"] as? String ?? "",
            location: location,
            locationCity: locationCity,
            locationStateCode: locationStateCode,
            age: data["age"] as? Int ?? (data["age"] as? String).flatMap(Int.init),
            image: data["image"] as? String ?? "",
            about: data["about"] as? String ?? "",
            interests: data["interests"] as? [String] ?? [],
            aspirations: data["aspirations"] as? String ?? "",
            additionalImages: data["additionalImages"] as? [String] ?? [],
            socialHandle: data["socialHandle"] as? String ?? "",
            socialPlatform: RidgitsSocialPlatform.from(storageValue: data["socialPlatform"] as? String),
            ageRangeMin: data["ageRangeMin"] as? Int ?? (data["ageRangeMin"] as? String).flatMap(Int.init),
            ageRangeMax: data["ageRangeMax"] as? Int ?? (data["ageRangeMax"] as? String).flatMap(Int.init),
            subscriptionTier: data["subscriptionTier"] as? String ?? "free",
            profilePhotoVerified: data["profilePhotoVerified"] as? Bool ?? false,
            visibleInCommunity: data["visibleInCommunity"] as? Bool ?? true,
            completedQuizBadges: Self.parseCompletedQuizBadges(from: data)
        )
    }

    private static func parseCompletedQuizBadges(from data: [String: Any]) -> [RidgitsQuizBadge] {
        guard let raw = data["completedQuizBadges"] as? [[String: Any]] else { return [] }
        return raw.compactMap { RidgitsQuizBadge.from(data: $0) }
    }

    func ridgitSnapshot() -> [String: Any] {
        [
            "name": name,
            "location": location,
            "image": image,
            "socialHandle": socialHandle,
            "socialPlatform": socialPlatform?.rawValue as Any,
            "about": about,
            "interests": interests,
            "age": age as Any,
        ]
    }
}

struct RidgitQuestion: Identifiable, Equatable, Codable {
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

struct RidgitChallenge: Identifiable, Equatable, Codable {
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
    var sameMetro: Bool = false
    let compatibility: RidgitsCompatibility
    let about: String?
    let subscriptionTier: String?
    let profilePhotoVerified: Bool?

    var isProfilePhotoVerified: Bool {
        profilePhotoVerified == true
    }

    func withDistanceMiles(_ miles: Double?) -> RidgitsMatch {
        RidgitsMatch(
            id: id,
            userId: userId,
            name: name,
            image: image,
            location: location,
            distanceMiles: miles,
            sameMetro: sameMetro,
            compatibility: compatibility,
            about: about,
            subscriptionTier: subscriptionTier,
            profilePhotoVerified: profilePhotoVerified
        )
    }

    func withCompatibility(_ scores: RidgitsCompatibility) -> RidgitsMatch {
        RidgitsMatch(
            id: id,
            userId: userId,
            name: name,
            image: image,
            location: location,
            distanceMiles: distanceMiles,
            sameMetro: sameMetro,
            compatibility: scores,
            about: about,
            subscriptionTier: subscriptionTier,
            profilePhotoVerified: profilePhotoVerified
        )
    }
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

    static let empty = RidgitsCompatibility(
        overall: 0,
        communication: 0,
        intimacy: 0,
        values: 0,
        social: 0,
        commitment: 0
    )

    var hasScores: Bool {
        overall > 0
            || communication > 0
            || intimacy > 0
            || values > 0
            || social > 0
            || commitment > 0
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
    case declined
}

struct RidgitsConversation: Identifiable, Equatable, Codable, Hashable {
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
    let otherUserProfilePhotoVerified: Bool
    let unreadCount: Int
    let isIncomingPending: Bool
    let isOutgoingPending: Bool
    let isOutgoingDeclined: Bool
    var isArchived: Bool = false

    var isExpired: Bool {
        status == .expired || (expiresAt.map { $0 <= Date() } ?? false)
    }

    var messagesRemaining: Int {
        max(0, effectiveMaxMessages - messageCount)
    }

    var effectiveMaxMessages: Int {
        RidgitsMessagingLimits.maxMessages
    }

    var canSendMessage: Bool {
        status == .active && !isExpired && messageCount < effectiveMaxMessages
    }

    var isMessagingClosed: Bool {
        status == .expired || (status == .active && !canSendMessage)
    }

    var hitMessageLimit: Bool {
        messageCount >= effectiveMaxMessages
    }

    var isConversationExpired: Bool {
        status == .expired || isExpired
    }

    var closedStatusLabel: String {
        "Expired"
    }

    var inboxSubtitle: String {
        isMessagingClosed ? "Expired conversation" : (lastMessage ?? "No messages yet")
    }

    var messagingClosedUserMessage: String {
        if isConversationExpired {
            return "You can't message them — this conversation has already expired."
        }
        if hitMessageLimit {
            return "You can't message them — you've already hit the \(RidgitsMessagingLimits.maxMessages)-message limit for this conversation."
        }
        return "You can't message them — this conversation has already expired."
    }

    var messagingClosedThreadMessage: String {
        "Expired conversation"
    }

    func withArchived(_ archived: Bool) -> RidgitsConversation {
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
            otherUserName: otherUserName,
            otherUserImage: otherUserImage,
            otherUserSubscriptionTier: otherUserSubscriptionTier,
            otherUserProfilePhotoVerified: otherUserProfilePhotoVerified,
            unreadCount: unreadCount,
            isIncomingPending: isIncomingPending,
            isOutgoingPending: isOutgoingPending,
            isOutgoingDeclined: isOutgoingDeclined,
            isArchived: archived
        )
    }
}

struct RidgitsMessage: Identifiable, Equatable {
    let id: String
    let senderId: String
    let text: String
    let createdAt: Date
}

struct RidgitsMonthlyMessageQuota: Equatable {
    let periodKey: String
    let sentCount: Int
    let limit: Int?
    let remaining: Int?
    let unlimited: Bool
    let resetsAt: Date?
    let tier: String

    var canSend: Bool {
        unlimited || (remaining ?? 0) > 0
    }

    var displayLabel: String? {
        nil
    }

    static func fromDictionary(_ data: [String: Any]) -> RidgitsMonthlyMessageQuota? {
        guard let periodKey = data["periodKey"] as? String else { return nil }
        let sentCount = data["sentCount"] as? Int ?? 0
        let limit = data["limit"] as? Int
        let remaining = data["remaining"] as? Int
        let unlimited = data["unlimited"] as? Bool ?? (limit == nil)
        let tier = data["tier"] as? String ?? "free"
        let resetsAt: Date?
        if let iso = data["resetsAt"] as? String {
            resetsAt = ISO8601DateFormatter().date(from: iso)
        } else {
            resetsAt = nil
        }
        return RidgitsMonthlyMessageQuota(
            periodKey: periodKey,
            sentCount: sentCount,
            limit: limit,
            remaining: remaining,
            unlimited: unlimited,
            resetsAt: resetsAt,
            tier: tier
        )
    }
}

struct RidgitsPokeCredits: Equatable {
    let balance: Int
    let starterGrantApplied: Bool

    static func fromDictionary(_ data: [String: Any]) -> RidgitsPokeCredits? {
        guard let balance = data["balance"] as? Int else { return nil }
        return RidgitsPokeCredits(
            balance: balance,
            starterGrantApplied: data["starterGrantApplied"] as? Bool ?? false
        )
    }
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
    let userSubmitted: Bool
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
    var questionsAnswered: Int
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
        var status = ConversationStatus(rawValue: statusRaw) ?? .pending
        if (data["isExpired"] as? Bool) == true, status == .active {
            status = .expired
        }
        let approvals = data["approvals"] as? [String: Bool] ?? [:]
        let approvedByMe = approvals[currentUserId] == true
        let approvedByOther = approvals[otherUserId] == true
        let initiatorId = data["initiatorId"] as? String ?? participantIds.first ?? ""

        let otherUserName = participantString(other, keys: ["displayName", "name"]) ?? ""
        let otherUserImage = participantString(other, keys: ["imageUrl", "image", "photoUrl", "photoURL", "avatarUrl", "avatar"]) ?? ""
        let otherUserSubscriptionTier = other["subscriptionTier"] as? String
        let otherUserProfilePhotoVerified = other["profilePhotoVerified"] as? Bool ?? false
        let archivedBy = data["archivedBy"] as? [String] ?? []

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
            otherUserProfilePhotoVerified: otherUserProfilePhotoVerified,
            unreadCount: (data["unreadCounts"] as? [String: Int])?[currentUserId] ?? 0,
            isIncomingPending: status == .pending && initiatorId != currentUserId && !approvedByMe,
            isOutgoingPending: status == .pending && initiatorId == currentUserId && !approvedByOther,
            isOutgoingDeclined: status == .declined && initiatorId == currentUserId,
            isArchived: archivedBy.contains(currentUserId)
        )
    }

    func updatingOtherUser(
        name: String,
        image: String,
        subscriptionTier: String? = nil,
        profilePhotoVerified: Bool? = nil
    ) -> RidgitsConversation {
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
            otherUserProfilePhotoVerified: profilePhotoVerified ?? otherUserProfilePhotoVerified,
            unreadCount: unreadCount,
            isIncomingPending: isIncomingPending,
            isOutgoingPending: isOutgoingPending,
            isOutgoingDeclined: isOutgoingDeclined,
            isArchived: isArchived
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
            sameMetro: dict["sameMetro"] as? Bool ?? false,
            compatibility: parsedCompatibility,
            about: about,
            subscriptionTier: dict["subscriptionTier"] as? String,
            profilePhotoVerified: dict["profilePhotoVerified"] as? Bool
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
