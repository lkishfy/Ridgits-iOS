import Foundation
import FirebaseAuth

enum QuizCardViewMode: String, CaseIterable, Identifiable {
    case card
    case list

    var id: String { rawValue }

    var label: String {
        switch self {
        case .card: return "Card"
        case .list: return "List"
        }
    }
}

@MainActor
final class QuizViewModel: ObservableObject {
    let mode: QuizMode
    let questions = QuizCatalog.questions

    @Published var orderedIndices: [Int]
    @Published var activePool: [Int]
    @Published var poolPosition = 0
    @Published var answers: [String: QuizAnswerRecord] = [:]
    @Published var activeMultiSelect: Set<String> = []
    @Published var freePassesRemaining = 3
    @Published var hideAnsweredQuestions = false
    @Published var selectedCategory: String?
    @Published var cardViewMode: QuizCardViewMode = .card
    @Published var showPreferenceSheet = false
    @Published var isSaving = false
    @Published var isLoading = false
    @Published var didComplete = false
    @Published var errorMessage: String?

    init(mode: QuizMode = .onboarding) {
        self.mode = mode
        let ordered = QuizCatalog.buildOrderedIndices(mode: mode)
        self.orderedIndices = ordered
        self.activePool = ordered
    }

    var currentQuestionIndex: Int {
        guard poolPosition >= 0, poolPosition < activePool.count else { return 0 }
        return activePool[poolPosition]
    }

    var currentQuestion: QuizQuestion {
        questions[currentQuestionIndex]
    }

    var answeredCount: Int {
        answers.values.filter(\.hasAnswer).count
    }

    var personalityAnsweredCount: Int {
        answers.filter { key, record in
            guard record.hasAnswer else { return false }
            return questions.first(where: { $0.id == key })?.category != "Demographics"
        }.count
    }

    var remainingCount: Int {
        max(0, activePool.count - poolPosition - 1)
    }

    var canShowCategoryNav: Bool {
        mode == .modify || personalityAnsweredCount >= 50
    }

    var categoryProgress: [String: (answered: Int, total: Int)] {
        QuizCatalog.categoryCounts(in: answers)
    }

    var progressFraction: Double {
        guard !activePool.isEmpty else { return 0 }
        return Double(poolPosition + 1) / Double(activePool.count)
    }

    var isLastInPool: Bool {
        poolPosition >= activePool.count - 1
    }

    var canFinish: Bool {
        personalityAnsweredCount >= QuizCatalog.minimumAnswersToComplete
    }

    func bootstrap() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            if let progress = try await RidgitsFirebaseClient.shared.fetchQuizProgress(uid: uid) {
                answers = progress.answers
                freePassesRemaining = progress.freePassesRemaining
                if mode == .modify {
                    poolPosition = min(progress.currentQuestion, max(activePool.count - 1, 0))
                } else if progress.currentQuestion > 0 {
                    poolPosition = min(progress.currentQuestion, max(activePool.count - 1, 0))
                }
            }
            refreshActivePool()
            syncFreePasses()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshActivePool() {
        if let selectedCategory {
            activePool = orderedIndices.filter { index in
                let question = questions[index]
                guard question.category == selectedCategory else { return false }
                if hideAnsweredQuestions, answers[question.id]?.hasAnswer == true { return false }
                return true
            }
        } else if hideAnsweredQuestions {
            activePool = orderedIndices.filter { index in
                answers[questions[index].id]?.hasAnswer != true
            }
        } else {
            activePool = orderedIndices
        }
        poolPosition = min(poolPosition, max(activePool.count - 1, 0))
    }

    func selectCategory(_ category: String?) {
        selectedCategory = category
        poolPosition = 0
        refreshActivePool()
    }

    func toggleHideAnswered(_ hidden: Bool) {
        hideAnsweredQuestions = hidden
        poolPosition = 0
        refreshActivePool()
    }

    func isSelected(_ value: Int, for question: QuizQuestion) -> Bool {
        guard let record = answers[question.id] else { return false }
        if isMultiSelectActive(for: question) || question.multiSelect {
            return (record.answers ?? []).contains(value)
        }
        return record.answer == value
    }

