import Foundation

private struct CachedMatchesRecord: Codable {
    var matches: [RidgitsMatch]
    var fetchedAt: Date
}

struct CachedNearbyPoolRecord: Codable {
    var matches: [RidgitsMatch]
    var closeMatchCount: Int
    var poolRadius: Int
    var poolAccessKey: String
    var fetchedAt: Date
}

@MainActor
final class RidgitsMatchesCache {
    static let shared = RidgitsMatchesCache()

    private let refreshInterval: TimeInterval = 15 * 60
    private let fileManager = FileManager.default

    private init() {
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    func nationwide(for uid: String, limit: Int) -> [RidgitsMatch]? {
        if let record = loadRecord(filename: nationwideFilename(uid: uid, limit: limit)) {
            return record.matches
        }
        if limit < 10, let record = loadRecord(filename: nationwideFilename(uid: uid, limit: 10)) {
            return Array(record.matches.prefix(limit))
        }
        return nil
    }

    func isNationwideStale(uid: String, limit: Int) -> Bool {
        if let record = loadRecord(filename: nationwideFilename(uid: uid, limit: limit)) {
            return isStale(record)
        }
        if limit < 10, let record = loadRecord(filename: nationwideFilename(uid: uid, limit: 10)) {
            return isStale(record)
        }
        return true
    }

    func saveNationwide(_ matches: [RidgitsMatch], uid: String, limit: Int) {
        save(matches, filename: nationwideFilename(uid: uid, limit: limit))
        prefetchImages(for: matches)
    }

    func nearby(for uid: String, maxDistance: Int) -> [RidgitsMatch]? {
        loadRecord(filename: nearbyFilename(uid: uid, maxDistance: maxDistance))?.matches
    }

    func isNearbyStale(uid: String, maxDistance: Int) -> Bool {
        guard let record = loadRecord(filename: nearbyFilename(uid: uid, maxDistance: maxDistance)) else {
            return true
        }
        return isStale(record)
    }

    func hasNationwide(uid: String, limit: Int) -> Bool {
        if loadRecord(filename: nationwideFilename(uid: uid, limit: limit)) != nil {
            return true
        }
        if limit < 10, loadRecord(filename: nationwideFilename(uid: uid, limit: 10)) != nil {
            return true
        }
        return false
    }

    func hasNearby(uid: String, maxDistance: Int) -> Bool {
        loadRecord(filename: nearbyFilename(uid: uid, maxDistance: maxDistance)) != nil
    }

    func saveNearby(_ matches: [RidgitsMatch], uid: String, maxDistance: Int) {
        save(matches, filename: nearbyFilename(uid: uid, maxDistance: maxDistance))
        prefetchImages(for: matches)
    }

    func nearbyPool(for uid: String) -> CachedNearbyPoolRecord? {
        loadPoolRecord(filename: poolFilename(uid: uid))
    }

    func isNearbyPoolStale(uid: String) -> Bool {
        guard let record = nearbyPool(for: uid) else { return true }
        return isStale(record.fetchedAt)
    }

    func saveNearbyPool(
        _ matches: [RidgitsMatch],
        closeMatchCount: Int,
        poolRadius: Int,
        poolAccessKey: String,
        uid: String
    ) {
        let record = CachedNearbyPoolRecord(
            matches: matches,
            closeMatchCount: closeMatchCount,
            poolRadius: poolRadius,
            poolAccessKey: poolAccessKey,
            fetchedAt: Date()
        )
        guard let data = try? JSONEncoder().encode(record) else { return }
        let url = cacheDirectory.appendingPathComponent(poolFilename(uid: uid))
        try? data.write(to: url, options: .atomic)
        prefetchImages(for: matches)
    }

    func clear(uid: String? = nil) {
        guard let uid else {
            try? fileManager.removeItem(at: cacheDirectory)
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            return
        }

        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) else {
            return
        }
        for file in files where file.lastPathComponent.hasPrefix("\(uid)_") {
            try? fileManager.removeItem(at: file)
        }
    }

    func clearNearbyPool(uid: String) {
        try? fileManager.removeItem(at: cacheDirectory.appendingPathComponent(poolFilename(uid: uid)))
    }

    func clearNationwide(uid: String) {
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) else {
            return
        }
        for file in files where file.lastPathComponent.hasPrefix("\(uid)_nationwide_") {
            try? fileManager.removeItem(at: file)
        }
    }

    // MARK: - Private

    private var cacheDirectory: URL {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Ridgits/Matches", isDirectory: true)
    }

    private func nationwideFilename(uid: String, limit: Int) -> String {
        "\(uid)_nationwide_\(limit).json"
    }

    private func nearbyFilename(uid: String, maxDistance: Int) -> String {
        "\(uid)_nearby_\(maxDistance).json"
    }

    private func poolFilename(uid: String) -> String {
        "\(uid)_nearby_pool.json"
    }

    private func loadPoolRecord(filename: String) -> CachedNearbyPoolRecord? {
        let url = cacheDirectory.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(CachedNearbyPoolRecord.self, from: data)
    }

    private func loadRecord(filename: String) -> CachedMatchesRecord? {
        let url = cacheDirectory.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(CachedMatchesRecord.self, from: data)
    }

    private func save(_ matches: [RidgitsMatch], filename: String) {
        let record = CachedMatchesRecord(matches: matches, fetchedAt: Date())
        guard let data = try? JSONEncoder().encode(record) else { return }
        let url = cacheDirectory.appendingPathComponent(filename)
        try? data.write(to: url, options: .atomic)
    }

    private func isStale(_ record: CachedMatchesRecord) -> Bool {
        isStale(record.fetchedAt)
    }

    private func isStale(_ fetchedAt: Date) -> Bool {
        Date().timeIntervalSince(fetchedAt) > refreshInterval
    }

    private func prefetchImages(for matches: [RidgitsMatch]) {
        for match in matches {
            RidgitsProfileCache.shared.scheduleImagePrefetch(remoteURL: match.image)
        }
    }
}
