import SwiftUI

enum RidgitsAgeVerificationCopy {
    static let termsSummary =
        "You must be at least \(RidgitsMinimumAge.accountYears) years old to create an account or use Ridgits. By continuing, you represent that you are \(RidgitsMinimumAge.accountYears) or older. Ridgits may request additional proof of age if we suspect misrepresentation, as described in our Terms of Service."

    static let checkboxLabel =
        "I confirm that I am \(RidgitsMinimumAge.accountYears) years of age or older and agree to comply with Ridgits' Terms of Service, operated by GEISTS, LLC."

    static let complianceNote =
        "This information is required for legal compliance and will be stored securely."

    static let confirmRequired = RidgitsMinimumAge.confirmRequiredMessage
}

struct RidgitsAgeVerificationConsent: View {
    @Binding var confirmOver18: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(RidgitsAgeVerificationCopy.termsSummary)
                .font(RidgitsTypography.caption(12))
                .foregroundStyle(RidgitsColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Link("Terms & Conditions", destination: RidgitsAppLinks.terms)
                .font(RidgitsTypography.caption(12))
                .foregroundStyle(RidgitsColors.textHeadline)

            Button {
                confirmOver18.toggle()
            } label: {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: confirmOver18 ? "checkmark.square.fill" : "square")
                        .font(.system(size: 20))
                        .foregroundStyle(
                            confirmOver18 ? RidgitsColors.textHeadline : RidgitsColors.textMuted
                        )

                    Text(RidgitsAgeVerificationCopy.checkboxLabel)
                        .font(RidgitsTypography.caption(13))
                        .foregroundStyle(RidgitsColors.textSecondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .buttonStyle(RidgitsHapticPlainButtonStyle())

            Text(RidgitsAgeVerificationCopy.complianceNote)
                .font(RidgitsTypography.caption(11))
                .foregroundStyle(RidgitsColors.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
