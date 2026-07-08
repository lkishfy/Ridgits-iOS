import Foundation

enum RidgitsMessagingValidation {
    private static let phonePatterns: [String] = [
        #"(?i)\b(?:\+?1[-.\s]?)?(?:\(\d{3}\)|\d{3})[-.\s]?\d{3}[-.\s]?\d{4}\b"#,
        #"\b(?:\d[\s.\-()]*){7,}\d\b"#,
    ]

    static func containsPhoneNumber(_ text: String) -> Bool {
        phonePatterns.contains { pattern in
            guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            return regex.firstMatch(in: text, range: range) != nil
        }
    }

    static func isTooEarlyForPhoneNumber(messageCount: Int) -> Bool {
        messageCount < RidgitsMessagingLimits.earlyPhoneMessageThreshold
    }

    static func blocksEarlyPhoneNumber(text: String, messageCount: Int) -> Bool {
        isTooEarlyForPhoneNumber(messageCount: messageCount) && containsPhoneNumber(text)
    }
}
