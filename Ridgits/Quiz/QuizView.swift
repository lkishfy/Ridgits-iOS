import SwiftUI

struct QuizView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var referralStore: RidgitsReferralStore
    @StateObject private var viewModel: QuizViewModel
    @State private var preferredSelection: Set<Int> = []
    @State private var importance: QuizImportance = .somewhat
    @State private var showCategorySheet = false
    @State private var preferencePanelExpanded = false

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
                } else if mode == .modify && viewModel.cardViewMode == .list {
                    modifyListMode
                } else {
                    cardMode
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .sheet(isPresented: $showCategorySheet) {
                categoryBrowseSheet
            }
        }
        .task { await viewModel.bootstrap() }
        .onDisappear {
            guard mode == .modify else { return }
            Task { await viewModel.persistDraftOnExit() }
        }
        .onChange(of: viewModel.currentQuestionIndex) { _, _ in
            preferencePanelExpanded = false
            syncPreferenceStateFromRecord()
        }
        .onChange(of: viewModel.didComplete) { _, completed in
            if completed {
                RidgitsHaptics.play(.success)
                Task {
                    if mode == .onboarding {
                        if let uid = authManager.currentUser?.uid {
                            try? await RidgitsFirebaseClient.shared.ensureQuizCompletionRecorded(uid: uid)
                        }
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

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if mode == .modify {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") {
                    Task {
                        await viewModel.persistDraftOnExit()
                        onDismiss?()
                    }
                }
                .font(RidgitsTypography.label(12))
            }
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text("Modify Quiz")
                        .font(RidgitsTypography.label(13))
                    Text("\(viewModel.personalityAnsweredCount) of \(viewModel.totalPersonalityQuestions) answered")
                        .font(RidgitsTypography.caption(10))
                        .foregroundStyle(RidgitsColors.textMuted)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                modifyToolbarMenu
            }
        } else {
            ToolbarItem(placement: .principal) {
                if usesModernQuizLayout {
                    VStack(spacing: 2) {
                        Text("Personality Quiz")
                            .font(RidgitsTypography.label(13))
                        Text("\(viewModel.personalityAnsweredCount) of \(viewModel.totalPersonalityQuestions) answered")
                            .font(RidgitsTypography.caption(10))
                            .foregroundStyle(RidgitsColors.textMuted)
                    }
                } else {
                    Text("Personality Quiz")
                        .font(RidgitsTypography.label(13))
                }
            }
        }
    }

    private var modifyToolbarMenu: some View {
        Menu {
            Picker("View", selection: $viewModel.cardViewMode) {
                ForEach(QuizCardViewMode.allCases) { viewMode in
                    Text(viewMode.label).tag(viewMode)
                }
            }

            Toggle(
                isOn: Binding(
                    get: { viewModel.hideAnsweredQuestions },
                    set: { viewModel.toggleHideAnswered($0) }
                )
            ) {
                Label("Hide answered", systemImage: "eye.slash")
            }

            Button {
                showCategorySheet = true
            } label: {
                Label("Browse categories", systemImage: "square.grid.2x2")
            }

            Divider()

            Button {
                Task { await viewModel.completeQuiz() }
            } label: {
                Label("Update results", systemImage: "arrow.triangle.2.circlepath")
            }
            .disabled(viewModel.isSaving || !viewModel.canFinish)
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(RidgitsColors.textHeadline)
        }
    }

    private var usesModernQuizLayout: Bool {
        showsPreferencePanel
    }

    private var cardMode: some View {
        VStack(spacing: 0) {
            if usesModernQuizLayout {
                quizProgressHeader
            } else {
                demographicsProgressHeader
            }

            ScrollView {
                VStack(alignment: .leading, spacing: usesModernQuizLayout ? 16 : 20) {
                    if usesModernQuizLayout {
                        modifyQuestionBlock
                        modifyFeatureChips
                    } else {
                        questionText
                    }
                    optionsList
                }
                .padding(.horizontal, 20)
                .padding(.vertical, usesModernQuizLayout ? 16 : 20)
            }

            quizBottomChrome
        }
        .onAppear { syncPreferenceStateFromRecord() }
    }

    private var showsPrimaryFooter: Bool {
        mode == .modify || !usesModernQuizLayout
    }

    private var quizBottomChrome: some View {
        ZStack(alignment: .bottom) {
            if mode == .modify {
                modifyUpdateFooter
            } else if !usesModernQuizLayout {
                footer
            }

            if showsPreferencePanel {
                preferenceBottomDrawer
                    .padding(.bottom, preferencePanelExpanded ? 0 : (showsPrimaryFooter ? quizPrimaryFooterHeight : 0))
            }
        }
    }

    private var quizPrimaryFooterHeight: CGFloat { 72 }

    private var showsPreferencePanel: Bool {
        viewModel.currentQuestion.category != "Demographics"
    }

    private var modifyListMode: some View {
        List {
            ForEach(viewModel.orderedIndices, id: \.self) { index in
                let question = viewModel.questions[index]
                let record = viewModel.answers[question.id]
                Button {
                    if let poolIndex = viewModel.activePool.firstIndex(of: index) {
                        viewModel.poolPosition = poolIndex
                        viewModel.cardViewMode = .card
                    }
                } label: {
                    modifyListRow(question: question, record: record)
                }
                .buttonStyle(RidgitsHapticPlainButtonStyle())
                .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                .listRowSeparator(.visible)
                .listRowBackground(RidgitsColors.surface)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(RidgitsColors.feedBackground)
        .safeAreaInset(edge: .bottom) {
            modifyUpdateFooter
        }
    }

    private func modifyListRow(question: QuizQuestion, record: QuizAnswerRecord?) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(question.category)
                    .font(RidgitsTypography.caption(10))
                    .foregroundStyle(RidgitsColors.textMuted)
                    .textCase(.uppercase)

                Text(question.text)
                    .font(RidgitsTypography.label(15))
                    .foregroundStyle(RidgitsColors.textHeadline)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                if let record, record.hasAnswer {
                    Text(answerSummary(record, question: question))
                        .font(RidgitsTypography.caption(12))
                        .foregroundStyle(RidgitsColors.textSecondary)
                        .lineLimit(2)

                    HStack(spacing: 6) {
                        if record.dealbreaker {
                            modifyListTag("Dealbreaker", tint: RidgitsColors.destructive)
                        }
                        if (record.answers?.count ?? 0) > 1 {
                            modifyListTag("Multi-select", tint: Color(hex: 0xC2410C))
                        }
                    }
                } else {
                    Text("Not answered")
                        .font(RidgitsTypography.caption(12))
                        .foregroundStyle(RidgitsColors.textMuted)
                }
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(RidgitsColors.textMuted)
                .padding(.top, 4)
        }
        .contentShape(Rectangle())
    }

    private func modifyListTag(_ title: String, tint: Color) -> some View {
        Text(title)
            .font(RidgitsTypography.caption(10))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(tint.opacity(0.1))
            .clipShape(Capsule())
    }

    private var quizProgressHeader: some View {
        modifyCompactProgress
    }

    private var demographicsProgressHeader: some View {
        VStack(spacing: 8) {
            Text("Getting Started")
                .font(RidgitsTypography.caption(11))
                .foregroundStyle(RidgitsColors.textSecondary)
                .tracking(1.1)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
        }
        .padding(.vertical, 12)
        .background(RidgitsColors.surface)
        .overlay(Rectangle().frame(height: 1).foregroundStyle(RidgitsColors.border), alignment: .bottom)
    }

    private var modifyCompactProgress: some View {
        VStack(spacing: 8) {
            categoryProgressHeader

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    categoryActiveBadge
                    quizHeaderNav
                }

                Spacer()

                Text("Question \(viewModel.displayedQuestionNumber) of \(viewModel.displayedQuestionTotal)")
                    .font(RidgitsTypography.caption(11))
                    .foregroundStyle(RidgitsColors.textMuted)
                    .padding(.top, 6)
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 10)
        .background(RidgitsColors.surface)
        .overlay(Rectangle().frame(height: 1).foregroundStyle(RidgitsColors.border), alignment: .bottom)
    }

    private var categoryActiveBadge: some View {
        let category = viewModel.currentQuestion.category
        let color = QuizCategoryColors.color(for: category)

        return HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(category)
                .font(RidgitsTypography.label(12))
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }

    private var progressSegmentMode: QuizMode {
        showsPreferencePanel ? .modify : mode
    }

    private var categoryProgressHeader: some View {
        let segments = QuizCatalog.progressSegments(mode: progressSegmentMode)
        let segmentTotal = max(segments.reduce(0) { $0 + $1.count }, 1)
        let activeCategory = viewModel.currentQuestion.category

        return GeometryReader { geo in
            VStack(spacing: 6) {
                HStack(spacing: 3) {
                    ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                        let stats = viewModel.categoryProgress[segment.category] ?? (0, 0)
                        let fill = stats.total > 0 ? Double(stats.answered) / Double(stats.total) : 0
                        let width = geo.size.width * CGFloat(segment.count) / CGFloat(segmentTotal)
                        let isActive = segment.category == activeCategory
                        let color = QuizCategoryColors.color(for: segment.category)

                        let fillFraction = min(max(fill, 0), 1)
                        let barHeight: CGFloat = isActive ? 8 : 6

                        Capsule()
                            .fill(QuizCategoryColors.track)
                            .overlay(alignment: .leading) {
                                if fillFraction > 0 {
                                    color.frame(width: width * fillFraction)
                                }
                            }
                            .frame(width: width, height: barHeight)
                            .clipShape(Capsule())
                            .overlay {
                                if isActive {
                                    Capsule()
                                        .stroke(color, lineWidth: 2)
                                }
                            }
                    }
                }

                HStack(spacing: 3) {
                    ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                        let width = geo.size.width * CGFloat(segment.count) / CGFloat(segmentTotal)
                        let isActive = segment.category == activeCategory
                        let color = QuizCategoryColors.color(for: segment.category)

                        Text(categoryBarLabel(segment.category))
                            .font(RidgitsTypography.caption(isActive ? 9 : 8))
                            .fontWeight(isActive ? .semibold : .regular)
                            .foregroundStyle(isActive ? color : RidgitsColors.textMuted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                            .frame(width: width)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
        .frame(height: 28)
        .padding(.horizontal, 20)
    }

    private func categoryBarLabel(_ category: String) -> String {
        switch category {
        case "Communication": return "Comm"
        case "Intimacy": return "Intimacy"
        case "Values": return "Values"
        case "Social": return "Social"
        case "Commitment": return "Commit"
        default: return category
        }
    }

    private var modifyQuestionBlock: some View {
        Text(viewModel.currentQuestion.text)
            .font(RidgitsTypography.headline(24))
            .foregroundStyle(RidgitsColors.textHeadline)
            .fixedSize(horizontal: false, vertical: true)
            .lineSpacing(2)
    }

    private var modifyFeatureChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                let record = viewModel.answers[viewModel.currentQuestion.id]
                let hasAnswer = record?.hasAnswer == true

                modifyFeatureChip(
                    title: "Dealbreaker",
                    icon: "exclamationmark.triangle.fill",
                    active: record?.dealbreaker == true,
                    enabled: hasAnswer,
                    activeColor: RidgitsColors.destructive
                ) {
                    viewModel.toggleDealbreaker(for: viewModel.currentQuestion)
                }

                modifyFeatureChip(
                    title: multiSelectChipTitle,
                    icon: "checklist",
                    active: viewModel.isMultiSelectActive(for: viewModel.currentQuestion),
                    enabled: viewModel.canActivateMultiSelect(for: viewModel.currentQuestion) ||
                        viewModel.isMultiSelectActive(for: viewModel.currentQuestion),
                    activeColor: Color(hex: 0xC2410C)
                ) {
                    viewModel.activateMultiSelect(for: viewModel.currentQuestion)
                }

                if viewModel.isMultiSelectActive(for: viewModel.currentQuestion) {
                    modifyListTag("Tap multiple answers", tint: RidgitsColors.textSecondary)
                }
            }
        }
    }

    private var multiSelectChipTitle: String {
        if viewModel.isMultiSelectActive(for: viewModel.currentQuestion) {
            return "Multi-select on"
        }
        return "Multi-select · \(viewModel.freePassesRemaining) left"
    }

    private func modifyFeatureChip(
        title: String,
        icon: String,
        active: Bool,
        enabled: Bool,
        activeColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(title)
                    .font(RidgitsTypography.caption(11))
            }
            .foregroundStyle(active ? .white : (enabled ? RidgitsColors.textHeadline : RidgitsColors.textMuted))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(active ? activeColor : RidgitsColors.surface)
            .overlay(
                Capsule()
                    .stroke(active ? activeColor : RidgitsColors.border, lineWidth: 1)
            )
            .clipShape(Capsule())
        }
        .disabled(!enabled)
        .buttonStyle(RidgitsHapticPlainButtonStyle())
    }

    private var categoryBrowseSheet: some View {
        NavigationStack {
            ScrollView {
                categoryBrowse
                    .padding(20)
            }
            .background(RidgitsColors.feedBackground)
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showCategorySheet = false }
                        .font(RidgitsTypography.label(12))
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var questionText: some View {
        Text(viewModel.currentQuestion.text)
            .font(RidgitsTypography.headline(22))
            .foregroundStyle(RidgitsColors.textHeadline)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var optionsList: some View {
        VStack(spacing: usesModernQuizLayout ? 12 : 10) {
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
                            .font(usesModernQuizLayout ? RidgitsTypography.body(15) : RidgitsTypography.body())
                            .foregroundStyle(selected ? .white : RidgitsColors.textHeadline)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        if selected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(selected ? .white : RidgitsColors.ctaBlack)
                        }
                    }
                    .padding(.horizontal, usesModernQuizLayout ? 18 : 16)
                    .padding(.vertical, usesModernQuizLayout ? 16 : 16)
                    .background(selected ? RidgitsColors.ctaBlack : RidgitsColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: RidgitsRadius.md)
                            .stroke(selected ? RidgitsColors.ctaBlack : RidgitsColors.border, lineWidth: selected ? 2 : 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.md))
                }
            }
        }
    }

    private var categoryBrowse: some View {
        VStack(alignment: .leading, spacing: 12) {
            if mode != .modify {
                Text("BROWSE BY CATEGORY")
                    .font(RidgitsTypography.sectionLabel(11))
                    .foregroundStyle(RidgitsColors.textSecondary)
                Text("Jump to specific topics or continue answering.")
                    .font(RidgitsTypography.caption(12))
                    .foregroundStyle(RidgitsColors.textMuted)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(QuizCatalog.personalityCategories, id: \.self) { category in
                    let stats = viewModel.categoryProgress[category] ?? (0, 0)
                    Button {
                        viewModel.selectCategory(viewModel.selectedCategory == category ? nil : category)
                        showCategorySheet = false
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
                        .background(viewModel.selectedCategory == category ? QuizCategoryColors.color(for: category).opacity(0.12) : RidgitsColors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: RidgitsRadius.md)
                                .stroke(
                                    viewModel.selectedCategory == category
                                        ? QuizCategoryColors.color(for: category)
                                        : RidgitsColors.border,
                                    lineWidth: viewModel.selectedCategory == category ? 2 : 1
                                )
                        )
                    }
                    .buttonStyle(RidgitsHapticPlainButtonStyle())
                }
            }

            if viewModel.selectedCategory != nil {
                Button("Show all categories") {
                    viewModel.selectCategory(nil)
                    showCategorySheet = false
                }
                .font(RidgitsTypography.caption(12))
                .foregroundStyle(RidgitsColors.textSecondary)
            }
        }
        .padding(.top, mode == .modify ? 0 : 8)
    }

    private var quizHeaderNav: some View {
        HStack(spacing: 18) {
            quizNavIconButton(
                systemName: "chevron.backward",
                accessibilityLabel: "Back",
                isEnabled: viewModel.poolPosition > 0
            ) {
                viewModel.goBack()
            }

            quizNavIconButton(
                systemName: "arrow.right",
                accessibilityLabel: "Skip",
                isEnabled: true
            ) {
                viewModel.skipQuestion()
            }

            quizNavIconButton(
                systemName: viewModel.isLastInPool && mode == .onboarding ? "checkmark" : "chevron.forward",
                accessibilityLabel: viewModel.isLastInPool && mode == .onboarding ? "Finish" : "Next",
                isEnabled: viewModel.canAdvance
            ) {
                viewModel.goNext()
            }
        }
    }

    private func quizNavIconButton(
        systemName: String,
        accessibilityLabel: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isEnabled ? RidgitsColors.textSecondary : RidgitsColors.textMuted.opacity(0.35))
                .frame(width: 32, height: 32)
                .contentShape(Circle())
        }
        .disabled(!isEnabled)
        .buttonStyle(RidgitsCircularIconButtonStyle())
        .accessibilityLabel(accessibilityLabel)
    }

    private var modifyUpdateFooter: some View {
        RidgitsPrimaryButton(
            title: "Update Results",
            isLoading: viewModel.isSaving,
            isDisabled: !viewModel.canFinish
        ) {
            Task { await viewModel.completeQuiz() }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(RidgitsColors.surface)
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
        .padding(.horizontal, 20)
        .padding(.vertical, mode == .modify ? 12 : 20)
        .background(RidgitsColors.surface)
    }

    private var primaryActionTitle: String {
        if viewModel.isLastInPool {
            return "Finish"
        }
        return "Next"
    }

    private var preferencePanelMaxHeight: CGFloat {
        min(UIScreen.main.bounds.height * 0.58, 560)
    }

    private var preferenceBottomDrawer: some View {
        VStack(spacing: 0) {
            if preferencePanelExpanded {
                ScrollView {
                    preferencePanelContent
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 20)
                }
                .frame(maxHeight: preferencePanelMaxHeight)
                .background(RidgitsColors.surface)
            }

            Button {
                RidgitsHaptics.play(.light)
                withAnimation(.easeInOut(duration: 0.25)) {
                    if preferencePanelExpanded {
                        preferencePanelExpanded = false
                    } else {
                        viewModel.preparePreferenceDefaultsIfNeeded()
                        syncPreferenceStateFromRecord()
                        if preferredSelection.isEmpty, let record = viewModel.answers[viewModel.currentQuestion.id] {
                            if let multi = record.answers {
                                preferredSelection = Set(multi)
                            } else if let single = record.answer {
                                preferredSelection = [single]
                            }
                        }
                        preferencePanelExpanded = true
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Text("Choose Their Ideal Answer")
                        .font(RidgitsTypography.label(12))
                        .foregroundStyle(RidgitsColors.textHeadline)
                        .textCase(.uppercase)
                    Text("Optional")
                        .font(RidgitsTypography.caption(10))
                        .foregroundStyle(RidgitsColors.textMuted)
                        .textCase(.uppercase)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(RidgitsColors.textMuted)
                        .rotationEffect(.degrees(preferencePanelExpanded ? 180 : 0))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .padding(.horizontal, 20)
                .background(Color(hex: 0xF0F0F0))
            }
            .buttonStyle(RidgitsHapticPlainButtonStyle())
        }
        .background(RidgitsColors.surface)
        .overlay(Rectangle().frame(height: 1).foregroundStyle(Color(hex: 0x999999)), alignment: .top)
        .shadow(color: .black.opacity(preferencePanelExpanded ? 0.14 : 0), radius: 16, y: -6)
        .animation(.easeInOut(duration: 0.25), value: preferencePanelExpanded)
    }

    private var preferencePanelContent: some View {
        let question = viewModel.currentQuestion
        let record = viewModel.answers[question.id]

        return VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text("How should others answer?")
                    .font(RidgitsTypography.label(14))
                    .foregroundStyle(RidgitsColors.textHeadline)
                Text(question.text)
                    .font(RidgitsTypography.body(13))
                    .foregroundStyle(RidgitsColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let record, record.hasAnswer {
                    Text("Your answer: \(answerSummary(record, question: question))")
                        .font(RidgitsTypography.caption(12))
                        .foregroundStyle(RidgitsColors.textMuted)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Their ideal answer")
                    .font(RidgitsTypography.sectionLabel(11))
                    .foregroundStyle(RidgitsColors.textSecondary)

                ForEach(question.options) { option in
                    let selected = preferredSelection.contains(option.value)
                    Button {
                        if selected { preferredSelection.remove(option.value) }
                        else { preferredSelection.insert(option.value) }
                        RidgitsHaptics.play(.selection)
                    } label: {
                        HStack {
                            Text(option.label)
                                .font(RidgitsTypography.body(13))
                                .foregroundStyle(RidgitsColors.textHeadline)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            if selected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                            }
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 14)
                        .background(selected ? RidgitsColors.hoverSurface : RidgitsColors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: RidgitsRadius.sm)
                                .stroke(selected ? RidgitsColors.ctaBlack : RidgitsColors.border, lineWidth: selected ? 2 : 1)
                        )
                    }
                    .buttonStyle(RidgitsHapticPlainButtonStyle())
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("How important is this?")
                    .font(RidgitsTypography.sectionLabel(11))
                    .foregroundStyle(RidgitsColors.textSecondary)

                ForEach(QuizImportance.allCases) { level in
                    let selected = importance == level
                    Button {
                        importance = level
                        RidgitsHaptics.play(.selection)
                    } label: {
                        HStack {
                            Text(level.label)
                                .font(RidgitsTypography.label(13))
                                .foregroundStyle(RidgitsColors.textHeadline)
                            Text("– \(level.subtitle)")
                                .font(RidgitsTypography.caption(12))
                                .foregroundStyle(RidgitsColors.textSecondary)
                            Spacer()
                            if selected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 14)
                        .background(selected ? RidgitsColors.hoverSurface : RidgitsColors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: RidgitsRadius.sm)
                                .stroke(selected ? RidgitsColors.ctaBlack : RidgitsColors.border, lineWidth: selected ? 2 : 1)
                        )
                    }
                    .buttonStyle(RidgitsHapticPlainButtonStyle())
                }
            }

            RidgitsPrimaryButton(
                title: "Save",
                isDisabled: preferredSelection.isEmpty
            ) {
                viewModel.applyPreference(preferred: preferredSelection, importance: importance)
                withAnimation(.easeInOut(duration: 0.25)) {
                    preferencePanelExpanded = false
                }
            }
            .padding(.top, 4)
        }
    }

    private func syncPreferenceStateFromRecord() {
        if let record = viewModel.answers[viewModel.currentQuestion.id] {
            preferredSelection = Set(record.preferredAnswers)
            importance = QuizImportance(rawValue: record.importance) ?? .somewhat
        } else {
            preferredSelection = []
            importance = .somewhat
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
