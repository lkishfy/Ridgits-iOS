import SwiftUI

struct ReferralQuizGatePresentation: Identifiable {
    let id: Int
    let slot: Int
    let pack: RidgitsArchetypePack
}

struct ReferralQuizGateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var referralStore: RidgitsReferralStore

    let slot: Int
    let pack: RidgitsArchetypePack

    @State private var showShareSheet = false
    @State private var didAutoPresentShare = false

    private var referralsCompleted: Int {
        referralStore.referralProfile?.referralsCompleted ?? 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Text(RidgitsReferralLimits.referralsRequiredLabel(for: slot))
                                .font(RidgitsTypography.headline(22))
                        }
                        .foregroundStyle(RidgitsColors.textHeadline)

                        Text(pack.title)
                            .font(RidgitsTypography.label(13))
                            .foregroundStyle(RidgitsColors.textSecondary)
                    }

                    Text(RidgitsReferralLimits.gateMessage(for: slot, referralsCompleted: referralsCompleted))
                        .font(RidgitsTypography.body(14))
                        .foregroundStyle(RidgitsColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let referral = referralStore.referralProfile {
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
                    } else if referralStore.isLoadingReferral {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text("Loading your referral code…")
                                .font(RidgitsTypography.body(13))
                                .foregroundStyle(RidgitsColors.textSecondary)
                        }
                    }

                    Text("\(referralsCompleted)/\(RidgitsReferralLimits.maxReferrals) friends referred")
                        .font(RidgitsTypography.body(12))
                        .foregroundStyle(RidgitsColors.textSecondary)
                }
                .padding(20)
            }
            .background(RidgitsColors.feedBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(RidgitsTypography.label(14))
                }
            }
        }
        .task {
            if referralStore.referralProfile == nil {
                await referralStore.loadReferral()
            }
        }
        .onAppear {
            guard !didAutoPresentShare else { return }
            didAutoPresentShare = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                if referralStore.shareReferralMessage() != nil {
                    showShareSheet = true
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let message = referralStore.shareReferralMessage() {
                RidgitsShareSheet(items: [message])
            }
        }
    }
}
