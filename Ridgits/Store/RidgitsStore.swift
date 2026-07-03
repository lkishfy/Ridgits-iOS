import Foundation
import StoreKit
import UIKit
import FirebaseAuth

struct RidgitsAccess {
    var hasNearbyAccess: Bool = false
    var activeProductId: String?
    var expirationDate: Date?
    var subscriptionSource: String?
    var subscriptionTier: String?
    var subscriptionBillingPeriod: String?
    var isSubscribed: Bool = false
    var isLoading: Bool = true

    var membershipTier: RidgitsSubscriptionTier {
        RidgitsSubscriptionTier.from(stored: subscriptionTier)
    }
}

@MainActor
final class RidgitsStore: ObservableObject {
    @Published private(set) var access = RidgitsAccess()
    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var isPurchasing = false
    @Published var purchaseError: String?

    var hasNearbyAccess: Bool { access.hasNearbyAccess }
    var isLoadingAccess: Bool { access.isLoading }
    var hasWebSubscription: Bool { access.subscriptionSource == "stripe" }
    var membershipTier: RidgitsSubscriptionTier { access.membershipTier }
    var isMembershipActive: Bool { access.isSubscribed }
    /// Active Ridgits+ or higher (Premium, Ultra).
    var hasPlusMembership: Bool {
        isMembershipActive && membershipTier.rank >= RidgitsSubscriptionTier.plus.rank
    }
    var subscriptionBillingPeriod: RidgitsSubscriptionBilling? {
        guard let raw = access.subscriptionBillingPeriod else { return nil }
        return RidgitsSubscriptionBilling(rawValue: raw)
    }

    private var transactionListenerTask: Task<Void, Never>?

    init() {
        transactionListenerTask = Task { await listenForTransactions() }
    }

    deinit {
        transactionListenerTask?.cancel()
    }

    func bootstrap() async {
        access.isLoading = true
        defer { access.isLoading = false }
        await refreshAccessInBackground()
        await loadProducts()
        if !access.hasNearbyAccess {
            await linkUnprocessedEntitlements()
            await applyServerAccessIfAvailable()
        }
    }

    func refreshAccessInBackground() async {
        await refreshEntitlements()
        await applyServerAccessIfAvailable()
    }

    func reset() {
        access = RidgitsAccess(hasNearbyAccess: false, isLoading: false)
        products = []
    }

    var yearlyProduct: Product? {
        products.first { $0.id == RidgitsProductID.nearbyYearly }
    }

    var yearlyPriceLine: String {
        yearlyProduct?.displayPrice ?? "$29.99"
    }

    var plusYearlyPriceLine: String {
        subscriptionProduct(tier: .plus, billing: .yearly)?.displayPrice
            ?? RidgitsSubscriptionCatalog.fallbackPrice(tier: .plus, billing: .yearly)
    }

    var archetypeBundleProduct: Product? {
        products.first { $0.id == RidgitsProductID.archetypeBundle }
    }

    var packPriceLine: String {
        product(forPackId: "situationship")?.displayPrice ?? "$9.99"
    }

    var bundlePriceLine: String {
        archetypeBundleProduct?.displayPrice ?? "$50"
    }

    func product(for pack: RidgitsArchetypePack) -> Product? {
        guard let productId = pack.productId else { return nil }
        return products.first { $0.id == productId }
    }

    func product(forPackId packId: String) -> Product? {
        guard let productId = RidgitsProductID.packProductId(for: packId) else { return nil }
        return products.first { $0.id == productId }
    }

    func purchaseArchetypePack(_ pack: RidgitsArchetypePack) async -> Bool {
        guard let product = product(for: pack) else {
            purchaseError = "This pack is unavailable right now. Try again shortly."
            return false
        }
        return await purchase(product: product)
    }

    func subscriptionProduct(
        tier: RidgitsSubscriptionTier,
        billing: RidgitsSubscriptionBilling,
        ultraYearlyVariant: RidgitsSubscriptionCatalog.UltraYearlyVariant = .standard
    ) -> Product? {
        guard let productId = RidgitsSubscriptionCatalog.productId(
            tier: tier,
            billing: billing,
            ultraYearlyVariant: ultraYearlyVariant
        ) else { return nil }
        return products.first { $0.id == productId }
    }

