import SwiftUI

struct QuizFullResultsPresentation: Identifiable {
    let id = UUID()
    let archetypeName: String
    let archetypeDescription: String
    let scores: RidgitsCompatibilityScores
    let profile: RidgitsUserProfile?
    let insights: [String]
    var previousArchetypeName: String?
}

struct QuizFullResultsView: View {
    @Environment(\.dismiss) private var dismiss

    let archetypeName: String
    let archetypeDescription: String
    let scores: RidgitsCompatibilityScores
    let profile: RidgitsUserProfile?
    let insights: [String]
    var previousArchetypeName: String?
    var showsUpdatedTitle = false
    var embedInNavigationStack = true
    var onDone: (() -> Void)?

    private var navigationTitle: String {
        showsUpdatedTitle ? "Updated Results" : "Full Results"
    }

    private let dimensions: [QuizDimensionDisplay] = [
        QuizDimensionDisplay(
            title: "Communication",
            leftLabel: "Expressive",
            rightLabel: "Reserved",
            detail: "How openly you share thoughts and feelings."
        ),
        QuizDimensionDisplay(
            title: "Relational Depth",
            leftLabel: "Affectionate",
            rightLabel: "Boundaried",
            detail: "Your approach to closeness and boundaries."
        ),
        QuizDimensionDisplay(
            title: "Values",
            leftLabel: "Traditional",
            rightLabel: "Progressive",
            detail: "Your outlook on beliefs and lifestyle."
        ),
        QuizDimensionDisplay(
            title: "Social",
            leftLabel: "Outgoing",
            rightLabel: "Private",
            detail: "How you engage socially."
        ),
        QuizDimensionDisplay(
            title: "Life Direction",
            leftLabel: "Aligned Goals",
            rightLabel: "Flexible Priorities",
            detail: "Your approach to long-term goals and priorities."
        ),
    ]

