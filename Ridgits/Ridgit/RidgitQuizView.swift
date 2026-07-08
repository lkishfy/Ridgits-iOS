import SwiftUI
import FirebaseAuth

struct RidgitQuizView: View {
    let ridgitId: String

    @EnvironmentObject private var authManager: AuthManager
    @State private var ridgit: RidgitChallenge?
    @State private var isLoading = true
    @State private var currentQuestion = 0
    @State private var selectedAnswers: [Int?] = []
    @State private var isComplete = false
    @State private var attempts = 0
    @State private var isSubscribed = false
    @State private var compatibility: RidgitsCompatibility?
    @State private var showCompatibilityUnavailable = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(RidgitsColors.feedBackground)
            } else if let ridgit {
                quizContent(ridgit)
            } else {
                VStack(spacing: 12) {
                    Text("This ridgit no longer exists")
                        .font(RidgitsTypography.headline(18))
                        .foregroundStyle(RidgitsColors.textHeadline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(RidgitsColors.feedBackground)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    @ViewBuilder
    private func quizContent(_ ridgit: RidgitChallenge) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                if let compatibility, compatibility.hasScores, authManager.userIsLoggedIn {
                    RidgitQuizCompatibilityCard(
                        creatorFirstName: RidgitsDisplaySanitize.displayFirstName(ridgit.profile.name),
                        compatibility: compatibility
                    )
                }

                RidgitsDashboardCard {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 12) {
                            profileImage(for: ridgit.profile)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(ridgit.profile.name)
                                    .font(RidgitsTypography.label(16))
                                    .foregroundStyle(RidgitsColors.textHeadline)
                                Text(ridgit.profile.location)
                                    .font(RidgitsTypography.caption(12))
                                    .foregroundStyle(RidgitsColors.textSecondary)
                            }
                        }

                        Text(ridgit.title)
                            .font(RidgitsTypography.headline(18))
                            .foregroundStyle(RidgitsColors.textHeadline)

                        Text("Ridgit quizzes only work in the Ridgits app. Pass to unlock their social handle.")
                            .font(RidgitsTypography.caption(12))
                            .foregroundStyle(RidgitsColors.textMuted)

                        if showCompatibilityUnavailable, authManager.userIsLoggedIn, !isComplete {
                            Text("Complete the Ridgits quiz to see how compatible you are.")
                                .font(RidgitsTypography.caption(12))
                                .foregroundStyle(RidgitsColors.textMuted)
                        }

                        if !authManager.userIsLoggedIn {
                            Text("Sign in to Ridgits to take this quiz.")
                                .font(RidgitsTypography.body(13))
                                .foregroundStyle(RidgitsColors.textSecondary)
                        } else if isComplete {
                            successView(ridgit)
                        } else if !ridgit.questions.isEmpty, authManager.userIsLoggedIn {
                            let question = ridgit.questions[currentQuestion]
                            Text("Question \(currentQuestion + 1) of \(ridgit.questions.count)")
                                .font(RidgitsTypography.caption(11))
                                .foregroundStyle(RidgitsColors.textMuted)

                            Text(question.question)
                                .font(RidgitsTypography.body(15))
                                .foregroundStyle(RidgitsColors.textHeadline)

                            ForEach(Array(question.activeOptions.enumerated()), id: \.offset) { index, option in
                                Button {
                                    selectedAnswers[currentQuestion] = index
                                } label: {
                                    HStack {
                                        Text(option)
                                            .font(RidgitsTypography.body(13))
                                            .foregroundStyle(RidgitsColors.textHeadline)
                                        Spacer()
                                        if selectedAnswers.indices.contains(currentQuestion),
                                           selectedAnswers[currentQuestion] == index {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 12, weight: .bold))
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(
                                        selectedAnswers.indices.contains(currentQuestion) && selectedAnswers[currentQuestion] == index
                                        ? RidgitsColors.hoverSurface
                                        : RidgitsColors.surface
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: RidgitsRadius.sm)
                                            .stroke(
                                                selectedAnswers.indices.contains(currentQuestion) && selectedAnswers[currentQuestion] == index
                                                ? RidgitsColors.ctaBlack
                                                : RidgitsColors.border,
                                                lineWidth: 1
                                            )
                                    )
                                }
                                .buttonStyle(RidgitsHapticPlainButtonStyle())
                            }

                            RidgitsSquareButton(
                                title: currentQuestion == ridgit.questions.count - 1 ? "Submit Answers" : "Next",
                                style: .filled
                            ) {
                                advance(ridgit)
                            }
                            .disabled(!selectedAnswers.indices.contains(currentQuestion) || selectedAnswers[currentQuestion] == nil)

                            if attempts > 0 {
                                Text("Attempts: \(attempts)")
                                    .font(RidgitsTypography.caption(11))
                                    .foregroundStyle(RidgitsColors.textMuted)
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .padding(16)
        }
        .background(RidgitsColors.feedBackground)
    }

    @ViewBuilder
    private func successView(_ ridgit: RidgitChallenge) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("You passed!")
                .font(RidgitsTypography.headline(18))
                .foregroundStyle(RidgitsColors.textHeadline)
            if !ridgit.profile.socialInfo.isEmpty {
                Text("Connect:")
                    .font(RidgitsTypography.caption(11))
                    .foregroundStyle(RidgitsColors.textMuted)
                Text(ridgit.profile.socialInfo.displayText)
                    .font(RidgitsTypography.headline(20))
                    .foregroundStyle(RidgitsColors.textHeadline)
            } else {
                Text("They'll reach out soon.")
                    .font(RidgitsTypography.body(13))
                    .foregroundStyle(RidgitsColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    @ViewBuilder
    private func profileImage(for profile: RidgitsUserProfile) -> some View {
        Group {
            if let url = URL(string: profile.image), !profile.image.isEmpty {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image.resizable().scaledToFill()
                    } else {
                        Color(hex: 0xF5F5F5)
                    }
                }
            } else {
                Color(hex: 0xF5F5F5)
                    .overlay(Image(systemName: "person.fill").foregroundStyle(RidgitsColors.textMuted))
            }
        }
        .frame(width: 64, height: 64)
        .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.md))
        .overlay(RoundedRectangle(cornerRadius: RidgitsRadius.md).stroke(RidgitsColors.border, lineWidth: 1))
    }

    private func advance(_ ridgit: RidgitChallenge) {
        if currentQuestion < ridgit.questions.count - 1 {
            currentQuestion += 1
            return
        }

        let allCorrect = ridgit.questions.enumerated().allSatisfy { index, question in
            selectedAnswers.indices.contains(index) && selectedAnswers[index] == question.correctAnswer
        }

        if allCorrect {
            isComplete = true
        } else {
            attempts += 1
            currentQuestion = 0
            selectedAnswers = Array(repeating: nil, count: ridgit.questions.count)
        }
    }

    @MainActor
    private func load() async {
        isLoading = true
        defer { isLoading = false }
        ridgit = await RidgitsFirebaseClient.shared.fetchRidgit(id: ridgitId)
        if let ridgit {
            selectedAnswers = Array(repeating: nil, count: ridgit.questions.count)
            isSubscribed = await RidgitsFirebaseClient.shared.isUserSubscribed(uid: ridgit.userId)
            await loadCompatibility(for: ridgit)
        }
    }

    @MainActor
    private func loadCompatibility(for ridgit: RidgitChallenge) async {
        compatibility = nil
        showCompatibilityUnavailable = false

        guard authManager.userIsLoggedIn,
              let uid = Auth.auth().currentUser?.uid,
              uid != ridgit.userId else {
            return
        }

        if let scores = await RidgitsQuizCompatibility.compatibilityBetween(
            currentUserId: uid,
            otherUserId: ridgit.userId
        ), scores.hasScores {
            compatibility = scores
        } else {
            showCompatibilityUnavailable = true
        }
    }
}
