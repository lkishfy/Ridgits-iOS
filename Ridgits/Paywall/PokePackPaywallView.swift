import SwiftUI
import StoreKit

struct PokePackOption: Identifiable {
    let id: String
    let credits: Int
    let badge: String?

    static let catalog: [PokePackOption] = [
        PokePackOption(id: RidgitsProductID.pokes5Pack, credits: 5, badge: nil),
        PokePackOption(id: RidgitsProductID.pokes10Pack, credits: 10, badge: "Popular"),
        PokePackOption(id: RidgitsProductID.pokes25Pack, credits: 25, badge: "Best value"),
    ]
}

struct PokePackPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var ridgitsStore: RidgitsStore

    @State private var showSubscriptionPaywall = false

    var onPurchaseComplete: (() -> Void)?

    private var canPurchasePokePacks: Bool {
        ridgitsStore.hasNearbyAccess
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    if canPurchasePokePacks {
                        ForEach(PokePackOption.catalog) { option in
                            packRow(option)
                        }
                    } else {
                        subscriptionRequiredCard
                    }

                    if let error = ridgitsStore.purchaseError {
                        Text(error)
                            .font(RidgitsTypography.caption(12))
                            .foregroundStyle(RidgitsColors.destructive)
                    }

                    Text(footerNote)
                        .font(RidgitsTypography.caption(11))
                        .foregroundStyle(RidgitsColors.textMuted)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .background(RidgitsColors.feedBackground)
            .navigationTitle("Get poke credits")
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
        .task {
            await ridgitsStore.loadProducts()
            await ridgitsStore.refreshAccessInBackground()
        }
        .sheet(isPresented: $showSubscriptionPaywall) {
            SubscriptionPaywallView(
                highlightTier: .plus,
                headline: "Subscribe to buy pokes",
                subheadline: "Ridgits+ members can purchase extra poke credits."
            )
            .environmentObject(ridgitsStore)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Say hi without the pressure of a message")
                .font(RidgitsTypography.headline(22))
                .foregroundStyle(RidgitsColors.textHeadline)
            Text(
                canPurchasePokePacks
                    ? "Each poke uses one credit. New accounts start with a few free pokes."
                    : "Subscribe to Ridgits+ to unlock poke pack purchases."
            )
            .font(RidgitsTypography.body(14))
            .foregroundStyle(RidgitsColors.textSecondary)
        }
    }

    private var footerNote: String {
        canPurchasePokePacks
            ? "Poke credits are used when you tap Poke on a match."
            : "Free starter pokes are included for new accounts. Extra packs require Ridgits+."
    }

    private var subscriptionRequiredCard: some View {
        RidgitsDashboardCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Ridgits+ required")
                    .font(RidgitsTypography.label(14))
                    .foregroundStyle(RidgitsColors.textHeadline)
                Text("Poke packs are available to Ridgits+ members. Subscribe first, then come back to buy more credits.")
                    .font(RidgitsTypography.caption(12))
                    .foregroundStyle(RidgitsColors.textSecondary)
                RidgitsSquareButton(title: "Subscribe to Ridgits+", style: .filled) {
                    showSubscriptionPaywall = true
                }
            }
            .padding(16)
        }
    }

    private func packRow(_ option: PokePackOption) -> some View {
        let product = ridgitsStore.pokePackProduct(id: option.id)
        let price = product?.displayPrice ?? fallbackPrice(for: option.credits)

        return Button {
            guard canPurchasePokePacks else {
                showSubscriptionPaywall = true
                return
            }
            guard let product else {
                ridgitsStore.purchaseError = "Product unavailable. Try again shortly."
                return
            }
            Task {
                let success = await ridgitsStore.purchase(product: product)
                if success {
                    onPurchaseComplete?()
                    dismiss()
                }
            }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("\(option.credits) pokes")
                            .font(RidgitsTypography.headline(17))
                            .foregroundStyle(RidgitsColors.textHeadline)
                        if let badge = option.badge {
                            Text(badge)
                                .font(RidgitsTypography.caption(10))
                                .fontWeight(.semibold)
                                .foregroundStyle(Color(hex: 0x15803D))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color(hex: 0xDCFCE7))
                                .clipShape(Capsule())
                        }
                    }
                    Text("One-time purchase · consumable")
                        .font(RidgitsTypography.caption(12))
                        .foregroundStyle(RidgitsColors.textSecondary)
                }

                Spacer(minLength: 0)

                Text(price)
                    .font(RidgitsTypography.body(16))
                    .fontWeight(.semibold)
                    .foregroundStyle(RidgitsColors.textHeadline)
            }
            .padding(16)
            .background(RidgitsColors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: RidgitsRadius.lg)
                    .stroke(RidgitsColors.dashboardBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: RidgitsRadius.lg))
        }
        .buttonStyle(RidgitsHapticPlainButtonStyle())
        .disabled(ridgitsStore.isPurchasing)
    }

    private func fallbackPrice(for credits: Int) -> String {
        switch credits {
        case 5: return "$5.00"
        case 10: return "$7.99"
        case 25: return "$19.99"
        default: return "$—"
        }
    }
}
