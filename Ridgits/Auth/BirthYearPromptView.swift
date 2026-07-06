import SwiftUI

/// Blocking screen shown to Google/Apple sign-ins that don't have a `birthYear` on file
/// yet (OAuth doesn't collect it the way the email/password signup sheet does). Ridgits
/// requires everyone to be 21+, enforced again server-side via `validate-signup` and by
/// Firestore rules on the `users`/`publicProfiles` documents.
struct BirthYearPromptView: View {
    @EnvironmentObject private var authManager: AuthManager

    @State private var birthYear = ""
    @State private var confirmOver18 = false
    @State private var errorMessage: String?
    @State private var isSubmitting = false

    let onComplete: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text("What year were you born?")
                    .font(RidgitsTypography.headline(22))
                    .foregroundStyle(RidgitsColors.textHeadline)

                Text("Ridgits is for adults \(RidgitsMinimumAge.accountYears) and older. We use your birth year to confirm your age.")
                    .font(RidgitsTypography.body(14))
                    .foregroundStyle(RidgitsColors.textSecondary)

                if let errorMessage {
                    Text(errorMessage)
                        .font(RidgitsTypography.caption(13))
                        .foregroundStyle(RidgitsColors.destructive)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RidgitsColors.destructive.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.md))
                }

                TextField("YYYY (e.g. 1990)", text: $birthYear)
                    .keyboardType(.numberPad)
                    .font(RidgitsTypography.body(16))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(RidgitsColors.inputSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: RidgitsRadius.md)
                            .stroke(RidgitsColors.inputBorder, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.md))

                RidgitsAgeVerificationConsent(confirmOver18: $confirmOver18)

                RidgitsPrimaryButton(
                    title: "Continue",
                    isLoading: isSubmitting,
                    isDisabled: !canSubmit
                ) {
                    Task { await submit() }
                }
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RidgitsColors.feedBackground)
    }

    private var canSubmit: Bool {
        birthYear.trimmingCharacters(in: .whitespaces).count == 4 && confirmOver18
    }

    @MainActor
    private func submit() async {
        guard confirmOver18 else {
            errorMessage = RidgitsAgeVerificationCopy.confirmRequired
            return
        }

        guard let year = Int(birthYear) else {
            errorMessage = "Please enter a valid birth year."
            return
        }

        let currentYear = Calendar.current.component(.year, from: Date())
        let age = currentYear - year
        if age < RidgitsMinimumAge.accountYears {
            errorMessage = RidgitsMinimumAge.underageErrorMessage
            return
        }
        if age > 120 || year < 1900 {
            errorMessage = "Please enter a valid birth year."
            return
        }

        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await authManager.completeBirthYear(year)
            onComplete()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
