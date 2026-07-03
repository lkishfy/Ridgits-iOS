import SwiftUI

struct ReferralQuizzesSection: View {
    @EnvironmentObject private var ridgitsStore: RidgitsStore
    @EnvironmentObject private var referralStore: RidgitsReferralStore

    let packProfile: RidgitsPackProfile
    let onSelectPack: (RidgitsArchetypePack) -> Void
    let onViewAnalysis: (RidgitsArchetypePack) -> Void

    private var referralsCompleted: Int {
        referralStore.referralProfile?.referralsCompleted ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(RidgitsColors.border)
                .frame(height: 1)

            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Referral Quizzes")
                        .font(RidgitsTypography.label(13))
                        .foregroundStyle(RidgitsColors.textHeadline)
                    Text("Exclusive quizzes you unlock when friends finish their quiz — up to 3 total.")
                        .font(RidgitsTypography.caption(11))
                        .foregroundStyle(RidgitsColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 12) {
                    ForEach(RidgitsArchetypePack.referralCatalog) { pack in
                        referralPackCard(pack)
                    }
                }
            }
            .padding(16)
        }
    }

    @ViewBuilder
    private func referralPackCard(_ pack: RidgitsArchetypePack) -> some View {
        let hasAccess = packProfile.hasAccess(
            to: pack,
            ownsBundle: false,
            membershipTier: ridgitsStore.membershipTier,
            referralsCompleted: referralsCompleted
        )
        let result = packProfile.result(for: pack)

        if let result, hasAccess {
            completedPackCard(pack: pack, result: result)
        } else {
            lockedPackCard(pack: pack, hasAccess: hasAccess)
        }
    }

    private func completedPackCard(pack: RidgitsArchetypePack, result: RidgitsPackArchetypeResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            packHeader(pack, locked: false)
            Text(result.name)
                .font(RidgitsTypography.label(13))
                .foregroundStyle(RidgitsColors.textHeadline)
            if !result.description.isEmpty {
                Text(result.description)
                    .font(RidgitsTypography.caption(12))
                    .foregroundStyle(RidgitsColors.textSecondary)
                    .lineLimit(2)
            }
            Button {
                onViewAnalysis(pack)
            } label: {
                Text("View Full Analysis")
                    .font(RidgitsTypography.label(11))
                    .foregroundStyle(RidgitsColors.textHeadline)
                    .underline()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RidgitsColors.feedBackground)
        .overlay(
            RoundedRectangle(cornerRadius: RidgitsRadius.lg)
                .stroke(RidgitsColors.dashboardBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.lg))
    }

    private func lockedPackCard(pack: RidgitsArchetypePack, hasAccess: Bool) -> some View {
        let slot = pack.referralSlot ?? 1

        return Button {
            onSelectPack(pack)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                packHeader(pack, locked: !hasAccess)
                Text(pack.description)
                    .font(RidgitsTypography.caption(12))
                    .foregroundStyle(RidgitsColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)

                if hasAccess {
                    Text("Take Quiz")
                        .font(RidgitsTypography.label(11))
                        .tracking(0.4)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .foregroundStyle(RidgitsColors.textHeadline)
                        .background(RidgitsColors.hoverSurface)
                        .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.sm))
                } else {
                    referralLockButton(requiredReferrals: slot)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RidgitsColors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: RidgitsRadius.lg)
                    .stroke(RidgitsColors.border, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
            )
            .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.lg))
        }
        .buttonStyle(.plain)
    }

    private func referralLockButton(requiredReferrals: Int) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.system(size: 11, weight: .semibold))
            Text(RidgitsReferralLimits.referralsRequiredLabel(for: requiredReferrals))
                .font(RidgitsTypography.label(11))
                .tracking(0.3)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 36)
        .background(RidgitsColors.ctaBlack)
        .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.sm))
    }

    private func packHeader(_ pack: RidgitsArchetypePack, locked: Bool = false) -> some View {
        HStack(spacing: 10) {
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: RidgitsRadius.lg)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: pack.gradientStart), Color(hex: pack.gradientEnd)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: pack.icon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white)
                            .opacity(locked ? 0.55 : 1)
                    )

                if locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(4)
                        .background(RidgitsColors.ctaBlack)
                        .clipShape(Circle())
                        .offset(x: 4, y: 4)
                }
            }

            Text(pack.title)
                .font(RidgitsTypography.label(13))
                .foregroundStyle(RidgitsColors.textHeadline)
                .multilineTextAlignment(.leading)
            Spacer()
        }
    }
}
