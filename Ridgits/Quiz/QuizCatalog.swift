import Foundation

enum QuizMode {
    case onboarding
    case modify
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
