import SwiftUI

struct QuizPersonalityFeaturesIntroSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("A few tools for the questions ahead")
                            .font(RidgitsTypography.headline(22))
                            .foregroundStyle(RidgitsColors.textHeadline)

                        Text("These help you shape how matches are scored. All are optional.")
                            .font(RidgitsTypography.body(14))
                            .foregroundStyle(RidgitsColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    introRow(
                        chip: {
                            QuizIntroFeatureChip(
                                title: "Dealbreaker",
                                systemImage: "exclamationmark.triangle.fill",
                                activeColor: RidgitsColors.destructive
                            )
                        },
                        body: "Mark a must-have. If a match answers differently, compatibility takes a bigger hit."
                    )

                    introRow(
                        chip: {
                            QuizIntroFeatureChip(
                                title: "Multi-select · 3 left",
                                systemImage: "checklist",
                                activeColor: Color(hex: 0xC2410C)
                            )
                        },
                        body: "Choose more than one answer on up to three questions when more than one option fits."
                    )

                    introRow(
                        chip: {
                            QuizIdealAnswerPreviewBar()
                        },
                        body: "Choose how you'd want someone else to answer and how important their answer is to you."
                    )

                    RidgitsPrimaryButton(title: "Got it") {
                        dismiss()
                    }
                    .padding(.top, 4)
                }
                .padding(24)
            }
            .background(RidgitsColors.feedBackground)
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func introRow<Chip: View>(
        @ViewBuilder chip: () -> Chip,
        body: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            chip()
            Text(body)
                .font(RidgitsTypography.body(13))
                .foregroundStyle(RidgitsColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Static preview of an active quiz feature chip (matches `modifyFeatureChip` when on).
private struct QuizIntroFeatureChip: View {
    let title: String
    let systemImage: String
    let activeColor: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold))
            Text(title)
                .font(RidgitsTypography.label(12))
                .tracking(0.4)
                .lineLimit(1)
        }
        .fixedSize(horizontal: true, vertical: false)
        .foregroundStyle(activeColor)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(activeColor.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: RidgitsRadius.md)
                .stroke(activeColor, lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.md))
    }
}

private struct QuizIdealAnswerPreviewBar: View {
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(spacing: 2) {
                Text("CHOOSE THEIR IDEAL ANSWER")
                    .font(RidgitsTypography.label(11))
                    .foregroundStyle(RidgitsColors.textHeadline)
                    .tracking(0.35)
                Text("OPTIONAL")
                    .font(RidgitsTypography.caption(10))
                    .foregroundStyle(RidgitsColors.textMuted)
                    .tracking(0.35)
            }
            .frame(maxWidth: .infinity)

            Image(systemName: "chevron.up")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(RidgitsColors.textMuted)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(Color(hex: 0xF0F0F0))
        .overlay(
            RoundedRectangle(cornerRadius: RidgitsRadius.md)
                .stroke(Color(hex: 0x999999), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.md))
    }
}