    func priceLine(
        tier: RidgitsSubscriptionTier,
        billing: RidgitsSubscriptionBilling,
        ultraYearlyVariant: RidgitsSubscriptionCatalog.UltraYearlyVariant = .standard
    ) -> String {
        subscriptionProduct(tier: tier, billing: billing, ultraYearlyVariant: ultraYearlyVariant)?.displayPrice
            ?? RidgitsSubscriptionCatalog.fallbackPrice(
                tier: tier,
                billing: billing,
                ultraYearlyVariant: ultraYearlyVariant
            )
    }

    /// Two Ultra yearly SKUs exist for legacy pricing; only show a picker when both load with different prices.
    func shouldShowUltraYearlyVariantPicker(isCurrentPlan: Bool) -> Bool {
        guard !isCurrentPlan else { return false }
        guard
            subscriptionProduct(tier: .ultra, billing: .yearly, ultraYearlyVariant: .standard) != nil,
            subscriptionProduct(tier: .ultra, billing: .yearly, ultraYearlyVariant: .premium) != nil
        else { return false }
        let standardPrice = priceLine(tier: .ultra, billing: .yearly, ultraYearlyVariant: .standard)
        let premiumPrice = priceLine(tier: .ultra, billing: .yearly, ultraYearlyVariant: .premium)
        return standardPrice != premiumPrice
    }

    func canUpgrade(to tier: RidgitsSubscriptionTier) -> Bool {
        RidgitsSubscriptionCatalog.canUpgrade(
            from: membershipTier,
            to: tier,
            isActive: isMembershipActive
        )
    }

    func purchaseSubscription(
        tier: RidgitsSubscriptionTier,
        billing: RidgitsSubscriptionBilling,
        ultraYearlyVariant: RidgitsSubscriptionCatalog.UltraYearlyVariant = .standard
    ) async -> Bool {
        guard canUpgrade(to: tier) else {
            purchaseError = "Downgrades aren't available in the app. Cancel your current plan in Apple Subscriptions, then resubscribe after it expires."
            return false
        }
        guard membershipTier != tier || !isMembershipActive else {
            purchaseError = "You're already on this plan."
            return false
        }
        guard let product = subscriptionProduct(
            tier: tier,
            billing: billing,
            ultraYearlyVariant: ultraYearlyVariant
        ) else {
            purchaseError = "This plan isn't available right now. Try again shortly."
            return false
        }
        return await purchase(product: product)
    }

    func showManageSubscriptions() async {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        try? await AppStore.showManageSubscriptions(in: scene)
    }

