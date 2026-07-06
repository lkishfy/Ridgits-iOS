import SwiftUI
import FirebaseAuth

struct MatchProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var pokeInbox: RidgitsPokeInbox

    let match: RidgitsMatch
    let onMessage: () -> Void
    let onPoke: () -> Void
    var onUnpoke: () -> Void = {}

    @State private var profile: RidgitsUserProfile?
    @State private var compatibility = RidgitsCompatibility.empty
    @State private var isLoadingProfile = true

    private var sentPoke: Bool {
        pokeInbox.sentPokeIdsByUser[match.userId] != nil
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                heroSection
                if !displayQuizBadges.isEmpty {
                    ProfileQuizBadgesSection(badges: displayQuizBadges)
                }
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .ridgitsFloatingTabBarPadding()
        }
        .background(RidgitsColors.feedBackground)
        .navigationTitle(match.displayFirstName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadProfile()
        }
    }

    private var displayAbout: String {
        let raw = profile?.about ?? match.about ?? ""
        return RidgitsDisplaySanitize.sanitizeBio(raw)
    }

    private var displayInterests: [String] {
        profile?.interests ?? []
    }

    private var displayAspirations: String {
        profile?.aspirations ?? ""
    }

    private var displayQuizBadges: [RidgitsQuizBadge] {
        profile?.completedQuizBadges ?? []
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            RidgitsCachedProfileImage(remoteURL: match.image.isEmpty ? nil : match.image) {
                RidgitsColors.border
            }
            .frame(maxWidth: .infinity)
            .frame(height: 280)
            .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.lg))
            .ridgitsProfilePhotoVerifiedOverlay(
                show: match.isProfilePhotoVerified || (profile?.profilePhotoVerified == true),
                size: 28
            )

            HStack(spacing: 8) {
                Text(match.displayFirstName)
                    .font(RidgitsTypography.headline(22))
                    .foregroundStyle(RidgitsColors.textHeadline)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                RidgitsProfileTrustBadges(
                    subscriptionTier: match.subscriptionTier,
                    profilePhotoVerified: match.isProfilePhotoVerified || (profile?.profilePhotoVerified == true),
                    badgeSize: 18
                )
                Spacer(minLength: 0)
                RidgitsCompatibilityBadge(percent: compatibility.overall)
            }

            if let miles = match.distanceMiles {
                Text(String(format: "%.0f mi away · %@", miles, match.location))
                    .font(RidgitsTypography.body(14))
                    .foregroundStyle(RidgitsColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else if !match.location.isEmpty {
                Text(match.location)
                    .font(RidgitsTypography.body(14))
                    .foregroundStyle(RidgitsColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var compatibilitySection: some View {
        RidgitsDashboardCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Compatibility")
                    .font(RidgitsTypography.label(15))
                    .foregroundStyle(RidgitsColors.textHeadline)

                dimensionRow("Communication", compatibility.communication)
                dimensionRow("Relational Depth", compatibility.intimacy)
                dimensionRow("Values", compatibility.values)
                dimensionRow("Social", compatibility.social)
                dimensionRow("Life Direction", compatibility.commitment)
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
            if sentPoke {
                Button("Poked") {
                    onUnpoke()
                }
                .font(RidgitsTypography.label(14))
                .foregroundStyle(RidgitsColors.textMuted)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .overlay(
                    RoundedRectangle(cornerRadius: RidgitsRadius.md)
                        .stroke(RidgitsColors.border, lineWidth: 1)
                )
            } else {
                Button("Poke") {
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
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func dimensionRow(_ title: String, _ value: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(RidgitsTypography.label(13))
                    .foregroundStyle(RidgitsColors.textHeadline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Spacer(minLength: 8)
                Text("\(value)%")
                    .font(RidgitsTypography.label(13))
                    .foregroundStyle(RidgitsColors.textSecondary)
                    .monospacedDigit()
            }

            Capsule()
                .fill(RidgitsColors.contextBar)
                .frame(maxWidth: .infinity)
                .frame(height: 6)
                .overlay(alignment: .leading) {
                    GeometryReader { geo in
                        Capsule()
                            .fill(RidgitsColors.ctaBlack)
                            .frame(width: max(0, geo.size.width * CGFloat(value) / 100))
                    }
                }
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

        compatibility = match.compatibility.withDerivedOverallIfNeeded()
        if !compatibility.hasScores,
           let uid = Auth.auth().currentUser?.uid,
           let calculated = await RidgitsQuizCompatibility.compatibilityBetween(
               currentUserId: uid,
               otherUserId: match.userId
           ) {
            compatibility = calculated
        }

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
