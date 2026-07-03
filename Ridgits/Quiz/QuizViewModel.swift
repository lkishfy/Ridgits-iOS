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
        QuizCatalog.personalityAnsweredCount(in: answers)
    }

    var totalPersonalityQuestions: Int {
        if mode == .modify || orderedIndices.allSatisfy({ questions[$0].category != "Demographics" }) {
            return orderedIndices.filter { questions[$0].category != "Demographics" }.count
        }
        return QuizCatalog.personalityQuestionCount
    }

    /// Position within the full modify quiz order (not the filtered pool).
    var globalQuestionNumber: Int {
        (orderedIndices.firstIndex(of: currentQuestionIndex) ?? poolPosition) + 1
    }

    var displayedQuestionTotal: Int {
        if mode == .modify {
            if hideAnsweredQuestions || selectedCategory != nil {
                return max(activePool.count, 1)
            }
            return totalPersonalityQuestions
        }
        return activePool.count
    }

    var displayedQuestionNumber: Int {
        if mode == .modify, !hideAnsweredQuestions, selectedCategory == nil {
            return globalQuestionNumber
        }
        return poolPosition + 1
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
            Task { try? await persistProgress(completed: false) }
        }
    }

    func preparePreferenceDefaultsIfNeeded() {
        guard var record = answers[currentQuestion.id], record.hasAnswer else { return }
        if record.preferredAnswers.isEmpty {
            if let multi = record.answers, !multi.isEmpty {
                record.preferredAnswers = multi
            } else if let single = record.answer {
                record.preferredAnswers = [single]
            }
        }
        answers[currentQuestion.id] = record
    }

    func applyPreference(preferred: Set<Int>, importance: QuizImportance) {
        guard var record = answers[currentQuestion.id], record.hasAnswer else { return }
        record.preferredAnswers = Array(preferred).sorted()
        record.importance = importance.rawValue
        answers[currentQuestion.id] = record
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
        return record.answer != nil
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

        let markCompleted = resolvedCompletedFlag(requested: completed)
        // Only recalculate archetype when explicitly finishing — not on modify autosaves.
        let archetype = completed && markCompleted
            ? QuizArchetypeCalculator.calculate(answers: answers, questions: questions)
            : nil
        try await RidgitsFirebaseClient.shared.saveQuizProgress(
            uid: userId,
            answers: answers,
            currentQuestion: poolPosition,
            freePassesRemaining: freePassesRemaining,
            completed: markCompleted,
            archetype: archetype
        )
    }

    /// Saves in-progress edits when leaving modify mode without clearing quiz completion.
    func persistDraftOnExit() async {
        try? await persistProgress(completed: false)
    }

    private func resolvedCompletedFlag(requested completed: Bool) -> Bool {
        if completed { return true }
        if mode == .modify && QuizCatalog.hasEnoughPersonalityAnswers(in: answers) {
            return true
        }
        return false
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
