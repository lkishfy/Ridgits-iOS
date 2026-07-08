import SwiftUI

struct EmailVerificationPromptView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var isSending = false
    @State private var isRefreshing = false
    @State private var message: String?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "envelope.badge")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Verify your email")
                .font(.title2.bold())

            Text("Check your inbox for a verification link from Ridgits. You'll need to verify before matching, poking, or messaging.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if let message {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 12) {
                Button {
                    Task { await refreshStatus() }
                } label: {
                    if isRefreshing {
                        ProgressView()
                    } else {
                        Text("I've verified my email")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isRefreshing)

                Button {
                    Task { await resendEmail() }
                } label: {
                    if isSending {
                        ProgressView()
                    } else {
                        Text("Resend verification email")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isSending)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .padding()
    }

    private func resendEmail() async {
        isSending = true
        defer { isSending = false }
        do {
            try await authManager.resendVerificationEmail()
            message = "Verification email sent. Check your inbox and spam folder."
        } catch {
            message = error.localizedDescription
        }
    }

    private func refreshStatus() async {
        isRefreshing = true
        defer { isRefreshing = false }
        await authManager.refreshEmailVerificationStatus()
        if authManager.emailVerified {
            message = "Email verified. Loading your profile…"
        } else {
            message = "Email not verified yet. Tap the link in your inbox, then try again."
        }
    }
}
