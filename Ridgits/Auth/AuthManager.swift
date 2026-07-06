import Foundation
import UIKit
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import GoogleSignIn

@MainActor
final class AuthManager: ObservableObject {
    @Published var userIsLoggedIn = false
    @Published var isCheckingAuthState = true
    @Published var isSigningOut = false
    @Published var onboardingCompleted = false
    @Published var currentUser: User?

    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?

    /// From Firebase Auth directly (not a Firestore field a client could fake). Google/Apple
    /// sign-ins are verified automatically; password accounts must click the emailed link.
    var emailVerified: Bool {
        currentUser?.isEmailVerified ?? false
    }

    init() {
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                self?.userIsLoggedIn = user != nil
                self?.isCheckingAuthState = false
                if let uid = user?.uid {
                    await self?.fetchOnboardingStatus(uid: uid)
                } else {
                    self?.onboardingCompleted = false
                }
            }
        }
    }

    deinit {
        if let handle = authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    func signInWithGoogle(presenting viewController: UIViewController) async throws {
        if GIDSignIn.sharedInstance.configuration == nil {
            GIDSignIn.sharedInstance.configuration = RidgitsFirebaseBootstrap.googleSignInConfiguration()
        }
        guard GIDSignIn.sharedInstance.configuration != nil else {
            throw RidgitsError.configuration("Firebase configuration error — is GoogleService-Info.plist in the app bundle?")
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
        guard let idToken = result.user.idToken?.tokenString else {
            throw RidgitsError.configuration("Missing Google ID token")
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )

        let authResult: AuthDataResult
        do {
            authResult = try await Auth.auth().signIn(with: credential)
        } catch {
            throw RidgitsError.configuration(
                "Firebase Google sign-in failed: \(Self.describeAuthError(error))"
            )
        }

        do {
            try await saveUserProfile(
                uid: authResult.user.uid,
                email: authResult.user.email,
                fullName: authResult.user.displayName
            )
        } catch {
            throw RidgitsError.configuration(
                "Signed in with Google, but could not save profile: \(error.localizedDescription)"
            )
        }
    }

    func signInWithEmail(email: String, password: String) async throws {
        let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
        try await saveUserProfile(
            uid: authResult.user.uid,
            email: authResult.user.email,
            fullName: authResult.user.displayName
        )
    }

    func createAccountWithEmail(email: String, password: String, birthYear: Int) async throws {
        // Authoritative server-side check — a modified client can't bypass this the way
        // it could a purely client-side disposable-email/age check.
        let validation = try await RidgitsAPIClient.shared.validateSignup(email: email, birthYear: birthYear)
        guard validation.ok else {
            throw RidgitsError.server(validation.error ?? "This email or birth year can't be used to sign up.")
        }

        let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
        try? await authResult.user.sendEmailVerification()
        try await saveUserProfile(
            uid: authResult.user.uid,
            email: authResult.user.email,
            fullName: nil,
            birthYear: birthYear,
            isNewAccount: true
        )
    }

    /// Resends the Firebase email-verification link to the signed-in user.
    func resendVerificationEmail() async throws {
        guard let user = Auth.auth().currentUser else { throw RidgitsError.notAuthenticated }
        try await user.sendEmailVerification()
    }

    /// Re-fetches the current user's Auth record so `emailVerified` reflects a just-clicked
    /// verification link without requiring a full sign-out/sign-in.
    func refreshEmailVerificationStatus() async {
        try? await Auth.auth().currentUser?.reload()
        currentUser = Auth.auth().currentUser
    }

    /// Google/Apple sign-in doesn't collect a birth year today, so new *and* legacy OAuth
    /// accounts may be missing it. Returns true when the current user has none on file.
    func needsBirthYear() async -> Bool {
        guard let uid = currentUser?.uid else { return false }
        let year = await RidgitsFirebaseClient.shared.fetchBirthYear(uid: uid)
        return year == nil
    }

    /// Completes the birth-year requirement for OAuth sign-ups (minimum age enforced both here and
    /// server-side via `/api/auth/validate-signup` + Firestore rules).
    func completeBirthYear(_ birthYear: Int) async throws {
        guard let uid = currentUser?.uid else { throw RidgitsError.notAuthenticated }
        let validation = try await RidgitsAPIClient.shared.validateSignup(birthYear: birthYear)
        guard validation.ok else {
            throw RidgitsError.server(validation.error ?? "Please enter a valid birth year.")
        }
        try await RidgitsFirebaseClient.shared.saveBirthYear(uid: uid, birthYear: birthYear)
    }

    func signInWithApple(idToken: String, nonce: String, fullName: PersonNameComponents?) async throws {
        let credential = OAuthProvider.appleCredential(
            withIDToken: idToken,
            rawNonce: nonce,
            fullName: fullName
        )
        let authResult = try await Auth.auth().signIn(with: credential)
        let composedName = [fullName?.givenName, fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        try await saveUserProfile(
            uid: authResult.user.uid,
            email: authResult.user.email ?? authResult.user.providerData.first?.email,
            fullName: composedName.isEmpty ? nil : composedName
        )
    }

    func reauthenticateWithPassword(_ password: String) async throws {
        guard let user = currentUser, let email = user.email else {
            throw RidgitsError.notAuthenticated
        }
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        try await user.reauthenticate(with: credential)
    }

    func signOut() throws {
        let uid = currentUser?.uid
        isSigningOut = true
        defer { isSigningOut = false }
        try Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()
        if let uid {
            RidgitsProfileCache.shared.clear(uid: uid)
            RidgitsMatchesCache.shared.clear(uid: uid)
            RidgitsConversationsCache.shared.clear(uid: uid)
            RidgitsPublicProfileCache.shared.clear()
        }
    }

    func idToken() async throws -> String {
        guard let user = Auth.auth().currentUser else {
            throw RidgitsError.notAuthenticated
        }
        return try await user.getIDToken()
    }

    func markQuizCompleted() async throws {
        guard let uid = currentUser?.uid else { return }
        onboardingCompleted = true
        try await Firestore.firestore()
            .collection("users")
            .document(uid)
            .setData(["onboardingCompleted": true, "quizCompletedAt": FieldValue.serverTimestamp()], merge: true)
    }

    private func fetchOnboardingStatus(uid: String) async {
        do {
            let doc = try await Firestore.firestore().collection("users").document(uid).getDocument()
            onboardingCompleted = doc.data()?["onboardingCompleted"] as? Bool ?? false
            let quizDone = try await RidgitsFirebaseClient.shared.isQuizCompleted(uid: uid)
            if quizDone { onboardingCompleted = true }
        } catch {
            onboardingCompleted = false
        }
    }

    private func saveUserProfile(
        uid: String,
        email: String?,
        fullName: String?,
        birthYear: Int? = nil,
        isNewAccount: Bool = false
    ) async throws {
        var payload: [String: Any] = [
            "lastLogin": FieldValue.serverTimestamp(),
        ]
        if isNewAccount {
            payload["createdAt"] = FieldValue.serverTimestamp()
            payload["accountCreationDate"] = FieldValue.serverTimestamp()
        }
        if let email { payload["email"] = email }
        if let fullName, !fullName.isEmpty { payload["name"] = fullName }
        if let birthYear {
            payload["birthYear"] = birthYear
            payload["age"] = Calendar.current.component(.year, from: Date()) - birthYear
            payload["ageVerificationConfirmed"] = true
            payload["ageVerifiedAt"] = ISO8601DateFormatter().string(from: Date())
        }
        try await Firestore.firestore().collection("users").document(uid).setData(payload, merge: true)
    }

    private static func describeAuthError(_ error: Error) -> String {
        let nsError = error as NSError
        if nsError.domain == AuthErrorDomain,
           let code = AuthErrorCode(rawValue: nsError.code) {
            switch code {
            case .internalError:
                return "Internal Firebase Auth error. If App Check is enforced, register the iOS app and add a debug token from Xcode console in Firebase → App Check."
            case .operationNotAllowed:
                return "Google sign-in is disabled in Firebase Console → Authentication → Sign-in method."
            case .invalidCredential:
                return "Invalid Google credential. Re-download GoogleService-Info.plist and confirm Google is enabled in Firebase."
            default:
                return "\(code) — \(nsError.localizedDescription)"
            }
        }
        return nsError.localizedDescription
    }
}
