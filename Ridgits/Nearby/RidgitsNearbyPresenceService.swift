import Foundation
import MultipeerConnectivity
import UIKit
import UserNotifications
import CryptoKit

/// Discovers other Ridgits users nearby via Bluetooth/Wi‑Fi (MultipeerConnectivity),
/// sends match pings, and supports consent-based nearby Ridgit quiz handoff.
@MainActor
final class RidgitsNearbyPresenceService: NSObject, ObservableObject {
    @Published private(set) var isActive = false
    @Published private(set) var nearbyPeerCount = 0
    @Published private(set) var nearbyPeers: [RidgitNearbyPeer] = []
    @Published private(set) var sharePhase: RidgitSharePhase = .idle
    @Published private(set) var pendingShareInvitation: RidgitPendingShareInvitation?
    @Published var alertsEnabled: Bool {
        didSet { UserDefaults.standard.set(alertsEnabled, forKey: Self.alertsKey) }
    }

    private static let serviceType = "ridgits-nearby"
    private static let alertsKey = "ridgits.nearbyAlertsEnabled"
    private static let notificationCooldown: TimeInterval = 300
    private static let inviteTimeout: TimeInterval = 45

    private var peerID: MCPeerID?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private var session: MCSession?

    private var discoveredPeerKeys = Set<String>()
    private var peerRegistry: [String: MCPeerID] = [:]
    private var peerDiscoveryInfo: [String: [String: String]] = [:]
    private var lastNotificationAt: [String: Date] = [:]

    private var wantsMatchingAlerts = false
    private var wantsRidgitShareListening = false
    private var isShareSenderActive = false
    private var pendingSharePayload: RidgitSharePayload?
    private var pendingInvitationHandler: ((Bool, MCSession?) -> Void)?
    private var pendingInvitationPeer: MCPeerID?

    private var displayName = "Ridgits User"
    private var userId: String?
    private var isAppActive = true
    private var backgroundKeepAliveTask: UIBackgroundTaskIdentifier = .invalid

    override init() {
        alertsEnabled = UserDefaults.standard.object(forKey: Self.alertsKey) as? Bool ?? true
        super.init()
        registerNotificationCategoryIfNeeded()
    }

    func handleAppBecameActive() {
        isAppActive = true
        endBackgroundKeepAliveTaskIfNeeded()
        refreshDiscoverySession()
        requestNotificationPermissionIfNeeded()
    }

    func handleAppEnteredBackground() {
        isAppActive = false
        refreshDiscoverySession()
        beginBackgroundKeepAliveTaskIfNeeded()
    }

    // MARK: - Public API (matches presence)

    func updateEligibility(isSignedIn: Bool, profileComplete: Bool, hasNearbyAccess: Bool, displayName: String, userId: String?) {
        wantsMatchingAlerts = isSignedIn && profileComplete && hasNearbyAccess
        self.displayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.userId = userId
        syncSessionLifecycle()
    }

    /// Keeps MCP available for incoming Ridgit shares for any signed-in user.
    func updateShareListening(isSignedIn: Bool, displayName: String, userId: String?) {
        wantsRidgitShareListening = isSignedIn
        self.displayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.userId = userId
        syncSessionLifecycle()
    }

    func pause() {
        wantsMatchingAlerts = false
        wantsRidgitShareListening = false
        cancelShareFlow(resetSession: true)
        syncSessionLifecycle()
    }

    // MARK: - Public API (Ridgit share)

    func beginSharingRidgit(_ payload: RidgitSharePayload) {
        pendingSharePayload = payload
        isShareSenderActive = true
        sharePhase = .searching
        syncSessionLifecycle()

        if let peer = nearbyPeers.first {
            invitePeer(id: peer.id, payload: payload)
        }
    }

    func invitePeer(id: String, payload: RidgitSharePayload? = nil) {
        guard let peer = peerRegistry[id] else {
            sharePhase = .failed("That person is no longer nearby.")
            return
        }
        let payload = payload ?? pendingSharePayload
        guard let payload else { return }

        pendingSharePayload = payload
        isShareSenderActive = true
        ensureSession()

        guard let browser, let session else {
            sharePhase = .failed("Could not start nearby sharing.")
            return
        }

        sharePhase = .inviting(peerName: peer.displayName)
        browser.invitePeer(peer, to: session, withContext: payload.invitationContext, timeout: Self.inviteTimeout)
    }

