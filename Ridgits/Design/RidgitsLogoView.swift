import SwiftUI

enum RidgitsLogoView {
    /// White squircle grid on black — matches `Ridgits/ridgits/src/assets/logo.png` on dark backgrounds (login circle, loading).
    static func onDark(size: CGFloat) -> some View {
        Image("RidgitsLogo")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }

    /// Inverted for light backgrounds — matches web home nav `filter: invert(1) brightness(0)`.
    static func onLight(size: CGFloat) -> some View {
        Image("RidgitsLogo")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .colorInvert()
            .brightness(-1)
    }
}

/// Top navigation logo with the active subscription tier badge in the bottom-right corner.
struct RidgitsNavLogoView: View {
    let membershipTier: RidgitsSubscriptionTier
    let isMembershipActive: Bool
    var size: CGFloat = 22

    var body: some View {
        RidgitsLogoView.onLight(size: size)
            .overlay(alignment: .bottomTrailing) {
                if let badgeTier {
                    RidgitsVerifiedBadge(tier: badgeTier, size: badgeSize)
                        .background(Circle().fill(RidgitsColors.surface))
                        .offset(x: 4, y: 4)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel)
    }

    private var badgeTier: RidgitsSubscriptionTier? {
        guard isMembershipActive, membershipTier.showsVerifiedBadge else { return nil }
        return membershipTier
    }

    private var badgeSize: CGFloat {
        max(12, size * 0.58)
    }

    private var accessibilityLabel: String {
        if let badgeTier {
            return "Ridgits, \(badgeTier.displayName) subscriber"
        }
        return "Ridgits"
    }
}
