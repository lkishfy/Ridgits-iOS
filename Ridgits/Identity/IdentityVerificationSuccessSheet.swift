import SwiftUI

struct IdentityVerificationSuccessSheet: View {
    let canMessage: Bool
    let photoMatchStatus: String
    var onDone: () -> Void
    var onRetryPhotoMatch: (() -> Void)?

    private var title: String {
        if canMessage { return "You're verified" }
        if photoMatchStatus == "failed" { return "ID verified — photo needs a retry" }
        return "ID verified"
    }

    private var message: String {
        if canMessage {
            return "Your identity is confirmed and your profile photo matches your ID. You can send and accept messages."
        }
        if photoMatchStatus == "failed" {
            return "Your government ID and phone are verified. We couldn't automatically match your profile photo to your ID selfie — tap Retry to compare them again, or update your profile photo first."
        }
        if photoMatchStatus == "pending" {
            return "Your government ID and phone are verified. We're comparing your profile photo to your ID selfie — pull to refresh on Profile in a moment."
        }
        return "Your government ID and phone are verified. We're finishing your profile photo check — if this doesn't update in a minute, tap Retry photo verification on your profile."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: canMessage ? "checkmark.seal.fill" : "person.badge.shield.checkmark.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(canMessage ? RidgitsColors.forestGreen : RidgitsColors.textHeadline)
                Text(title)
                    .font(RidgitsTypography.headline(22))
                    .foregroundStyle(RidgitsColors.textHeadline)
            }

            Text(message)
                .font(RidgitsTypography.body(14))
                .foregroundStyle(RidgitsColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            RidgitsPrimaryButton(title: "Done", action: onDone)

            if photoMatchStatus == "failed", let onRetryPhotoMatch {
                RidgitsSquareButton(title: "Retry photo verification", style: .ghost, action: onRetryPhotoMatch)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(RidgitsColors.feedBackground)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
