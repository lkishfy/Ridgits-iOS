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
    @State private var showPostPurchaseIdentityVerification = false
    @State private var showManageSubscriptionSheet = false

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

                    if let message = ridgitsStore.restoreStatusMessage {
                        Text(message)
                            .font(RidgitsTypography.caption(12))
                            .foregroundStyle(RidgitsColors.textSecondary)
                    }

                    Button {
                        Task { await ridgitsStore.restorePurchases() }
                    } label: {
                        HStack(spacing: 8) {
                            if ridgitsStore.isRestoring {
                                ProgressView()
                                    .controlSize(.small)
                            }
                            Text(ridgitsStore.isRestoring ? "Restoring…" : "Restore purchases")
                        }
                    }
                    .font(RidgitsTypography.body(13))
                    .foregroundStyle(RidgitsColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .disabled(ridgitsStore.isRestoring)
                }
                .padding(.horizontal, 20)
                .padding(.top, showsDragIndicator ? 0 : 12)
                .padding(.bottom, showsDragIndicator ? 32 : 16)
                .modifier(EmbeddedTabBarBottomPadding(enabled: !showsDragIndicator))
            }
        }
        .background(RidgitsColors.feedBackground)
        .modifier(SubscriptionPaywallSheetPresentation(showsDragIndicator: showsDragIndicator))
        .task {
            await ridgitsStore.loadProducts()
            await ridgitsStore.refreshAccessInBackground()
            dismissIfSubscriptionAlreadySatisfied()
        }
        .onChange(of: ridgitsStore.membershipTier) { _, _ in
            dismissIfSubscriptionAlreadySatisfied()
        }
        .onChange(of: ridgitsStore.isMembershipActive) { _, _ in
            dismissIfSubscriptionAlreadySatisfied()
        }
        .sheet(isPresented: $showPostPurchaseIdentityVerification) {
            IdentityVerificationView(autoStart: true) { success in
                showPostPurchaseIdentityVerification = false
                Task { await ridgitsStore.refreshAccessInBackground() }
                if success {
                    dismiss()
                }
            }
            .environmentObject(ridgitsStore)
        }
        .sheet(isPresented: $showManageSubscriptionSheet) {
            ManageSubscriptionSheet()
                .environmentObject(ridgitsStore)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
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
        let canPurchase = ridgitsStore.canUpgrade(to: tier)
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
                        showManageSubscriptionSheet = true
                    }
                    .font(RidgitsTypography.label(12))
                    .foregroundStyle(RidgitsColors.textSecondary)
                    .frame(maxWidth: .infinity)
                } else if canPurchase {
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
                            guard success else { return }
                            await ridgitsStore.refreshAccessInBackground()
                            if ridgitsStore.isVerifiedForMessaging {
                                dismiss()
                            } else {
                                showPostPurchaseIdentityVerification = true
                            }
                        }
                    }
                    .disabled(ridgitsStore.isPurchasing)
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

    private func dismissIfSubscriptionAlreadySatisfied() {
        guard let highlightTier else { return }
        guard ridgitsStore.isMembershipActive else { return }
        guard ridgitsStore.membershipTier.rank >= highlightTier.rank else { return }
        dismiss()
    }
}

private struct EmbeddedTabBarBottomPadding: ViewModifier {
    let enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content.ridgitsFloatingTabBarPadding()
        } else {
            content
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

private struct ManageSubscriptionSheet: View {
    @EnvironmentObject private var ridgitsStore: RidgitsStore
    @Environment(\.dismiss) private var dismiss
    @State private var openError: String?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Manage your plan")
                    .font(RidgitsTypography.headline(22))
                    .foregroundStyle(RidgitsColors.textHeadline)

                if ridgitsStore.isMembershipActive {
                    HStack(spacing: 10) {
                        RidgitsVerifiedBadge(tier: ridgitsStore.membershipTier, size: 18)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Current plan")
                                .font(RidgitsTypography.caption(11))
                                .foregroundStyle(RidgitsColors.textMuted)
                            Text(ridgitsStore.membershipTier.displayName)
                                .font(RidgitsTypography.label(15))
                                .foregroundStyle(RidgitsColors.textHeadline)
                        }
                    }
                }

                Text("Ridgits subscriptions are billed through Apple. Change or cancel your plan in your Apple account, then return here and tap Restore purchases if Ridgits doesn't update right away.")
                    .font(RidgitsTypography.body(14))
                    .foregroundStyle(RidgitsColors.textSecondary)

                VStack(alignment: .leading, spacing: 12) {
                    instructionRow(
                        number: 1,
                        title: "Open Apple Subscriptions",
                        detail: "Use the button below to jump to your Ridgits subscription."
                    )
                    instructionRow(
                        number: 2,
                        title: "Change or cancel there",
                        detail: "Downgrades and cancellations take effect at the end of your billing period."
                    )
                    instructionRow(
                        number: 3,
                        title: "Upgrade in Ridgits",
                        detail: "To move to a higher tier, choose a plan on the previous screen instead."
                    )
                }

                if let openError {
                    Text(openError)
                        .font(RidgitsTypography.caption(12))
                        .foregroundStyle(RidgitsColors.destructive)
                }

                RidgitsSquareButton(
                    title: ridgitsStore.isOpeningSubscriptionManagement
                        ? "Opening…"
                        : "Open Apple Subscriptions",
                    style: .filled
                ) {
                    Task {
                        openError = nil
                        let opened = await ridgitsStore.openSubscriptionManagement()
                        if opened {
                            dismiss()
                        } else {
                            openError = ridgitsStore.purchaseError
                        }
                    }
                }
                .disabled(ridgitsStore.isOpeningSubscriptionManagement)

                Button("Done") { dismiss() }
                    .font(RidgitsTypography.label(13))
                    .foregroundStyle(RidgitsColors.textSecondary)
                    .frame(maxWidth: .infinity)
            }
            .padding(20)
        }
        .background(RidgitsColors.feedBackground)
    }

    private func instructionRow(number: Int, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(RidgitsTypography.label(12))
                .foregroundStyle(RidgitsColors.textHeadline)
                .frame(width: 24, height: 24)
                .background(RidgitsColors.hoverSurface)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(RidgitsTypography.label(14))
                    .foregroundStyle(RidgitsColors.textHeadline)
                Text(detail)
                    .font(RidgitsTypography.caption(12))
                    .foregroundStyle(RidgitsColors.textSecondary)
            }
        }
    }
}
