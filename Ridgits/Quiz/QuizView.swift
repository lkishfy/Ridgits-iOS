import SwiftUI

struct QuizView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var referralStore: RidgitsReferralStore
    @StateObject private var viewModel: QuizViewModel
    @State private var preferredSelection: Set<Int> = []
    @State private var importance: QuizImportance = .somewhat
    @State private var dealbreaker = false

    var mode: QuizMode
    var onCompleted: (() -> Void)?
    var onDismiss: (() -> Void)?

    init(mode: QuizMode = .onboarding, onCompleted: (() -> Void)? = nil, onDismiss: (() -> Void)? = nil) {
        self.mode = mode
        self.onCompleted = onCompleted
        self.onDismiss = onDismiss
        _viewModel = StateObject(wrappedValue: QuizViewModel(mode: mode))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RidgitsColors.feedBackground.ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView("Loading your quiz…")
                } else if viewModel.cardViewMode == .list && mode == .modify {
                    listMode
                } else {
                    cardMode
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if mode == .modify {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Close") { onDismiss?() }
                            .font(RidgitsTypography.label(12))
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text(mode == .modify ? "Modify Quiz Mode" : "Personality Quiz")
                        .font(RidgitsTypography.label(13))
                }
            }
        }
        .task { await viewModel.bootstrap() }
        .sheet(isPresented: $viewModel.showPreferenceSheet) {
            preferenceSheet
        }
        .onChange(of: viewModel.didComplete) { _, completed in
            if completed {
                Task {
                    if mode == .onboarding {
                        try? await authManager.markQuizCompleted()
                        await referralStore.qualifyReferralIfNeeded()
                    }
                    onCompleted?()
                    onDismiss?()
                }
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var cardMode: some View {
        VStack(spacing: 0) {
            progressHeader
            if mode == .modify {
                modifyControls
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    categoryLabel
                    questionText
                    actionBadges
                    optionsList
                    if viewModel.canShowCategoryNav {
                        categoryBrowse
                    }
                }
                .padding(20)
            }
            footer
        }
    }

    private var listMode: some View {
        List {
            Section {
                modifyControls
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            ForEach(viewModel.orderedIndices, id: \.self) { index in
                let question = viewModel.questions[index]
                let record = viewModel.answers[question.id]
                VStack(alignment: .leading, spacing: 8) {
                    Text(question.category.uppercased())
                        .font(RidgitsTypography.caption(10))
                        .foregroundStyle(RidgitsColors.textMuted)
                    Text(question.text)
                        .font(RidgitsTypography.label(14))
                    if let record, record.hasAnswer {
                        Text(answerSummary(record, question: question))
                            .font(RidgitsTypography.caption(12))
                            .foregroundStyle(RidgitsColors.textSecondary)
                        if record.dealbreaker {
                            Text("Dealbreaker")
                                .font(RidgitsTypography.caption(11))
                                .foregroundStyle(RidgitsColors.destructive)
                        }
                    } else {
                        Text("Not answered")
                            .font(RidgitsTypography.caption(12))
                            .foregroundStyle(RidgitsColors.textMuted)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if let poolIndex = viewModel.activePool.firstIndex(of: index) {
                        viewModel.poolPosition = poolIndex
                        viewModel.cardViewMode = .card
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    private var modifyControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Toggle("Hide answered questions", isOn: Binding(
                    get: { viewModel.hideAnsweredQuestions },
                    set: { viewModel.toggleHideAnswered($0) }
                ))
                .font(RidgitsTypography.caption(12))
            }

            HStack(spacing: 10) {
                Text("\(viewModel.personalityAnsweredCount) answered • \(viewModel.remainingCount) remaining")
                    .font(RidgitsTypography.caption(11))
                    .foregroundStyle(RidgitsColors.textSecondary)
                Spacer()
                Picker("View", selection: $viewModel.cardViewMode) {
                    ForEach(QuizCardViewMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 160)
            }

            RidgitsSquareButton(
                title: viewModel.isSaving ? "Saving…" : "Update Results",
                style: .filled
            ) {
                Task { await viewModel.completeQuiz() }
            }
            .disabled(viewModel.isSaving || !viewModel.canFinish)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(RidgitsColors.surface)
    }

    private var progressHeader: some View {
        VStack(spacing: 8) {
            Text(viewModel.currentQuestion.category.uppercased())
                .font(RidgitsTypography.caption(11))
                .foregroundStyle(RidgitsColors.textSecondary)
                .tracking(1.1)

            segmentedProgressBar

            Text("\(viewModel.personalityAnsweredCount) QUESTIONS ANSWERED")
                .font(RidgitsTypography.caption(10))
                .foregroundStyle(RidgitsColors.textMuted)
                .tracking(0.8)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(RidgitsColors.surface)
        .overlay(Rectangle().frame(height: 1).foregroundStyle(RidgitsColors.border), alignment: .bottom)
    }

    private var segmentedProgressBar: some View {
        GeometryReader { geo in
            HStack(spacing: 2) {
                ForEach(QuizCatalog.personalityCategories, id: \.self) { category in
                    let stats = viewModel.categoryProgress[category] ?? (0, 0)
                    let fraction = stats.total > 0 ? Double(stats.answered) / Double(stats.total) : 0
                    Capsule()
                        .fill(categoryColor(category).opacity(fraction > 0 ? 1 : 0.25))
                        .frame(width: max(8, (geo.size.width - 8) / 5 * CGFloat(max(fraction, stats.answered > 0 ? 0.12 : 0.05))))
                }
            }
        }
        .frame(height: 6)
    }

    private var categoryLabel: some View {
        Text(viewModel.currentQuestion.category.uppercased())
            .font(RidgitsTypography.caption(11))
            .foregroundStyle(RidgitsColors.textMuted)
            .tracking(1)
    }

    private var questionText: some View {
        Text(viewModel.currentQuestion.text)
            .font(RidgitsTypography.headline(22))
            .foregroundStyle(RidgitsColors.textHeadline)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var actionBadges: some View {
        HStack(spacing: 8) {
            if viewModel.freePassesRemaining < 3 {
                badge("✓ \(3 - viewModel.freePassesRemaining)/3 Multi-Select Pass Used", tint: .blue)
            }
            if viewModel.isMultiSelectActive(for: viewModel.currentQuestion) {
                badge("Multi-Select Active", tint: .orange)
            }
        }
    }

    private var optionsList: some View {
        VStack(spacing: 10) {
            ForEach(viewModel.currentQuestion.options) { option in
                let selected = viewModel.isSelected(option.value, for: viewModel.currentQuestion)
                Button {
                    viewModel.recordAnswer(optionValue: option.value)
                    if !viewModel.isMultiSelectActive(for: viewModel.currentQuestion) {
                        preferredSelection = [option.value]
                    }
                } label: {
                    HStack {
                        Text(option.label)
                            .font(RidgitsTypography.body())
                            .foregroundStyle(selected ? .white : RidgitsColors.textHeadline)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        if selected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(selected ? .white : RidgitsColors.ctaBlack)
                        }
                    }
                    .padding(16)
                    .background(selected ? RidgitsColors.ctaBlack : RidgitsColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: RidgitsRadius.md)
                            .stroke(selected ? RidgitsColors.ctaBlack : RidgitsColors.border, lineWidth: selected ? 2 : 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.md))
                }
            }

            HStack(spacing: 10) {
                featureButton(
                    title: "Dealbreaker",
                    active: viewModel.answers[viewModel.currentQuestion.id]?.dealbreaker == true,
                    enabled: viewModel.answers[viewModel.currentQuestion.id]?.hasAnswer == true
                ) {
                    viewModel.toggleDealbreaker(for: viewModel.currentQuestion)
                }

                featureButton(
                    title: "Multi-Select (\(viewModel.freePassesRemaining) left)",
                    active: viewModel.isMultiSelectActive(for: viewModel.currentQuestion),
                    enabled: viewModel.canActivateMultiSelect(for: viewModel.currentQuestion) ||
                        viewModel.isMultiSelectActive(for: viewModel.currentQuestion)
                ) {
                    viewModel.activateMultiSelect(for: viewModel.currentQuestion)
                }
            }
        }
    }

    private var categoryBrowse: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("BROWSE BY CATEGORY")
                .font(RidgitsTypography.sectionLabel(11))
                .foregroundStyle(RidgitsColors.textSecondary)
            Text("Jump to specific topics or continue answering.")
                .font(RidgitsTypography.caption(12))
                .foregroundStyle(RidgitsColors.textMuted)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(QuizCatalog.personalityCategories, id: \.self) { category in
                    let stats = viewModel.categoryProgress[category] ?? (0, 0)
                    Button {
                        viewModel.selectCategory(viewModel.selectedCategory == category ? nil : category)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(category)
                                .font(RidgitsTypography.label(13))
                                .foregroundStyle(RidgitsColors.textHeadline)
                            Text("\(stats.answered)/\(stats.total) answered")
                                .font(RidgitsTypography.caption(11))
                                .foregroundStyle(RidgitsColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(viewModel.selectedCategory == category ? RidgitsColors.contextBar : RidgitsColors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: RidgitsRadius.md)
                                .stroke(viewModel.selectedCategory == category ? RidgitsColors.ctaBlack : RidgitsColors.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.top, 8)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            if viewModel.poolPosition > 0 {
                RidgitsSecondaryButton(title: "Back") { viewModel.goBack() }
            }
            RidgitsSecondaryButton(title: "Skip") { viewModel.skipQuestion() }
            RidgitsPrimaryButton(
                title: primaryActionTitle,
                isLoading: viewModel.isSaving,
                isDisabled: !viewModel.canAdvance && mode != .modify
            ) {
                viewModel.goNext()
            }
        }
        .padding(20)
        .background(RidgitsColors.surface)
    }

    private var primaryActionTitle: String {
        if viewModel.isLastInPool {
            return mode == .modify ? "Update Results" : "Finish"
        }
        return "Next"
    }

    private var preferenceSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Acceptable answers")
                    .font(RidgitsTypography.headline())
                    .foregroundStyle(RidgitsColors.textHeadline)
                Text("Select all answers you'd accept from a match.")
                    .font(RidgitsTypography.body(14))
                    .foregroundStyle(RidgitsColors.textSecondary)

                ForEach(viewModel.currentQuestion.options) { option in
                    let selected = preferredSelection.contains(option.value)
                    Button {
                        if selected { preferredSelection.remove(option.value) }
                        else { preferredSelection.insert(option.value) }
                    } label: {
                        HStack {
                            Text(option.label)
                                .font(RidgitsTypography.body())
                                .foregroundStyle(RidgitsColors.textHeadline)
                            Spacer()
                            Image(systemName: selected ? "checkmark.square.fill" : "square")
                                .foregroundStyle(RidgitsColors.ctaBlack)
                        }
                    }
                }

                Text("Importance")
                    .font(RidgitsTypography.headline(16))
                Picker("Importance", selection: $importance) {
                    ForEach(QuizImportance.allCases) { level in
                        Text(level.label).tag(level)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 120)

                Toggle("This is a dealbreaker", isOn: $dealbreaker)
                    .font(RidgitsTypography.body())
                    .tint(RidgitsColors.ctaBlack)

                RidgitsPrimaryButton(title: "Save", isDisabled: preferredSelection.isEmpty) {
                    viewModel.updatePreference(
                        preferred: preferredSelection,
                        importance: importance,
                        dealbreaker: dealbreaker
                    )
                }
            }
            .padding(20)
            .background(RidgitsColors.feedBackground)
            .presentationDetents([.medium, .large])
        }
        .onAppear {
            if let record = viewModel.answers[viewModel.currentQuestion.id] {
                preferredSelection = Set(record.preferredAnswers)
                importance = QuizImportance(rawValue: record.importance) ?? .somewhat
                dealbreaker = record.dealbreaker
            }
        }
    }

    private func badge(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(RidgitsTypography.caption(11))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.12))
            .clipShape(Capsule())
    }

    private func featureButton(title: String, active: Bool, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(RidgitsTypography.caption(12))
                .foregroundStyle(active ? .white : RidgitsColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(active ? RidgitsColors.ctaBlack : RidgitsColors.hoverSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: RidgitsRadius.md)
                        .stroke(RidgitsColors.border, lineWidth: 1)
                )
        }
        .disabled(!enabled)
        .buttonStyle(.plain)
    }

    private func categoryColor(_ category: String) -> Color {
        switch category {
        case "Communication": return Color(hex: 0x4F8EF7)
        case "Intimacy": return Color(hex: 0xE56AAA)
        case "Values": return Color(hex: 0x57B77D)
        case "Social": return Color(hex: 0xF3A64C)
        case "Commitment": return Color(hex: 0x9B6CF3)
        default: return RidgitsColors.ctaBlack
        }
    }

    private func answerSummary(_ record: QuizAnswerRecord, question: QuizQuestion) -> String {
        let values = record.answers ?? record.answer.map { [$0] } ?? []
        let labels = values.compactMap { value in
            question.options.first(where: { $0.value == value })?.label
        }
        return labels.joined(separator: ", ")
    }
}
