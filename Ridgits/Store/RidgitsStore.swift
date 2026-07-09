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
    var identityVerificationStatus: String = "none"
    var phoneVerificationStatus: String = "none"
    var profilePhotoIdentityMatchStatus: String = "none"
    var canSubscribe: Bool = false
    var canMessage: Bool = false
    var skipsOnboarding: Bool = false

    var membershipTier: RidgitsSubscriptionTier {
        RidgitsSubscriptionTier.from(stored: subscriptionTier)
    }

    /// Best-known tier from Firestore string and the active StoreKit product id.
    var resolvedMembershipTier: RidgitsSubscriptionTier {
        let stored = membershipTier
        guard let productId = activeProductId,
              let productTier = RidgitsSubscriptionCatalog.tier(for: productId) else {
            return stored
        }
        return stored.rank >= productTier.rank ? stored : productTier
    }

    var hasActiveMembership: Bool {
        if isSubscribed && resolvedMembershipTier.rank > 0 { return true }
        return hasNearbyAccess && resolvedMembershipTier.rank >= RidgitsSubscriptionTier.plus.rank
    }

    var isIdentityVerified: Bool {
        identityVerificationStatus == "verified"
    }

    var isPhoneVerified: Bool {
        phoneVerificationStatus == "verified"
    }

    var isProfilePhotoVerified: Bool {
        profilePhotoIdentityMatchStatus == "verified"
    }

    var isFullyIdentityVerified: Bool {
        isIdentityVerified && isPhoneVerified
    }

    var isReviewBypassAccount: Bool {
        skipsOnboarding
    }
}

@MainActor
final class RidgitsStore: ObservableObject {
    @Published private(set) var access = RidgitsAccess()
    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var isPurchasing = false
    @Published private(set) var isRestoring = false
    @Published private(set) var isOpeningSubscriptionManagement = false
    @Published var purchaseError: String?
    @Published var restoreStatusMessage: String?

    var hasNearbyAccess: Bool { access.hasNearbyAccess }
    var isLoadingAccess: Bool { access.isLoading }
    var hasWebSubscription: Bool { access.subscriptionSource == "stripe" }
    var membershipTier: RidgitsSubscriptionTier { access.resolvedMembershipTier }
    var isMembershipActive: Bool { access.hasActiveMembership }
    /// Active Ridgits+ or higher (Premium, Ultra).
    var hasPlusMembership: Bool {
        isMembershipActive && membershipTier.rank >= RidgitsSubscriptionTier.plus.rank
    }
    /// App Review / QA bypass from `RIDGITS_BYPASS_EMAILS` on ridgits-api.
    var skipsOnboarding: Bool { access.skipsOnboarding }
    /// ID, phone, and profile photo verified — required to message.
    var isVerifiedForMessaging: Bool {
        access.isReviewBypassAccount || access.canMessage
    }

    var needsProfilePhotoMatchForMessaging: Bool {
        !access.isReviewBypassAccount
            && access.isFullyIdentityVerified
            && !access.isProfilePhotoVerified
    }