    func acceptPendingShareInvitation() {
        guard let handler = pendingInvitationHandler else { return }
        ensureSession()
        guard let session else {
            declinePendingShareInvitation()
            return
        }
        handler(true, session)
        pendingInvitationHandler = nil
        if let preview = pendingShareInvitation?.preview {
            sharePhase = .connecting(peerName: preview.senderName)
        }
    }

    func declinePendingShareInvitation() {
        pendingInvitationHandler?(false, nil)
        clearPendingInvitation()
        if case .incomingInvite = sharePhase {
            sharePhase = .idle
        }
    }

    func cancelShareFlow(resetSession: Bool = false) {
        isShareSenderActive = false
        pendingSharePayload = nil
        declinePendingShareInvitation()
        sharePhase = .idle
        if resetSession {
            disconnectSession()
        }
    }

    func clearReceivedShare() {
        if case .received = sharePhase {
            sharePhase = .idle
        }
    }

    func requestNotificationPermissionIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        }
    }

    private func registerNotificationCategoryIfNeeded() {
        let category = UNNotificationCategory(
            identifier: "RIDGITS_NEARBY",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().getNotificationCategories { existing in
            guard !existing.contains(where: { $0.identifier == category.identifier }) else { return }
            var categories = existing
            categories.insert(category)
            UNUserNotificationCenter.current().setNotificationCategories(categories)
        }
    }

    private func refreshDiscoverySession() {
        #if targetEnvironment(simulator)
        return
        #endif
        guard isActive, advertiser != nil, browser != nil else { return }
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        advertiser?.startAdvertisingPeer()
        browser?.startBrowsingForPeers()
    }

    private func beginBackgroundKeepAliveTaskIfNeeded() {
        guard backgroundKeepAliveTask == .invalid else { return }
        backgroundKeepAliveTask = UIApplication.shared.beginBackgroundTask(withName: "ridgits.nearby.discovery") { [weak self] in
            Task { @MainActor in
                self?.endBackgroundKeepAliveTaskIfNeeded()
            }
        }
    }

    private func endBackgroundKeepAliveTaskIfNeeded() {
        guard backgroundKeepAliveTask != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundKeepAliveTask)
        backgroundKeepAliveTask = .invalid
    }

    // MARK: - Session lifecycle

    private func syncSessionLifecycle() {
        let shouldRun = wantsMatchingAlerts || wantsRidgitShareListening || isShareSenderActive
        if shouldRun {
            startIfNeeded()
        } else {
            stop()
        }
    }

    private func startIfNeeded() {
        #if targetEnvironment(simulator)
        return
        #endif

        let name = Self.opaquePeerDisplayName(for: userId)
        if isActive, peerID?.displayName != name {
            stop()
        }
        guard !isActive else { return }

        let peer = MCPeerID(displayName: name)
        peerID = peer

        let info = ["app": "ridgits"]

        let advertiser = MCNearbyServiceAdvertiser(peer: peer, discoveryInfo: info, serviceType: Self.serviceType)
        advertiser.delegate = self
        self.advertiser = advertiser

        let browser = MCNearbyServiceBrowser(peer: peer, serviceType: Self.serviceType)
        browser.delegate = self
        self.browser = browser

        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
        isActive = true
    }

    private func stop() {
        disconnectSession()
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        advertiser = nil
        browser = nil
        peerID = nil
        discoveredPeerKeys.removeAll()
        peerRegistry.removeAll()
        peerDiscoveryInfo.removeAll()
        nearbyPeers = []
        nearbyPeerCount = 0
        isActive = false
    }

    private func ensureSession() {
        guard let peerID else { return }
        if session == nil {
            let session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
            session.delegate = self
            self.session = session
        }
    }

    private func disconnectSession() {
        session?.disconnect()
        session?.delegate = nil
        session = nil
    }

    // MARK: - Peer registry

    private func registerPeer(_ peerID: MCPeerID, discoveryInfo: [String: String]?) {
        guard discoveryInfo?["app"] == "ridgits" else { return }
        let key = peerID.displayName
        let isNew = discoveredPeerKeys.insert(key).inserted
        peerRegistry[key] = peerID
        peerDiscoveryInfo[key] = discoveryInfo
        rebuildNearbyPeers()
        nearbyPeerCount = discoveredPeerKeys.count

        if isShareSenderActive, case .searching = sharePhase, let payload = pendingSharePayload {
            invitePeer(id: key, payload: payload)
        }

        guard isNew, wantsMatchingAlerts, alertsEnabled else { return }
        if isAppActive {
            RidgitsHaptics.play(.warning)
        }
        notifyNearbyPerson(named: peerID.displayName, key: key)
    }

    private func unregisterPeer(_ peerID: MCPeerID) {
        let key = peerID.displayName
        discoveredPeerKeys.remove(key)
        peerRegistry.removeValue(forKey: key)
        peerDiscoveryInfo.removeValue(forKey: key)
        rebuildNearbyPeers()
        nearbyPeerCount = discoveredPeerKeys.count
    }

    private func rebuildNearbyPeers() {
        nearbyPeers = discoveredPeerKeys.sorted().map { key in
            RidgitNearbyPeer(
                id: key,
                displayName: key,
                profileCode: nil
            )
        }
    }

    private static func opaquePeerDisplayName(for uid: String?) -> String {
        guard let uid, !uid.isEmpty else { return "Ridgits-User" }
        let digest = SHA256.hash(data: Data(uid.utf8))
        let prefix = digest.prefix(4).map { String(format: "%02x", $0) }.joined()
        return "Ridgits-\(prefix)"
    }

    private func notifyNearbyPerson(named name: String, key: String) {
        let now = Date()
        if let last = lastNotificationAt[key], now.timeIntervalSince(last) < Self.notificationCooldown {
            return
        }
        lastNotificationAt[key] = now

        let content = UNMutableNotificationContent()
        content.title = "Ridgits person nearby"
        content.body = "\(name) is close by. Open Matches to see who's around."
        content.sound = .default
        content.categoryIdentifier = "RIDGITS_NEARBY"
        content.userInfo = [
            "route": "matches",
            "type": "nearby_bluetooth",
        ]
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }

        let request = UNNotificationRequest(
            identifier: "ridgits.nearby.\(key)",
            content: content,
            trigger: nil
        )

        let backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "ridgits.nearby.alert")
        UNUserNotificationCenter.current().add(request) { _ in
            if backgroundTask != .invalid {
                UIApplication.shared.endBackgroundTask(backgroundTask)
            }
        }
    }

    private func clearPendingInvitation() {
        pendingInvitationHandler = nil
        pendingInvitationPeer = nil
        pendingShareInvitation = nil
    }

    private func sendPendingPayloadIfNeeded() {
        guard isShareSenderActive,
              let payload = pendingSharePayload,
              let session,
              !session.connectedPeers.isEmpty else { return }

        guard let data = try? JSONEncoder().encode(payload) else { return }
        sharePhase = .sending
        do {
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
            let peerName = session.connectedPeers.first?.displayName ?? "Someone nearby"
            sharePhase = .sent(peerName: peerName)
            isShareSenderActive = false
            pendingSharePayload = nil
        } catch {
            sharePhase = .failed("Could not send your Ridgit. Try again.")
        }
    }
}

