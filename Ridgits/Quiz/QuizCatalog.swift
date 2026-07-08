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

    /// Question IDs contributed by the Ridgits community (mirrors web `quizData.js` userSubmitted flags).
    static let communityQuestionIDs: Set<String> = [
        "intim_020",
        "vals_004",
        "vals_014",
        "vals_016",
        "vals_022",
        "vals_023",
        "vals_031",
        "vals_035",
        "vals_036",
        "socl_018",
        "comt_020",
        "vals_037",
        "vals_038",
        "social_024",
        "intm_023",
        "vals_039",
        "vals_041",
        "social_025",
        "comt_025",
        "vals_043",
        "intm_025",
        "comt_021",
        "comt_022",
        "comt_024",
        "socl_022",
        "comt_026",
        "vals_044",
        "comm_020",
        "socl_023",
        "socl_024",
        "vals_045",
        "vals_046",
        "socl_025",
        "comm_021",
        "socl_026"
    ]

    static func isCommunityQuestion(id: String) -> Bool {
        communityQuestionIDs.contains(id)
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

    /// Enough personality answers to unlock results / matching (mirrors API threshold).
    static let onboardingSkipThreshold = minimumAnswersToComplete

    static let onboardingQuestionsPerCategory = 10
    static let onboardingPersonalityQuestionCount = onboardingQuestionsPerCategory * personalityCategories.count
    static let onboardingTotalQuestionCount = demographicQuestionIDs.count + onboardingPersonalityQuestionCount

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
        personalityAnsweredCount(in: answers) >= minimumAnswersToComplete
    }

    static var personalityQuestionCount: Int {
        questions.filter { $0.category != "Demographics" }.count
    }

    static let demographicQuestionIDs = ["demo_000", "demo_001", "demo_002"]

    static var demographicQuestions: [QuizQuestion] {
        demographicQuestionIDs.compactMap { id in questions.first { $0.id == id } }
    }

    static func selectedOptionValues(from record: QuizAnswerRecord?) -> [Int] {
        guard let record else { return [] }
        if let answers = record.answers, !answers.isEmpty { return answers }
        if let answer = record.answer { return [answer] }
        return []
    }

    static func labels(for values: [Int], in question: QuizQuestion) -> [String] {
        values.compactMap { value in
            question.options.first { $0.value == value }?.label
        }
    }

    /// Segment widths for the category progress bar.
    static func progressSegments(mode: QuizMode) -> [(category: String, count: Int)] {
        personalityCategories.map { category in
            if mode == .onboarding {
                return (category, onboardingQuestionsPerCategory)
            }
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
                ordered.append(contentsOf: all.filter { questions[$0].category == category }.prefix(onboardingQuestionsPerCategory))
            }
            return ordered
        case .modify:
            var ordered: [Int] = []
            for category in personalityCategories {
                ordered.append(contentsOf: all.filter { questions[$0].category == category }.prefix(10))
            }
            for category in personalityCategories {
                ordered.append(contentsOf: all.filter { questions[$0].category == category }.dropFirst(10))
            }
            return ordered
        }
    }

    static func categoryCounts(
        in answers: [String: QuizAnswerRecord],
        mode: QuizMode = .modify,
        orderedIndices: [Int]? = nil
    ) -> [String: (answered: Int, total: Int)] {
        var totals: [String: Int] = [:]
        var answered: [String: Int] = [:]

        let scopedQuestions: [QuizQuestion]
        if mode == .onboarding, let orderedIndices {
            scopedQuestions = orderedIndices.map { questions[$0] }.filter { $0.category != "Demographics" }
        } else {
            scopedQuestions = questions.filter { $0.category != "Demographics" }
        }

        for question in scopedQuestions {
            totals[question.category, default: 0] += 1
            if answers[question.id]?.hasAnswer == true {
                answered[question.category, default: 0] += 1
            }
        }

        var result: [String: (answered: Int, total: Int)] = [:]
        for category in personalityCategories {
            let total = mode == .onboarding
                ? onboardingQuestionsPerCategory
                : (totals[category] ?? 0)
            result[category] = (answered[category] ?? 0, total)
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
            isSpicy: false,
            userSubmitted: false
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
    let userSubmitted: Bool?
    let options: [QuizOptionDTO]

    var asQuestion: QuizQuestion {
        QuizQuestion(
            id: id,
            category: category,
            text: text,
            options: options.map { QuizOption(value: $0.value, label: $0.label) },
            multiSelect: multiSelect ?? false,
            isSpicy: isSpicy ?? false,
            userSubmitted: userSubmitted ?? QuizCatalog.isCommunityQuestion(id: id)
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
