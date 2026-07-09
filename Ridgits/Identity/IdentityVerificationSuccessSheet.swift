import SwiftUI

struct IdentityVerificationSuccessSheet: View {
    let canMessage: Bool
    let photoMatchStatus: String
    var onDone: () -> Void
    var onRetryPhotoMatch: (() -> Void)?

    private var isPhotoMatchWarning: Bool {
        !canMessage && photoMatchStatus != "pending"
    }

    private var title: String {
        if canMessage { return "You're verified" }
        if isPhotoMatchWarning { return IdentityVerificationStatusCard.photoMatchFailureAfterStripeTitle }
        return "ID verified"
    }

    private var message: String {
        if canMessage {
            return "Your identity is confirmed and your profile photo matches your ID. You can send and accept messages."
        }
        if isPhotoMatchWarning {
            return IdentityVerificationStatusCard.photoMatchFailureAfterStripeMessage
        }
        if photoMatchStatus == "pending" {
            return "Your government ID and phone are verified. We're comparing your profile photo to your ID selfie — pull to refresh on Profile in a moment."
        }
        return "Your government ID and phone are verified. We're finishing your profile photo check — if this doesn't update in a minute, tap Retry photo verification on your profile."
    }

    private var statusIcon: String {
        if canMessage { return "checkmark.seal.fill" }
        if isPhotoMatchWarning { return "exclamationmark.triangle.fill" }
        return "person.badge.shield.checkmark.fill"
    }

    private var statusColor: Color {
        if canMessage { return RidgitsColors.forestGreen }
        if isPhotoMatchWarning { return RidgitsColors.destructive }
        return RidgitsColors.textHeadline
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: statusIcon)
                    .font(.system(size: 28))
                    .foregroundStyle(statusColor)
                Text(title)
                    .font(RidgitsTypography.headline(22))
                    .foregroundStyle(RidgitsColors.textHeadline)
            }

            Text(message)
                .font(RidgitsTypography.body(14))
                .foregroundStyle(RidgitsColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if isPhotoMatchWarning {
                Text(IdentityVerificationStatusCard.photoMatchFailureSupportPrompt)
                    .font(RidgitsTypography.body(14))
                    .foregroundStyle(RidgitsColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let supportURL = URL(string: "mailto:\(RidgitsCustomerFacingError.supportEmail)") {
                    Link(destination: supportURL) {
                        Text(RidgitsCustomerFacingError.supportEmail)
                            .font(RidgitsTypography.label(14))
                            .foregroundStyle(RidgitsColors.forestGreen)
                    }
                }
            }

            if isPhotoMatchWarning, let onRetryPhotoMatch {
                RidgitsPrimaryButton(title: "Retry photo verification", action: onRetryPhotoMatch)
                RidgitsSquareButton(title: "Done for now", style: .ghost, action: onDone)
            } else {
                RidgitsPrimaryButton(title: "Done", action: onDone)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(RidgitsColors.feedBackground)
        .presentationDetents(isPhotoMatchWarning ? [.medium, .large] : [.medium])
        .presentationDragIndicator(.visible)
    }
}
