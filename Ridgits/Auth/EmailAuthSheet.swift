import SwiftUI

struct EmailAuthSheet: View {
    enum Mode {
        case signIn
        case signUp

        var title: String {
            switch self {
            case .signIn: return "Sign in with email"
            case .signUp: return "Create your account"
            }
        }

        var submitTitle: String {
            switch self {
            case .signIn: return "Sign In"
            case .signUp: return "Create Account"
            }
        }
    }

    @Environment(\.dismiss) private var dismiss

    @State private var mode: Mode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var birthYear = ""
    @State private var localError: String?
    @State private var isSubmitting = false

    let onSignIn: (String, String) async throws -> Void
    let onSignUp: (String, String, Int) async throws -> Void

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(RidgitsColors.border)
                .frame(width: 36, height: 4)
                .padding(.top, 8)
                .padding(.bottom, 16)

            HStack {
                Text(mode.title)
                    .font(RidgitsTypography.headline(18))
                    .foregroundStyle(RidgitsColors.textHeadline)

                Spacer()

                Button("Cancel") { dismiss() }
                    .font(RidgitsTypography.caption(13))
                    .foregroundStyle(RidgitsColors.textSecondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    if let localError {
                        Text(localError)
                            .font(RidgitsTypography.caption(13))
                            .foregroundStyle(RidgitsColors.destructive)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RidgitsColors.destructive.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.md))
                    }

                    Picker("Account mode", selection: $mode) {
                        Text("Sign In").tag(Mode.signIn)
                        Text("Sign Up").tag(Mode.signUp)
                    }
                    .pickerStyle(.segmented)
                    .ridgitsSelectionHaptic(trigger: mode)

                    if mode == .signUp {
                        authField(title: "Birth Year", text: $birthYear, prompt: "YYYY (e.g. 1990)")
                            .keyboardType(.numberPad)
                        Text("You must be at least 18 years old to use Ridgits.")
                            .font(RidgitsTypography.caption(12))
                            .foregroundStyle(RidgitsColors.textMuted)
                    }

                    authField(title: "Email", text: $email, prompt: "you@example.com")
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    authField(title: "Password", text: $password, prompt: "Password", secure: true)

                    if mode == .signUp {
                        authField(title: "Confirm Password", text: $confirmPassword, prompt: "Confirm password", secure: true)
                    }

                    RidgitsPrimaryButton(
                        title: mode.submitTitle,
                        isLoading: isSubmitting,
                        isDisabled: !canSubmit
                    ) {
                        Task { await submit() }
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .background(RidgitsColors.surface)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(16)
    }

    private var canSubmit: Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !password.isEmpty else { return false }
        if mode == .signUp {
            return !birthYear.isEmpty && !confirmPassword.isEmpty
        }
        return true
    }

    @ViewBuilder
    private func authField(title: String, text: Binding<String>, prompt: String, secure: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(RidgitsTypography.label(13))
                .foregroundStyle(RidgitsColors.textSecondary)

            Group {
                if secure {
                    SecureField(prompt, text: text)
                } else {
                    TextField(prompt, text: text)
                }
            }
            .font(RidgitsTypography.body(15))
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(RidgitsColors.inputSurface)
            .overlay(
                RoundedRectangle(cornerRadius: RidgitsRadius.md)
                    .stroke(RidgitsColors.inputBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.md))
        }
    }

    @MainActor
    private func submit() async {
        localError = nil
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        if mode == .signUp {
            guard let validationError = validateSignUp(email: trimmedEmail) else {
                isSubmitting = true
                defer { isSubmitting = false }
                do {
                    try await onSignUp(trimmedEmail, password, Int(birthYear)!)
                    dismiss()
                } catch {
                    localError = error.localizedDescription
                }
                return
            }
            localError = validationError
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await onSignIn(trimmedEmail, password)
            dismiss()
        } catch {
            localError = error.localizedDescription
        }
    }

    private func validateSignUp(email: String) -> String? {
        if email.isEmpty || password.isEmpty || confirmPassword.isEmpty || birthYear.isEmpty {
            return "All fields are required."
        }
        if isDisposableEmail(email) {
            return "Please use a valid, permanent email address."
        }
        if password != confirmPassword {
            return "Passwords do not match."
        }
        if password.count < 6 {
            return "Password must be at least 6 characters."
        }
        guard let year = Int(birthYear) else {
            return "Please enter a valid birth year."
        }
        let currentYear = Calendar.current.component(.year, from: Date())
        let age = currentYear - year
        if age < 18 {
            return "You must be at least 18 years old to use Ridgits."
        }
        if age > 120 || year < 1900 {
            return "Please enter a valid birth year."
        }
        return nil
    }

    private func isDisposableEmail(_ email: String) -> Bool {
        RidgitsDisposableEmail.isDisposable(email)
    }
}