    var body: some View {
        if embedInNavigationStack {
            NavigationStack {
                resultsContent
                    .navigationTitle(navigationTitle)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { finish() }
                                .foregroundStyle(RidgitsColors.textSecondary)
                        }
                    }
            }
        } else {
            resultsContent
        }
    }

    private var resultsContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                if showsArchetypeChangeBanner {
                    archetypeChangeBanner
                }
                archetypeSection
                if hasProfileContent {
                    profileSection
                }
                dimensionsSection
                if !insights.isEmpty {
                    aboutYouSection
                }
            }
            .padding(16)
        }
        .background(RidgitsColors.feedBackground)
    }

    private var showsArchetypeChangeBanner: Bool {
        guard let previousArchetypeName, !previousArchetypeName.isEmpty else { return false }
        return previousArchetypeName != archetypeName
    }

    private var archetypeChangeBanner: some View {
        RidgitsDashboardCard {
            VStack(alignment: .leading, spacing: 6) {
                Text("Archetype updated")
                    .font(RidgitsTypography.label(13))
                    .foregroundStyle(RidgitsColors.textHeadline)
                Text("You were \(previousArchetypeName ?? ""). You're now \(archetypeName).")
                    .font(RidgitsTypography.body(13))
                    .foregroundStyle(RidgitsColors.textSecondary)
                    .lineSpacing(3)
            }
            .padding(14)
        }
    }

    private func finish() {
        if let onDone {
            onDone()
        } else {
            dismiss()
        }
    }

    private var hasProfileContent: Bool {
        guard let profile else { return false }
        return !profile.about.isEmpty || !profile.interests.isEmpty || !profile.image.isEmpty
    }

    private var archetypeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionBadge("Your Archetype")
            Text(archetypeName)
                .font(RidgitsTypography.headline(24))
                .foregroundStyle(RidgitsColors.textHeadline)
            if !archetypeDescription.isEmpty {
                Text(archetypeDescription)
                    .font(RidgitsTypography.body(14))
                    .foregroundStyle(RidgitsColors.textSecondary)
                    .lineSpacing(3)
            }
        }
    }

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let profile, !profile.about.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    sectionBadge("About Me")
                    HStack(alignment: .top, spacing: 14) {
                        if !profile.image.isEmpty {
                            RidgitsCachedProfileImage(
                                remoteURL: profile.image.isEmpty ? nil : profile.image
                            ) {
                                RidgitsColors.border
                            }
                            .frame(width: 72, height: 72)
                            .clipShape(Circle())
                        }
                        Text(profile.about)
                            .font(RidgitsTypography.body(14))
                            .foregroundStyle(RidgitsColors.textSecondary)
                            .lineSpacing(3)
                    }
                }
            }

            if let profile, !profile.interests.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    sectionBadge("Interests")
                    FlowLayout(spacing: 8) {
                        ForEach(profile.interests, id: \.self) { interest in
                            Text(interest)
                                .font(RidgitsTypography.caption(12))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(RidgitsColors.ctaBlack)
                                .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.sm))
                        }
                    }
                }
            }
        }
    }

    private var dimensionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionBadge("Your Personality Dimensions")

            ForEach(Array(dimensions.enumerated()), id: \.offset) { index, dimension in
                dimensionSpectrum(dimension, percent: dimensionScore(at: index))
            }

            Text("There's no \"better\" or \"worse\"—just your unique preferences.")
                .font(RidgitsTypography.caption(11))
                .foregroundStyle(RidgitsColors.textMuted)
                .frame(maxWidth: .infinity)
        }
    }

    private var aboutYouSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About You")
                .font(RidgitsTypography.headline(18))
                .foregroundStyle(RidgitsColors.textHeadline)

            ForEach(Array(insights.prefix(3).enumerated()), id: \.offset) { _, insight in
                RidgitsDashboardCard {
                    Text(insight)
                        .font(RidgitsTypography.body(13))
                        .foregroundStyle(RidgitsColors.textSecondary)
                        .lineSpacing(3)
                        .padding(14)
                }
            }
        }
    }

    private func dimensionScore(at index: Int) -> Int {
        switch index {
        case 0: return scores.communication
        case 1: return scores.intimacy
        case 2: return scores.values
        case 3: return scores.social
        default: return scores.commitment
        }
    }

    private func dimensionSpectrum(_ dimension: QuizDimensionDisplay, percent: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(dimension.title)
                    .font(RidgitsTypography.label(14))
                    .foregroundStyle(RidgitsColors.textHeadline)
                Spacer()
                Text(balancedLabel(for: percent))
                    .font(RidgitsTypography.caption(11))
                    .foregroundStyle(RidgitsColors.textMuted)
            }

            HStack {
                Text(dimension.leftLabel)
                    .font(RidgitsTypography.caption(10))
                    .foregroundStyle(RidgitsColors.textSecondary)
                Spacer()
                Text(dimension.rightLabel)
                    .font(RidgitsTypography.caption(10))
                    .foregroundStyle(RidgitsColors.textSecondary)
            }

            GeometryReader { geo in
                let trackHeight: CGFloat = 8
                let thumbSize: CGFloat = 18
                let thumbX = max(
                    0,
                    min(
                        geo.size.width - thumbSize,
                        geo.size.width * CGFloat(percent) / 100 - thumbSize / 2
                    )
                )

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(RidgitsColors.borderLight)
                        .overlay(
                            Capsule()
                                .stroke(RidgitsColors.border, lineWidth: 1)
                        )
                        .frame(height: trackHeight)

                    Circle()
                        .fill(RidgitsColors.ctaBlack)
                        .frame(width: thumbSize, height: thumbSize)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2.5)
                        )
                        .shadow(color: Color.black.opacity(0.18), radius: 2, y: 1)
                        .offset(x: thumbX)
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 22)

            Text(dimension.detail)
                .font(RidgitsTypography.caption(11))
                .foregroundStyle(RidgitsColors.textMuted)
        }
        .padding(.vertical, 4)
    }

    private func balancedLabel(for percent: Int) -> String {
        if abs(percent - 50) <= 8 { return "Balanced" }
        return "\(percent)%"
    }

    private func sectionBadge(_ title: String) -> some View {
        Text(title.uppercased())
            .font(RidgitsTypography.sectionLabel(11))
            .foregroundStyle(RidgitsColors.textSecondary)
            .tracking(0.8)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .overlay(
                RoundedRectangle(cornerRadius: RidgitsRadius.sm)
                    .stroke(RidgitsColors.border, lineWidth: 1)
            )
    }
}

private struct QuizDimensionDisplay {
    let title: String
    let leftLabel: String
    let rightLabel: String
    let detail: String
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
    }
}
