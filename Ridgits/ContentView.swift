import SwiftUI
import AuthenticationServices
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var ridgitsStore: RidgitsStore
    @EnvironmentObject private var referralStore: RidgitsReferralStore

    @State private var currentAppleNonce: String?
    @State private var showError = false
    @State private var errorMessage: String?
    @State private var quizCompleted = false
    @State private var profileComplete = false
    @State private var isBootstrapping = false
    @State private var showEmailAuthSheet = false
    @State private var sessionReady = false
    @State private var needsBirthYear = false
    @State private var needsReferralWelcome = false

    var body: some View {
        Group {
            if authManager.isCheckingAuthState || isBootstrapping {
                RidgitsLoadingView()
            } else if !authManager.userIsLoggedIn {
                loginView
            } else if ridgitsStore.isLoadingAccess && !sessionReady {
                RidgitsLoadingView()
            } else if needsReferralWelcome {
                ReferralWelcomeView {
                    needsReferralWelcome = false
                }
            } else if needsBirthYear {
                BirthYearPromptView {
                    needsBirthYear = false
                }
            } else if !quizCompleted {
                QuizView(mode: .onboarding) {
                    quizCompleted = true
                }
            } else if !profileComplete {
                ProfileSetupView {
                    profileComplete = true
                }
            } else {
                DashboardView()
            }
        }
        .task(id: authManager.userIsLoggedIn) {
            if authManager.userIsLoggedIn {
                await bootstrapSession()
            } else {
                quizCompleted = false
                profileComplete = false
                sessionReady = false
                needsReferralWelcome = false
                ridgitsStore.reset()
                referralStore.reset()
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Something went wrong.")
        }
        .sheet(isPresented: $showEmailAuthSheet) {
            EmailAuthSheet(
                onSignIn: { email, password in
                    try await authManager.signInWithEmail(email: email, password: password)
                },
                onSignUp: { email, password, birthYear in
                    try await authManager.createAccountWithEmail(
                        email: email,
                        password: password,
                        birthYear: birthYear
                    )
                }
            )
        }
    }

    private var loginView: some View {
        LoginView(
            onAppleRequest: configureAppleRequest,
            onAppleCompletion: handleAppleSignIn,
            onGoogleSignIn: signInWithGoogle,
            onEmailSignIn: { showEmailAuthSheet = true }
        )
    }

    private func bootstrapSession() async {
        isBootstrapping = true
        defer {
            isBootstrapping = false
            sessionReady = true
        }
        await ridgitsStore.bootstrap()
        guard let uid = authManager.currentUser?.uid else { return }

        if let anonymousCode = UserDefaults.standard.string(forKey: "ridgits_pending_referral_code_anonymous"),
           !anonymousCode.isEmpty {
            RidgitsReferralStorage.savePendingCode(anonymousCode, firebaseUid: uid)
            UserDefaults.standard.removeObject(forKey: "ridgits_pending_referral_code_anonymous")
        }

        await referralStore.loadReferral()

        let progress = try? await RidgitsFirebaseClient.shared.fetchQuizProgress(uid: uid)
        let answeredCount = progress.map { QuizCatalog.personalityAnsweredCount(in: $0.answers) } ?? 0
        let answeredEnough = answeredCount >= QuizCatalog.onboardingSkipThreshold
        let quizDoneFromServer = (try? await RidgitsFirebaseClient.shared.isQuizCompleted(uid: uid)) ?? false
        let quizDoneFromProgress = progress?.completed == true

        if answeredEnough && !quizDoneFromServer {
            if (try? await RidgitsFirebaseClient.shared.ensureQuizCompletionRecorded(uid: uid)) == true {
                authManager.onboardingCompleted = true
            }
        } else if quizDoneFromProgress && !quizDoneFromServer {
            if (try? await RidgitsFirebaseClient.shared.ensureQuizCompletionRecorded(uid: uid)) == true {
                authManager.onboardingCompleted = true
            }
        }

        quizCompleted = authManager.onboardingCompleted
            || quizDoneFromServer
            || quizDoneFromProgress
            || answeredEnough
        let profile = try? await RidgitsFirebaseClient.shared.fetchUserProfile(uid: uid)
        profileComplete = profile?.isCompleteForMatching ?? false
        needsBirthYear = await authManager.needsBirthYear()
        needsReferralWelcome = !quizCompleted
            && !RidgitsReferralStorage.hasSeenWelcome(firebaseUid: uid)
            && !referralStore.hasRedeemedReferralCode
    }

    private func configureAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = AppleSignInNonce.randomNonceString()
        currentAppleNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = AppleSignInNonce.sha256(nonce)
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let nonce = currentAppleNonce,
                  let tokenData = credential.identityToken,
                  let token = String(data: tokenData, encoding: .utf8) else {
                errorMessage = "Invalid Apple sign-in response"
                showError = true
                return
            }
            Task {
                do {
                    try await authManager.signInWithApple(
                        idToken: token,
                        nonce: nonce,
                        fullName: credential.fullName
                    )
                } catch {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }

    private func signInWithGoogle() {
        guard let presenter = RidgitsPresentation.topViewController() else {
            errorMessage = "Unable to present Google Sign-In"
            showError = true
            return
        }
        Task {
            do {
                try await authManager.signInWithGoogle(presenting: presenter)
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}
