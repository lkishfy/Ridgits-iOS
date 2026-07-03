import Foundation
import FirebaseAuth

@MainActor
final class QuizViewModel: ObservableObject {
    @Published var currentIndex = 0
    @Published var answers: [String: QuizAnswerRecord] = [:]
    @Published var showPreferenceSheet = false
    @Published var isSaving = false
    @Published var didComplete = false
    @Published var errorMessage: String?

    let questions = QuizCatalog.questions

    var currentQuestion: QuizQuestion {
        questions[currentIndex]
    }

    var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentIndex + 1) / Double(questions.count)
    }

    var isLastQuestion: Bool {
        currentIndex >= questions.count - 1
    }

    func recordAnswer(optionValue: Int) {
        let question = currentQuestion
        if question.multiSelect {
            var record = answers[question.id] ?? QuizAnswerRecord(
                preferredAnswers: [optionValue], importance: QuizImportance.aLittle.rawValue, dealbreaker: false
            )
            var selected = Set(record.answers ?? [])
            if selected.contains(optionValue) {
                selected.remove(optionValue)
            } else {
                selected.insert(optionValue)
            }
            record.answers = Array(selected).sorted()
            record.preferredAnswers = record.answers ?? []
            answers[question.id] = record
        } else {
            answers[question.id] = QuizAnswerRecord(
                answer: optionValue,
                preferredAnswers: [optionValue],
                importance: QuizImportance.aLittle.rawValue,
                dealbreaker: false
            )
            showPreferenceSheet = true
        }
    }

    func updatePreference(preferred: Set<Int>, importance: QuizImportance, dealbreaker: Bool) {
        let questionId = currentQuestion.id
        guard var record = answers[questionId] else { return }
        record.preferredAnswers = Array(preferred).sorted()
        record.importance = importance.rawValue
        record.dealbreaker = dealbreaker
        answers[questionId] = record
        showPreferenceSheet = false
    }

    func goNext() {
        guard canAdvance else { return }
        if isLastQuestion {
            Task { await completeQuiz() }
        } else {
            currentIndex += 1
        }
    }

    func goBack() {
        currentIndex = max(0, currentIndex - 1)
    }

    var canAdvance: Bool {
        guard let record = answers[currentQuestion.id] else { return false }
        if currentQuestion.multiSelect {
            return !(record.answers ?? []).isEmpty
        }
        return record.answer != nil && !showPreferenceSheet
    }

    func completeQuiz() async {
        guard let uid = AuthBridge.currentUID else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            try await RidgitsFirebaseClient.shared.saveQuizProgress(
                uid: uid,
                answers: answers,
                currentIndex: currentIndex,
                completed: true
            )
            didComplete = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private enum AuthBridge {
    static var currentUID: String? { Auth.auth().currentUser?.uid }
}
