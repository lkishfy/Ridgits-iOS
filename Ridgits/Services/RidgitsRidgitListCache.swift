import Foundation

struct CachedRidgitListRecord: Codable {
    var ridgits: [RidgitChallenge]
    var activeRidgitIds: [String]
    var fetchedAt: Date
}

@MainActor
final class RidgitsRidgitListCache {
    static let shared = RidgitsRidgitListCache()

    /// Avoid hammering Firestore on every tab switch; refresh in the background when stale.
    private let refreshInterval: TimeInterval = 15 * 60

    private let fileManager = FileManager.default

    private init() {
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    func record(for uid: String) -> CachedRidgitListRecord? {
        loadRecord(for: uid)
    }

    func ridgits(for uid: String) -> [RidgitChallenge]? {
        loadRecord(for: uid)?.ridgits
    }

    func activeRidgitIds(for uid: String) -> [String]? {
        loadRecord(for: uid)?.activeRidgitIds
    }

    func isStale(uid: String) -> Bool {
        guard let record = loadRecord(for: uid) else { return true }
        return Date().timeIntervalSince(record.fetchedAt) > refreshInterval
    }

    func save(ridgits: [RidgitChallenge], activeRidgitIds: [String], uid: String) {
        let record = CachedRidgitListRecord(
            ridgits: ridgits,
            activeRidgitIds: activeRidgitIds,
            fetchedAt: Date()
        )
        writeRecord(record, for: uid)
    }

    func updateActiveRidgitIds(_ ids: [String], uid: String) {
        guard var record = loadRecord(for: uid) else { return }
        record.activeRidgitIds = ids
        record.fetchedAt = Date()
        writeRecord(record, for: uid)
    }

    func clear(uid: String? = nil) {
        if let uid, let url = recordURL(for: uid) {
            try? fileManager.removeItem(at: url)
        } else if uid == nil {
            try? fileManager.removeItem(at: cacheDirectory)
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }

    private var cacheDirectory: URL {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Ridgits/RidgitLists", isDirectory: true)
    }

    private func recordURL(for uid: String) -> URL? {
        cacheDirectory.appendingPathComponent("\(uid).json")
    }

    private func loadRecord(for uid: String) -> CachedRidgitListRecord? {
        guard let url = recordURL(for: uid),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(CachedRidgitListRecord.self, from: data)
    }

    private func writeRecord(_ record: CachedRidgitListRecord, for uid: String) {
        guard let url = recordURL(for: uid),
              let data = try? JSONEncoder().encode(record) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
