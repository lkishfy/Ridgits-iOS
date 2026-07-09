import SwiftUI

struct IdentityVerificationStatusCard: View {
    static let photoMatchDeadlineWarning =
        "Add your profile photo within 48 hours of verifying your ID. If verification does not work, email support@ridgits.com and we will help."

    let access: RidgitsAccess
    let canStartVerification: Bool
    let hasProfilePhoto: Bool
    let onVerify: () -> Void
    let onSubscribe: () -> Void
    var onEditProfilePhoto: (() -> Void)? = nil
    var onRetryPhotoMatch: (() -> Void)? = nil
    var isRetryingPhotoMatch: Bool = false
    var photoMatchStatusMessage: String? = nil

    private var statusLabel: String {
        if access.isFullyIdentityVerified && access.isProfilePhotoVerified {
            return "Verified"
        }
        if access.isFullyIdentityVerified && access.profilePhotoIdentityMatchStatus == "failed" {
            return "Photo verification failed"
        }
        if access.isFullyIdentityVerified && !access.isProfilePhotoVerified {
            return "Photo verification needed"
        }
        switch access.identityVerificationStatus {
        case "verified":
            if access.isPhoneVerified { return "Verified" }
            if access.phoneVerificationStatus == "failed" { return "Phone verification incomplete" }
            return "ID verified — phone pending"
        case "pending", "processing":
            return "Verification in progress"
        case "requires_input":
            return "Action needed"
        case "failed", "canceled":
            return "Verification failed"
        default:
            return "Not verified"
        }
    }

    private var statusColor: Color {
        if access.isProfilePhotoVerified && access.isFullyIdentityVerified {
            return RidgitsColors.forestGreen
        }
        if access.isFullyIdentityVerified && access.profilePhotoIdentityMatchStatus == "failed" {
            return RidgitsColors.destructive
        }
        if access.isFullyIdentityVerified {
            return RidgitsColors.textSecondary
        }
        if access.isIdentityVerified {
            return RidgitsColors.forestGreen
        }
        return RidgitsColors.textSecondary
    }

    private var statusIcon: String {
        if access.isProfilePhotoVerified && access.isFullyIdentityVerified {
            return "checkmark.seal.fill"
        }
        if access.isFullyIdentityVerified && access.profilePhotoIdentityMatchStatus == "failed" {
            return "exclamationmark.triangle.fill"
        }
        if access.isFullyIdentityVerified || access.isIdentityVerified {
            return "person.badge.shield.checkmark.fill"
        }
        return "person.badge.shield.checkmark.fill"
    }

    private var detailText: String {
        if access.isProfilePhotoVerified && access.isFullyIdentityVerified {
            return "You're verified and your profile photo matches your ID. You can chat with other members."
        }
        if access.isFullyIdentityVerified && access.profilePhotoIdentityMatchStatus == "failed" {
            return "Your profile photo didn't match your verified ID selfie. Use a clear face photo, similar to your ID verification selfie, then try again."
        }
        if access.isFullyIdentityVerified && !access.isProfilePhotoVerified {
            return "Your ID is verified. Add a profile photo that matches your ID selfie to start chatting."
        }
        if canStartVerification && !access.isIdentityVerified {
            return "Add a profile photo first, then complete identity verification to accept and send messages."
        }
        if access.isFullyIdentityVerified {
            if canStartVerification {
                return "You're verified. Match your profile photo to your ID to chat with other members."
            }
            return "You're verified. Subscribe to Ridgits+ to accept and send messages."
        }
        if access.isIdentityVerified {
            return "Your ID is verified. Complete phone verification to finish."
        }
        return "Subscribe first to unlock identity verification, then verify to message other members."
    }

    private var shouldShowPhotoDeadlineWarning: Bool {
        if access.isReviewBypassAccount { return false }
        if access.isFullyIdentityVerified && !access.isProfilePhotoVerified { return true }
        if canStartVerification && !access.isIdentityVerified { return true }
        return false
    }

    private var needsProfilePhotoBeforeVerify: Bool {
        canStartVerification && !access.isIdentityVerified && !hasProfilePhoto
    }

    var body: some View {
        RidgitsDashboardCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: statusIcon)
                        .font(.system(size: 18))
                        .foregroundStyle(statusColor)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Identity Verification")
                            .font(RidgitsTypography.label(14))
                            .foregroundStyle(RidgitsColors.textHeadline)

                        if !(access.isProfilePhotoVerified && access.isFullyIdentityVerified) {
                            Text(statusLabel)
                                .font(RidgitsTypography.caption(12))
                                .foregroundStyle(statusColor)
                        }
                    }
                    Spacer(minLength: 0)
                }

                Text(detailText)
                    .font(RidgitsTypography.caption(12))
                    .foregroundStyle(RidgitsColors.textSecondary)

                if shouldShowPhotoDeadlineWarning {
                    Text(Self.photoMatchDeadlineWarning)
                        .font(RidgitsTypography.caption(12))
                        .foregroundStyle(RidgitsColors.destructive)
                }

                if let photoMatchStatusMessage, !photoMatchStatusMessage.isEmpty {
                    Text(photoMatchStatusMessage)
                        .font(RidgitsTypography.caption(12))
                        .foregroundStyle(RidgitsColors.destructive)
                }

                if access.isFullyIdentityVerified && !access.isProfilePhotoVerified {
                    if let onEditProfilePhoto {
                        RidgitsSquareButton(title: "Change profile photo", style: .filled, action: onEditProfilePhoto)
                    }
                    if let onRetryPhotoMatch {
                        RidgitsSquareButton(
                            title: isRetryingPhotoMatch ? "Retrying…" : "Retry photo verification",
                            style: .ghost,
                            action: onRetryPhotoMatch
                        )
                        .disabled(isRetryingPhotoMatch)
                    }
                } else if !access.isFullyIdentityVerified {
                    if needsProfilePhotoBeforeVerify, let onEditProfilePhoto {
                        RidgitsSquareButton(title: "Add profile photo first", style: .filled, action: onEditProfilePhoto)
                    } else if access.isIdentityVerified, canStartVerification {
                        RidgitsSquareButton(title: "Complete verification", style: .filled, action: onVerify)
                    } else if !access.isIdentityVerified, canStartVerification {
                        RidgitsSquareButton(title: "Verify identity", style: .filled, action: onVerify)
                    } else if !access.isIdentityVerified {
                        RidgitsSquareButton(title: "Subscribe to verify", style: .filled, action: onSubscribe)
                    }
                }
            }
            .padding(16)
        }
    }
}
