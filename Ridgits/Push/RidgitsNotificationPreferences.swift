import Foundation

struct RidgitsNotificationPreferences: Codable, Equatable {
    var pushEnabled: Bool = true
    var pokes: Bool = true
    var messages: Bool = true
    var messageRequests: Bool = true
    var conversationExpiring: Bool = true
    var conversationApproved: Bool = true
    var nearby: Bool = true
    var ridgits: Bool = true
    var reEngagement: Bool = true
    var marketing: Bool = false

    static func fromDictionary(_ data: [String: Any]) -> RidgitsNotificationPreferences {
        RidgitsNotificationPreferences(
            pushEnabled: data["pushEnabled"] as? Bool ?? true,
            pokes: data["pokes"] as? Bool ?? true,
            messages: data["messages"] as? Bool ?? true,
            messageRequests: data["messageRequests"] as? Bool ?? true,
            conversationExpiring: data["conversationExpiring"] as? Bool ?? true,
            conversationApproved: data["conversationApproved"] as? Bool ?? true,
            nearby: data["nearby"] as? Bool ?? true,
            ridgits: data["ridgits"] as? Bool ?? true,
            reEngagement: data["reEngagement"] as? Bool ?? true,
            marketing: data["marketing"] as? Bool ?? false
        )
    }

    func asDictionary() -> [String: Bool] {
        [
            "pushEnabled": pushEnabled,
            "pokes": pokes,
            "messages": messages,
            "messageRequests": messageRequests,
            "conversationExpiring": conversationExpiring,
            "conversationApproved": conversationApproved,
            "nearby": nearby,
            "ridgits": ridgits,
            "reEngagement": reEngagement,
            "marketing": marketing,
        ]
    }
}
