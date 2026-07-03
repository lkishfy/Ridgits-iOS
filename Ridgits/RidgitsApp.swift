import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct RidgitsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var authManager = AuthManager()
    @StateObject private var ridgitsStore = RidgitsStore()
    @StateObject private var referralStore = RidgitsReferralStore()
    @StateObject private var deepLinkRouter = RidgitsDeepLinkRouter()
    @StateObject private var nearbyPresence = RidgitsNearbyPresenceService()
    @StateObject private var pokeInbox = RidgitsPokeInbox()

    init() {
        AppDelegate.pushService = RidgitsPushNotificationService.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(ridgitsStore)
                .environmentObject(referralStore)
                .environmentObject(deepLinkRouter)
                .environmentObject(nearbyPresence)
                .environmentObject(pokeInbox)
                .preferredColorScheme(.light)
                .onOpenURL { url in
                    _ = deepLinkRouter.handle(url)
                }
                .onAppear {
                    RidgitsPushNotificationService.shared.configure(deepLinkRouter: deepLinkRouter)
                }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                nearbyPresence.requestNotificationPermissionIfNeeded()
                RidgitsPushNotificationService.shared.requestAuthorizationAndRegister()
                Task { await RidgitsPushNotificationService.shared.syncTokenWithBackend() }
            }
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    static var pushService: RidgitsPushNotificationService?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        RidgitsFirebaseBootstrap.configureAppCheck()
        FirebaseApp.configure()
        configureGoogleSignIn()

        if let remoteNotification = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            Task { @MainActor in
                Self.pushService?.handleNotificationPayload(remoteNotification)
            }
        }

        for scene in application.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                window.backgroundColor = .white
            }
        }

        return true
    }

    private func configureGoogleSignIn() {
        GIDSignIn.sharedInstance.configuration = RidgitsFirebaseBootstrap.googleSignInConfiguration()
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task { @MainActor in
            Self.pushService?.handleDeviceToken(deviceToken)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("[RidgitsPush] APNs registration failed:", error.localizedDescription)
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }
}
