import SwiftUI

struct IdentityVerificationStatusCard: View {
    let access: RidgitsAccess
    let canStartVerification: Bool
    let onVerify: () -> Void
    let onSubscribe: () -> Void

    private var statusLabel: String {
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
        if access.isFullyIdentityVerified {
            return RidgitsColors.forestGreen
        }
        if access.isIdentityVerified {
            return RidgitsColors.forestGreen
        }
        return RidgitsColors.textSecondary
    }

    private var statusIcon: String {
        if access.isFullyIdentityVerified || access.isIdentityVerified {
            return "checkmark.seal.fill"
        }
        return "person.badge.shield.checkmark.fill"
    }

    private var detailText: String {
        if access.isFullyIdentityVerified {
            if access.isProfilePhotoVerified {
                return "You're verified and your profile photo matches your ID."
            }
            if canStartVerification {
                return "You're verified. You can accept and send messages with an active plan."
            }
            return "You're verified. Subscribe to Ridgits+ to accept and send messages."
        }
        if access.isIdentityVerified {
            return "Your ID is verified. Complete phone verification to finish."
        }
        if canStartVerification {
            return "Complete identity verification to accept and send messages."
        }
        return "Subscribe first to unlock identity verification, then verify to message other members."
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
                        Text(statusLabel)
                            .font(RidgitsTypography.caption(12))
                            .foregroundStyle(statusColor)
                    }
                    Spacer(minLength: 0)
                }

                Text(detailText)
                    .font(RidgitsTypography.caption(12))
                    .foregroundStyle(RidgitsColors.textSecondary)

                if !access.isFullyIdentityVerified {
                    if access.isIdentityVerified, canStartVerification {
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
