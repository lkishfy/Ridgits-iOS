import SwiftUI
import FirebaseAuth

struct IdentityVerificationView: View {
    @EnvironmentObject private var ridgitsStore: RidgitsStore
    @ObservedObject private var coordinator = IdentityVerificationCoordinator.shared
    @Environment(\.dismiss) private var dismiss

    /// When true, opens identity verification immediately (ID + phone OTP + selfie).
    var autoStart: Bool
    var onComplete: (Bool) -> Void

    @State private var hasProfilePhoto = false
    @State private var isLoadingProfile = true
    @State private var showSuccessSheet = false
    @State private var successCanMessage = false
    @State private var successPhotoMatchStatus = "none"

    init(autoStart: Bool = false, onComplete: @escaping (Bool) -> Void) {
        self.autoStart = autoStart
        self.onComplete = onComplete
    }

    private var canStartVerification: Bool {
        ridgitsStore.hasPlusMembership || ridgitsStore.hasNearbyAccess
    }

    private var canProceed: Bool {
        canStartVerification && hasProfilePhoto && !isLoadingProfile
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
                            bullet("Add a profile photo on your profile before you start (required).")
                            bullet("Confirm you're \(RidgitsMinimumAge.accountYears)+ with a driver's license or passport.")
                            bullet("Verify your phone number with a one-time code.")
                            bullet("Take a quick selfie so we know it's really you.")
                            bullet("Ridgits only stores your verification status and a hashed phone fingerprint.")
                            bullet("Your subscription badge activates as soon as you subscribe.")
                            bullet("Complete this step when you're ready to accept and send messages.")
                        }
                        .padding(16)
                    }

                    Text(IdentityVerificationStatusCard.photoMatchDeadlineWarning)
                        .font(RidgitsTypography.caption(12))
                        .foregroundStyle(RidgitsColors.destructive)

                    if !canStartVerification {
                        Text("Subscribe to Ridgits+ first to unlock identity verification.")
                            .font(RidgitsTypography.caption(12))
                            .foregroundStyle(RidgitsColors.textSecondary)
                    }

                    if isLoadingProfile {
                        ProgressView("Checking profile photo…")
                            .font(RidgitsTypography.body(13))
                            .foregroundStyle(RidgitsColors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 8)
                    } else if !hasProfilePhoto {
                        Text("Add a profile photo on your profile before continuing. Your photo must match your ID selfie within 48 hours of verifying.")
                            .font(RidgitsTypography.caption(12))
                            .foregroundStyle(RidgitsColors.destructive)
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
                        .disabled(coordinator.isVerifying || !canProceed)
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
                await loadProfilePhotoStatus()
                guard autoStart, canProceed else { return }
                await coordinator.startVerificationFlow()
            }
            .onChange(of: coordinator.verificationSucceeded) { _, succeeded in
                guard succeeded else { return }
                Task {
                    await ridgitsStore.refreshAccessInBackground()
                    if let status = try? await RidgitsAPIClient.shared.fetchIdentityStatus() {
                        successCanMessage = status.canMessage
                        successPhotoMatchStatus = status.profilePhotoIdentityMatchStatus
                    } else {
                        successCanMessage = ridgitsStore.isVerifiedForMessaging
                        successPhotoMatchStatus = ridgitsStore.access.profilePhotoIdentityMatchStatus
                    }
                    showSuccessSheet = true
                }
            }
            .sheet(isPresented: $showSuccessSheet) {
                IdentityVerificationSuccessSheet(
                    canMessage: successCanMessage,
                    photoMatchStatus: successPhotoMatchStatus,
                    onDone: {
                        showSuccessSheet = false
                        onComplete(true)
                        dismiss()
                    },
                    onRetryPhotoMatch: !successCanMessage && successPhotoMatchStatus != "pending"
                        ? {
                            showSuccessSheet = false
                            Task {
                                _ = await ridgitsStore.retryProfilePhotoIdentityMatch()
                                await ridgitsStore.refreshAccessInBackground()
                                onComplete(true)
                                dismiss()
                            }
                        }
                        : nil
                )
            }
        }
    }

    @MainActor
    private func loadProfilePhotoStatus() async {
        isLoadingProfile = true
        defer { isLoadingProfile = false }

        guard let uid = Auth.auth().currentUser?.uid else {
            hasProfilePhoto = false
            return
        }

        if let cached = RidgitsProfileCache.shared.profile(for: uid),
           !cached.image.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            hasProfilePhoto = true
            return
        }

        if let loaded = try? await RidgitsFirebaseClient.shared.fetchUserProfile(uid: uid) {
            hasProfilePhoto = !loaded.image.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } else {
            hasProfilePhoto = false
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
