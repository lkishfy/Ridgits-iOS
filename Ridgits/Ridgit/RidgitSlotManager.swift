import Foundation

/// Tracks which custom Ridgits are "active" for the user's current membership slot limit.
enum RidgitSlotManager {
    static func isActive(ridgitId: String, activeIds: [String]) -> Bool {
        activeIds.contains(ridgitId)
    }

    static func inactiveRidgits(from all: [RidgitChallenge], activeIds: [String]) -> [RidgitChallenge] {
        all.filter { !activeIds.contains($0.id) }
    }

    static func activeRidgits(from all: [RidgitChallenge], activeIds: [String]) -> [RidgitChallenge] {
        let idSet = Set(activeIds)
        return all.filter { idSet.contains($0.id) }
    }

    /// User must pick which Ridgits stay active when over the tier limit (e.g. after downgrade).
    static func needsSelection(
        ridgits: [RidgitChallenge],
        activeIds: [String],
        limit: Int
    ) -> Bool {
        guard limit > 0 else { return false }
        let validActive = activeIds.filter { id in ridgits.contains(where: { $0.id == id }) }
        if validActive.count > limit { return true }
        if validActive.isEmpty && ridgits.count > limit { return true }
        return false
    }

    /// Newest-first default when under limit and nothing selected yet.
    static func defaultActiveIds(from ridgits: [RidgitChallenge], limit: Int) -> [String] {
        Array(ridgits.prefix(max(0, limit)).map(\.id))
    }

    static func sanitizedActiveIds(
        _ activeIds: [String],
        ridgits: [RidgitChallenge],
        limit: Int
    ) -> [String] {
        let valid = activeIds.filter { id in ridgits.contains(where: { $0.id == id }) }
        if valid.count <= limit { return valid }
        return Array(valid.prefix(limit))
    }
}
