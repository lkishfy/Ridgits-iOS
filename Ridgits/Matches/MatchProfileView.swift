import SwiftUI

struct MatchProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var pokeInbox: RidgitsPokeInbox

    let match: RidgitsMatch
    let onMessage: () -> Void
    let onPoke: () -> Void

    @State private var profile: RidgitsUserProfile?
    @State private var isLoadingProfile = true

    private var sentPoke: Bool {
        pokeInbox.sentPokeIdsByUser[match.userId] != nil
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                heroSection
                compatibilitySection
                aboutSection
                if !displayInterests.isEmpty {
                    interestsSection
                }
                if !displayAspirations.isEmpty {
                    aspirationsSection
                }
                actionButtons
            }
            .padding(20)
            .ridgitsFloatingTabBarPadding()
        }
        .background(RidgitsColors.feedBackground)
        .navigationTitle(match.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadProfile()
        }
    }

    private var displayAbout: String {
        profile?.about ?? match.about ?? ""
    }

    private var displayInterests: [String] {
        profile?.interests ?? []
    }

    private var displayAspirations: String {
        profile?.aspirations ?? ""
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            RidgitsCachedProfileImage(remoteURL: match.image.isEmpty ? nil : match.image) {
                RidgitsColors.border
            }
            .frame(maxWidth: .infinity)
            .frame(height: 280)
            .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.lg))

            HStack(spacing: 8) {
                Text(match.name)
                    .font(RidgitsTypography.headline(22))
                    .foregroundStyle(RidgitsColors.textHeadline)
                RidgitsVerifiedBadge(tier: match.subscriptionTier, size: 18)
                Spacer()
                RidgitsCompatibilityBadge(percent: match.compatibility.overall)
            }

            if let miles = match.distanceMiles {
                Text(String(format: "%.0f mi away · %@", miles, match.location))
                    .font(RidgitsTypography.body(14))
                    .foregroundStyle(RidgitsColors.textSecondary)
            } else if !match.location.isEmpty {
                Text(match.location)
                    .font(RidgitsTypography.body(14))
                    .foregroundStyle(RidgitsColors.textSecondary)
            }
        }
    }

    private var compatibilitySection: some View {
        RidgitsDashboardCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Compatibility")
                    .font(RidgitsTypography.label(15))
                    .foregroundStyle(RidgitsColors.textHeadline)

                dimensionRow("Communication", match.compatibility.communication)
                dimensionRow("Relational Depth", match.compatibility.intimacy)
                dimensionRow("Values", match.compatibility.values)
                dimensionRow("Social", match.compatibility.social)
                dimensionRow("Life Direction", match.compatibility.commitment)
            }
            .padding(16)
        }
    }

    private var aboutSection: some View {
        Group {
            if isLoadingProfile {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            } else if !displayAbout.isEmpty {
                profileTextSection(title: "About", body: displayAbout)
            }
        }
    }

    private var interestsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionBadge("Interests")
            FlowLayout(spacing: 8) {
                ForEach(displayInterests, id: \.self) { interest in
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

    private var aspirationsSection: some View {
        profileTextSection(title: "Aspirations", body: displayAspirations)
    }

    private var actionButtons: some View {
        HStack(spacing: 10) {
            RidgitsPrimaryButton(title: "Message") {
                onMessage()
                dismiss()
            }
            Button(sentPoke ? "Unpoke" : "Poke") {
                onPoke()
            }
            .font(RidgitsTypography.label(14))
            .foregroundStyle(RidgitsColors.textHeadline)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .overlay(
                RoundedRectangle(cornerRadius: RidgitsRadius.md)
                    .stroke(RidgitsColors.border, lineWidth: 1)
            )
        }
        .padding(.top, 4)
    }

    private func profileTextSection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionBadge(title)
            Text(body)
                .font(RidgitsTypography.body(14))
                .foregroundStyle(RidgitsColors.textSecondary)
                .lineSpacing(3)
        }
    }

    private func dimensionRow(_ title: String, _ value: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(RidgitsTypography.label(13))
                    .foregroundStyle(RidgitsColors.textHeadline)
                Spacer()
                Text("\(value)%")
                    .font(RidgitsTypography.label(13))
                    .foregroundStyle(RidgitsColors.textSecondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(RidgitsColors.contextBar)
                    Capsule()
                        .fill(RidgitsColors.ctaBlack)
                        .frame(width: max(0, geo.size.width * CGFloat(value) / 100))
                }
            }
            .frame(height: 6)
        }
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

    @MainActor
    private func loadProfile() async {
        isLoadingProfile = true
        defer { isLoadingProfile = false }
        profile = await RidgitsFirebaseClient.shared.fetchPublicProfile(uid: match.userId)
    }
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
