import SwiftUI

struct AdditionalArchetypesSection: View {
    @EnvironmentObject private var ridgitsStore: RidgitsStore

    let packProfile: RidgitsPackProfile
    let ownsBundle: Bool
    @Binding var showAll: Bool
    let onSelectPack: (RidgitsArchetypePack) -> Void
    let onViewAnalysis: (RidgitsArchetypePack) -> Void

    private var visiblePacks: [RidgitsArchetypePack] {
        if showAll {
            return RidgitsArchetypePack.catalog
        }
        return Array(RidgitsArchetypePack.catalog.prefix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(RidgitsColors.border)
                .frame(height: 1)

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Additional Archetypes")
                        .font(RidgitsTypography.label(13))
                        .foregroundStyle(RidgitsColors.textHeadline)
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showAll.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(showAll ? "Show Less" : "Show All")
                                .font(RidgitsTypography.label(11))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                                .rotationEffect(.degrees(showAll ? 180 : 0))
                        }
                        .foregroundStyle(RidgitsColors.textSecondary)
                    }
                    .buttonStyle(RidgitsHapticPlainButtonStyle())
                }

                Text("Enhance your matches with deeper archetype insights")
                    .font(RidgitsTypography.caption(11))
                    .foregroundStyle(RidgitsColors.textSecondary)

                VStack(spacing: 12) {
                    ForEach(visiblePacks) { pack in
                        packCard(pack)
                    }
                }
            }
            .padding(16)
        }
    }

    @ViewBuilder
    private func packCard(_ pack: RidgitsArchetypePack) -> some View {
        let hasAccess = packProfile.hasAccess(
            to: pack,
            ownsBundle: ownsBundle,
            membershipTier: ridgitsStore.membershipTier
        )
        let result = packProfile.result(for: pack)

        if let result, hasAccess {
            completedPackCard(pack: pack, result: result)
        } else {
            availablePackCard(pack: pack, hasAccess: hasAccess)
        }
    }

    private func completedPackCard(pack: RidgitsArchetypePack, result: RidgitsPackArchetypeResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                packIcon(pack)
                VStack(alignment: .leading, spacing: 2) {
                    Text(pack.title.uppercased())
                        .font(RidgitsTypography.caption(10))
                        .foregroundStyle(RidgitsColors.textSecondary)
                        .tracking(0.8)
                    Text(result.name)
                        .font(RidgitsTypography.label(13))
                        .foregroundStyle(RidgitsColors.textHeadline)
                }
                Spacer(minLength: 28)
            }

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
                    .contentShape(Rectangle())
            }
            .buttonStyle(RidgitsHapticPlainButtonStyle())
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RidgitsColors.feedBackground)
        .overlay(
            RoundedRectangle(cornerRadius: RidgitsRadius.lg)
                .stroke(RidgitsColors.dashboardBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.lg))
        .overlay(alignment: .topTrailing) {
            packCornerBadge(for: pack)
        }
        .overlay(alignment: .bottomTrailing) {
            if pack.isFree {
                freeBadge
            }
        }
    }

    private func availablePackCard(
        pack: RidgitsArchetypePack,
        hasAccess: Bool
    ) -> some View {
        Button {
            onSelectPack(pack)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    packIcon(pack)
                    Text(pack.title)
                        .font(RidgitsTypography.label(13))
                        .foregroundStyle(RidgitsColors.textHeadline)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 28)
                }

                Text(pack.description)
                    .font(RidgitsTypography.caption(12))
                    .foregroundStyle(RidgitsColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)

                Text("Take Quiz")
                    .font(RidgitsTypography.label(11))
                    .tracking(0.4)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .foregroundStyle(hasAccess && !pack.isFree ? RidgitsColors.textHeadline : .white)
                    .background(hasAccess ? RidgitsColors.hoverSurface : RidgitsColors.ctaBlack)
                    .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.sm))
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RidgitsColors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: RidgitsRadius.lg)
                    .stroke(RidgitsColors.border, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
            )
            .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.lg))
            .overlay(alignment: .topTrailing) {
                packCornerBadge(for: pack)
            }
            .overlay(alignment: .bottomTrailing) {
                if pack.isFree {
                    freeBadge
                }
            }
        }
        .buttonStyle(RidgitsHapticPlainButtonStyle())
    }

    @ViewBuilder
    private func packCornerBadge(for pack: RidgitsArchetypePack) -> some View {
        if let tier = pack.requiredMembershipTier {
            RidgitsVerifiedBadge(tier: tier, size: 22)
                .padding(10)
        }
    }

    private func packIcon(_ pack: RidgitsArchetypePack) -> some View {
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
            )
    }

    private var freeBadge: some View {
        Text("FREE")
            .font(RidgitsTypography.caption(9))
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color(hex: 0x10B981))
            .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.sm))
            .padding(10)
    }
}

struct CommunitySection: View {
    @StateObject private var statsViewModel = CommunityStatsViewModel()

    var body: some View {
        RidgitsDashboardCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    Text("Community")
                        .font(RidgitsTypography.label(15))
                        .foregroundStyle(RidgitsColors.textHeadline)
                    Spacer()
                    ShareLink(
                        item: RidgitsAppLinks.appStoreURL,
                        subject: Text("Ridgits"),
                        message: Text("Take personality quizzes and find compatible people nearby — only on Ridgits.")
                    ) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 11, weight: .medium))
                            Text("Invite friends")
                                .font(RidgitsTypography.label(11))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(RidgitsColors.ctaBlack)
                        .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.md))
                    }
                }

                if statsViewModel.isLoading {
                    Text("Loading community stats…")
                        .font(RidgitsTypography.caption(12))
                        .foregroundStyle(RidgitsColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                } else {
                    VStack(spacing: 6) {
                        Text("\(statsViewModel.stats.completedThisWeek.formatted())")
                            .font(.system(size: 44, weight: .semibold))
                            .foregroundStyle(RidgitsColors.textHeadline)
                            .monospacedDigit()

                        Text("Quizzes completed this week")
                            .font(RidgitsTypography.caption(13))
                            .foregroundStyle(RidgitsColors.textSecondary)

                        Text("\(statsViewModel.stats.totalCompleted.formatted()) total all time")
                            .font(RidgitsTypography.caption(11))
                            .foregroundStyle(RidgitsColors.textMuted)
                            .padding(.top, 2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .onAppear { statsViewModel.startListening() }
        .onDisappear { statsViewModel.stopListening() }
    }
}
