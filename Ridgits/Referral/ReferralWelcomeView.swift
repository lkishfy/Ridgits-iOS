import SwiftUI

struct ReferralWelcomeView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var referralStore: RidgitsReferralStore

    @State private var referralCode = ""
    @State private var validationTask: Task<Void, Never>?
    @State private var statusMessage: String?
    @State private var statusIsError = false

    let onComplete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 24)

            RidgitsLogoView.onLight(size: 36)

            Text("Welcome to Ridgits")
                .font(RidgitsTypography.headline(28))
                .foregroundStyle(RidgitsColors.textHeadline)
                .padding(.top, 20)

            Text("Got a friend's invite code? Enter it below. When you finish your personality quiz, they'll unlock a free special quiz — up to \(RidgitsReferralLimits.maxReferrals) friends.")
                .font(RidgitsTypography.body(15))
                .foregroundStyle(RidgitsColors.textSecondary)
                .padding(.top, 10)

            qualificationCallout
                .padding(.top, 16)

            TextField("RIDGITS-XXXXXX", text: $referralCode)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .font(RidgitsTypography.body(16))
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(RidgitsColors.inputSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: RidgitsRadius.md)
                        .stroke(RidgitsColors.inputBorder, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.md))
                .padding(.top, 20)
                .onChange(of: referralCode) { _, newValue in
                    scheduleValidation(for: newValue)
                }

            if let statusMessage {
                Text(statusMessage)
                    .font(RidgitsTypography.caption(13))
                    .foregroundStyle(statusIsError ? RidgitsColors.destructive : RidgitsColors.textSecondary)
                    .padding(.top, 10)
            }

            if referralStore.isRedeemingReferral {
                ProgressView()
                    .padding(.top, 12)
            }

            Spacer(minLength: 24)

            RidgitsPrimaryButton(
                title: referralCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Continue" : "Apply code & continue",
                isDisabled: referralStore.isRedeemingReferral
            ) {
                Task { await finishWelcome() }
            }

            Button("Skip for now") {
                Task {
                    if let uid = authManager.currentUser?.uid {
                        await referralStore.redeemPendingReferralIfNeeded(firebaseUid: uid)
                    }
                    markCompleteAndContinue()
                }
            }
            .font(RidgitsTypography.label(13))
            .foregroundStyle(RidgitsColors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 24)
        .background(RidgitsColors.feedBackground.ignoresSafeArea())
        .task {
            await referralStore.loadReferral()
            if referralStore.hasRedeemedReferralCode {
                markCompleteAndContinue()
                return
            }
            if let uid = authManager.currentUser?.uid,
               let pending = RidgitsReferralStorage.loadPendingCode(firebaseUid: uid),
               referralCode.isEmpty {
                referralCode = pending
            }
        }
    }

    private var qualificationCallout: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "gift.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(RidgitsColors.primaryBlue)
            Text(RidgitsReferralLimits.referredUserQualificationMotivation)
                .font(RidgitsTypography.body(13))
                .foregroundStyle(RidgitsColors.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RidgitsColors.hoverSurface)
        .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.md))
    }

    private func scheduleValidation(for value: String) {
        validationTask?.cancel()
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 8 else {
            statusMessage = nil
            return
        }

        validationTask = Task {
            try? await Task.sleep(nanoseconds: 450_000_000)
            guard !Task.isCancelled else { return }
            await redeemIfNeeded(trimmed, showSuccess: false)
        }
    }

    private func finishWelcome() async {
        let trimmed = referralCode.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            if let uid = authManager.currentUser?.uid {
                await referralStore.redeemPendingReferralIfNeeded(firebaseUid: uid)
            }
            markCompleteAndContinue()
            return
        }

        let success = await redeemIfNeeded(trimmed, showSuccess: true)
        if success || referralStore.hasRedeemedReferralCode {
            markCompleteAndContinue()
        }
    }

    @discardableResult
    private func redeemIfNeeded(_ code: String, showSuccess: Bool) async -> Bool {
        let success = await referralStore.redeemReferralCode(code, source: "welcome")
        if let message = referralStore.referralMessage {
            statusMessage = message
            statusIsError = !success && !referralStore.hasRedeemedReferralCode
        } else if showSuccess && success {
            statusMessage = "Code applied."
            statusIsError = false
        }
        if success, let uid = authManager.currentUser?.uid {
            RidgitsReferralStorage.clearPendingCode(firebaseUid: uid)
        }
        return success
    }

    private func markCompleteAndContinue() {
        if let uid = authManager.currentUser?.uid {
            RidgitsReferralStorage.markWelcomeSeen(firebaseUid: uid)
        }
        onComplete()
    }
}
