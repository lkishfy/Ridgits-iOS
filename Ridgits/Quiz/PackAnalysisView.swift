import SwiftUI

struct PackAnalysisPresentation: Identifiable {
    let id: String
    let pack: RidgitsArchetypePack
    let result: RidgitsPackArchetypeResult
}

struct PackAnalysisView: View {
    @Environment(\.dismiss) private var dismiss

    let pack: RidgitsArchetypePack
    let result: RidgitsPackArchetypeResult
    var embedInNavigationStack: Bool = true

    var body: some View {
        if embedInNavigationStack {
            NavigationStack {
                analysisContent
                    .navigationTitle(pack.title)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { dismiss() }
                                .foregroundStyle(RidgitsColors.textSecondary)
                        }
                    }
            }
        } else {
            analysisContent
        }
    }

    private var analysisContent: some View {
        ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    heroSection

                    if !result.characteristics.isEmpty {
                        sectionCard(title: "Key Characteristics") {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(result.characteristics, id: \.self) { trait in
                                    HStack(alignment: .top, spacing: 10) {
                                        Image(systemName: "checkmark.circle")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(RidgitsColors.textHeadline)
                                            .padding(.top, 1)
                                        Text(trait)
                                            .font(RidgitsTypography.body(14))
                                            .foregroundStyle(RidgitsColors.textSecondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                        }
                    }

                    if !result.suggestions.isEmpty {
                        sectionCard(title: "Suggestions for Growth") {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(result.suggestions, id: \.self) { suggestion in
                                    Text(suggestion)
                                        .font(RidgitsTypography.body(14))
                                        .foregroundStyle(RidgitsColors.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .padding(12)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(RidgitsColors.feedBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.md))
                                }
                            }
                        }
                    }

                    if let idealMatch = result.idealMatch, !idealMatch.isEmpty {
                        sectionCard(title: "Ideal Match") {
                            Text(idealMatch)
                                .font(RidgitsTypography.body(14))
                                .foregroundStyle(RidgitsColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(16)
            }
            .background(RidgitsColors.feedBackground)
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("YOUR ARCHETYPE")
                .font(RidgitsTypography.sectionLabel(11))
                .foregroundStyle(RidgitsColors.textSecondary)
                .tracking(0.8)
            Text(result.name)
                .font(RidgitsTypography.headline(24))
                .foregroundStyle(RidgitsColors.textHeadline)
            if !result.description.isEmpty {
                Text(result.description)
                    .font(RidgitsTypography.body(14))
                    .foregroundStyle(RidgitsColors.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RidgitsColors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: RidgitsRadius.lg)
                .stroke(RidgitsColors.dashboardBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.lg))
    }

    private func sectionCard(title: String, @ViewBuilder content: () -> some View) -> some View {
        RidgitsDashboardCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(RidgitsTypography.label(15))
                    .foregroundStyle(RidgitsColors.textHeadline)
                content()
            }
            .padding(16)
        }
    }
}
