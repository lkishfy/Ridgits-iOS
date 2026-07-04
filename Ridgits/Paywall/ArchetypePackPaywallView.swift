import SwiftUI

struct ArchetypePackPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var ridgitsStore: RidgitsStore

    let pack: RidgitsArchetypePack
    var onPurchaseComplete: () -> Void
    var onViewSubscriptions: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    pricingOptions
                    if let error = ridgitsStore.purchaseError {
                        Text(error)
                            .font(RidgitsTypography.caption(12))
                            .foregroundStyle(RidgitsColors.destructive)
                    }
                }
                .padding(20)
            }
            .background(RidgitsColors.feedBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(RidgitsColors.textSecondary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: RidgitsRadius.lg)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: pack.gradientStart), Color(hex: pack.gradientEnd)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: pack.icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(pack.title)
                        .font(RidgitsTypography.headline(18))
                        .foregroundStyle(RidgitsColors.textHeadline)
                    if pack.ultraOnly {
                        Text("Included with Ridgits Ultra")
                            .font(RidgitsTypography.caption(11))
                            .foregroundStyle(RidgitsColors.textSecondary)
                    }
                }
            }

            Text(pack.description)
                .font(RidgitsTypography.body(14))
                .foregroundStyle(RidgitsColors.textSecondary)
                .lineSpacing(3)
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

    private var showsSubscriptionOption: Bool {
        if pack.ultraOnly {
            return ridgitsStore.membershipTier != .ultra
        }
        return ridgitsStore.membershipTier.rank < RidgitsSubscriptionTier.premium.rank
    }

    private var subscriptionTier: RidgitsSubscriptionTier {
        pack.ultraOnly ? .ultra : .premium
    }

    private var subscriptionPriceLine: String {
        ridgitsStore.priceLine(tier: subscriptionTier, billing: .yearly)
    }

    private var pricingOptions: some View {
        VStack(spacing: 12) {
            Text("UNLOCK OPTIONS")
                .font(RidgitsTypography.sectionLabel(11))
                .foregroundStyle(RidgitsColors.textSecondary)
                .tracking(0.8)
                .frame(maxWidth: .infinity, alignment: .leading)

            if showsSubscriptionOption {
                subscriptionCard
            }

            Text("OR BUY SEPARATELY")
                .font(RidgitsTypography.sectionLabel(11))
                .foregroundStyle(RidgitsColors.textSecondary)
                .tracking(0.8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)

            pricingCard(
                title: pack.title,
                price: ridgitsStore.product(for: pack)?.displayPrice ?? "$9.99",
                subtitle: "One-time purchase · 50-question quiz",
                highlighted: true
            ) {
                Task {
                    if await ridgitsStore.purchaseArchetypePack(pack) {
                        onPurchaseComplete()
                        dismiss()
                    }
                }
            }

            Text("Take the quiz in app. Results sync to your Ridgits profile.")
                .font(RidgitsTypography.caption(11))
                .foregroundStyle(RidgitsColors.textMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
        }
    }

    private var subscriptionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(subscriptionTier.displayName)
                    .font(RidgitsTypography.label(14))
                    .foregroundStyle(RidgitsColors.textHeadline)
                Spacer()
                Text("\(subscriptionPriceLine)/yr")
                    .font(RidgitsTypography.headline(18))
                    .foregroundStyle(RidgitsColors.textHeadline)
            }
            Text(
                pack.ultraOnly
                    ? "Included with Ultra · All exclusive archetype packs"
                    : "Included with Premium · All additional archetype quizzes"
            )
            .font(RidgitsTypography.caption(12))
            .foregroundStyle(RidgitsColors.textSecondary)

            RidgitsSquareButton(
                title: "Subscribe — \(subscriptionPriceLine)/yr",
                style: .filled
            ) {
                onViewSubscriptions()
            }
        }
        .padding(16)
        .background(RidgitsColors.feedBackground)
        .overlay(
            RoundedRectangle(cornerRadius: RidgitsRadius.lg)
                .stroke(RidgitsColors.ctaBlack, lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.lg))
    }

    private func pricingCard(
        title: String,
        price: String,
        subtitle: String,
        highlighted: Bool,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(RidgitsTypography.label(14))
                    .foregroundStyle(RidgitsColors.textHeadline)
                Spacer()
                Text(price)
                    .font(RidgitsTypography.headline(18))
                    .foregroundStyle(RidgitsColors.textHeadline)
            }
            Text(subtitle)
                .font(RidgitsTypography.caption(12))
                .foregroundStyle(RidgitsColors.textSecondary)

            RidgitsSquareButton(
                title: ridgitsStore.isPurchasing ? "Processing…" : "Unlock for \(price)",
                style: highlighted ? .filled : .outlined
            ) {
                guard !ridgitsStore.isPurchasing else { return }
                action()
            }
            .disabled(ridgitsStore.isPurchasing)
        }
        .padding(16)
        .background(highlighted ? RidgitsColors.feedBackground : RidgitsColors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: RidgitsRadius.lg)
                .stroke(highlighted ? RidgitsColors.ctaBlack : RidgitsColors.dashboardBorder, lineWidth: highlighted ? 2 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.lg))
    }
}
