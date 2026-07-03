import Foundation
import StoreKit
import FirebaseAuth

struct RidgitsAccess {
    var hasNearbyAccess: Bool = false
    var activeProductId: String?
    var expirationDate: Date?
    var subscriptionSource: String?
    var subscriptionTier: String?
    var isLoading: Bool = true
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
        await refreshEntitlements()
        await applyServerAccessIfAvailable()
        await loadProducts()
        if !access.hasNearbyAccess {
            await linkUnprocessedEntitlements()
            await applyServerAccessIfAvailable()
        }
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
        var storeKitAccess = false
        var activeProductId: String?
        var latestExpiration: Date?

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard transaction.productID == RidgitsProductID.nearbyYearly else { continue }

            if let expiration = transaction.expirationDate {
                if expiration > Date() {
                    storeKitAccess = true
                    activeProductId = transaction.productID
                    if latestExpiration == nil || expiration > latestExpiration! {
                        latestExpiration = expiration
                    }
                }
            } else {
                storeKitAccess = true
                activeProductId = transaction.productID
            }
        }

        if storeKitAccess {
            access.hasNearbyAccess = true
            access.activeProductId = activeProductId
            access.expirationDate = latestExpiration
            if access.subscriptionSource == nil {
                access.subscriptionSource = "app_store"
            }
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
                    await applyServerAccessIfAvailable()
                }
                return access.hasNearbyAccess
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
            if account.hasNearbyAccess {
                access.hasNearbyAccess = true
                if let expires = account.subscriptionExpiresAt {
                    access.expirationDate = ISO8601DateFormatter().date(from: expires)
                }
                access.subscriptionSource = account.subscriptionSource
                access.subscriptionTier = account.subscriptionTier
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
            return transaction.productID == RidgitsProductID.nearbyYearly
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
