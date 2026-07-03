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
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw RidgitsError.configuration("Firebase configuration error")
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
        guard let idToken = result.user.idToken?.tokenString else {
            throw RidgitsError.configuration("Missing Google ID token")
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )
        let authResult = try await Auth.auth().signIn(with: credential)
        try await saveUserProfile(
            uid: authResult.user.uid,
            email: authResult.user.email,
            fullName: authResult.user.displayName
        )
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

    func signOut() throws {
        isSigningOut = true
        defer { isSigningOut = false }
        try Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()
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

    private func saveUserProfile(uid: String, email: String?, fullName: String?) async throws {
        var payload: [String: Any] = [
            "lastLogin": FieldValue.serverTimestamp(),
            "accountCreationDate": FieldValue.serverTimestamp(),
        ]
        if let email { payload["email"] = email }
        if let fullName, !fullName.isEmpty { payload["name"] = fullName }
        try await Firestore.firestore().collection("users").document(uid).setData(payload, merge: true)
    }
}
