import Foundation

enum QuizArchetypeCalculator {
    static func calculate(answers: [String: QuizAnswerRecord], questions: [QuizQuestion]) -> QuizArchetypeDefinition? {
        let archetypes = QuizCatalog.archetypes
        guard !archetypes.isEmpty else { return nil }

        var groups: [String: [Double]] = [
            "communication": [],
            "intimacy": [],
            "values": [],
            "social": [],
            "commitment": [],
        ]

        for question in questions where question.category != "Demographics" {
            guard let record = answers[question.id], record.hasAnswer else { continue }
            let numeric: Double?
            if let multi = record.answers, !multi.isEmpty {
                numeric = Double(multi.reduce(0, +)) / Double(multi.count)
            } else if let single = record.answer {
                numeric = Double(single)
            } else {
                numeric = nil
            }
            guard let numeric else { continue }

            let key = question.category.lowercased()
            if key.contains("communication") {
                groups["communication", default: []].append(numeric)
            } else if key.contains("intimacy") {
                groups["intimacy", default: []].append(numeric)
            } else if key.contains("values") {
                groups["values", default: []].append(numeric)
            } else if key.contains("social") {
                groups["social", default: []].append(numeric)
            } else if key.contains("commitment") {
                groups["commitment", default: []].append(numeric)
            }
        }

        func average(_ values: [Double]) -> Double {
            guard !values.isEmpty else { return 1.5 }
            return values.reduce(0, +) / Double(values.count)
        }

        let avgComm = average(groups["communication"] ?? [])
        let avgIntimacy = average(groups["intimacy"] ?? [])
        let avgValues = average(groups["values"] ?? [])
        let avgSocial = average(groups["social"] ?? [])
        let avgCommit = average(groups["commitment"] ?? [])

        var scores: [String: Int] = [
            "romantic": 0,
            "thoughtful": 0,
            "independent": 0,
            "adventurous": 0,
            "cautious": 0,
            "practical": 0,
            "freeSpirit": 0,
        ]

        switch avgComm {
        case ...0.75: scores["thoughtful", default: 0] += 2
        case 0.75...1.5: scores["romantic", default: 0] += 2
        case 1.5...2.25: scores["independent", default: 0] += 2
        default: scores["freeSpirit", default: 0] += 2
        }

        switch avgIntimacy {
        case ...0.75: scores["adventurous", default: 0] += 2
        case 0.75...1.5: scores["romantic", default: 0] += 2
        case 1.5...2.25: scores["cautious", default: 0] += 2
        default: scores["independent", default: 0] += 2
        }

        switch avgValues {
        case ...0.75: scores["practical", default: 0] += 2
        case 0.75...1.5: scores["thoughtful", default: 0] += 2
        case 1.5...2.25: scores["freeSpirit", default: 0] += 2
        default: scores["adventurous", default: 0] += 2
        }

        switch avgSocial {
        case ...0.75: scores["adventurous", default: 0] += 2
        case 0.75...1.5: scores["practical", default: 0] += 2
        case 1.5...2.25: scores["cautious", default: 0] += 2
        default: scores["thoughtful", default: 0] += 2
        }

        switch avgCommit {
        case ...0.75: scores["practical", default: 0] += 2
        case 0.75...1.5: scores["cautious", default: 0] += 2
        case 1.5...2.25: scores["freeSpirit", default: 0] += 2
        default: scores["independent", default: 0] += 2
        }

        let maxScore = scores.values.max() ?? 0
        let minScore = scores.values.min() ?? 0
        let closeCount = scores.values.filter { $0 >= maxScore - 1 }.count
        let isBalanced = (maxScore - minScore) <= 1 && closeCount >= 4

        let map: [String: Int] = [
            "romantic": 0,
            "thoughtful": 1,
            "independent": 2,
            "adventurous": 3,
            "cautious": 4,
            "practical": 5,
            "freeSpirit": 6,
        ]

        if isBalanced, archetypes.count > 7 {
            return archetypes[7]
        }

        guard let top = scores.max(by: { $0.value < $1.value })?.key,
              let index = map[top],
              index < archetypes.count else {
            return archetypes.first
        }
        return archetypes[index]
    }
}
