import Foundation
import OSLog

enum RidgitsFirestoreIndexErrorLogging {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.ridgits.app",
        category: "FirestoreIndex"
    )

    static func logIfMissingIndex(_ error: Error, context: String) {
        logIfMissingIndex(error.localizedDescription, context: context)
    }

    static func logIfMissingIndex(_ message: String, context: String) {
        guard isMissingIndexMessage(message) else { return }

        if let url = extractFirestoreIndexURL(from: message) {
            logger.error("[\(context, privacy: .public)] Missing Firestore index — create it here: \(url, privacy: .public)")
            print("[Ridgits][FirestoreIndex][\(context)] \(url)")
        } else {
            logger.error("[\(context, privacy: .public)] Missing Firestore index: \(message, privacy: .public)")
            print("[Ridgits][FirestoreIndex][\(context)] \(message)")
        }
    }

    private static func isMissingIndexMessage(_ message: String) -> Bool {
        let normalized = message.lowercased()
        return normalized.contains("requires an index")
            || normalized.contains("failed_precondition")
    }

    private static func extractFirestoreIndexURL(from message: String) -> String? {
        guard let range = message.range(
            of: #"https://console\.firebase\.google\.com[^\s\]]+"#,
            options: .regularExpression
        ) else {
            return nil
        }
        return String(message[range])
    }
}
