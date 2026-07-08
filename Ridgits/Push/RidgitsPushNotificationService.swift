import Foundation
import UIKit
import UserNotifications
import FirebaseMessaging

enum RidgitsEngagementRoute: Equatable {
    case home
    case matches(pokeFromUserId: String?, pokeId: String?)
    case messages(conversationId: String?)
    case ridgit(id: String)
    case pack(id: String)
}

@MainActor
final class RidgitsPushNotificationService: NSObject, ObservableObject {
    static let shared = RidgitsPushNotificationService()

    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var fcmToken: String?

    private var deepLinkRouter: RidgitsDeepLinkRouter?
    private var hasRegisteredCategories = false

    private override init() {
        super.init()
    }

    func configure(deepLinkRouter: RidgitsDeepLinkRouter) {
        self.deepLinkRouter = deepLinkRouter
        registerCategoriesIfNeeded()
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        refreshAuthorizationStatus()
    }

    func requestAuthorizationAndRegister() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
            Task { @MainActor in
                self.refreshAuthorizationStatus()
            }
        }
        UIApplication.shared.registerForRemoteNotifications()
    }

    func refreshAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }

    func handleDeviceToken(_ deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func syncTokenWithBackend() async {
        guard let token = fcmToken ?? Messaging.messaging().fcmToken,
              let deviceId = UIDevice.current.identifierForVendor?.uuidString else { return }
        try? await RidgitsAPIClient.shared.registerDevice(
            deviceId: deviceId,
            fcmToken: token,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
            deviceModel: UIDevice.current.model
        )
    }

    func unregisterFromBackend() async {
        guard let deviceId = UIDevice.current.identifierForVendor?.uuidString else { return }
        try? await RidgitsAPIClient.shared.unregisterDevice(deviceId: deviceId)
    }

    func handleNotificationPayload(_ userInfo: [AnyHashable: Any]) {
        let data = userInfo as? [String: Any] ?? [:]
        let merged = mergeDataPayload(userInfo: userInfo, data: data)

        if let route = parseRoute(from: merged) {
            deepLinkRouter?.route(to: route)
        }

        if let type = merged["type"] as? String {
            Task {
                try? await RidgitsAPIClient.shared.recordNotificationOpened(
                    type: type,
                    metadata: merged.compactMapValues { $0 as? String }
                )
            }
        }
    }

    private func registerCategoriesIfNeeded() {
        guard !hasRegisteredCategories else { return }
        hasRegisteredCategories = true

        let categories: [UNNotificationCategory] = [
            "RIDGITS_POKE",
            "RIDGITS_MESSAGE",
            "RIDGITS_MESSAGE_REQUEST",
            "RIDGITS_CONVERSATION_EXPIRING",
            "RIDGITS_CONVERSATION_APPROVED",
            "RIDGITS_NEARBY",
            "RIDGITS_RIDGIT",
            "RIDGITS_GENERAL",
        ].map { UNNotificationCategory(identifier: $0, actions: [], intentIdentifiers: [], options: []) }

        UNUserNotificationCenter.current().setNotificationCategories(Set(categories))
    }

    private func mergeDataPayload(userInfo: [AnyHashable: Any], data: [String: Any]) -> [String: Any] {
        var merged = data
        if let nested = data["data"] as? [String: Any] {
            merged.merge(nested) { _, new in new }
        }
        if let gcm = userInfo["gcm.notification.data"] as? [String: Any] {
            merged.merge(gcm) { _, new in new }
        }
        for (key, value) in userInfo {
            if let key = key as? String, merged[key] == nil, let string = value as? String {
                merged[key] = string
            }
        }
        return merged
    }

    private func parseRoute(from data: [String: Any]) -> RidgitsEngagementRoute? {
        if let ridgitId = data["ridgitId"] as? String, !ridgitId.isEmpty {
            return .ridgit(id: ridgitId)
        }

        switch data["route"] as? String {
        case "messages":
            return .messages(conversationId: data["conversationId"] as? String)
        case "matches":
            return .matches(
                pokeFromUserId: data["fromUserId"] as? String,
                pokeId: data["pokeId"] as? String
            )
        case "ridgit":
            if let ridgitId = data["ridgitId"] as? String { return .ridgit(id: ridgitId) }
            return nil
        default:
            if let conversationId = data["conversationId"] as? String {
                return .messages(conversationId: conversationId)
            }
            if data["pokeId"] != nil || data["fromUserId"] != nil {
                return .matches(
                    pokeFromUserId: data["fromUserId"] as? String,
                    pokeId: data["pokeId"] as? String
                )
            }
            return .home
        }
    }
}

extension RidgitsPushNotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        if notification.request.content.categoryIdentifier == "RIDGITS_NEARBY" {
            await MainActor.run {
                RidgitsHaptics.play(.warning)
            }
        }
        return [.banner, .sound, .badge]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        await MainActor.run {
            handleNotificationPayload(userInfo)
        }
    }
}

extension RidgitsPushNotificationService: MessagingDelegate {
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken else { return }
        Task { @MainActor in
            self.fcmToken = fcmToken
            await self.syncTokenWithBackend()
        }
    }
}
