import SwiftUI

struct RidgitsVerifiedBadge: View {
    let tier: RidgitsSubscriptionTier
    var size: CGFloat = 16

    init(tier: RidgitsSubscriptionTier, size: CGFloat = 16) {
        self.tier = tier
        self.size = size
    }

    init(tier: String?, size: CGFloat = 16) {
        self.tier = RidgitsSubscriptionTier.from(stored: tier)
        self.size = size
    }

    var body: some View {
        if tier.showsVerifiedBadge, let assetName = tier.badgeAssetName {
            Image(assetName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .accessibilityLabel("\(tier.displayName) subscriber")
        }
    }
}

extension RidgitsSubscriptionTier {
    var showsVerifiedBadge: Bool {
        switch self {
        case .plus, .premium, .ultra: return true
        case .free: return false
        }
    }

    var badgeAssetName: String? {
        switch self {
        case .plus: return "VerifiedBadgePlus"
        case .premium: return "VerifiedBadgePremium"
        case .ultra: return "VerifiedBadgeUltra"
        case .free: return nil
        }
    }

    var navShortLabel: String {
        switch self {
        case .free: return "Free"
        case .plus: return "Ridgits+"
        case .premium: return "Premium"
        case .ultra: return "Ultra"
        }
    }

    static func verifiedTier(from stored: String?) -> RidgitsSubscriptionTier? {
        let tier = from(stored: stored)
        return tier.showsVerifiedBadge ? tier : nil
    }
}

struct RidgitsVerifiedBadgeLabel: View {
    let tier: RidgitsSubscriptionTier
    var badgeSize: CGFloat = 16
    var font: Font = RidgitsTypography.label(13)

    var body: some View {
        HStack(spacing: 6) {
            Text(tier.navShortLabel)
                .font(font)
                .foregroundStyle(RidgitsColors.textHeadline)
            RidgitsVerifiedBadge(tier: tier, size: badgeSize)
        }
    }
}

/// Badge shown when a member's profile photo matched their verified ID selfie.
struct RidgitsPhotoVerifiedBadge: View {
    var size: CGFloat = 16

    var body: some View {
        Image(systemName: "checkmark.seal.fill")
            .font(.system(size: size))
            .foregroundStyle(RidgitsColors.forestGreen)
            .accessibilityLabel("Photo verified")
    }
}

extension View {
    func ridgitsProfilePhotoVerifiedOverlay(show: Bool, size: CGFloat = 22) -> some View {
        overlay(alignment: .bottomTrailing) {
            if show {
                RidgitsPhotoVerifiedBadge(size: size)
                    .background(Circle().fill(RidgitsColors.surface))
                    .offset(x: 2, y: 2)
            }
        }
    }
}

struct RidgitsProfileTrustBadges: View {
    let subscriptionTier: String?
    let profilePhotoVerified: Bool
    var badgeSize: CGFloat = 16

    var body: some View {
        HStack(spacing: 4) {
            RidgitsVerifiedBadge(tier: subscriptionTier, size: badgeSize)
            if profilePhotoVerified {
                RidgitsPhotoVerifiedBadge(size: badgeSize)
            }
        }
    }
}
