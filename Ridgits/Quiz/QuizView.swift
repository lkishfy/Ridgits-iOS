import SwiftUI

struct QuizView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var referralStore: RidgitsReferralStore
    @StateObject private var viewModel: QuizViewModel
    @State private var preferredSelection: Set<Int> = []
    @State private var importance: QuizImportance = .somewhat
    @State private var showCategorySheet = false
    @State private var preferencePanelExpanded = false
    @State private var updatedResultsProfile: RidgitsUserProfile?
    @State private var showSignOutConfirmation = false
    @State private var isSigningOut = false

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

                if let presentation = viewModel.updatedResultsPresentation {
                    updatedResultsView(presentation)
                } else if viewModel.isLoading {
                    ProgressView("Loading your quiz…")
                } else if mode == .modify && viewModel.cardViewMode == .list {
                    modifyListMode
                } else {
                    cardMode
                }

                if preferencePanelExpanded {
                    preferenceFullScreenPanel
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.25), value: preferencePanelExpanded)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(preferencePanelExpanded ? .hidden : .visible, for: .navigationBar)
            .toolbar { quizToolbarContent }
            .sheet(isPresented: $showCategorySheet) {
                categoryBrowseSheet
            }
        }
        .task { await viewModel.bootstrap() }
        .onDisappear {
            guard !viewModel.didComplete, viewModel.hasBootstrapped, viewModel.canPersistForCurrentUser else { return }
            Task { await viewModel.saveProgressForExit() }
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
                        onCompleted?()
                        onDismiss?()
                    }
                }
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .confirmationDialog(
            "Sign out of Ridgits?",
            isPresented: $showSignOutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) {
                Task { await signOutFromQuiz() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your quiz progress will be saved so you can pick up where you left off.")
        }
    }

    @MainActor
    private func signOutFromQuiz() async {
        guard !isSigningOut else { return }
        isSigningOut = true
        defer { isSigningOut = false }
        await viewModel.saveProgressForExit()
        do {
            try authManager.signOut()
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }

    private func updatedResultsView(_ presentation: QuizFullResultsPresentation) -> some View {
        QuizFullResultsView(
            archetypeName: presentation.archetypeName,
            archetypeDescription: presentation.archetypeDescription,
            scores: presentation.scores,
            profile: updatedResultsProfile ?? presentation.profile,
            insights: presentation.insights,
            previousArchetypeName: presentation.previousArchetypeName,
            showsUpdatedTitle: true,
            embedInNavigationStack: false,
            onDone: finishUpdatedResults
        )
        .task(id: viewModel.didComplete) {
            guard updatedResultsProfile == nil,
                  let uid = authManager.currentUser?.uid else { return }
            updatedResultsProfile = try? await RidgitsFirebaseClient.shared.fetchUserProfile(uid: uid)
        }
    }

    private func finishUpdatedResults() {
        Task {
            if let uid = authManager.currentUser?.uid {
                _ = try? await RidgitsFirebaseClient.shared.ensureQuizCompletionRecorded(uid: uid)
            }
            onCompleted?()
            onDismiss?()
        }
    }

    @ToolbarContentBuilder
    private var quizToolbarContent: some ToolbarContent {
        if viewModel.updatedResultsPresentation != nil {
            ToolbarItem(placement: .principal) {
                Text("Updated Results")
                    .font(RidgitsTypography.label(13))
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { finishUpdatedResults() }
                    .font(RidgitsTypography.label(12))
            }
        } else {
            toolbarContent
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if mode == .modify {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") {
                    Task {
                        await viewModel.saveProgressForExit()
                        onDismiss?()
                    }
                }
                .font(RidgitsTypography.label(12))
                .disabled(viewModel.isLoading)
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
                        Text(onboardingProgressSubtitle)
                            .font(RidgitsTypography.caption(10))
                            .foregroundStyle(RidgitsColors.textMuted)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    Text("Personality Quiz")
                        .font(RidgitsTypography.label(13))
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                signOutButton
            }
        }
    }

    private var signOutButton: some View {
        Button("SIGN OUT") {
            showSignOutConfirmation = true
        }
        .font(RidgitsTypography.label(12))
        .foregroundStyle(RidgitsColors.textSecondary)
        .buttonStyle(.plain)
        .disabled(isSigningOut || viewModel.isLoading)
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
            Image(systemName: "ellipsis")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(RidgitsColors.textSecondary)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(RidgitsColors.surface)
                )
                .overlay(
                    Circle()
                        .stroke(RidgitsColors.border, lineWidth: 1)
                )
        }
        .buttonStyle(RidgitsHapticPlainButtonStyle())
    }

    private var quizCommunityBadge: some View {
        quizCommunityBadge(compact: false)
    }

    private func quizCommunityBadge(compact: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.system(size: compact ? 9 : 10, weight: .semibold))
            Text("Community")
                .font(RidgitsTypography.caption(compact ? 9 : 10))
                .textCase(.uppercase)
                .tracking(0.4)
        }
        .foregroundStyle(Color(hex: 0x059669))
        .padding(.horizontal, compact ? 6 : 8)
        .padding(.vertical, compact ? 3 : 4)
        .background(Color(hex: 0xECFDF5))
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .accessibilityLabel("Community question")
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
                    if viewModel.currentQuestion.userSubmitted {
                        quizCommunityBadge
                    }
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

            if mode != .onboarding {
                quizBottomChrome
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if mode == .onboarding && showsPreferencePanel && !preferencePanelExpanded {
                onboardingPreferenceCollapsedBar
            }
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

            if showsPreferencePanel && !preferencePanelExpanded {
                preferenceCollapsedBar
                    .padding(.bottom, showsPrimaryFooter ? quizPrimaryFooterHeight : 0)
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
                HStack(spacing: 6) {
                    Text(question.category)
                        .font(RidgitsTypography.caption(10))
                        .foregroundStyle(RidgitsColors.textMuted)
                        .textCase(.uppercase)

                    if question.userSubmitted {
                        quizCommunityBadge(compact: true)
                    }
                }

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
            if mode == .onboarding,
               viewModel.personalityAnsweredCount < QuizCatalog.onboardingSkipThreshold {
                Text("Answer at least \(QuizCatalog.onboardingSkipThreshold) questions to unlock your personality results.")
                    .font(RidgitsTypography.caption(11))
                    .foregroundStyle(RidgitsColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            categoryProgressHeader

            HStack(alignment: .center, spacing: 12) {
                quizNavIconButton(
                    systemName: "arrow.left",
                    accessibilityLabel: "Back",
                    isEnabled: viewModel.poolPosition > 0
                ) {
                    viewModel.goBack()
                }

                Text("Question \(viewModel.displayedQuestionNumber) of \(viewModel.displayedQuestionTotal)")
                    .font(RidgitsTypography.caption(11))
                    .foregroundStyle(RidgitsColors.textMuted)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)

                quizNavIconButton(
                    systemName: mode == .onboarding && viewModel.canFinish ? "checkmark" : "arrow.right",
                    accessibilityLabel: mode == .onboarding && viewModel.canFinish ? "Finish" : "Next",
                    isEnabled: viewModel.canAdvance || (mode == .onboarding && viewModel.canFinish)
                ) {
                    viewModel.goNext()
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 10)
        .background(RidgitsColors.surface)
        .overlay(Rectangle().frame(height: 1).foregroundStyle(RidgitsColors.border), alignment: .bottom)
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
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 8) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        let record = viewModel.answers[viewModel.currentQuestion.id]

                        modifyFeatureChip(
                            title: "Dealbreaker",
                            icon: "exclamationmark.triangle.fill",
                            active: record?.dealbreaker == true,
                            enabled: true,
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
                    }
                }

                if mode != .modify {
                    modifyIconFeatureChip(
                        icon: "forward.end",
                        accessibilityLabel: "Skip"
                    ) {
                        viewModel.skipQuestion()
                    }
                }
            }

            if viewModel.isMultiSelectActive(for: viewModel.currentQuestion) {
                modifyListTag("Tap multiple answers", tint: RidgitsColors.textSecondary)
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
                    .lineLimit(1)
            }
            .fixedSize(horizontal: true, vertical: false)
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
        .layoutPriority(1)
    }

    private func modifyIconFeatureChip(
        icon: String,
        accessibilityLabel: String,
        enabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(enabled ? RidgitsColors.textHeadline : RidgitsColors.textMuted)
                .frame(width: 34, height: 34)
                .background(RidgitsColors.surface)
                .overlay(
                    Capsule()
                        .stroke(RidgitsColors.border, lineWidth: 1)
                )
                .clipShape(Capsule())
        }
        .disabled(!enabled)
        .buttonStyle(RidgitsHapticPlainButtonStyle())
        .layoutPriority(1)
        .accessibilityLabel(accessibilityLabel)
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

    private var onboardingProgressSubtitle: String {
        let answered = viewModel.personalityAnsweredCount
        let required = QuizCatalog.onboardingSkipThreshold
        if answered >= required {
            return "\(answered) answered · Results unlocked"
        }
        let remaining = required - answered
        return "\(answered) of \(required) answered · \(remaining) more to see your results"
    }

    private var optionsList: some View {
        let canSelectAnswers = mode == .onboarding ||
            !usesModernQuizLayout ||
            viewModel.canSelectAnswer(for: viewModel.currentQuestion)

        return VStack(spacing: usesModernQuizLayout ? 12 : 10) {
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
                            .stroke(selected ? RidgitsColors.ctaBlack : RidgitsColors.optionBorder, lineWidth: selected ? 2 : 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.md))
                }
                .disabled(!canSelectAnswers)
                .opacity(canSelectAnswers ? 1 : 0.45)
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

    private func quizNavIconButton(
        systemName: String,
        accessibilityLabel: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isEnabled ? RidgitsColors.textHeadline : RidgitsColors.textMuted)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(isEnabled ? RidgitsColors.surface : RidgitsColors.feedBackground)
                )
                .overlay(
                    Circle()
                        .stroke(RidgitsColors.border, lineWidth: 1)
                )
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
        .buttonStyle(RidgitsHapticPlainButtonStyle())
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

    private var preferenceCollapsedBar: some View {
        Button {
            openPreferencePanel()
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
                Image(systemName: "chevron.up")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(RidgitsColors.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .background(Color(hex: 0xF0F0F0))
        }
        .buttonStyle(RidgitsHapticPlainButtonStyle())
        .frame(maxWidth: .infinity)
        .background(RidgitsColors.surface)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: RidgitsRadius.md,
                topTrailingRadius: RidgitsRadius.md
            )
        )
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: RidgitsRadius.md,
                topTrailingRadius: RidgitsRadius.md
            )
            .stroke(Color(hex: 0x999999), lineWidth: 1),
            alignment: .top
        )
        .shadow(color: .black.opacity(0.08), radius: 12, y: -4)
    }

    /// Onboarding-only bar pinned to the physical bottom edge (no gap below the home indicator).
    private var onboardingPreferenceCollapsedBar: some View {
        Button {
            openPreferencePanel()
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
                Image(systemName: "chevron.up")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(RidgitsColors.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 16)
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
        }
        .buttonStyle(RidgitsHapticPlainButtonStyle())
        .frame(maxWidth: .infinity)
        .background {
            UnevenRoundedRectangle(
                topLeadingRadius: RidgitsRadius.md,
                topTrailingRadius: RidgitsRadius.md
            )
            .fill(Color(hex: 0xF0F0F0))
            .ignoresSafeArea(edges: .bottom)
        }
        .overlay(alignment: .top) {
            UnevenRoundedRectangle(
                topLeadingRadius: RidgitsRadius.md,
                topTrailingRadius: RidgitsRadius.md
            )
            .stroke(Color(hex: 0x999999), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.08), radius: 12, y: -4)
    }

    private var preferenceFullScreenPanel: some View {
        VStack(spacing: 0) {
            preferenceFullScreenHeader

            ScrollView {
                preferencePanelScrollContent
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 20)
            }

            preferencePanelSaveFooter
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RidgitsColors.surface.ignoresSafeArea())
    }

    private var preferenceFullScreenHeader: some View {
        HStack(spacing: 12) {
            Button {
                closePreferencePanel()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(RidgitsColors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(RidgitsColors.hoverSurface)
                    .clipShape(Circle())
            }
            .buttonStyle(RidgitsHapticPlainButtonStyle())
            .accessibilityLabel("Dismiss")

            VStack(spacing: 2) {
                Text("Choose Their Ideal Answer")
                    .font(RidgitsTypography.label(13))
                    .foregroundStyle(RidgitsColors.textHeadline)
                    .textCase(.uppercase)
                Text("Optional")
                    .font(RidgitsTypography.caption(10))
                    .foregroundStyle(RidgitsColors.textMuted)
                    .textCase(.uppercase)
            }

            Spacer(minLength: 36)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: 0xF0F0F0))
    }

    private func openPreferencePanel() {
        RidgitsHaptics.play(.light)
        viewModel.preparePreferenceDefaultsIfNeeded()
        syncPreferenceStateFromRecord()
        if preferredSelection.isEmpty, let record = viewModel.answers[viewModel.currentQuestion.id] {
            if let multi = record.answers {
                preferredSelection = Set(multi)
            } else if let single = record.answer {
                preferredSelection = [single]
            }
        }
        withAnimation(.easeInOut(duration: 0.25)) {
            preferencePanelExpanded = true
        }
    }

    private func closePreferencePanel() {
        RidgitsHaptics.play(.light)
        withAnimation(.easeInOut(duration: 0.25)) {
            preferencePanelExpanded = false
        }
    }

    private var preferencePanelScrollContent: some View {
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
        }
    }

    private var preferencePanelSaveFooter: some View {
        RidgitsPrimaryButton(
            title: "Save",
            isDisabled: preferredSelection.isEmpty
        ) {
            viewModel.applyPreference(preferred: preferredSelection, importance: importance)
            closePreferencePanel()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(RidgitsColors.surface)
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
