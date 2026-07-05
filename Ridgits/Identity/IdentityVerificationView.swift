import SwiftUI

struct IdentityVerificationView: View {
    @EnvironmentObject private var ridgitsStore: RidgitsStore
    @ObservedObject private var coordinator = IdentityVerificationCoordinator.shared
    @Environment(\.dismiss) private var dismiss

    /// When true, opens identity verification immediately (ID + phone OTP + selfie).
    var autoStart: Bool
    var onComplete: (Bool) -> Void

    init(autoStart: Bool = false, onComplete: @escaping (Bool) -> Void) {
        self.autoStart = autoStart
        self.onComplete = onComplete
    }

    private var canStartVerification: Bool {
        ridgitsStore.hasPlusMembership || ridgitsStore.hasNearbyAccess
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    RidgitsSectionHeader(
                        title: "Verify Your Identity",
                        subtitle: "We verify your government ID, phone number, and selfie before you can message other members."
                    )

                    RidgitsDashboardCard {
                        VStack(alignment: .leading, spacing: 14) {
                            bullet("Confirm you're 18+ with a driver's license or passport.")
                            bullet("Verify your phone number with a one-time code.")
                            bullet("Take a quick selfie so we know it's really you.")
                            bullet("Ridgits only stores your verification status and a hashed phone fingerprint.")
                            bullet("Subscribe first, then complete this step to accept and send messages.")
                        }
                        .padding(16)
                    }

                    if !canStartVerification {
                        Text("Subscribe to Ridgits+ first to unlock identity verification.")
                            .font(RidgitsTypography.caption(12))
                            .foregroundStyle(RidgitsColors.textSecondary)
                    }

                    if let error = coordinator.errorMessage {
                        Text(error)
                            .font(RidgitsTypography.caption(12))
                            .foregroundStyle(RidgitsColors.destructive)
                    }

                    if !autoStart {
                        RidgitsSquareButton(
                            title: coordinator.isVerifying ? "Verifying…" : "Continue",
                            style: .filled
                        ) {
                            Task { await coordinator.startVerificationFlow() }
                        }
                        .disabled(coordinator.isVerifying || !canStartVerification)
                    } else if coordinator.isVerifying {
                        ProgressView("Opening verification…")
                            .font(RidgitsTypography.body(13))
                            .foregroundStyle(RidgitsColors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 8)
                    }

                    Text("You'll return to Ridgits automatically when verification finishes.")
                        .font(RidgitsTypography.caption(11))
                        .foregroundStyle(RidgitsColors.textSecondary)
                }
                .padding(16)
            }
            .background(RidgitsColors.feedBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        onComplete(false)
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(RidgitsColors.textHeadline)
                    }
                }
            }
            .task {
                guard autoStart, canStartVerification else { return }
                await coordinator.startVerificationFlow()
            }
            .onChange(of: coordinator.verificationSucceeded) { _, succeeded in
                guard succeeded else { return }
                onComplete(true)
                dismiss()
            }
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(RidgitsColors.textHeadline)
                .padding(.top, 2)
            Text(text)
                .font(RidgitsTypography.body(13))
                .foregroundStyle(RidgitsColors.textSecondary)
        }
    }
}
