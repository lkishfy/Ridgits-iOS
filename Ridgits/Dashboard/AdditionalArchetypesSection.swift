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
            RidgitsFullWidthDivider()

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
    let userArchetypeName: String
    @StateObject private var statsViewModel = CommunityStatsViewModel()

    var body: some View {
        RidgitsDashboardCard(edgeToEdge: true) {
            VStack(alignment: .leading, spacing: 0) {
                headerRow
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)

                RidgitsFullWidthDivider()

                if statsViewModel.isLoading {
                    Text("Loading community stats…")
                        .font(RidgitsTypography.caption(12))
                        .foregroundStyle(RidgitsColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 32)
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        quizStatsBlock
                            .padding(16)

                        RidgitsFullWidthDivider()

                        popularQuestionsBlock
                            .padding(16)

                        RidgitsFullWidthDivider()

                        suggestQuestionBlock
                            .padding(16)

                        if !statsViewModel.archetypeDistribution.isEmpty {
                            RidgitsFullWidthDivider()

                            archetypeDistributionBlock
                                .padding(16)
                        }
                    }
                }
            }
        }
        .onAppear { statsViewModel.startListening() }
        .onDisappear { statsViewModel.stopListening() }
    }

    private var headerRow: some View {
        HStack(alignment: .center) {
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
                    Text("Invite your friends")
                        .font(RidgitsTypography.label(11))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(RidgitsColors.ctaBlack)
                .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.md))
            }
        }
    }

    private var quizStatsBlock: some View {
        VStack(spacing: 0) {
            monthlyActivityBadge
                .padding(.bottom, 16)

            Text("Ridgits Quizzes Completed")
                .font(RidgitsTypography.caption(13))
                .foregroundStyle(RidgitsColors.textSecondary)
                .padding(.bottom, 8)

            Text(statsViewModel.stats.totalCompleted.formatted())
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(RidgitsColors.textHeadline)
                .monospacedDigit()
                .tracking(-0.5)
        }
        .frame(maxWidth: .infinity)
    }

    private var monthlyActivityBadge: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(hex: 0x059669))
                .frame(width: 8, height: 8)

            Text(monthlyActivityBadgeText)
                .font(RidgitsTypography.label(11))
                .foregroundStyle(Color(hex: 0x065F46))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(hex: 0xD1FAE5))
        .clipShape(Capsule())
    }

    private var monthlyActivityBadgeText: String {
        statsViewModel.stats.monthlyActivityLabel
    }

    private var popularQuestionsBlock: some View {
        VStack(spacing: 12) {
            popularQuestionCard(
                icon: "person.2",
                label: "Most Popular Community Question",
                question: statsViewModel.popularCommunityQuestion,
                emptyMessage: "No community questions rated yet"
            )
            popularQuestionCard(
                icon: "hand.thumbsup",
                label: "Most Popular Original Question",
                question: statsViewModel.popularOriginalQuestion,
                emptyMessage: "No original questions rated yet"
            )
        }
    }

    private func popularQuestionCard(
        icon: String,
        label: String,
        question: PopularQuestionRating?,
        emptyMessage: String
    ) -> some View {
        Group {
            if let question, question.upCount > 0 {
                HStack(alignment: .top, spacing: 12) {
                    RoundedRectangle(cornerRadius: RidgitsRadius.md)
                        .fill(RidgitsColors.hoverSurface)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: icon)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(RidgitsColors.textHeadline)
                        )

                    VStack(alignment: .leading, spacing: 6) {
                        Text(label)
                            .font(RidgitsTypography.caption(10))
                            .foregroundStyle(RidgitsColors.textSecondary)
                            .tracking(0.6)
                        Text("\"\(question.questionText)\"")
                            .font(RidgitsTypography.body(13))
                            .foregroundStyle(RidgitsColors.textHeadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(RidgitsColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: RidgitsRadius.lg)
                        .stroke(RidgitsColors.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.lg))
            } else {
                Text(emptyMessage)
                    .font(RidgitsTypography.body(13))
                    .foregroundStyle(RidgitsColors.textMuted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(RidgitsColors.feedBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: RidgitsRadius.lg)
                            .stroke(RidgitsColors.border, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.lg))
            }
        }
    }

    private var suggestQuestionBlock: some View {
        VStack(spacing: 12) {
            Text("Suggest a Question")
                .font(RidgitsTypography.caption(12))
                .foregroundStyle(RidgitsColors.textSecondary)
                .frame(maxWidth: .infinity)

            HStack(spacing: 8) {
                Image(systemName: "person.3")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(RidgitsColors.textHeadline)
                Text("\(CommunityStatsViewModel.communityQuestionCount) questions added")
                    .font(RidgitsTypography.label(13))
                    .foregroundStyle(RidgitsColors.textHeadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(RidgitsColors.hoverSurface)
            .overlay(
                RoundedRectangle(cornerRadius: RidgitsRadius.md)
                    .stroke(RidgitsColors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.md))

            Text("Help improve the quiz by suggesting new questions")
                .font(RidgitsTypography.caption(12))
                .foregroundStyle(RidgitsColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            if statsViewModel.questionSubmitStatus == .success {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(Color(hex: 0x22C55E))
                    Text("Thanks for your suggestion!")
                        .font(RidgitsTypography.label(13))
                        .foregroundStyle(Color(hex: 0x16A34A))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(hex: 0xF0FDF4))
                .overlay(
                    RoundedRectangle(cornerRadius: RidgitsRadius.md)
                        .stroke(Color(hex: 0x86EFAC), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.md))
            } else {
                VStack(spacing: 10) {
                    TextField(
                        "What question would help people find better matches?",
                        text: $statsViewModel.questionDraft,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                    .font(RidgitsTypography.body(13))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(RidgitsColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: RidgitsRadius.md)
                            .stroke(RidgitsColors.border, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.md))
                    .disabled(statsViewModel.isSubmittingQuestion)
                    .onChange(of: statsViewModel.questionDraft) { _, newValue in
                        if newValue.count > 500 {
                            statsViewModel.questionDraft = String(newValue.prefix(500))
                        }
                    }

                    if statsViewModel.questionSubmitStatus == .error {
                        Text("Something went wrong. Please try again.")
                            .font(RidgitsTypography.caption(12))
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }

                    HStack {
                        Text("\(statsViewModel.questionDraft.count)/500")
                            .font(RidgitsTypography.caption(12))
                            .foregroundStyle(RidgitsColors.textMuted)

                        Spacer()

                        Button {
                            Task { await statsViewModel.submitQuestionIdea() }
                        } label: {
                            Text(statsViewModel.isSubmittingQuestion ? "Sending…" : "Submit")
                                .font(RidgitsTypography.label(13))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(RidgitsColors.ctaBlack)
                                .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.md))
                                .opacity(
                                    statsViewModel.isSubmittingQuestion
                                        || statsViewModel.questionDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                        ? 0.5
                                        : 1
                                )
                        }
                        .buttonStyle(RidgitsHapticPlainButtonStyle())
                        .disabled(
                            statsViewModel.isSubmittingQuestion
                                || statsViewModel.questionDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        )
                    }
                }
            }
        }
        .padding(.top, 4)
    }

    private var archetypeDistributionBlock: some View {
        VStack(spacing: 12) {
            Text("Community Archetypes")
                .font(RidgitsTypography.caption(12))
                .foregroundStyle(RidgitsColors.textSecondary)
                .frame(maxWidth: .infinity)

            VStack(spacing: 12) {
                ForEach(statsViewModel.archetypeDistribution) { entry in
                    archetypeRow(entry)
                }
            }
        }
    }

    private func archetypeRow(_ entry: ArchetypeDistributionEntry) -> some View {
        let total = max(statsViewModel.stats.totalCompleted, 1)
        let percentage = Double(entry.count) / Double(total) * 100
        let isUserArchetype = entry.name == userArchetypeName

        return VStack(spacing: 4) {
            HStack {
                Text("\(entry.name)\(isUserArchetype ? " (You)" : "")")
                    .font(RidgitsTypography.caption(12))
                    .fontWeight(isUserArchetype ? .bold : .regular)
                    .foregroundStyle(isUserArchetype ? RidgitsColors.textHeadline : RidgitsColors.textSecondary)
                Spacer()
                Text("\(entry.count) (\(String(format: "%.1f", percentage))%)")
                    .font(RidgitsTypography.caption(12))
                    .foregroundStyle(RidgitsColors.textMuted)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(hex: 0xE0E0E0))
                    Rectangle()
                        .fill(isUserArchetype ? RidgitsColors.textHeadline : Color(hex: 0x666666))
                        .frame(width: geometry.size.width * CGFloat(entry.count) / CGFloat(total))
                }
            }
            .frame(height: 8)
        }
    }
}
