import SwiftUI
import StoreKit

struct SubscriptionPaywallView: View {
    @EnvironmentObject private var ridgitsStore: RidgitsStore
    @Environment(\.dismiss) private var dismiss

    var preferredBilling: RidgitsSubscriptionBilling = .yearly
    /// When set, only this tier is shown (e.g. Ridgits+ upsell from messaging or quick tools).
    var highlightTier: RidgitsSubscriptionTier?
    var headline: String?
    var subheadline: String?

    @State private var billing: RidgitsSubscriptionBilling
    @State private var ultraYearlyVariant: RidgitsSubscriptionCatalog.UltraYearlyVariant = .standard

    private let tiers: [RidgitsSubscriptionTier] = [.plus, .premium, .ultra]

    private var displayedTiers: [RidgitsSubscriptionTier] {
        if let highlightTier { return [highlightTier] }
        return tiers
    }

    init(
        preferredBilling: RidgitsSubscriptionBilling = .yearly,
        highlightTier: RidgitsSubscriptionTier? = nil,
        headline: String? = nil,
        subheadline: String? = nil
    ) {
        self.preferredBilling = preferredBilling
        self.highlightTier = highlightTier
        self.headline = headline
        self.subheadline = subheadline
        _billing = State(initialValue: preferredBilling)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    billingToggle

                    ForEach(displayedTiers) { tier in
                        tierCard(tier)
                    }

                    if let error = ridgitsStore.purchaseError {
                        Text(error)
                            .font(RidgitsTypography.caption(12))
                            .foregroundStyle(RidgitsColors.destructive)
                    }

                    Button("Restore purchases") {
                        Task { await ridgitsStore.restorePurchases() }
                    }
                    .font(RidgitsTypography.body(13))
                    .foregroundStyle(RidgitsColors.textSecondary)
                    .frame(maxWidth: .infinity)

                    Text("Upgrades only — cancel anytime in Apple Subscriptions. Downgrades take effect after your current period ends.")
                        .font(RidgitsTypography.caption(11))
                        .foregroundStyle(RidgitsColors.textMuted)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .padding(16)
            }
            .background(RidgitsColors.feedBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(RidgitsColors.textSecondary)
                }
            }
            .task { await ridgitsStore.loadProducts() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(headline ?? "Choose your plan")
                .font(RidgitsTypography.headline(24))
                .foregroundStyle(RidgitsColors.textHeadline)
            Text(subheadline ?? "Upgrade anytime.")
                .font(RidgitsTypography.body(14))
                .foregroundStyle(RidgitsColors.textSecondary)
        }
    }

    private var billingToggle: some View {
        let yearlyBadge = RidgitsSubscriptionCatalog.maxYearlyDiscountBadge()

        return VStack(spacing: 6) {
            if let yearlyBadge {
                HStack(spacing: 0) {
                    Color.clear
                        .frame(maxWidth: .infinity)
                    Text(yearlyBadge)
                        .font(RidgitsTypography.caption(9))
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(hex: 0x15803D))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color(hex: 0xDCFCE7))
                        .clipShape(Capsule())
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .frame(maxWidth: .infinity)
                }
            }

            HStack(spacing: 0) {
                ForEach(RidgitsSubscriptionBilling.allCases) { period in
                    Button {
                        billing = period
                    } label: {
                        Text(period.label)
                            .font(RidgitsTypography.label(12))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundStyle(billing == period ? RidgitsColors.textHeadline : RidgitsColors.textSecondary)
                            .background(billing == period ? RidgitsColors.surface : RidgitsColors.hoverSurface)
                    }
                    .buttonStyle(RidgitsHapticPlainButtonStyle())
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: RidgitsRadius.md)
                    .stroke(RidgitsColors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.md))
        }
    }

    private func tierCard(_ tier: RidgitsSubscriptionTier) -> some View {
        let isCurrent = ridgitsStore.isMembershipActive && ridgitsStore.membershipTier == tier
        let canUpgrade = ridgitsStore.canUpgrade(to: tier)
        let isSupersededByCurrentPlan = ridgitsStore.isMembershipActive && ridgitsStore.membershipTier.rank > tier.rank
        let resolvedUltraVariant = tier == .ultra && billing == .yearly ? ultraYearlyVariant : .standard
        let price = ridgitsStore.priceLine(
            tier: tier,
            billing: billing,
            ultraYearlyVariant: resolvedUltraVariant
        )
        let usesYearlyMonthlyEquivalent = billing == .yearly && tier != .free
        let displayPrice = usesYearlyMonthlyEquivalent
            ? RidgitsSubscriptionCatalog.yearlyMonthlyEquivalent(
                for: tier,
                ultraYearlyVariant: resolvedUltraVariant
            )
            : price
        let priceSuffix = billing == .monthly || usesYearlyMonthlyEquivalent ? "/month" : "/year"
        let yearlyTotal = billing == .yearly ? price : nil
        let yearlyDiscount = billing == .yearly
            ? RidgitsSubscriptionCatalog.yearlyDiscountBadge(for: tier)
            : nil

        return RidgitsDashboardCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        if let yearlyDiscount {
                            Text(yearlyDiscount)
                                .font(RidgitsTypography.caption(9))
                                .fontWeight(.semibold)
                                .foregroundStyle(Color(hex: 0x15803D))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color(hex: 0xDCFCE7))
                                .clipShape(Capsule())
                        }
                        HStack(spacing: 8) {
                            RidgitsVerifiedBadge(tier: tier, size: 18)
                            Text(tier.displayName)
                                .font(RidgitsTypography.headline(18))
                                .foregroundStyle(RidgitsColors.textHeadline)
                        }
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(displayPrice)
                                .font(RidgitsTypography.headline(22))
                            Text(priceSuffix)
                                .font(RidgitsTypography.caption(12))
                                .foregroundStyle(RidgitsColors.textSecondary)
                        }
                        if billing == .yearly, let yearlyTotal, usesYearlyMonthlyEquivalent {
                            Text("Billed \(yearlyTotal)/year")
                                .font(RidgitsTypography.caption(11))
                                .foregroundStyle(RidgitsColors.textMuted)
                        }
                    }
                    Spacer()
                    if isCurrent {
                        Text("CURRENT")
                            .font(RidgitsTypography.caption(9))
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(RidgitsColors.ctaBlack)
                            .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.sm))
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(RidgitsSubscriptionCatalog.features(for: tier)) { feature in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(RidgitsColors.textHeadline)
                                .padding(.top, 2)
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 8) {
                                    if let badgeTier = feature.badgeTier {
                                        RidgitsVerifiedBadge(tier: badgeTier, size: 16)
                                    }
                                    Text(feature.title)
                                        .font(RidgitsTypography.label(13))
                                        .foregroundStyle(RidgitsColors.textHeadline)
                                }
                                if let detail = feature.detail {
                                    Text(detail)
                                        .font(RidgitsTypography.caption(11))
                                        .foregroundStyle(RidgitsColors.textSecondary)
                                }
                            }
                        }
                    }
                }

                if tier == .ultra && billing == .yearly && ridgitsStore.shouldShowUltraYearlyVariantPicker(isCurrentPlan: isCurrent) {
                    Picker("Ultra yearly", selection: $ultraYearlyVariant) {
                        Text(ridgitsStore.priceLine(tier: .ultra, billing: .yearly, ultraYearlyVariant: .standard) + "/yr")
                            .tag(RidgitsSubscriptionCatalog.UltraYearlyVariant.standard)
                        Text(ridgitsStore.priceLine(tier: .ultra, billing: .yearly, ultraYearlyVariant: .premium) + "/yr")
                            .tag(RidgitsSubscriptionCatalog.UltraYearlyVariant.premium)
                    }
                    .pickerStyle(.segmented)
                }

                if isCurrent {
                    RidgitsSquareButton(title: "Current Plan", style: .ghost) {}
                        .disabled(true)
                    Button("Manage Plan") {
                        Task { await ridgitsStore.showManageSubscriptions() }
                    }
                    .font(RidgitsTypography.label(12))
                    .foregroundStyle(RidgitsColors.textSecondary)
                    .frame(maxWidth: .infinity)
                } else if canUpgrade {
                    RidgitsSquareButton(
                        title: buttonTitle(for: tier),
                        style: .filled
                    ) {
                        Task {
                            let success = await ridgitsStore.purchaseSubscription(
                                tier: tier,
                                billing: billing,
                                ultraYearlyVariant: ultraYearlyVariant
                            )
                            if success { dismiss() }
                        }
                    }
                    .disabled(ridgitsStore.isPurchasing)
                } else {
                    RidgitsSquareButton(title: "Included in your plan", style: .ghost) {}
                        .disabled(true)
                }
            }
            .padding(16)
            .overlay(
                RoundedRectangle(cornerRadius: RidgitsRadius.lg)
                    .stroke(isCurrent ? RidgitsColors.ctaBlack : RidgitsColors.dashboardBorder, lineWidth: isCurrent ? 2 : 1)
            )
        }
    }

    private func buttonTitle(for tier: RidgitsSubscriptionTier) -> String {
        switch tier {
        case .plus: return "Get Ridgits+"
        case .premium: return "Get Premium"
        case .ultra: return "Get Ultra"
        default: return "Subscribe"
        }
    }
}
