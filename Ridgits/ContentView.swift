import SwiftUI
import AuthenticationServices
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var ridgitsStore: RidgitsStore

    @State private var currentAppleNonce: String?
    @State private var showError = false
    @State private var errorMessage: String?
    @State private var quizCompleted = false
    @State private var profileComplete = false
    @State private var isBootstrapping = false

    var body: some View {
        Group {
            if authManager.isCheckingAuthState || isBootstrapping {
                RidgitsLoadingView()
            } else if !authManager.userIsLoggedIn {
                loginView
            } else if ridgitsStore.isLoadingAccess {
                RidgitsLoadingView()
            } else if !quizCompleted {
                QuizView {
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
                ridgitsStore.reset()
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Something went wrong.")
        }
    }

    private var loginView: some View {
        LoginView(
            onAppleRequest: configureAppleRequest,
            onAppleCompletion: handleAppleSignIn,
            onGoogleSignIn: signInWithGoogle
        )
    }

    private func bootstrapSession() async {
        isBootstrapping = true
        defer { isBootstrapping = false }
        await ridgitsStore.bootstrap()
        guard let uid = authManager.currentUser?.uid else { return }
        let quizDone = (try? await RidgitsFirebaseClient.shared.isQuizCompleted(uid: uid)) ?? false
        quizCompleted = authManager.onboardingCompleted || quizDone
        let profile = try? await RidgitsFirebaseClient.shared.fetchUserProfile(uid: uid)
        profileComplete = profile?.isCompleteForMatching ?? false
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
        guard let root = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController else {
            errorMessage = "Unable to present Google Sign-In"
            showError = true
            return
        }
        Task {
            do {
                try await authManager.signInWithGoogle(presenting: root)
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}
