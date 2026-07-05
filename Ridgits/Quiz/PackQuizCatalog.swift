import Foundation

struct PackQuizBundle: Decodable {
    let id: String
    let questions: [PackQuizQuestionDTO]
    let archetypes: [PackArchetypeDTO]
}

struct PackQuizQuestionDTO: Decodable {
    let id: String
    let category: String
    let text: String
    let options: [PackQuizOptionDTO]
}

struct PackArchetypeDTO: Decodable {
    let name: String
    let description: String
    let characteristics: [String]?
    let suggestions: [String]?
    let traits: [String]?
    let ideal_match: String?
    let growth_tip: String?
}

struct PackQuizOptionDTO: Decodable {
    let value: Int
    let label: String
}

enum PackQuizCatalog {
    static func bundle(for packId: String) -> PackQuizBundle? {
        guard let url = Bundle.main.url(forResource: packId, withExtension: "json", subdirectory: "Quiz/Packs")
            ?? Bundle.main.url(forResource: packId, withExtension: "json") else {
            return nil
        }
        guard let data = try? Data(contentsOf: url),
              let bundle = try? JSONDecoder().decode(PackQuizBundle.self, from: data) else {
            return nil
        }
        return bundle
    }

    static func questions(for packId: String) -> [QuizQuestion] {
        guard let bundle = bundle(for: packId) else { return [] }
        return bundle.questions.map {
            QuizQuestion(
                id: $0.id,
                category: $0.category,
                text: $0.text,
                options: $0.options.map { QuizOption(value: $0.value, label: $0.label) },
                multiSelect: false,
                isSpicy: false,
                userSubmitted: false
            )
        }
    }
}

struct PackQuizScoredResult: Equatable {
    let archetype: RidgitsPackArchetypeResult
    let categoryScores: [String: Double]
}

struct PackQuizSavedState: Equatable {
    var answers: [String: Int] = [:]
    var result: PackQuizScoredResult?
}

struct PackQuizPresentation: Identifiable {
    let id: String
    let pack: RidgitsArchetypePack
    var forceRetake: Bool = false
}
