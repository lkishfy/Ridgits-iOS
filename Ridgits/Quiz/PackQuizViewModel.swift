import Foundation
import FirebaseAuth

@MainActor
final class PackQuizViewModel: ObservableObject {
    let pack: RidgitsArchetypePack
    let questions: [QuizQuestion]

    @Published var currentIndex = 0
    @Published var answers: [String: Int] = [:]
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var showResults = false
    @Published var result: PackQuizScoredResult?
    @Published var errorMessage: String?

    init(pack: RidgitsArchetypePack) {
        self.pack = pack
        self.questions = PackQuizCatalog.questions(for: pack.id)
    }

    var currentQuestion: QuizQuestion {
        questions[max(0, min(currentIndex, questions.count - 1))]
    }

    var progressFraction: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentIndex + 1) / Double(questions.count)
    }

    var answeredCount: Int {
        questions.filter { answers[$0.id] != nil }.count
    }

    var isComplete: Bool {
        questions.allSatisfy { answers[$0.id] != nil }
    }

    var isFirst: Bool { currentIndex == 0 }
    var isLast: Bool { currentIndex >= questions.count - 1 }

    func bootstrap(forceRetake: Bool = false) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            if forceRetake {
                showResults = false
                result = nil
                currentIndex = 0
                answers = [:]
                errorMessage = nil
                return
            }

            let saved = try await RidgitsFirebaseClient.shared.fetchPackQuizState(uid: uid, pack: pack)
            if let savedResult = saved.result {
                result = savedResult
                answers = saved.answers
                showResults = true
                return
            }
            answers = saved.answers
            if let firstUnanswered = questions.firstIndex(where: { answers[$0.id] == nil }) {
                currentIndex = firstUnanswered
            } else {
                currentIndex = 0
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectAnswer(_ value: Int) {
        answers[currentQuestion.id] = value
        guard !isLast else { return }
        currentIndex += 1
    }

    func goBack() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
    }

    func goForward() {
        guard currentIndex < questions.count - 1 else { return }
        currentIndex += 1
    }

    func submit() async {
        guard isComplete else { return }
        isSaving = true
        defer { isSaving = false }

        guard let scored = PackQuizScoring.calculate(packId: pack.id, answers: answers) else {
            errorMessage = "Could not calculate your results. Please try again."
            return
        }

        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "You must be signed in to save results."
            return
        }

        do {
            try await RidgitsFirebaseClient.shared.savePackQuizResults(
                uid: uid,
                pack: pack,
                answers: answers,
                result: scored
            )
            result = scored
            showResults = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
