import FirebaseCore
import FirebaseAppCheck
import GoogleSignIn

final class RidgitsAppAttestProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        AppAttestProvider(app: app)
    }
}

enum RidgitsFirebaseBootstrap {
    static func configureAppCheck() {
        #if DEBUG
        let providerFactory = AppCheckDebugProviderFactory()
        print("🔐 Ridgits App Check: using DEBUG provider")
        print("🔐 After launch, copy the 'Firebase App Check debug token' from Xcode console")
        print("🔐 Firebase Console → App Check → Ridgits iOS → Manage debug tokens")
        #else
        let providerFactory = RidgitsAppAttestProviderFactory()
        print("🔐 Ridgits App Check: using App Attest provider")
        #endif
        AppCheck.setAppCheckProviderFactory(providerFactory)
    }

    static func googleSignInConfiguration() -> GIDConfiguration? {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return nil }
        if let webClientID = googleWebClientID() {
            return GIDConfiguration(clientID: clientID, serverClientID: webClientID)
        }
        return GIDConfiguration(clientID: clientID)
    }

    private static func googleWebClientID() -> String? {
        for source in [secretsWebClientID(), googleServiceWebClientID()] {
            if let source, isValidGoogleOAuthClientID(source) {
                return source
            }
        }
        return nil
    }

    private static func secretsWebClientID() -> String? {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let secrets = NSDictionary(contentsOfFile: path) as? [String: Any],
              let webClientID = secrets["googleWebClientID"] as? String else {
            return nil
        }
        return webClientID
    }

    private static func googleServiceWebClientID() -> String? {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path) as? [String: Any],
              let webClientID = plist["WEB_CLIENT_ID"] as? String else {
            return nil
        }
        return webClientID
    }

    /// Rejects template values like `YOUR_FIREBASE_WEB_CLIENT_ID.apps.googleusercontent.com`.
    private static func isValidGoogleOAuthClientID(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        if trimmed.localizedCaseInsensitiveContains("YOUR_") { return false }
        return trimmed.range(
            of: #"^\d+-[\w-]+\.apps\.googleusercontent\.com$"#,
            options: .regularExpression
        ) != nil
    }
}