    @Published private(set) var isRetryingProfilePhotoMatch = false
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
    }

    func refreshAccessInBackground() async {
        await refreshEntitlements()
        await linkUnprocessedEntitlements()
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

    func pokePackProduct(id: String) -> Product? {
        products.first { $0.id == id }
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

    /// Legacy dual Ultra yearly SKUs — hidden while only `Ultra` is sold in App Store Connect.
    func shouldShowUltraYearlyVariantPicker(isCurrentPlan: Bool) -> Bool {
        false
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
        guard RidgitsSubscriptionCatalog.offersMonthlySubscriptions || billing == .yearly else {
            purchaseError = "Only yearly plans are available in the app right now."
            return false
        }
        guard canUpgrade(to: tier) else {
            purchaseError = "Downgrades aren't available in the app. Cancel your current plan in Apple Subscriptions, then resubscribe after it expires."
            return false
        }
        await refreshAccessInBackground()
        if membershipTier.rank >= tier.rank && isMembershipActive {
            purchaseError = "You're already on \(membershipTier.displayName)."
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

    func resumePendingSubscriptionPurchaseIfNeeded() async -> Bool {
        false
    }

    /// Opens Stripe Identity after a successful subscription purchase when still unverified.
    func promptIdentityVerificationIfNeeded() async -> Bool {
        await refreshAccessInBackground()
        if isVerifiedForMessaging {
            return true
        }
        // Status check syncs from Stripe — skip the browser flow if already verified there.
        do {
            let status = try await RidgitsAPIClient.shared.fetchIdentityStatus()
            if status.isFullyVerifiedForSubscribe && status.isProfilePhotoMatched {
                await refreshAccessInBackground()
                return true
            }
        } catch {
            purchaseError = error.localizedDescription
            return false
        }
        let verified = await IdentityVerificationCoordinator.shared.runVerificationFlow()
        if verified {
            await refreshAccessInBackground()
        }
        return verified
    }

    /// Re-runs profile photo ↔ ID selfie comparison without changing the photo.
    func retryProfilePhotoIdentityMatch() async -> String? {
        isRetryingProfilePhotoMatch = true
        defer { isRetryingProfilePhotoMatch = false }

        do {
            let result = try await RidgitsAPIClient.shared.matchProfilePhotoToIdentity()
            await refreshAccessInBackground()
            if result.isVerified {
                return nil
            }
            return result.userFacingFailureMessage
                ?? RidgitsProfilePhotoIdentityMatch.fallbackMismatchMessage(
                    score: result.score,
                    threshold: result.threshold
                )
        } catch let error as RidgitsError {
            await refreshAccessInBackground()
            return RidgitsProfilePhotoIdentityMatch.userFacingMessage(
                for: error.code ?? "",
                fallback: error.localizedDescription
            ) ?? error.localizedDescription
        } catch {
            return error.localizedDescription
        }
    }

    /// Opens Apple's subscription management page (Settings / App Store). Prefer this over
    /// `AppStore.showManageSubscriptions`, which often shows a blank sheet with "Cannot connect".
    @discardableResult
    func openSubscriptionManagement() async -> Bool {
        isOpeningSubscriptionManagement = true
        defer { isOpeningSubscriptionManagement = false }

        let candidates = [
            URL(string: "itms-apps://apps.apple.com/account/subscriptions"),
            URL(string: "https://apps.apple.com/account/subscriptions"),
        ].compactMap { $0 }

        for url in candidates {
            if await openExternalURL(url) {
                return true
            }
        }

        purchaseError = "Open Settings → your name → Subscriptions to manage your Ridgits plan."
        return false
    }

    /// Legacy entry point — routes to `openSubscriptionManagement()`.
    func showManageSubscriptions() async {
        _ = await openSubscriptionManagement()
    }

    @MainActor
    private func openExternalURL(_ url: URL) async -> Bool {
        await withCheckedContinuation { continuation in
            UIApplication.shared.open(url, options: [:]) { success in
                continuation.resume(returning: success)
            }
        }
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

        await applySubscriptionGroupStatus()
        // When StoreKit has no active membership, keep existing access until the server
        // confirms in `applyServerAccessIfAvailable` — avoids flashing free tier on refresh.
    }

    /// Reads the subscription group status so pending upgrades (autoRenewPreference) match Apple.
    private func applySubscriptionGroupStatus() async {
        guard let statuses = try? await Product.SubscriptionInfo.status(
            for: RidgitsSubscriptionCatalog.appStoreSubscriptionGroupId
        ) else { return }

        var entitledTier: RidgitsSubscriptionTier = .free
        var entitledProductId: String?
        var renewalTier: RidgitsSubscriptionTier = .free
        var renewalProductId: String?
        var renewalJWS: String?
        var bestExpiration = access.expirationDate

        for status in statuses {
            switch status.state {
            case .subscribed, .inGracePeriod, .inBillingRetryPeriod:
                break
            default:
                continue
            }

            guard case .verified(let transaction) = status.transaction,
                  let transactionTier = RidgitsSubscriptionCatalog.tier(for: transaction.productID) else {
                continue
            }

            if transactionTier.rank > entitledTier.rank {
                entitledTier = transactionTier
                entitledProductId = transaction.productID
                if let expiration = transaction.expirationDate {
                    if bestExpiration == nil || expiration > bestExpiration! {
                        bestExpiration = expiration
                    }
                }
            }

            guard case .verified(let renewalInfo) = status.renewalInfo,
                  renewalInfo.willAutoRenew,
                  let nextProductId = renewalInfo.autoRenewPreference,
                  let nextTier = RidgitsSubscriptionCatalog.tier(for: nextProductId) else {
                continue
            }

            if nextTier.rank > renewalTier.rank {
                renewalTier = nextTier
                renewalProductId = nextProductId
                renewalJWS = status.renewalInfo.jwsRepresentation
            }
        }

        let scannedTier = access.resolvedMembershipTier
        var effectiveTier = scannedTier
        var effectiveProductId = access.activeProductId

        if renewalTier.rank > entitledTier.rank {
            effectiveTier = renewalTier
            effectiveProductId = renewalProductId ?? entitledProductId
        } else if entitledTier.rank > effectiveTier.rank {
            effectiveTier = entitledTier
            effectiveProductId = entitledProductId
        }

        if effectiveTier != .free {
            access.isSubscribed = true
            access.hasNearbyAccess = true
            access.subscriptionTier = effectiveTier.rawValue
            if let effectiveProductId {
                access.activeProductId = effectiveProductId
            }
            if let billing = effectiveProductId.flatMap(RidgitsSubscriptionCatalog.billing(for:)) {
                access.subscriptionBillingPeriod = billing.rawValue
            }
            access.expirationDate = bestExpiration ?? access.expirationDate
            access.subscriptionSource = "app_store"
        }

        if renewalTier.rank > entitledTier.rank, let renewalProductId {
            _ = try? await RidgitsAPIClient.shared.syncRenewalPreference(
                renewalProductId: renewalProductId,
                signedRenewalInfo: renewalJWS
            )
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

        guard await assertProfileCompleteForPurchase() else { return false }

        if RidgitsProductID.allPokePackProductIds.contains(product.id), !hasNearbyAccess {
            purchaseError = "Subscribe to Ridgits+ to buy poke packs."
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
                var linked = await linkTransaction(verification)
                if !linked {
                    await refreshEntitlements()
                    linked = await linkTransaction(verification)
                }
                if linked {
                    await transaction.finish()
                    RidgitsHaptics.play(.success)
                } else {
                    purchaseError = purchaseError
                        ?? "Payment received, but Ridgits couldn't activate your plan yet. Tap Restore purchases in a moment to retry."
                }
                await refreshAccessInBackground()
                return linked || hasPlusMembership
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

    /// Whether an active subscriber still needs Stripe Identity (ID + phone + selfie).
    var needsIdentityVerificationAfterSubscription: Bool {
        isMembershipActive && !isVerifiedForMessaging
    }

    /// Restores App Store purchases. Returns `true` when subscription is active but identity
    /// verification still needs to run (same follow-up as after a fresh purchase).
    @discardableResult
    func restorePurchases() async -> Bool {
        guard !isRestoring else { return false }
        isRestoring = true
        purchaseError = nil
        restoreStatusMessage = nil
        defer { isRestoring = false }

        let tierBefore = membershipTier

        do {
            try await AppStore.sync()
            try? await Task.sleep(nanoseconds: 500_000_000)
            await refreshEntitlements()
            await linkUnprocessedEntitlements(restoring: true)
            await applyServerAccessIfAvailable()

            if membershipTier.rank > tierBefore.rank {
                restoreStatusMessage = "Restored \(membershipTier.displayName)."
                RidgitsHaptics.play(.success)
            } else if isMembershipActive {
                restoreStatusMessage = "Your \(membershipTier.displayName) plan is active."
                RidgitsHaptics.play(.success)
            } else {
                restoreStatusMessage = "No active subscriptions found for this Apple ID."
            }
            return needsIdentityVerificationAfterSubscription
        } catch {
            purchaseError = error.localizedDescription
            return false
        }
    }

    private func applyServerAccessIfAvailable() async {
        guard Auth.auth().currentUser != nil else { return }
        let storeKitTier = access.resolvedMembershipTier
        let storeKitSubscribed = access.hasActiveMembership
        do {
            let account = try await RidgitsAPIClient.shared.fetchAccountAccess()
            access.hasNearbyAccess = account.hasNearbyAccess

            if let expires = account.subscriptionExpiresAt {
                access.expirationDate = ISO8601DateFormatter().date(from: expires)
            }
            if let source = account.subscriptionSource {
                access.subscriptionSource = source
            }

            let serverTier = RidgitsSubscriptionTier.from(stored: account.subscriptionTier)
            let mergedTier: RidgitsSubscriptionTier
            if account.hasNearbyAccess || storeKitSubscribed {
                mergedTier = storeKitTier.rank >= serverTier.rank ? storeKitTier : serverTier
                access.subscriptionTier = mergedTier.rawValue
                access.isSubscribed = mergedTier != .free
                access.hasNearbyAccess = true
            } else if storeKitSubscribed && storeKitTier.rank > 0 {
                // StoreKit shows an upgrade the server hasn't linked yet.
                mergedTier = storeKitTier
                access.subscriptionTier = mergedTier.rawValue
                access.isSubscribed = true
                access.hasNearbyAccess = true
            } else {
                mergedTier = .free
                access.isSubscribed = false
                access.subscriptionTier = "free"
            }

            if let identityStatus = account.identityVerificationStatus {
                access.identityVerificationStatus = identityStatus
            }
            if let phoneStatus = account.phoneVerificationStatus {
                access.phoneVerificationStatus = phoneStatus
            }
            if let matchStatus = account.profilePhotoIdentityMatchStatus {
                access.profilePhotoIdentityMatchStatus = matchStatus
            }
            access.canSubscribe = account.canSubscribe ?? access.isFullyIdentityVerified
            access.canMessage = account.canMessage ?? false
            access.skipsOnboarding = account.skipOnboarding ?? false
        } catch {
            // Keep StoreKit entitlements if the API is unreachable.
        }
    }

    private func linkUnprocessedEntitlements(restoring: Bool = false) async {
        var candidates: [(VerificationResult<Transaction>, Int)] = []
        var seenTransactionIds = Set<UInt64>()

        func consider(_ result: VerificationResult<Transaction>) {
            guard case .verified(let transaction) = result else { return }
            guard seenTransactionIds.insert(transaction.id).inserted else { return }
            guard isActiveSubscriptionTransaction(transaction) else { return }

            let rank: Int
            if let tier = RidgitsSubscriptionCatalog.tier(for: transaction.productID) {
                rank = tier.rank
            } else if transaction.productID == RidgitsProductID.nearbyYearly {
                rank = 0
            } else {
                return
            }
            candidates.append((result, rank))
        }

        for await result in Transaction.currentEntitlements {
            consider(result)
        }

        if restoring {
            for await result in Transaction.all {
                consider(result)
            }
        }

        candidates.sort { $0.1 < $1.1 }
        for (result, _) in candidates {
            _ = await linkTransaction(result, restoring: restoring)
        }
    }

    private func isActiveSubscriptionTransaction(_ transaction: Transaction) -> Bool {
        if let expiration = transaction.expirationDate {
            return expiration > Date()
        }
        return true
    }

    private func linkTransaction(_ result: VerificationResult<Transaction>, restoring: Bool = false) async -> Bool {
        guard case .verified(let transaction) = result else { return false }
        let signed = result.jwsRepresentation
        do {
            let response = try await RidgitsAPIClient.shared.linkPurchase(
                transactionId: String(transaction.id),
                productId: transaction.productID,
                signedTransactionInfo: signed,
                restoring: restoring
            )
            return response.linked
        } catch {
            if let ridgitsError = error as? RidgitsError, let code = ridgitsError.code {
                purchaseError = ridgitsError.localizedDescription
                if code == "SUBSCRIPTION_REQUIRED" || code == "PROFILE_INCOMPLETE" {
                    return false
                }
            } else {
                purchaseError = (error as? RidgitsError)?.localizedDescription
                    ?? error.localizedDescription
            }
            return false
        }
    }

    private func assertProfileCompleteForPurchase() async -> Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }

        let profile: RidgitsUserProfile?
        if let cached = RidgitsProfileCache.shared.profile(for: uid) {
            profile = cached
        } else {
            profile = try? await RidgitsFirebaseClient.shared.fetchUserProfile(uid: uid)
        }

        guard let profile, profile.isCompleteForMatching else {
            purchaseError = "Complete your profile (photo, bio, interests, and location) before purchasing."
            return false
        }
        return true
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            guard case .verified(let transaction) = result else { continue }
            let linked = await linkTransaction(result)
            if linked {
                await transaction.finish()
            }
            await refreshAccessInBackground()
        }
    }
}
