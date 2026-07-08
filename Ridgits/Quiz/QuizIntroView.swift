import SwiftUI

struct QuizIntroView: View {
    @EnvironmentObject private var authManager: AuthManager

    let onBegin: () -> Void

    @State private var showSignOutConfirmation = false
    @State private var isSigningOut = false

    private let totalQuestions = QuizCatalog.onboardingTotalQuestionCount

    var body: some View {
        VStack(spacing: 0) {
            introHeader

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    heroSection
                    statsSection
                    aboutSection
                    structureSection
                    disclaimerSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 48)
                .padding(.bottom, 64)
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .alert("Sign out of Ridgits?", isPresented: $showSignOutConfirmation) {
            Button("Sign Out", role: .destructive) {
                Task { await signOut() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You can return later to finish your quiz.")
        }
    }

    private var introHeader: some View {
        HStack {
            Text("Ridgits Archetype Quiz")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.black)
                .textCase(.uppercase)
                .tracking(1.6)

            Spacer()

            Button {
                showSignOutConfirmation = true
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.black)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
            .disabled(isSigningOut)
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(Color.white)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(hex: 0xE0E0E0))
                .frame(height: 1)
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            QuizIntroHeroStack()
                .padding(.bottom, 40)

            socialProofBadge
                .padding(.bottom, 24)

            Text("Find Your People")
                .font(.system(size: 32, weight: .regular))
                .foregroundStyle(Color.black)
                .tracking(-0.64)
                .padding(.bottom, 24)

            Text("Personality-based matching for adults seeking meaningful relationships or friendships")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(Color(hex: 0x666666))
                .lineSpacing(4)

            beginQuizButton
                .padding(.top, 24)
                .padding(.bottom, 32)

            whatToExpectSection
        }
        .padding(.bottom, 64)
    }

