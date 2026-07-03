import SwiftUI

struct QuizView: View {
    @EnvironmentObject private var authManager: AuthManager
    @StateObject private var viewModel = QuizViewModel()
    @State private var preferredSelection: Set<Int> = []
    @State private var importance: QuizImportance = .aLittle
    @State private var dealbreaker = false

    var onCompleted: () -> Void

    var body: some View {
        ZStack {
            RidgitsColors.feedBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                progressHeader
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        categoryLabel
                        questionText
                        optionsList
                    }
                    .padding(20)
                }
                footer
            }
        }
        .sheet(isPresented: $viewModel.showPreferenceSheet) {
            preferenceSheet
        }
        .onChange(of: viewModel.didComplete) { _, completed in
            if completed {
                Task {
                    try? await authManager.markQuizCompleted()
                    onCompleted()
                }
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var progressHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Question \(viewModel.currentIndex + 1) of \(viewModel.questions.count)")
                    .font(RidgitsTypography.caption())
                    .foregroundStyle(RidgitsColors.textSecondary)
                Spacer()
                if viewModel.currentQuestion.isSpicy {
                    Text("18+")
                        .font(RidgitsTypography.caption(11))
                        .foregroundStyle(RidgitsColors.destructive)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .overlay(Capsule().stroke(RidgitsColors.destructive.opacity(0.4), lineWidth: 1))
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(RidgitsColors.border)
                    Capsule()
                        .fill(RidgitsColors.ctaBlack)
                        .frame(width: geo.size.width * viewModel.progress)
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(RidgitsColors.surface)
        .overlay(Rectangle().frame(height: 1).foregroundStyle(RidgitsColors.border), alignment: .bottom)
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

    private var optionsList: some View {
        VStack(spacing: 10) {
            ForEach(viewModel.currentQuestion.options) { option in
                let selected = isSelected(option.value)
                Button {
                    viewModel.recordAnswer(optionValue: option.value)
                    if viewModel.currentQuestion.multiSelect == false {
                        preferredSelection = [option.value]
                    }
                } label: {
                    HStack {
                        Text(option.label)
                            .font(RidgitsTypography.body())
                            .foregroundStyle(RidgitsColors.textHeadline)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        if selected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(RidgitsColors.ctaBlack)
                        }
                    }
                    .padding(16)
                    .background(selected ? RidgitsColors.contextBar : RidgitsColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: RidgitsRadius.md)
                            .stroke(selected ? RidgitsColors.ctaBlack : RidgitsColors.border, lineWidth: selected ? 2 : 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.md))
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            if viewModel.currentIndex > 0 {
                RidgitsSecondaryButton(title: "Back") { viewModel.goBack() }
            }
            RidgitsPrimaryButton(
                title: viewModel.isLastQuestion ? "Finish" : "Next",
                isLoading: viewModel.isSaving,
                isDisabled: !viewModel.canAdvance
            ) {
                viewModel.goNext()
            }
        }
        .padding(20)
        .background(RidgitsColors.surface)
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
    }

    private func isSelected(_ value: Int) -> Bool {
        guard let record = viewModel.answers[viewModel.currentQuestion.id] else { return false }
        if viewModel.currentQuestion.multiSelect {
            return (record.answers ?? []).contains(value)
        }
        return record.answer == value
    }
}
