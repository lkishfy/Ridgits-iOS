import Foundation
import FirebaseAuth
import FirebaseFirestore

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
    @Published var dealbreakerEngaged: Set<String> = []
    @Published var activeMultiSelect: Set<String> = []
    @Published var freePassesRemaining = 3
    @Published var hideAnsweredQuestions = false
    @Published var selectedCategory: String?
    @Published var cardViewMode: QuizCardViewMode = .card
    @Published var isSaving = false
    @Published var isLoading = false
    @Published var didComplete = false
    @Published var updatedResultsPresentation: QuizFullResultsPresentation?
    @Published var errorMessage: String?

    private var previousArchetypeName: String?
    private var autoAdvanceTask: Task<Void, Never>?
    var hasBootstrapped = false
    private var wasQuizCompleteAtBootstrap = false
    private(set) var bootstrapUserId: String?

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
        orderedIndices.filter { questions[$0].category != "Demographics" }.count
    }

    var onboardingPersonalityAnsweredCount: Int {
        orderedIndices
            .map { questions[$0] }
            .filter { $0.category != "Demographics" }
            .filter { answers[$0.id]?.hasAnswer == true }
            .count
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
        return orderedIndices.count
    }

    var displayedQuestionNumber: Int {
        if mode == .modify, !hideAnsweredQuestions, selectedCategory == nil {
            return globalQuestionNumber
        }
        if mode == .onboarding {
            return globalQuestionNumber
        }
        return poolPosition + 1
    }

    var demographicsAnsweredCount: Int {
        QuizCatalog.demographicQuestionIDs.filter { answers[$0]?.hasAnswer == true }.count
    }

    var demographicsQuestionTotal: Int {
        orderedIndices.filter { questions[$0].category == "Demographics" }.count
    }

    var hasCompletedDemographics: Bool {
        demographicsAnsweredCount >= demographicsQuestionTotal
    }

    var isOnPersonalityQuestion: Bool {
        currentQuestion.category != "Demographics"
    }

    var remainingCount: Int {
        max(0, activePool.count - poolPosition - 1)
    }

    var canShowCategoryNav: Bool {
        mode == .modify || personalityAnsweredCount >= 50
    }

    var categoryProgress: [String: (answered: Int, total: Int)] {
        QuizCatalog.categoryCounts(in: answers, mode: mode, orderedIndices: orderedIndices)
    }

    var progressFraction: Double {
        guard !activePool.isEmpty else { return 0 }
        return Double(poolPosition + 1) / Double(activePool.count)
    }

    var isLastInPool: Bool {
        poolPosition >= activePool.count - 1
    }

    var canFinish: Bool {
        if mode == .onboarding {
            return onboardingPersonalityAnsweredCount >= QuizCatalog.onboardingPersonalityQuestionCount
        }
        return personalityAnsweredCount >= QuizCatalog.onboardingSkipThreshold
    }

    var finishAnswerThreshold: Int {
        mode == .onboarding
            ? QuizCatalog.onboardingPersonalityQuestionCount
            : QuizCatalog.onboardingSkipThreshold
    }

    var onboardingProgressAnsweredCount: Int {
        mode == .onboarding ? onboardingPersonalityAnsweredCount : personalityAnsweredCount
    }

    func bootstrap() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        bootstrapUserId = uid
        isLoading = true
        defer {
            isLoading = false
            hasBootstrapped = true
        }
        do {
            let source: FirestoreSource = mode == .modify ? .server : .default
            if let progress = try await RidgitsFirebaseClient.shared.fetchQuizProgress(uid: uid, source: source) {
                answers = progress.answers
                freePassesRemaining = progress.freePassesRemaining
                dealbreakerEngaged = Set(progress.answers.keys)
                wasQuizCompleteAtBootstrap = progress.completed
                    || QuizCatalog.hasEnoughPersonalityAnswers(in: progress.answers)
                    || progress.questionsAnswered >= QuizCatalog.onboardingSkipThreshold
                if mode == .modify {
                    poolPosition = min(progress.currentQuestion, max(activePool.count - 1, 0))
                } else if progress.currentQuestion > 0 {
                    poolPosition = min(progress.currentQuestion, max(activePool.count - 1, 0))
                }

                if personalityAnsweredCount == 0 && wasQuizCompleteAtBootstrap,
                   let repaired = try await RidgitsFirebaseClient.shared.fetchQuizProgress(uid: uid, source: .server) {
                    answers = repaired.answers
                    dealbreakerEngaged = Set(repaired.answers.keys)
                    freePassesRemaining = repaired.freePassesRemaining
                    if !repaired.answers.isEmpty {
                        wasQuizCompleteAtBootstrap = repaired.completed
                            || QuizCatalog.hasEnoughPersonalityAnswers(in: repaired.answers)
                    } else {
                        errorMessage = "Could not load your saved quiz answers. Try closing and reopening."
                    }
                }
            }
            if mode == .modify, let archetype = await RidgitsFirebaseClient.shared.fetchQuizArchetype(uid: uid) {
                previousArchetypeName = archetype.name
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
        autoAdvanceTask?.cancel()
        selectedCategory = category
        poolPosition = 0
        refreshActivePool()
    }

    func toggleHideAnswered(_ hidden: Bool) {
        autoAdvanceTask?.cancel()
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

    func canSelectAnswer(for question: QuizQuestion) -> Bool {
        // Modify mode must allow tapping options on unanswered questions without
        // requiring dealbreaker to be toggled first.
        mode == .onboarding || mode == .modify
    }

    func toggleDealbreaker(for question: QuizQuestion) {
        var record = answers[question.id] ?? QuizAnswerRecord(
            preferredAnswers: [],
            importance: QuizImportance.somewhat.rawValue,
            dealbreaker: false
        )
        record.dealbreaker.toggle()
        answers[question.id] = record
        dealbreakerEngaged.insert(question.id)
        Task { try? await persistProgress(completed: false) }
    }

    func recordAnswer(optionValue: Int) {
        RidgitsHaptics.play(.selection)
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
            let previousAnswer = answers[question.id]?.answer
            let existingDealbreaker = answers[question.id]?.dealbreaker ?? false
            answers[question.id] = QuizAnswerRecord(
                answer: optionValue,
                preferredAnswers: [optionValue],
                importance: QuizImportance.somewhat.rawValue,
                dealbreaker: existingDealbreaker
            )
            Task { try? await persistProgress(completed: false) }
            if previousAnswer != optionValue {
                scheduleAutoAdvanceAfterSingleSelect()
            }
        }
    }

    private func scheduleAutoAdvanceAfterSingleSelect() {
        autoAdvanceTask?.cancel()
        autoAdvanceTask = Task {
            try? await Task.sleep(nanoseconds: 200_000_000)
            guard !Task.isCancelled else { return }
            advanceAfterSingleSelectAnswer()
            autoAdvanceTask = nil
        }
    }

    private func advanceAfterSingleSelectAnswer() {
        guard canAdvance else { return }

        if hideAnsweredQuestions {
            refreshActivePool()
            if activePool.isEmpty {
                if mode == .modify || canFinish {
                    Task { await completeQuiz() }
                }
                return
            }
            Task { try? await persistProgress(completed: false) }
            return
        }

        if isLastInPool {
            if mode == .modify || canFinish {
                Task { await completeQuiz() }
            }
        } else {
            poolPosition += 1
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
        autoAdvanceTask?.cancel()
        if mode == .onboarding && canFinish {
            Task { await completeQuiz() }
            return
        }
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
        autoAdvanceTask?.cancel()
        poolPosition = max(0, poolPosition - 1)
    }

    func skipQuestion() {
        guard mode == .modify else { return }
        autoAdvanceTask?.cancel()
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
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "Please sign in again to save your quiz."
            return
        }
        guard hasBootstrapped else {
            errorMessage = "Still loading your quiz. Try again in a moment."
            return
        }
        guard mode == .modify || canFinish else {
            errorMessage = "Answer at least \(finishAnswerThreshold) questions to finish."
            return
        }
        isSaving = true
        defer { isSaving = false }
        do {
            try await persistProgress(completed: true, uid: uid)
            _ = try? await RidgitsFirebaseClient.shared.ensureQuizCompletionRecorded(uid: uid)
            if mode == .modify {
                updatedResultsPresentation = buildFullResultsPresentation()
            }
            didComplete = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func buildFullResultsPresentation() -> QuizFullResultsPresentation {
        let archetype = QuizArchetypeCalculator.calculate(answers: answers, questions: questions)
        let progress = LoadedQuizProgress(
            answers: answers,
            currentQuestion: poolPosition,
            completed: true,
            freePassesRemaining: freePassesRemaining,
            questionsAnswered: personalityAnsweredCount
        )
        return QuizFullResultsPresentation(
            archetypeName: archetype?.name ?? "Your Archetype",
            archetypeDescription: archetype?.description ?? "",
            scores: RidgitsQuizCompatibility.dimensionAverages(from: progress),
            profile: nil,
            insights: RidgitsQuizCompatibility.insights(from: progress),
            previousArchetypeName: previousArchetypeName
        )
    }

    var canPersistForCurrentUser: Bool {
        guard let bootstrapUserId else { return false }
        return Auth.auth().currentUser?.uid == bootstrapUserId
    }

    func persistProgress(completed: Bool, uid: String? = nil) async throws {
        let userId = uid ?? bootstrapUserId ?? Auth.auth().currentUser?.uid
        guard let userId else { return }
        guard hasBootstrapped else { return }
        guard canPersistForCurrentUser || uid != nil else { return }

        let markCompleted = resolvedCompletedFlag(requested: completed)
        if answers.isEmpty && !markCompleted {
            return
        }
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

    /// Cancels pending auto-advance and persists the current question index + answers.
    func saveProgressForExit() async {
        autoAdvanceTask?.cancel()
        try? await persistProgress(completed: false)
    }

    private func resolvedCompletedFlag(requested completed: Bool) -> Bool {
        if completed { return true }
        if mode == .modify {
            if QuizCatalog.hasEnoughPersonalityAnswers(in: answers) { return true }
            // Keep match eligibility while a previously finished user edits answers.
            if wasQuizCompleteAtBootstrap { return true }
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
