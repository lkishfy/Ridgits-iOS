import SwiftUI
import FirebaseAuth

struct ProfileSettingsView: View {
    @EnvironmentObject private var authManager: AuthManager

    @State private var showSignOutConfirm = false
    @State private var showDeleteFlow = false
    @State private var deleteConfirmationCode = ""
    @State private var userInputCode = ""
    @State private var password = ""
    @State private var confirmedPermanentDelete = false
    @State private var isDeleting = false
    @State private var deleteError: String?
    @State private var isResendingVerification = false
    @State private var verificationResendMessage: String?

    private var requiresPassword: Bool {
        authManager.currentUser?.providerData.contains { $0.providerID == EmailAuthProviderID } == true
    }

    /// Pokes/messages/community visibility require a verified email server-side. OAuth
    /// (Google/Apple) accounts are verified automatically, so this only ever shows for
    /// password accounts that haven't clicked their verification link yet.
    private var showsUnverifiedEmailCard: Bool {
        requiresPassword && !authManager.emailVerified
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                RidgitsDashboardCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Settings")
                            .font(RidgitsTypography.headline(20))
                            .foregroundStyle(RidgitsColors.textHeadline)
                        Text("Legal information and account actions.")
                            .font(RidgitsTypography.body(13))
                            .foregroundStyle(RidgitsColors.textSecondary)
                    }
                    .padding(16)
                }

                RidgitsDashboardCard {
                    VStack(spacing: 0) {
                        legalLinkRow(
                            title: "Terms & Conditions",
                            subtitle: "How you can use Ridgits",
                            url: RidgitsAppLinks.terms
                        )
                        RidgitsSectionDivider()
                        legalLinkRow(
                            title: "Privacy Policy",
                            subtitle: "How we handle your data",
                            url: RidgitsAppLinks.privacy
                        )
                    }
                    .padding(.vertical, 4)
                }

                if showsUnverifiedEmailCard {
                    RidgitsDashboardCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "envelope.badge.fill")
                                    .foregroundStyle(RidgitsColors.destructive)
                                Text("Verify your email")
                                    .font(RidgitsTypography.label(14))
                                    .foregroundStyle(RidgitsColors.textHeadline)
                            }
                            Text("You need to verify your email before you can appear in the community, poke, or message anyone.")
                                .font(RidgitsTypography.caption(12))
                                .foregroundStyle(RidgitsColors.textSecondary)
                            if let verificationResendMessage {
                                Text(verificationResendMessage)
                                    .font(RidgitsTypography.caption(12))
                                    .foregroundStyle(RidgitsColors.textSecondary)
                            }
                            RidgitsSquareButton(
                                title: isResendingVerification ? "Sending…" : "Resend verification email",
                                style: .ghost
                            ) {
                                Task { await resendVerification() }
                            }
                            .disabled(isResendingVerification)
                        }
                        .padding(16)
                    }
                }

                RidgitsDashboardCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ACCOUNT")
                            .font(RidgitsTypography.sectionLabel(11))
                            .foregroundStyle(RidgitsColors.textSecondary)
                            .tracking(0.8)

                        if let email = authManager.currentUser?.email {
                            Text(email)
                                .font(RidgitsTypography.body(14))
                                .foregroundStyle(RidgitsColors.textHeadline)
                        }

                        RidgitsSquareButton(title: "Sign Out", style: .ghost) {
                            showSignOutConfirm = true
                        }
                    }
                    .padding(16)
                }

                RidgitsDashboardCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("DANGER ZONE")
                            .font(RidgitsTypography.sectionLabel(11))
                            .foregroundStyle(RidgitsColors.destructive)
                            .tracking(0.8)

                        Text("Permanently delete your account and all associated data including your profile, quiz answers, Ridgits, messages, and analysis results.")
                            .font(RidgitsTypography.caption(12))
                            .foregroundStyle(RidgitsColors.textSecondary)

                        RidgitsSquareButton(title: "Delete Account", style: .destructive) {
                            beginDeleteFlow()
                        }
                    }
                    .padding(16)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(RidgitsColors.feedBackground)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Sign out?", isPresented: $showSignOutConfirm) {
            Button("Sign Out", role: .destructive) {
                try? authManager.signOut()
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showDeleteFlow) {
            deleteAccountSheet
        }
        .task {
            await authManager.refreshEmailVerificationStatus()
        }
    }

    private func resendVerification() async {
        isResendingVerification = true
        verificationResendMessage = nil
        defer { isResendingVerification = false }
        do {
            try await authManager.resendVerificationEmail()
            verificationResendMessage = "Verification email sent — check your inbox."
        } catch {
            verificationResendMessage = error.localizedDescription
        }
    }

    private func legalLinkRow(title: String, subtitle: String, url: URL) -> some View {
        Link(destination: url) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(RidgitsTypography.label(14))
                        .foregroundStyle(RidgitsColors.textHeadline)
                    Text(subtitle)
                        .font(RidgitsTypography.caption(12))
                        .foregroundStyle(RidgitsColors.textSecondary)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(RidgitsColors.textMuted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }

    private var deleteAccountSheet: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    warningBanner

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirmation code")
                            .font(RidgitsTypography.label(14))
                            .foregroundStyle(RidgitsColors.textHeadline)
                        Text("Type the code below to confirm you want to permanently delete your account.")
                            .font(RidgitsTypography.caption(12))
                            .foregroundStyle(RidgitsColors.textSecondary)

                        Text(deleteConfirmationCode)
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .tracking(4)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(RidgitsColors.hoverSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: RidgitsRadius.sm)
                                    .stroke(RidgitsColors.border, lineWidth: 1)
                            )

                        TextField("Enter code above", text: $userInputCode)
                            .font(.system(size: 18, weight: .medium, design: .monospaced))
                            .multilineTextAlignment(.center)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .padding(12)
                            .background(RidgitsColors.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: RidgitsRadius.sm)
                                    .stroke(RidgitsColors.border, lineWidth: 1)
                            )
                            .onChange(of: userInputCode) { _, newValue in
                                userInputCode = String(newValue.uppercased().prefix(8))
                            }
                    }

                    if requiresPassword {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Account password")
                                .font(RidgitsTypography.label(14))
                                .foregroundStyle(RidgitsColors.textHeadline)
                            Text("Enter your Ridgits password to verify it's really you.")
                                .font(RidgitsTypography.caption(12))
                                .foregroundStyle(RidgitsColors.textSecondary)

                            SecureField("Password", text: $password)
                                .padding(12)
                                .background(RidgitsColors.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: RidgitsRadius.sm)
                                        .stroke(RidgitsColors.border, lineWidth: 1)
                                )
                        }
                    }

                    Toggle(isOn: $confirmedPermanentDelete) {
                        Text("I understand this permanently deletes all of my data and cannot be undone.")
                            .font(RidgitsTypography.caption(12))
                            .foregroundStyle(RidgitsColors.textSecondary)
                    }
                    .tint(RidgitsColors.destructive)

                    if let deleteError {
                        Text(deleteError)
                            .font(RidgitsTypography.caption(12))
                            .foregroundStyle(RidgitsColors.destructive)
                    }

                    RidgitsSquareButton(
                        title: isDeleting ? "Deleting…" : "Delete Forever",
                        style: .destructive
                    ) {
                        Task { await confirmDelete() }
                    }
                    .disabled(!canConfirmDelete || isDeleting)
                    .opacity(canConfirmDelete && !isDeleting ? 1 : 0.5)
                }
                .padding(16)
            }
            .background(RidgitsColors.feedBackground)
            .navigationTitle("Delete Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        resetDeleteFlow()
                        showDeleteFlow = false
                    }
                    .disabled(isDeleting)
                }
            }
        }
        .interactiveDismissDisabled(isDeleting)
    }

    private var warningBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(RidgitsColors.destructive)
            VStack(alignment: .leading, spacing: 4) {
                Text("This action cannot be undone")
                    .font(RidgitsTypography.label(14))
                    .foregroundStyle(RidgitsColors.destructive)
                Text("Your profile, quiz results, Ridgits, messages, pokes, and all other data will be permanently removed.")
                    .font(RidgitsTypography.caption(12))
                    .foregroundStyle(RidgitsColors.textSecondary)
            }
        }
        .padding(12)
        .background(RidgitsColors.destructive.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: RidgitsRadius.sm)
                .stroke(RidgitsColors.destructive.opacity(0.25), lineWidth: 1)
        )
    }

    private var canConfirmDelete: Bool {
        let codeMatches = userInputCode == deleteConfirmationCode
        let passwordOk = !requiresPassword || !password.isEmpty
        return codeMatches && passwordOk && confirmedPermanentDelete
    }

    private func beginDeleteFlow() {
        deleteConfirmationCode = Self.generateConfirmationCode()
        userInputCode = ""
        password = ""
        confirmedPermanentDelete = false
        deleteError = nil
        showDeleteFlow = true
    }

    private func resetDeleteFlow() {
        deleteConfirmationCode = ""
        userInputCode = ""
        password = ""
        confirmedPermanentDelete = false
        deleteError = nil
        isDeleting = false
    }

    private func confirmDelete() async {
        guard canConfirmDelete else { return }
        isDeleting = true
        deleteError = nil

        do {
            if requiresPassword {
                try await authManager.reauthenticateWithPassword(password)
            }
            await RidgitsPushNotificationService.shared.unregisterFromBackend()
            try await RidgitsAPIClient.shared.deleteAccount()
            resetDeleteFlow()
            showDeleteFlow = false
            try authManager.signOut()
        } catch {
            deleteError = error.localizedDescription
            isDeleting = false
        }
    }

    private static func generateConfirmationCode() -> String {
        let chars = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
        return String((0..<8).map { _ in chars.randomElement()! })
    }
}
