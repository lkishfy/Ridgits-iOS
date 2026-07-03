import SwiftUI

struct ReferralProfileSection: View {
    @EnvironmentObject private var referralStore: RidgitsReferralStore

    @State private var redeemDraft = ""
    @State private var showShareSheet = false

    var body: some View {
        RidgitsDashboardCard {
            VStack(alignment: .leading, spacing: 16) {
                header

                if referralStore.isLoadingReferral, referralStore.referralProfile == nil {
                    loadingRow
                } else if let referral = referralStore.referralProfile {
                    codeCard(referral: referral)
                    progressLine(referral: referral)
                } else if referralStore.referralLoadFailed {
                    errorRow
                }

                if referralStore.hasRedeemedReferralCode {
                    redeemedSection
                } else {
                    redeemSection
                }

                if let message = referralStore.referralMessage, !message.isEmpty {
                    Text(message)
                        .font(RidgitsTypography.caption(13))
                        .foregroundStyle(RidgitsColors.textSecondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .task { await referralStore.loadReferral() }
        .sheet(isPresented: $showShareSheet) {
            if let message = referralStore.shareReferralMessage() {
                RidgitsShareSheet(items: [message])
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(RidgitsColors.textHeadline)
                Text("Refer friends")
                    .font(RidgitsTypography.headline(20))
                    .foregroundStyle(RidgitsColors.textHeadline)
            }
            Text("When a friend finishes their quiz, you unlock a free special quiz — up to \(RidgitsReferralLimits.maxReferrals) total.")
                .font(RidgitsTypography.body(13))
                .foregroundStyle(RidgitsColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var loadingRow: some View {
        HStack(spacing: 10) {
            ProgressView()
                .scaleEffect(0.9)
            Text("Loading your referral code…")
                .font(RidgitsTypography.body(13))
                .foregroundStyle(RidgitsColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }

    private var errorRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("We couldn't load your referral code right now.")
                .font(RidgitsTypography.body(13))
                .foregroundStyle(RidgitsColors.textSecondary)
            RidgitsSquareButton(title: "Try again", style: .outlined) {
                Task { await referralStore.loadReferral() }
            }
        }
    }

    private func codeCard(referral: RidgitsReferralProfile) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your code")
                .font(RidgitsTypography.label(11))
                .foregroundStyle(RidgitsColors.textSecondary)

            Text(referral.code)
                .font(.system(size: 17, weight: .semibold, design: .monospaced))
                .foregroundStyle(RidgitsColors.textHeadline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(RidgitsColors.inputSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: RidgitsRadius.md)
                        .stroke(RidgitsColors.inputBorder, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.md))

            HStack(spacing: 10) {
                RidgitsSquareButton(title: "Copy", style: .outlined) {
                    referralStore.copyReferralCodeToClipboard()
                }
                RidgitsSquareButton(title: "Share", style: .filled) {
                    showShareSheet = true
                }
            }
        }
    }

    private func progressLine(referral: RidgitsReferralProfile) -> some View {
        Group {
            if referral.canEarnMoreReferrals {
                Text("\(referral.referralsCompleted)/\(referral.maxReferrals) friends referred · \(referral.maxReferrals - referral.referralsCompleted) quiz\(referral.maxReferrals - referral.referralsCompleted == 1 ? "" : "zes") left to earn")
                    .font(RidgitsTypography.body(12))
                    .foregroundStyle(RidgitsColors.textSecondary)
            } else {
                Text("You've unlocked the maximum \(referral.maxReferrals) special quizzes from referrals.")
                    .font(RidgitsTypography.body(12))
                    .foregroundStyle(RidgitsColors.textSecondary)
            }
        }
    }

    private var redeemedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            RidgitsSectionDivider()
            Text("Friend's code on your account")
                .font(RidgitsTypography.label(11))
                .foregroundStyle(RidgitsColors.textSecondary)
            if let code = referralStore.redeemedReferralCode {
                Text(code)
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundStyle(RidgitsColors.textHeadline)
            }
            Text(referralStore.redeemedReferralStatusMessage)
                .font(RidgitsTypography.body(12))
                .foregroundStyle(RidgitsColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var redeemSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            RidgitsSectionDivider()
            Text("Have a friend's code?")
                .font(RidgitsTypography.label(11))
                .foregroundStyle(RidgitsColors.textSecondary)

            TextField("RIDGITS-XXXXXX", text: $redeemDraft)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(RidgitsColors.inputSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: RidgitsRadius.md)
                        .stroke(RidgitsColors.inputBorder, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.md))

            RidgitsPrimaryButton(
                title: "Apply code",
                isLoading: referralStore.isRedeemingReferral,
                isDisabled: redeemDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ) {
                Task {
                    let success = await referralStore.redeemReferralCode(redeemDraft, source: "profile")
                    if success { redeemDraft = "" }
                }
            }
        }
    }
}
