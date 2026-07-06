import SwiftUI

struct RidgitsQuizBadge: Identifiable, Equatable, Codable {
    let id: String
    let title: String
    let icon: String
    let gradientStart: UInt32
    let gradientEnd: UInt32

    init(id: String, title: String, icon: String, gradientStart: UInt32, gradientEnd: UInt32) {
        self.id = id
        self.title = title
        self.icon = icon
        self.gradientStart = gradientStart
        self.gradientEnd = gradientEnd
    }

    init(pack: RidgitsArchetypePack) {
        self.init(
            id: pack.id,
            title: pack.title,
            icon: pack.icon,
            gradientStart: pack.gradientStart,
            gradientEnd: pack.gradientEnd
        )
    }

    var firestorePayload: [String: Any] {
        [
            "id": id,
            "title": title,
            "icon": icon,
            "gradientStart": Int(gradientStart),
            "gradientEnd": Int(gradientEnd),
        ]
    }

    static func from(data: [String: Any]) -> RidgitsQuizBadge? {
        guard let id = data["id"] as? String,
              let title = data["title"] as? String,
              !id.isEmpty, !title.isEmpty else { return nil }
        let icon = data["icon"] as? String ?? "checkmark.seal.fill"
        let gradientStart = UInt32(truncatingIfNeeded: (data["gradientStart"] as? NSNumber)?.intValue ?? 0x111827)
        let gradientEnd = UInt32(truncatingIfNeeded: (data["gradientEnd"] as? NSNumber)?.intValue ?? 0x374151)
        return RidgitsQuizBadge(
            id: id,
            title: title,
            icon: icon,
            gradientStart: gradientStart,
            gradientEnd: gradientEnd
        )
    }
}

enum RidgitsQuizBadgeBuilder {
    static let personalityQuizId = "personality"

    private static let personalityBadge = RidgitsQuizBadge(
        id: personalityQuizId,
        title: "Personality Quiz",
        icon: "brain.head.profile",
        gradientStart: 0x111827,
        gradientEnd: 0x374151
    )

    static func badges(
        packProfile: RidgitsPackProfile,
        personalityQuizCompleted: Bool
    ) -> [RidgitsQuizBadge] {
        var badges: [RidgitsQuizBadge] = []
        if personalityQuizCompleted {
            badges.append(personalityBadge)
        }
        for pack in RidgitsArchetypePack.catalog + RidgitsArchetypePack.referralCatalog {
            if packProfile.result(for: pack) != nil {
                badges.append(RidgitsQuizBadge(pack: pack))
            }
        }
        return badges
    }
}

struct ProfileQuizBadgesSection: View {
    let badges: [RidgitsQuizBadge]

    var body: some View {
        if !badges.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("QUIZZES COMPLETED")
                    .font(RidgitsTypography.sectionLabel(11))
                    .foregroundStyle(RidgitsColors.textSecondary)
                    .tracking(0.8)

                FlowLayout(spacing: 8) {
                    ForEach(badges) { badge in
                        ProfileQuizBadgeChip(badge: badge)
                    }
                }
            }
        }
    }
}

struct ProfileQuizBadgeChip: View {
    let badge: RidgitsQuizBadge

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: badge.gradientStart), Color(hex: badge.gradientEnd)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 22, height: 22)
                .overlay(
                    Image(systemName: badge.icon)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white)
                )

            Text(badge.title)
                .font(RidgitsTypography.caption(11))
                .foregroundStyle(RidgitsColors.textHeadline)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(RidgitsColors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: RidgitsRadius.sm)
                .stroke(RidgitsColors.optionBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.sm))
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
