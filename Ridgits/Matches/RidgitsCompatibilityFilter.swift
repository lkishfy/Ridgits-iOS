import Foundation

struct RidgitsCompatibilityFilter: Equatable {
    var minOverall = 0
    var minValues = 0
    var minCommunication = 0
    var minIntimacy = 0
    var minSocial = 0
    var minCommitment = 0

    var isActive: Bool {
        minOverall > 0
            || minValues > 0
            || minCommunication > 0
            || minIntimacy > 0
            || minSocial > 0
            || minCommitment > 0
    }

    mutating func reset() {
        self = RidgitsCompatibilityFilter()
    }

    func includes(_ match: RidgitsMatch) -> Bool {
        let scores = match.compatibility
        return scores.overall >= minOverall
            && scores.values >= minValues
            && scores.communication >= minCommunication
            && scores.intimacy >= minIntimacy
            && scores.social >= minSocial
            && scores.commitment >= minCommitment
    }

    func filtered(_ matches: [RidgitsMatch]) -> [RidgitsMatch] {
        guard isActive else { return matches }
        return matches.filter { includes($0) }
    }
}

enum RidgitsCompatibilityFilterDimension: CaseIterable, Identifiable {
    case overall
    case values
    case communication
    case intimacy
    case social
    case commitment

    var id: Self { self }

    var title: String {
        switch self {
        case .overall: return "Overall"
        case .values: return "Values"
        case .communication: return "Communication"
        case .intimacy: return "Relational Depth"
        case .social: return "Social"
        case .commitment: return "Life Direction"
        }
    }

    func minimum(from filter: RidgitsCompatibilityFilter) -> Int {
        switch self {
        case .overall: return filter.minOverall
        case .values: return filter.minValues
        case .communication: return filter.minCommunication
        case .intimacy: return filter.minIntimacy
        case .social: return filter.minSocial
        case .commitment: return filter.minCommitment
        }
    }

    func setMinimum(_ value: Int, on filter: inout RidgitsCompatibilityFilter) {
        let stepped = Int((Double(value) / 5.0).rounded() * 5)
        switch self {
        case .overall: filter.minOverall = stepped
        case .values: filter.minValues = stepped
        case .communication: filter.minCommunication = stepped
        case .intimacy: filter.minIntimacy = stepped
        case .social: filter.minSocial = stepped
        case .commitment: filter.minCommitment = stepped
        }
    }
}
