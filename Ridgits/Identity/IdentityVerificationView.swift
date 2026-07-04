import SwiftUI

struct IdentityVerificationView: View {
    @ObservedObject private var coordinator = IdentityVerificationCoordinator.shared
    @Environment(\.dismiss) private var dismiss

    var onComplete: (Bool) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    RidgitsSectionHeader(
                        title: "Verify your identity",
                        subtitle: "Government ID + selfie required to subscribe and message on Ridgits."
                    )

                    RidgitsDashboardCard {
                        VStack(alignment: .leading, spacing: 14) {
                            bullet("Confirm you're 18+ with a driver's license or passport.")
                            bullet("Verify your phone number with a one-time code.")
                            bullet("Take a quick selfie so we know it's really you.")
                            bullet("Your ID images stay with Stripe — Ridgits only stores verification status and a hashed phone fingerprint.")
                            bullet("After subscribing, your profile photo must match your verified selfie.")
                        }
                        .padding(16)
                    }

                    if let error = coordinator.errorMessage {
                        Text(error)
                            .font(RidgitsTypography.caption(12))
                            .foregroundStyle(RidgitsColors.destructive)
                    }

                    RidgitsSquareButton(
                        title: coordinator.isVerifying ? "Verifying…" : "Continue to verification",
                        style: .filled
                    ) {
                        Task {
                            await coordinator.startVerificationFlow()
                        }
                    }
                    .disabled(coordinator.isVerifying)

                    Text("You'll return to Ridgits automatically when verification finishes, then your Apple subscription will continue.")
                        .font(RidgitsTypography.caption(11))
                        .foregroundStyle(RidgitsColors.textSecondary)
                }
                .padding(16)
            }
            .background(RidgitsColors.feedBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onComplete(false)
                        dismiss()
                    }
                }
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
