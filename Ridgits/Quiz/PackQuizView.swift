import SwiftUI

struct PackQuizView: View {
    let pack: RidgitsArchetypePack
    var forceRetake: Bool = false
    var onCompleted: (() -> Void)?
    var onDismiss: (() -> Void)?

    @StateObject private var viewModel: PackQuizViewModel

    init(
        pack: RidgitsArchetypePack,
        forceRetake: Bool = false,
        onCompleted: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.pack = pack
        self.forceRetake = forceRetake
        self.onCompleted = onCompleted
        self.onDismiss = onDismiss
        _viewModel = StateObject(wrappedValue: PackQuizViewModel(pack: pack))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading quiz…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.questions.isEmpty {
                missingQuizContent
            } else if viewModel.showResults, let result = viewModel.result {
                PackAnalysisView(
                    pack: pack,
                    result: result.archetype,
                    embedInNavigationStack: false
                )
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Close") { finish() }
                            .foregroundStyle(RidgitsColors.textSecondary)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Retake") {
                            Task { await viewModel.bootstrap(forceRetake: true) }
                        }
                        .foregroundStyle(RidgitsColors.textSecondary)
                    }
                }
            } else {
                quizContent
            }
        }
        .background(RidgitsColors.feedBackground)
        .navigationTitle(pack.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !viewModel.showResults {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { onDismiss?() }
                        .foregroundStyle(RidgitsColors.textSecondary)
                }
            }
        }
        .task(id: forceRetake) {
            await viewModel.bootstrap(forceRetake: forceRetake)
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onChange(of: viewModel.showResults) { _, completed in
            if completed {
                RidgitsHaptics.play(.success)
                onCompleted?()
            }
        }
    }

    private var missingQuizContent: some View {
        VStack(spacing: 12) {
            Text("Quiz unavailable")
                .font(RidgitsTypography.headline())
            Text("This pack could not be loaded. Try updating the app.")
                .font(RidgitsTypography.body(14))
                .foregroundStyle(RidgitsColors.textSecondary)
                .multilineTextAlignment(.center)
            RidgitsPrimaryButton(title: "Close") { onDismiss?() }
                .padding(.top, 8)
        }
        .padding(24)
    }

    private var quizContent: some View {
        VStack(spacing: 0) {
            progressHeader

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(viewModel.currentQuestion.category.uppercased())
                        .font(RidgitsTypography.caption(11))
                        .foregroundStyle(RidgitsColors.textMuted)
                        .tracking(1)

                    Text(viewModel.currentQuestion.text)
                        .font(RidgitsTypography.headline(22))
                        .foregroundStyle(RidgitsColors.textHeadline)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(spacing: 10) {
                        ForEach(viewModel.currentQuestion.options) { option in
                            let selected = viewModel.answers[viewModel.currentQuestion.id] == option.value
                            Button {
                                viewModel.selectAnswer(option.value)
                            } label: {
                                HStack {
                                    Text(option.label)
                                        .font(RidgitsTypography.body())
                                        .foregroundStyle(selected ? .white : RidgitsColors.textHeadline)
                                        .multilineTextAlignment(.leading)
                                    Spacer()
                                    if selected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.white)
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
                            .buttonStyle(RidgitsHapticPlainButtonStyle())
                        }
                    }
                }
                .padding(20)
            }

            footer
        }
    }

    private var progressHeader: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(RidgitsColors.border)
                    Capsule()
                        .fill(RidgitsColors.ctaBlack)
                        .frame(width: geo.size.width * viewModel.progressFraction)
                }
            }
            .frame(height: 6)

            Text("Question \(viewModel.currentIndex + 1) of \(viewModel.questions.count)")
                .font(RidgitsTypography.caption(11))
                .foregroundStyle(RidgitsColors.textSecondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(RidgitsColors.surface)
        .overlay(Rectangle().frame(height: 1).foregroundStyle(RidgitsColors.border), alignment: .bottom)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            RidgitsSquareButton(title: "Back", style: .outlined) {
                viewModel.goBack()
            }
            .disabled(viewModel.isFirst)

            if viewModel.isLast {
                RidgitsSquareButton(
                    title: viewModel.isSaving ? "Saving…" : "See Results",
                    style: .filled
                ) {
                    Task { await viewModel.submit() }
                }
                .disabled(!viewModel.isComplete || viewModel.isSaving)
            } else {
                RidgitsSquareButton(title: "Next", style: .filled) {
                    viewModel.goForward()
                }
                .disabled(viewModel.answers[viewModel.currentQuestion.id] == nil)
            }
        }
        .padding(20)
        .background(RidgitsColors.surface)
        .overlay(Rectangle().frame(height: 1).foregroundStyle(RidgitsColors.border), alignment: .top)
    }

    private func finish() {
        onCompleted?()
        onDismiss?()
    }
}
