import AuthenticationServices
import FirebaseAuth
import Foundation
import UIKit

@MainActor
final class IdentityVerificationCoordinator: NSObject, ObservableObject {
    static let shared = IdentityVerificationCoordinator()

    @Published private(set) var isVerifying = false
    @Published private(set) var verificationSucceeded = false
    @Published var errorMessage: String?

    private var authSession: ASWebAuthenticationSession?
    private var pendingCompletion: ((Bool) -> Void)?

    private override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleIdentityReturnNotification),
            name: RidgitsAppLinks.identityVerificationCompleteNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// Runs the full Stripe Identity flow (ID + phone OTP + selfie when configured in Dashboard).
    func runVerificationFlow() async -> Bool {
        do {
            let status = try await RidgitsAPIClient.shared.fetchIdentityStatus()
            if status.canMessage {
                return true
            }
            if status.isStripeIdentityFlowComplete {
                _ = await RidgitsProfilePhotoIdentityMatch.matchAfterProfileSaveIfNeeded()
                let refreshed = try await RidgitsAPIClient.shared.fetchIdentityStatus()
                return refreshed.canMessage
            }
        } catch {
            errorMessage = RidgitsCustomerFacingError.sanitize(error.localizedDescription)
            return false
        }

        return await withCheckedContinuation { continuation in
            pendingCompletion = { success in
                continuation.resume(returning: success)
            }
            Task { await self.startVerificationFlow() }
        }
    }

    func startVerificationFlow() async {
        guard !isVerifying else { return }
        isVerifying = true
        verificationSucceeded = false
        errorMessage = nil
        defer { isVerifying = false }

        do {
            let session = try await RidgitsAPIClient.shared.createIdentityVerificationSession()
            guard let url = URL(string: session.verificationUrl) else {
                errorMessage = "Could not open identity verification."
                finish(success: false)
                return
            }
            presentVerification(url: url)
        } catch {
            if let ridgitsError = error as? RidgitsError {
                if ridgitsError.code == "IDENTITY_ALREADY_VERIFIED" {
                    finish(success: true)
                    return
                }
                if ridgitsError.code == "SUBSCRIPTION_REQUIRED" {
                    errorMessage = "Subscribe to Ridgits+ first to unlock identity verification."
                    finish(success: false)
                    return
                }
                if ridgitsError.code == "PROFILE_PHOTO_REQUIRED" {
                    errorMessage = "Add a profile photo on your profile before starting identity verification."
                    finish(success: false)
                    return
                }
            }
            errorMessage = RidgitsCustomerFacingError.sanitize(error.localizedDescription)
            finish(success: false)
        }
    }

    func handleReturnFromStripe() {
        Task { await pollUntilVerified() }
    }

    @objc private func handleIdentityReturnNotification() {
        handleReturnFromStripe()
    }

    private func presentVerification(url: URL) {
        authSession?.cancel()
        let session = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: RidgitsAppLinks.urlScheme
        ) { [weak self] callbackURL, error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    let nsError = error as NSError
                    if nsError.domain == ASWebAuthenticationSessionError.errorDomain,
                       nsError.code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        self.finish(success: false)
                        return
                    }
                }
                if let callbackURL, !RidgitsAppLinks.isIdentityCompleteURL(callbackURL) {
                    // Stripe may redirect through https first; deep link still triggers poll via notification.
                }
                await self.pollUntilVerified()
            }
        }
        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = false
        authSession = session
        if !session.start() {
            errorMessage = "Could not start verification in the browser."
            finish(success: false)
        }
    }

    private func pollUntilVerified() async {
        isVerifying = true
        defer { isVerifying = false }

        for attempt in 0..<30 {
            if attempt > 0 {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
            }
            do {
                let status = try await RidgitsAPIClient.shared.fetchIdentityStatus()
                if status.isStripeIdentityFlowComplete {
                    authSession?.cancel()
                    authSession = nil
                    _ = await RidgitsProfilePhotoIdentityMatch.matchAfterProfileSaveIfNeeded()
                    finish(success: true)
                    return
                }
            } catch {
                errorMessage = RidgitsCustomerFacingError.sanitize(error.localizedDescription)
                finish(success: false)
                return
            }
        }

        errorMessage = "Verification is still processing. Try again in a moment."
        finish(success: false)
    }

    private func finish(success: Bool) {
        authSession?.cancel()
        authSession = nil
        if success {
            verificationSucceeded = true
        }
        pendingCompletion?(success)
        pendingCompletion = nil
    }
}

extension IdentityVerificationCoordinator: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let window = scenes.flatMap(\.windows).first { $0.isKeyWindow }
        return window ?? ASPresentationAnchor()
    }
}
