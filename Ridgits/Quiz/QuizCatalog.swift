import Foundation
import SwiftUI

enum QuizMode {
    case onboarding
    case modify
}

enum QuizCategoryColors {
    static let track = Color(hex: 0xE5E7EB)

    static func color(for category: String) -> Color {
        switch category {
        case "Communication": return Color(hex: 0x5B9FB5)
        case "Intimacy": return Color(hex: 0xE76F6F)
        case "Values": return Color(hex: 0x6BA593)
        case "Social": return Color(hex: 0xD4A574)
        case "Commitment": return Color(hex: 0xB85C5C)
        default: return RidgitsColors.textMuted
        }
    }
}

enum QuizCatalog {
    private static let bundled: QuizBundle? = {
        guard let url = Bundle.main.url(forResource: "quiz_questions", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let bundle = try? JSONDecoder().decode(QuizBundle.self, from: data) else {
            return nil
        }
        return bundle
    }()

    private static let spicyBundled: SpicyQuizBundle? = {
        guard let url = Bundle.main.url(forResource: "quiz_spicy_questions", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let bundle = try? JSONDecoder().decode(SpicyQuizBundle.self, from: data) else {
            return nil
        }
        return bundle
    }()

    static var questions: [QuizQuestion] {
        let core = bundled?.questions.map { $0.asQuestion } ?? fallbackQuestions
        let existingIDs = Set(core.map(\.id))
        let spicy = spicyBundled?.questions
            .map { $0.asQuestion }
            .filter { !existingIDs.contains($0.id) } ?? []
        return core + spicy
    }

    static var spicyQuestionIDs: Set<String> {
        Set(spicyBundled?.questions.map(\.id) ?? [])
    }

    static var archetypes: [QuizArchetypeDefinition] {
        bundled?.archetypes ?? []
    }

    static let personalityCategories = [
        "Communication",
        "Intimacy",
        "Values",
        "Social",
        "Commitment",
    ]

    static let minimumAnswersToComplete = 53

    /// Logged-in users at or above this count skip the onboarding quiz shell.
    static let onboardingSkipThreshold = 50

    static func personalityAnsweredCount(in answers: [String: QuizAnswerRecord]) -> Int {
        answers.filter { key, record in
            guard record.hasAnswer else { return false }
            guard let question = questions.first(where: { $0.id == key }) else { return false }
            return question.category != "Demographics"
        }.count
    }

    /// Maps legacy numeric / `legacy_*` Firestore keys to canonical question IDs.
    static func normalizedQuestionId(forStorageKey key: String) -> String {
        if key.hasPrefix("legacy_") {
            let index = Int(key.dropFirst("legacy_".count)) ?? -1
            if index >= 0, index < questions.count {
                return questions[index].id
            }
            return key
        }
        if let first = key.first, first.isLetter {
            return key
        }
        if let index = Int(key), index >= 0, index < questions.count {
            return questions[index].id
        }
        return key
    }

    static func hasEnoughPersonalityAnswers(in answers: [String: QuizAnswerRecord]) -> Bool {
        personalityAnsweredCount(in: answers) >= onboardingSkipThreshold
    }

    static var personalityQuestionCount: Int {
        questions.filter { $0.category != "Demographics" }.count
    }

    /// Segment widths for the category progress bar.
    static func progressSegments(mode: QuizMode) -> [(category: String, count: Int)] {
        if mode == .onboarding {
            return personalityCategories.map { ($0, 10) }
        }

        return personalityCategories.map { category in
            let total = questions.filter { $0.category == category }.count
            return (category, max(total, 1))
        }
    }

    static func index(for questionID: String) -> Int? {
        questions.firstIndex { $0.id == questionID }
    }

    static func buildOrderedIndices(mode: QuizMode) -> [Int] {
        let all = questions.enumerated().map { $0.offset }
        switch mode {
        case .onboarding:
            var ordered: [Int] = []
            ordered.append(contentsOf: all.filter { questions[$0].category == "Demographics" })
            for category in personalityCategories {
                ordered.append(contentsOf: all.filter { questions[$0].category == category }.prefix(5))
            }
            for category in personalityCategories {
                ordered.append(contentsOf: all.filter { questions[$0].category == category }.dropFirst(5))
            }
            return ordered
        case .modify:
            var ordered: [Int] = []
            for category in personalityCategories {
                ordered.append(contentsOf: all.filter { questions[$0].category == category }.prefix(5))
            }
            for category in personalityCategories {
                ordered.append(contentsOf: all.filter { questions[$0].category == category }.dropFirst(5))
            }
            return ordered
        }
    }

    static func categoryCounts(in answers: [String: QuizAnswerRecord]) -> [String: (answered: Int, total: Int)] {
        var totals: [String: Int] = [:]
        var answered: [String: Int] = [:]
        for question in questions where question.category != "Demographics" {
            totals[question.category, default: 0] += 1
            if answers[question.id]?.hasAnswer == true {
                answered[question.category, default: 0] += 1
            }
        }
        var result: [String: (answered: Int, total: Int)] = [:]
        for category in personalityCategories {
            result[category] = (answered[category] ?? 0, totals[category] ?? 0)
        }
        return result
    }

    private static let fallbackQuestions: [QuizQuestion] = [
        QuizQuestion(
            id: "demo_000",
            category: "Demographics",
            text: "What is your gender?",
            options: [
                QuizOption(value: 0, label: "Woman"),
                QuizOption(value: 1, label: "Man"),
            ],
            multiSelect: true,
            isSpicy: false
        ),
    ]
}

private struct QuizBundle: Decodable {
    let questions: [QuizQuestionDTO]
    let archetypes: [QuizArchetypeDefinition]
}

private struct SpicyQuizBundle: Decodable {
    let questions: [QuizQuestionDTO]
}

private struct QuizQuestionDTO: Decodable {
    let id: String
    let category: String
    let text: String
    let multiSelect: Bool?
    let isSpicy: Bool?
    let options: [QuizOptionDTO]

    var asQuestion: QuizQuestion {
        QuizQuestion(
            id: id,
            category: category,
            text: text,
            options: options.map { QuizOption(value: $0.value, label: $0.label) },
            multiSelect: multiSelect ?? false,
            isSpicy: isSpicy ?? false
        )
    }
}

private struct QuizOptionDTO: Decodable {
    let value: Int
    let label: String
}

struct QuizArchetypeDefinition: Decodable, Equatable {
    let name: String
    let description: String
    let traits: [String]?
    let ideal_match: String?
    let growth_tip: String?

    var firestorePayload: [String: Any] {
        [
            "name": name,
            "description": description,
            "traits": traits ?? [],
            "ideal_match": ideal_match ?? "",
            "growth_tip": growth_tip ?? "",
        ]
    }
}

extension QuizAnswerRecord {
    var hasAnswer: Bool {
        if let answers, !answers.isEmpty { return true }
        return answer != nil
    }
}
