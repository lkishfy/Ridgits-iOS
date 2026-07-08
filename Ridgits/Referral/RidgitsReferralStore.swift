import Foundation
import UIKit
import FirebaseAuth

@MainActor
final class RidgitsReferralStore: ObservableObject {
    @Published private(set) var referralProfile: RidgitsReferralProfile?
    @Published private(set) var referralMessage: String?
    @Published private(set) var isLoadingReferral = false
    @Published private(set) var referralLoadFailed = false
    @Published private(set) var isRedeemingReferral = false

    var hasRedeemedReferralCode: Bool {
        referralProfile?.hasRedeemedReferralCode == true
    }

    var redeemedReferralCode: String? {
        referralProfile?.redeemedReferralCode
    }

    var redeemedReferralStatusMessage: String {
        switch referralProfile?.redeemedReferralStatus {
        case "granted":
            return "Referral complete. You and your friend both unlocked a free special quiz."
        case "expired":
            return "Your last referral expired. Enter a new code below."
        case "pending":
            return RidgitsReferralLimits.referredUserQualificationMotivation
        default:
            return "This referral code is linked to your account and can't be changed."
        }
    }

    func loadReferral() async {
        isLoadingReferral = true
        referralLoadFailed = false
        defer { isLoadingReferral = false }

        do {
            let response = try await RidgitsAPIClient.shared.fetchReferralProfile()
            referralProfile = response.referral
            referralLoadFailed = false
            return
        } catch {
            referralProfile = nil
            referralLoadFailed = true
        }
    }

    @discardableResult
    func redeemReferralCode(_ code: String, source: String = "profile") async -> Bool {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            referralMessage = "Enter a referral code to redeem."
            return false
        }

        if hasRedeemedReferralCode {
            referralMessage = "You've already redeemed a referral code. Each account can only use one."
            return false
        }

        isRedeemingReferral = true
        referralMessage = nil
        defer { isRedeemingReferral = false }

        do {
            let response = try await RidgitsAPIClient.shared.redeemReferralCode(trimmed, source: source)
            if response.redeemed {
                if response.bonusPending == true {
                    referralMessage = "Referral code redeemed. \(RidgitsReferralLimits.referredUserQualificationMotivation)"
                } else {
                    referralMessage = "Referral code redeemed. Thanks for joining with a friend's invite."
                }
                await loadReferral()
                return true
            } else if response.alreadyRedeemed {
                referralMessage = "You've already redeemed a referral code. Each account can only use one."
            }
            await loadReferral()
            return false
        } catch let error as RidgitsError {
            switch error {
            case .serverCoded(let message, _):
                referralMessage = message.isEmpty ? "That referral code isn't valid." : message
            case .server(let message):
                referralMessage = message.isEmpty ? "That referral code isn't valid." : message
            default:
                referralMessage = "Could not redeem referral code. Try again."
            }
            return false
        } catch {
            referralMessage = "Could not redeem referral code. Try again."
            return false
        }
    }

    func redeemPendingReferralIfNeeded(firebaseUid: String) async {
        guard let pendingCode = RidgitsReferralStorage.loadPendingCode(firebaseUid: firebaseUid) else { return }

        let redeemed = await redeemReferralCode(pendingCode, source: "signup")
        if redeemed || hasRedeemedReferralCode {
            RidgitsReferralStorage.clearPendingCode(firebaseUid: firebaseUid)
        } else if let message = referralMessage,
                  message.contains("isn't valid") || message.contains("not found") || message.contains("Invalid") {
            RidgitsReferralStorage.clearPendingCode(firebaseUid: firebaseUid)
        }
    }

    func qualifyReferralIfNeeded() async {
        _ = try? await RidgitsAPIClient.shared.qualifyReferral()
        await loadReferral()
    }

    func copyReferralCodeToClipboard() {
        guard let code = referralProfile?.code else { return }
        UIPasteboard.general.string = code
        referralMessage = "Referral code copied."
    }

    func shareReferralMessage() -> String? {
        referralProfile?.shareMessage
    }

    func reset() {
        referralProfile = nil
        referralMessage = nil
        referralLoadFailed = false
        isLoadingReferral = false
        isRedeemingReferral = false
    }
}
