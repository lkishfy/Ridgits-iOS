import Foundation

private struct CachedConversationsRecord: Codable {
    var conversations: [RidgitsConversation]
    var fetchedAt: Date
}

@MainActor
final class RidgitsPublicProfileCache {
    static let shared = RidgitsPublicProfileCache()

    private let refreshInterval: TimeInterval = 15 * 60
    private var entries: [String: (profile: RidgitsUserProfile, fetchedAt: Date)] = [:]

    private init() {}

    func profile(for uid: String) -> RidgitsUserProfile? {
        guard let entry = entries[uid],
              Date().timeIntervalSince(entry.fetchedAt) <= refreshInterval else { return nil }
        return entry.profile
    }

    func save(_ profile: RidgitsUserProfile) {
        entries[profile.id] = (profile, Date())
        RidgitsProfileCache.shared.scheduleImagePrefetch(remoteURL: profile.image)
    }

    func clear() {
        entries.removeAll()
    }
}

@MainActor
final class RidgitsConversationsCache {
    static let shared = RidgitsConversationsCache()

    private let fileManager = FileManager.default

    private init() {
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    func conversations(for uid: String) -> [RidgitsConversation]? {
        loadRecord(for: uid)?.conversations
    }

    func save(_ conversations: [RidgitsConversation], uid: String) {
        let record = CachedConversationsRecord(conversations: conversations, fetchedAt: Date())
        guard let data = try? JSONEncoder().encode(record) else { return }
        let url = cacheDirectory.appendingPathComponent("\(uid).json")
        try? data.write(to: url, options: .atomic)
    }

    func clear(uid: String? = nil) {
        if let uid {
            try? fileManager.removeItem(at: cacheDirectory.appendingPathComponent("\(uid).json"))
        } else {
            try? fileManager.removeItem(at: cacheDirectory)
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }

    private var cacheDirectory: URL {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Ridgits/Conversations", isDirectory: true)
    }

    private func loadRecord(for uid: String) -> CachedConversationsRecord? {
        let url = cacheDirectory.appendingPathComponent("\(uid).json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(CachedConversationsRecord.self, from: data)
    }
}
