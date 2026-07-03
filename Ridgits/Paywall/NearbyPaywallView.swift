import SwiftUI
import StoreKit

struct NearbyPaywallView: View {
    @EnvironmentObject private var ridgitsStore: RidgitsStore
    @Environment(\.dismiss) private var dismiss

    var nearbyCount: Int = 0
    var radiusMiles: Int = 25

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(paywallTitle)
                            .font(RidgitsTypography.display(28))
                            .foregroundStyle(RidgitsColors.textHeadline)
                        Text(paywallSubtitle)
                            .font(RidgitsTypography.body())
                            .foregroundStyle(RidgitsColors.textSecondary)
                    }

                    if nearbyCount > 0 {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(hex: 0x059669))
                                .frame(width: 8, height: 8)
                            Text("\(nearbyCount) \(nearbyCount == 1 ? "person" : "people") within \(radiusMiles) miles")
                                .font(RidgitsTypography.body(14))
                                .foregroundStyle(Color(hex: 0x166534))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(hex: 0xF0FDF4))
                        .overlay(
                            Capsule().stroke(Color(hex: 0x86EFAC), lineWidth: 1)
                        )
                        .clipShape(Capsule())
                    }

                    RidgitsCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Yearly nearby access")
                                        .font(RidgitsTypography.headline())
                                    Text("\(ridgitsStore.yearlyPriceLine) for 12 months")
                                        .font(RidgitsTypography.body(14))
                                        .foregroundStyle(RidgitsColors.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(RidgitsColors.ctaBlack)
                            }
                            Divider()
                            featureRow("Browse compatible people in your radius")
                            featureRow("Filter by compatibility dimensions")
                            featureRow("Message matches — 24h / 16 message limit")
                        }
                    }

                    RidgitsPrimaryButton(
                        title: "Unlock for \(ridgitsStore.yearlyPriceLine)",
                        isLoading: ridgitsStore.isPurchasing
                    ) {
                        Task {
                            let success = await ridgitsStore.purchaseYearly()
                            if success { dismiss() }
                        }
                    }

                    Button("Restore purchases") {
                        Task { await ridgitsStore.restorePurchases() }
                    }
                    .font(RidgitsTypography.body(14))
                    .foregroundStyle(RidgitsColors.textSecondary)
                    .frame(maxWidth: .infinity)

                    if let error = ridgitsStore.purchaseError {
                        Text(error)
                            .font(RidgitsTypography.caption())
                            .foregroundStyle(RidgitsColors.destructive)
                    }

                    Text("Payment is processed by Apple. Already subscribed on ridgits.com? Sign in with the same account — your access carries over.")
                        .font(RidgitsTypography.caption())
                        .foregroundStyle(RidgitsColors.textMuted)
                }
                .padding(20)
            }
            .background(RidgitsColors.feedBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .task { await ridgitsStore.loadProducts() }
        }
    }

    private var paywallTitle: String {
        nearbyCount > 0 ? "People are near you" : "See people near you"
    }

    private var paywallSubtitle: String {
        if nearbyCount > 0 {
            return "Unlock local matches for one year and connect with compatible people close to you."
        }
        return "Unlock local matches for one year. Nationwide preview stays free."
    }

    private func featureRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            Text(text)
                .font(RidgitsTypography.body(14))
                .foregroundStyle(RidgitsColors.textPrimary)
        }
    }
}