// MARK: - Advertiser

extension RidgitsNearbyPresenceService: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        Task { @MainActor in
            guard let preview = RidgitSharePayload.decodeInvitationContext(context) else {
                invitationHandler(false, nil)
                return
            }

            pendingInvitationHandler = invitationHandler
            pendingInvitationPeer = peerID
            pendingShareInvitation = RidgitPendingShareInvitation(peerName: preview.senderName, preview: preview)
            sharePhase = .incomingInvite(preview)
        }
    }
}

// MARK: - Browser

extension RidgitsNearbyPresenceService: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        Task { @MainActor in
            registerPeer(peerID, discoveryInfo: info)
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Task { @MainActor in
            unregisterPeer(peerID)
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        Task { @MainActor in
            if isShareSenderActive {
                sharePhase = .failed(error.localizedDescription)
            }
        }
    }
}

// MARK: - Session

extension RidgitsNearbyPresenceService: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            switch state {
            case .connected:
                if isShareSenderActive {
                    sharePhase = .connecting(peerName: peerID.displayName)
                    sendPendingPayloadIfNeeded()
                }
            case .notConnected:
                if case .connecting = sharePhase {
                    sharePhase = .idle
                }
                if case .sending = sharePhase {
                    sharePhase = .failed("Connection lost before the Ridgit was sent.")
                }
            case .connecting:
                if isShareSenderActive {
                    sharePhase = .connecting(peerName: peerID.displayName)
                }
            @unknown default:
                break
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task { @MainActor in
            guard let payload = try? JSONDecoder().decode(RidgitSharePayload.self, from: data) else { return }
            sharePhase = .received(payload)
            pendingShareInvitation = RidgitPendingShareInvitation(peerName: payload.senderName, preview: payload)
        }
    }

    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