    private var socialProofBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "heart")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color(hex: 0xDB2777))

            Text("Over 465 quizzes complete this month")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color(hex: 0x9D174D))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(hex: 0xFDF2F8))
        .overlay(
            Capsule()
                .stroke(Color(hex: 0xFBCFE8), lineWidth: 1)
        )
        .clipShape(Capsule())
    }

    private var beginQuizButton: some View {
        Button(action: onBegin) {
            Text("Begin Quiz")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.white)
                .textCase(.uppercase)
                .tracking(1.12)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.black)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.black, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(RidgitsHapticPrimaryButtonStyle())
    }

    private var whatToExpectSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            expectRow(number: "1", text: "Answer honestly—no right or wrong answers")
            expectRow(number: "2", text: "Reflect as you go through self-discovery")
            expectRow(number: "3", text: "Get your archetype with personalized insights")
        }
    }

    private func expectRow(number: String, text: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(number)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color(hex: 0x999999))
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .stroke(Color(hex: 0xE0E0E0), lineWidth: 1)
                )

            Text(text)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color(hex: 0x666666))
                .lineSpacing(3)
        }
    }

    private var statsSection: some View {
        HStack(alignment: .top, spacing: 32) {
            statItem(value: "\(totalQuestions)", label: "Questions")
            statItem(value: "10-20", label: "Minutes")
            statItem(value: "8", label: "Archetypes")
        }
        .padding(.vertical, 24)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color(hex: 0xE0E0E0))
                .frame(height: 1)
        }
        .padding(.bottom, 48)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(Color.black)

            Text(label)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color(hex: 0x999999))
                .textCase(.uppercase)
                .tracking(1.1)
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("About Our Quiz")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(Color.black)
                .tracking(-0.24)
                .padding(.bottom, 16)

            Text("Based on validated frameworks in connection and relationship psychology:")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color(hex: 0x666666))
                .lineSpacing(4)
                .padding(.bottom, 32)

            frameworkRow(
                title: "Attachment Theory",
                description: "Early relationships shape adult bonding patterns"
            )
            frameworkRow(
                title: "Expression Styles",
                description: "How people express and receive affection"
            )
            frameworkRow(
                title: "Value Congruence",
                description: "Shared values predict relationship stability"
            )
            frameworkRow(
                title: "Communication Patterns",
                description: "How we connect and resolve conflict"
            )
        }
        .padding(.bottom, 48)
    }

    private func frameworkRow(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.black)

            Text(description)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color(hex: 0x666666))
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 24)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(hex: 0xE0E0E0))
                .frame(height: 1)
        }
    }

    private var structureSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Quiz Structure")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(Color.black)
                .tracking(-0.24)
                .padding(.top, 32)
                .padding(.bottom, 16)

            Text("Start with demographics, then five dimensions exploring how you connect with others—whether for friendship or romance. Your archetype is created after answering at least 50 questions.")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color(hex: 0x666666))
                .lineSpacing(4)
                .padding(.bottom, 32)

            structureRow(
                number: "01",
                title: "Communication & Connection",
                description: "Expression, conflict resolution, emotional intimacy.",
                questionCount: "20 questions"
            )
            structureRow(
                number: "02",
                title: "Closeness & Bonding",
                description: "How you build trust and deepen connections.",
                questionCount: "20 questions"
            )
            structureRow(
                number: "03",
                title: "Values & Lifestyle",
                description: "Core beliefs, priorities, long-term goals, political and ideological views.",
                questionCount: "37 questions"
            )
            structureRow(
                number: "04",
                title: "Social Life & Personality",
                description: "Social energy, boundaries, interpersonal style.",
                questionCount: "22 questions"
            )
            structureRow(
                number: "05",
                title: "Commitment & Future",
                description: "Connection goals, timeline, and what you're looking for.",
                questionCount: "20 questions"
            )
        }
        .padding(.bottom, 48)
    }

    private func structureRow(
        number: String,
        title: String,
        description: String,
        questionCount: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 16) {
                Text(number)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color(hex: 0x999999))

                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.black)
            }

            Text(description)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color(hex: 0x666666))
                .lineSpacing(3)

            Text(questionCount)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color(hex: 0x999999))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 20)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(hex: 0xE0E0E0))
                .frame(height: 1)
        }
    }

    private var disclaimerSection: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color(hex: 0xE0E0E0))
                .frame(height: 1)
                .padding(.bottom, 24)

            Text(disclaimerMarkdown)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color(hex: 0x999999))
                .tint(Color(hex: 0x666666))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .frame(maxWidth: .infinity)
        }
        .padding(.top, 32)
    }

    private var disclaimerMarkdown: LocalizedStringKey {
        let terms = RidgitsAppLinks.terms.absoluteString
        let privacy = RidgitsAppLinks.privacy.absoluteString
        return "You must be \(RidgitsMinimumAge.accountYears) years or older to use this service. By continuing, you agree to our [Terms of Service](\(terms)) and [Privacy Policy](\(privacy))."
    }

    @MainActor
    private func signOut() async {
        guard !isSigningOut else { return }
        isSigningOut = true
        defer { isSigningOut = false }
        try? authManager.signOut()
    }
}

// MARK: - Hero stack (matches ridgits.com/quiz-intro)

private struct QuizIntroHeroStack: View {
    private let cardSize: CGFloat = 200
    private let containerSize: CGFloat = 280

    var body: some View {
        ZStack {
            heroCard("HeroStack4", rotation: -12, xOffset: -30, zIndex: 1)
            heroCard("HeroStack3", rotation: -4, xOffset: -10, zIndex: 2)
            heroCard("HeroStack2", rotation: 4, xOffset: 10, zIndex: 3)
            heroCard("HeroStack1", rotation: 12, xOffset: 30, zIndex: 4)
        }
        .frame(width: containerSize, height: containerSize)
        .frame(maxWidth: .infinity)
    }

    private func heroCard(_ imageName: String, rotation: Double, xOffset: CGFloat, zIndex: Double) -> some View {
        Image(imageName)
            .resizable()
            .scaledToFill()
            .frame(width: cardSize, height: cardSize)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
            .rotationEffect(.degrees(rotation))
            .offset(x: xOffset)
            .zIndex(zIndex)
    }
}
