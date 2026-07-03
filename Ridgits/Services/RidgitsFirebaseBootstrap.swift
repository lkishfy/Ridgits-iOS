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
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let secrets = NSDictionary(contentsOfFile: path) as? [String: Any],
           let webClientID = secrets["googleWebClientID"] as? String,
           !webClientID.isEmpty {
            return webClientID
        }

        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path) as? [String: Any],
           let webClientID = plist["WEB_CLIENT_ID"] as? String,
           !webClientID.isEmpty {
            return webClientID
        }

        return nil
    }
}