    func purchaseArchetypeBundle() async -> Bool {
        guard let product = archetypeBundleProduct else {
            purchaseError = "Bundle unavailable right now. Try again shortly."
            return false
        }
        return await purchase(product: product)
    }

    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            products = try await Product.products(for: RidgitsProductID.all)
        } catch {
            products = []
        }
    }

    func refreshEntitlements() async {
        var storeKitNearbyAccess = false
        var nearbyProductId: String?
        var nearbyExpiration: Date?

        var bestTier: RidgitsSubscriptionTier = .free
        var bestBilling: RidgitsSubscriptionBilling?
        var bestExpiration: Date?
        var bestProductId: String?

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            if transaction.productID == RidgitsProductID.nearbyYearly {
                if let expiration = transaction.expirationDate {
                    if expiration > Date() {
                        storeKitNearbyAccess = true
                        nearbyProductId = transaction.productID
                        if nearbyExpiration == nil || expiration > nearbyExpiration! {
                            nearbyExpiration = expiration
                        }
                    }
                } else {
                    storeKitNearbyAccess = true
                    nearbyProductId = transaction.productID
                }
                continue
            }

            guard let tier = RidgitsSubscriptionCatalog.tier(for: transaction.productID) else { continue }
            let isActive: Bool
            if let expiration = transaction.expirationDate {
                isActive = expiration > Date()
            } else {
                isActive = true
            }
            guard isActive else { continue }

            if tier.rank > bestTier.rank {
                bestTier = tier
                bestBilling = RidgitsSubscriptionCatalog.billing(for: transaction.productID)
                bestExpiration = transaction.expirationDate
                bestProductId = transaction.productID
            }
        }

        access.hasNearbyAccess = false
        access.isSubscribed = false
        access.activeProductId = nil
        access.expirationDate = nil

        if storeKitNearbyAccess {
            access.hasNearbyAccess = true
            access.activeProductId = nearbyProductId
            access.expirationDate = nearbyExpiration
            access.subscriptionSource = "app_store"
        }

        if bestTier != .free {
            access.isSubscribed = true
            access.hasNearbyAccess = true
            access.subscriptionTier = bestTier.rawValue
            access.subscriptionBillingPeriod = bestBilling?.rawValue
            access.activeProductId = bestProductId
            access.expirationDate = bestExpiration ?? access.expirationDate
            access.subscriptionSource = "app_store"
        }
    }

    func purchaseYearly() async -> Bool {
        guard let product = yearlyProduct else {
            purchaseError = "Product unavailable. Try again shortly."
            return false
        }
        return await purchase(product: product)
    }

    func purchase(product: Product) async -> Bool {
        guard !isPurchasing else { return false }
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }

        guard Auth.auth().currentUser != nil else {
            purchaseError = "Sign in to purchase."
            return false
        }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    purchaseError = "Purchase could not be verified."
                    return false
                }
                let linked = await linkTransaction(verification)
                await transaction.finish()
                await refreshEntitlements()
                if linked {
                    if transaction.productID == RidgitsProductID.nearbyYearly {
                        await applyServerAccessIfAvailable()
                    } else if RidgitsSubscriptionCatalog.tier(for: transaction.productID) != nil {
                        await applyServerAccessIfAvailable()
                    }
                }
                return linked
            case .userCancelled:
                return false
            case .pending:
                purchaseError = "Purchase pending approval."
                return false
            @unknown default:
                return false
            }
        } catch {
            purchaseError = error.localizedDescription
            return false
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            await linkUnprocessedEntitlements()
            await applyServerAccessIfAvailable()
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    private func applyServerAccessIfAvailable() async {
        guard Auth.auth().currentUser != nil else { return }
        do {
            let account = try await RidgitsAPIClient.shared.fetchAccountAccess()
            access.hasNearbyAccess = account.hasNearbyAccess

            if let expires = account.subscriptionExpiresAt {
                access.expirationDate = ISO8601DateFormatter().date(from: expires)
            }
            if let source = account.subscriptionSource {
                access.subscriptionSource = source
            }

            if account.hasNearbyAccess {
                if let tier = account.subscriptionTier {
                    access.subscriptionTier = tier
                    if tier != "free", tier != "nearby_yearly" {
                        access.isSubscribed = true
                    }
                }
            } else {
                access.isSubscribed = false
                access.subscriptionTier = "free"
            }
        } catch {
            // Keep StoreKit entitlements if the API is unreachable.
        }
    }

    private func linkUnprocessedEntitlements() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified = result else { continue }
            _ = await linkTransaction(result)
        }
    }

    private func linkTransaction(_ result: VerificationResult<Transaction>) async -> Bool {
        guard case .verified(let transaction) = result else { return false }
        let signed = result.jwsRepresentation
        do {
            let response = try await RidgitsAPIClient.shared.linkPurchase(
                transactionId: String(transaction.id),
                productId: transaction.productID,
                signedTransactionInfo: signed
            )
            return response.linked
        } catch {
            return RidgitsProductID.all.contains(transaction.productID)
        }
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            guard case .verified(let transaction) = result else { continue }
            _ = await linkTransaction(result)
            await transaction.finish()
            await refreshEntitlements()
            await applyServerAccessIfAvailable()
        }
    }
}
