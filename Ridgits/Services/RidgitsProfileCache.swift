import CryptoKit
import Foundation
import UIKit

private struct CachedProfileRecord: Codable {
    var profile: RidgitsUserProfile
    var fetchedAt: Date
    var profileCode: String?
}

@MainActor
final class RidgitsProfileCache {
    static let shared = RidgitsProfileCache()

    /// Avoid hammering Firestore on every tab switch; refresh in the background when stale.
    private let refreshInterval: TimeInterval = 15 * 60

    private let fileManager = FileManager.default
    private var prefetchTasks: [String: Task<Void, Never>] = [:]

    private init() {
        try? ensureDirectories()
    }

    func profile(for uid: String) -> RidgitsUserProfile? {
        guard let record = loadRecord(for: uid) else { return nil }
        return record.profile
    }

    func profileCode(for uid: String) -> String? {
        guard let record = loadRecord(for: uid),
              let code = record.profileCode,
              !code.isEmpty else { return nil }
        return code
    }

    func isStale(uid: String) -> Bool {
        guard let record = loadRecord(for: uid) else { return true }
        return Date().timeIntervalSince(record.fetchedAt) > refreshInterval
    }

    func save(_ profile: RidgitsUserProfile) {
        var record = loadRecord(for: profile.id) ?? CachedProfileRecord(profile: profile, fetchedAt: Date())
        record.profile = profile
        record.fetchedAt = Date()
        writeRecord(record, for: profile.id)
        scheduleImagePrefetch(remoteURL: profile.image)
    }

    func saveProfileCode(_ code: String, uid: String) {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var record = loadRecord(for: uid) ?? CachedProfileRecord(
            profile: RidgitsUserProfile.empty(uid: uid),
            fetchedAt: .distantPast
        )
        record.profileCode = trimmed
        writeRecord(record, for: uid)
    }

    func clear(uid: String? = nil) {
        if let uid, let url = profileRecordURL(for: uid) {
            try? fileManager.removeItem(at: url)
        } else if uid == nil {
            try? fileManager.removeItem(at: profilesDirectory)
            try? fileManager.removeItem(at: imagesDirectory)
            try? ensureDirectories()
        }
        prefetchTasks.values.forEach { $0.cancel() }
        prefetchTasks.removeAll()
    }

    func localImageURL(for remoteURL: String) -> URL? {
        guard !remoteURL.isEmpty, remoteURL.hasPrefix("http") else { return nil }
        let fileURL = imageFileURL(for: remoteURL)
        return fileManager.fileExists(atPath: fileURL.path) ? fileURL : nil
    }

    /// Prefer a cached on-disk image; fall back to the remote URL string.
    func resolvedImageURLString(for remoteURL: String?) -> String? {
        guard let remoteURL, !remoteURL.isEmpty else { return nil }
        if let local = localImageURL(for: remoteURL) {
            return local.absoluteString
        }
        return remoteURL
    }

    func scheduleImagePrefetch(remoteURL: String) {
        guard !remoteURL.isEmpty, remoteURL.hasPrefix("http") else { return }
        if localImageURL(for: remoteURL) != nil { return }

        prefetchTasks[remoteURL]?.cancel()
        prefetchTasks[remoteURL] = Task {
            await prefetchImage(remoteURL: remoteURL)
            prefetchTasks[remoteURL] = nil
        }
    }

    func prefetchImage(remoteURL: String) async {
        guard !remoteURL.isEmpty,
              remoteURL.hasPrefix("http"),
              localImageURL(for: remoteURL) == nil,
              let remote = URL(string: remoteURL) else { return }

        do {
            let (data, response) = try await URLSession.shared.data(from: remote)
            guard !Task.isCancelled,
                  let http = response as? HTTPURLResponse,
                  (200 ... 299).contains(http.statusCode),
                  !data.isEmpty else { return }

            let destination = imageFileURL(for: remoteURL)
            try data.write(to: destination, options: .atomic)
        } catch {
            return
        }
    }

    func cachedUIImage(for remoteURL: String) -> UIImage? {
        guard let local = localImageURL(for: remoteURL),
              let data = try? Data(contentsOf: local) else { return nil }
        return UIImage(data: data)
    }

    // MARK: - Storage

    private var appSupportDirectory: URL {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Ridgits", isDirectory: true)
    }

    private var profilesDirectory: URL {
        appSupportDirectory.appendingPathComponent("Profiles", isDirectory: true)
    }

    private var imagesDirectory: URL {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("RidgitsProfileImages", isDirectory: true)
    }

    private func ensureDirectories() throws {
        try fileManager.createDirectory(at: profilesDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
    }

    private func profileRecordURL(for uid: String) -> URL? {
        profilesDirectory.appendingPathComponent("\(uid).json")
    }

    private func imageFileURL(for remoteURL: String) -> URL {
        imagesDirectory.appendingPathComponent("\(hash(remoteURL)).img")
    }

    private func loadRecord(for uid: String) -> CachedProfileRecord? {
        guard let url = profileRecordURL(for: uid),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(CachedProfileRecord.self, from: data)
    }

    private func writeRecord(_ record: CachedProfileRecord, for uid: String) {
        guard let url = profileRecordURL(for: uid),
              let data = try? JSONEncoder().encode(record) else { return }
        try? data.write(to: url, options: .atomic)
    }

    private func hash(_ value: String) -> String {
        let digest = SHA256.hash(data: Data(value.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