    func isMultiSelectActive(for question: QuizQuestion) -> Bool {
        question.multiSelect || activeMultiSelect.contains(question.id) || (answers[question.id]?.answers?.count ?? 0) > 1
    }

    func canActivateMultiSelect(for question: QuizQuestion) -> Bool {
        !question.multiSelect && question.category != "Demographics" && freePassesRemaining > 0
    }

    func activateMultiSelect(for question: QuizQuestion) {
        guard canActivateMultiSelect(for: question) else { return }
        activeMultiSelect.insert(question.id)
        if var record = answers[question.id], let single = record.answer, (record.answers ?? []).isEmpty {
            record.answers = [single]
            record.answer = nil
            answers[question.id] = record
        }
    }

    func toggleDealbreaker(for question: QuizQuestion) {
        guard var record = answers[question.id], record.hasAnswer else { return }
        record.dealbreaker.toggle()
        answers[question.id] = record
        Task { try? await persistProgress(completed: false) }
    }

    func recordAnswer(optionValue: Int) {
        let question = currentQuestion
        if isMultiSelectActive(for: question) || question.multiSelect {
            var record = answers[question.id] ?? QuizAnswerRecord(
                preferredAnswers: [],
                importance: QuizImportance.somewhat.rawValue,
                dealbreaker: false
            )
            var selected = Set(record.answers ?? (record.answer.map { [$0] } ?? []))
            if selected.contains(optionValue) {
                selected.remove(optionValue)
            } else {
                selected.insert(optionValue)
            }
            let sorted = Array(selected).sorted()
            record.answers = sorted.isEmpty ? nil : sorted
            record.answer = sorted.count == 1 ? sorted[0] : nil
            if record.preferredAnswers.isEmpty {
                record.preferredAnswers = sorted
            }
            answers[question.id] = record
            syncFreePasses()
            Task { try? await persistProgress(completed: false) }
        } else {
            answers[question.id] = QuizAnswerRecord(
                answer: optionValue,
                preferredAnswers: [optionValue],
                importance: QuizImportance.somewhat.rawValue,
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
        Task { try? await persistProgress(completed: false) }
    }

    func goNext() {
        guard canAdvance else { return }
        if isLastInPool {
            if mode == .modify || canFinish {
                Task { await completeQuiz() }
            }
        } else {
            poolPosition += 1
            Task { try? await persistProgress(completed: false) }
        }
    }

    func goBack() {
        poolPosition = max(0, poolPosition - 1)
    }

    func skipQuestion() {
        if isLastInPool {
            if mode == .modify || canFinish {
                Task { await completeQuiz() }
            }
        } else {
            poolPosition += 1
        }
    }

    var canAdvance: Bool {
        guard let record = answers[currentQuestion.id] else { return mode == .modify }
        if isMultiSelectActive(for: currentQuestion) || currentQuestion.multiSelect {
            return !(record.answers ?? []).isEmpty
        }
        return record.answer != nil && !showPreferenceSheet
    }

    func completeQuiz() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard mode == .modify || canFinish else {
            errorMessage = "Answer at least \(QuizCatalog.minimumAnswersToComplete) questions to finish."
            return
        }
        isSaving = true
        defer { isSaving = false }
        do {
            try await persistProgress(completed: true, uid: uid)
            didComplete = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func persistProgress(completed: Bool, uid: String? = nil) async throws {
        let userId = uid ?? Auth.auth().currentUser?.uid
        guard let userId else { return }
        let archetype = completed
            ? QuizArchetypeCalculator.calculate(answers: answers, questions: questions)
            : nil
        try await RidgitsFirebaseClient.shared.saveQuizProgress(
            uid: userId,
            answers: answers,
            currentQuestion: poolPosition,
            freePassesRemaining: freePassesRemaining,
            completed: completed,
            archetype: archetype
        )
    }

    private func syncFreePasses() {
        let used = questions.filter { question in
            !question.multiSelect &&
            question.category != "Demographics" &&
            (answers[question.id]?.answers?.count ?? 0) > 1
        }.count
        freePassesRemaining = max(0, 3 - used)
    }
}
