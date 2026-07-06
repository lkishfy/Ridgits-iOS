import Foundation

enum QuizArchetypeCalculator {
    private static let dimensionKeys = ["communication", "intimacy", "values", "social", "commitment"]

    private static let dimensionVotes: [String: [String: String]] = [
        "communication": ["low": "thoughtful", "mid": "romantic", "high": "independent"],
        "intimacy": ["low": "adventurous", "mid": "cautious", "high": "independent"],
        "values": ["low": "practical", "mid": "freeSpirit", "high": "romantic"],
        "social": ["low": "adventurous", "mid": "thoughtful", "high": "cautious"],
        "commitment": ["low": "practical", "mid": "cautious", "high": "freeSpirit"],
    ]

    private static let archetypeMap: [String: Int] = [
        "romantic": 0,
        "thoughtful": 1,
        "independent": 2,
        "adventurous": 3,
        "cautious": 4,
        "practical": 5,
        "freeSpirit": 6,
    ]

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

        let dimensionAverages = dimensionKeys.map { average(groups[$0] ?? []) }
        let maxDeviation = dimensionAverages.map { abs($0 - 1.5) }.max() ?? 0
        let isBalanced = maxDeviation < 0.35

        if isBalanced, archetypes.count > 7 {
            return archetypes[7]
        }

        var primaryIndex = 0
        for index in 1..<dimensionAverages.count {
            if abs(dimensionAverages[index] - 1.5) > abs(dimensionAverages[primaryIndex] - 1.5) {
                primaryIndex = index
            }
        }

        let primaryDimension = dimensionKeys[primaryIndex]
        let primaryTertile = tertile(for: dimensionAverages[primaryIndex])
        guard let topArchetype = dimensionVotes[primaryDimension]?[primaryTertile],
              let index = archetypeMap[topArchetype],
              index < archetypes.count else {
            return archetypes.first
        }

        return archetypes[index]
    }

    private static func tertile(for average: Double) -> String {
        if average < 1.25 { return "low" }
        if average < 1.75 { return "mid" }
        return "high"
    }
}
