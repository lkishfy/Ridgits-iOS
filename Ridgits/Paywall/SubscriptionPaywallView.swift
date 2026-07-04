import SwiftUI
import StoreKit

struct SubscriptionPaywallView: View {
    @EnvironmentObject private var ridgitsStore: RidgitsStore
    @Environment(\.dismiss) private var dismiss

    /// When set, only this tier is shown (e.g. Ridgits+ upsell from messaging or quick tools).
    var highlightTier: RidgitsSubscriptionTier?
    var headline: String?
    var subheadline: String?
    /// Custom drag handle for sheet presentations only; hidden when pushed from Profile.
    var showsDragIndicator: Bool

    @State private var ultraYearlyVariant: RidgitsSubscriptionCatalog.UltraYearlyVariant = .standard
    @State private var selectedBilling: RidgitsSubscriptionBilling = .yearly

    private let tiers: [RidgitsSubscriptionTier] = [.plus, .premium, .ultra]
    private var billing: RidgitsSubscriptionBilling { .yearly }

    private var displayedTiers: [RidgitsSubscriptionTier] {
        if let highlightTier { return [highlightTier] }
        return tiers
    }

    init(
        preferredBilling _: RidgitsSubscriptionBilling = .yearly,
        highlightTier: RidgitsSubscriptionTier? = nil,
        headline: String? = nil,
        subheadline: String? = nil,
        showsDragIndicator: Bool = true
    ) {
        self.highlightTier = highlightTier
        self.headline = headline
        self.subheadline = subheadline
        self.showsDragIndicator = showsDragIndicator
    }

    var body: some View {
        VStack(spacing: 0) {
            if showsDragIndicator {
                sheetDragIndicator
            }

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    if RidgitsSubscriptionCatalog.offersMonthlySubscriptions {
                        billingToggle
                    }

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
                }
                .padding(.horizontal, 20)
                .padding(.top, showsDragIndicator ? 0 : 12)
                .padding(.bottom, 32)
            }
        }
        .background(RidgitsColors.feedBackground)
        .modifier(SubscriptionPaywallSheetPresentation(showsDragIndicator: showsDragIndicator))
        .task { await ridgitsStore.loadProducts() }
        .sheet(isPresented: $ridgitsStore.showIdentityVerification) {
            IdentityVerificationView { success in
                ridgitsStore.completeIdentityVerificationFlow(success: success)
            }
        }
    }

    private var sheetDragIndicator: some View {
        Capsule()
            .fill(RidgitsColors.textMuted.opacity(0.35))
            .frame(width: 36, height: 5)
            .padding(.top, 10)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(headline ?? "Choose your plan")
                .font(RidgitsTypography.headline(24))
                .foregroundStyle(RidgitsColors.textHeadline)
            if let subheadline, !subheadline.isEmpty {
                Text(subheadline)
                    .font(RidgitsTypography.body(14))
                    .foregroundStyle(RidgitsColors.textSecondary)
            } else if !RidgitsSubscriptionCatalog.offersMonthlySubscriptions {
                Text("All plans are billed yearly.")
                    .font(RidgitsTypography.body(14))
                    .foregroundStyle(RidgitsColors.textSecondary)
            }
            Text("Verify with a government ID to subscribe and message.")
                .font(RidgitsTypography.caption(12))
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
                ForEach(RidgitsSubscriptionCatalog.purchaseBillingOptions) { period in
                    Button {
                        selectedBilling = period
                    } label: {
                        Text(period.label)
                            .font(RidgitsTypography.label(12))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundStyle(selectedBilling == period ? RidgitsColors.textHeadline : RidgitsColors.textSecondary)
                            .background(selectedBilling == period ? RidgitsColors.surface : RidgitsColors.hoverSurface)
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
        let activeBilling = RidgitsSubscriptionCatalog.offersMonthlySubscriptions ? selectedBilling : billing
        let isCurrent = ridgitsStore.isMembershipActive && ridgitsStore.membershipTier == tier
        let canUpgrade = ridgitsStore.canUpgrade(to: tier)
        let resolvedUltraVariant = tier == .ultra && activeBilling == .yearly ? ultraYearlyVariant : .standard
        let price = ridgitsStore.priceLine(
            tier: tier,
            billing: activeBilling,
            ultraYearlyVariant: resolvedUltraVariant
        )
        let usesYearlyMonthlyEquivalent = activeBilling == .yearly && tier != .free
        let displayPrice = usesYearlyMonthlyEquivalent
            ? RidgitsSubscriptionCatalog.yearlyMonthlyEquivalent(
                for: tier,
                ultraYearlyVariant: resolvedUltraVariant
            )
            : price
        let priceSuffix = activeBilling == .monthly || usesYearlyMonthlyEquivalent ? "/month" : "/year"
        let yearlyTotal = activeBilling == .yearly ? price : nil
        let yearlyDiscount = activeBilling == .yearly
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
                        if activeBilling == .yearly, let yearlyTotal, usesYearlyMonthlyEquivalent {
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

                if tier == .ultra && activeBilling == .yearly && ridgitsStore.shouldShowUltraYearlyVariantPicker(isCurrentPlan: isCurrent) {
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
                                billing: activeBilling,
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

private struct SubscriptionPaywallSheetPresentation: ViewModifier {
    let showsDragIndicator: Bool

    func body(content: Content) -> some View {
        if showsDragIndicator {
            content
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        } else {
            content
        }
    }
}
