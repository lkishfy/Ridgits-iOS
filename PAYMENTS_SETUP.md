# Ridgits payments setup

Checklist for **Apple In-App Purchases** (iOS) and the **ridgits-api** backend that verifies and syncs entitlements to Firebase.

Web subscriptions (Stripe on ridgits.com) are separate; the iOS app reads the same Firestore `subscriptionTier` field either way.

---

## 1. App Store Connect — agreements & tax

1. Sign in to [App Store Connect](https://appstoreconnect.apple.com).
2. Complete **Paid Apps Agreement**, banking, and tax forms under **Agreements, Tax, and Banking**.
3. Create the Ridgits app record (`com.ridgits.app`) if it does not exist yet.

---

## 2. Subscription group (memberships)

Create **one auto-renewable subscription group** named **Yearly** (group ID `22207786`).

Rank tiers **low → high** (Apple uses this for upgrades):

| Level | Tier | Product ID | Price (USD) | Duration |
|------:|------|------------|-------------|----------|
| 1 | Ridgits+ | `Plus` | $29.99 | 1 year |
| 2 | Premium | `Premium` | $49.99 | 1 year |
| 3 | Ultra | `Ultra` | $69.99 | 1 year |

**Legacy SKUs** (grandfather existing subscribers — do not sell in app):

| Product ID | Tier | Billing |
|------------|------|---------|
| `RidgitsPlusMonthly999` / `RidgitsPlusYearly6000` | Plus | monthly / yearly |
| `RidgitsPremiumMonthly1499` / `RidgitsPremiumYearly9900` | Premium | monthly / yearly |
| `RidgitsUltraMonthly1999` / `RidgitsUltraYearly9900` / `RidgitsUltraYearly14900` | Ultra | monthly / yearly |

**Policy in the app:** upgrades only (higher tier). No in-app downgrades — users cancel in **Settings → Apple ID → Subscriptions**.

For each subscription:

- Add localized display name and description (required — clears **Missing Metadata**).
- Set pricing for all territories.
- Submit for review with the app binary (subscriptions cannot go live alone).

---

## 3. Non-subscription IAP

| Product ID | Type | Price | Purpose |
|------------|------|------:|---------|
| `RidgitsNearbyYear2999` | **Non-Renewing Subscription** (1 year) | $29.99 | Nearby match radius unlock |
| `RidgitsArchetypeBundle5000` | Non-Consumable | $49.99 | All 10 archetype packs |
| `RidgitsPackSituationship999` | Non-Consumable | $9.99 | Single archetype pack |
| `RidgitsPackSelfSabotage999` | Non-Consumable | $9.99 | … |
| `RidgitsPackSocialBattery999` | Non-Consumable | $9.99 | … |
| `RidgitsPackMessaging999` | Non-Consumable | $9.99 | … |
| `RidgitsPackBoundaries999` | Non-Consumable | $9.99 | … |
| `RidgitsPackAttraction999` | Non-Consumable | $9.99 | … |
| `RidgitsPackDesireLogic999` | Non-Consumable | $9.99 | … |
| `RidgitsPackDealbreakerMap999` | Non-Consumable | $9.99 | … |
| `RidgitsPackIdentityPerformance999` | Non-Consumable | $9.99 | … |

**Consumable poke packs** (require active Ridgits+ / Premium / Ultra subscription to purchase):

| Product ID | Type | Credits | Suggested price |
|------------|------|--------:|----------------:|
| `RidgitsPokes5Pack` | **Consumable** | 5 | $5.00 |
| `RidgitsPokes10Pack` | **Consumable** | 10 | $7.99 |
| `RidgitsPokes25Pack` | **Consumable** | 25 | $19.99 |

Poke packs use Apple IAP (consumables). The app and API only credit purchases when the user has an active membership — free users can still use starter poke credits but cannot buy packs until subscribed.

Product IDs must match **exactly** — they are hard-coded in iOS (`RidgitsProductID.swift`) and `ridgits-api` (`ridgits-products.ts`).

---

## 4. App Store Server API & notifications

### 4.1 In-App Purchase key

1. App Store Connect → **Users and Access → Integrations → In-App Purchase**.
2. Generate an **App Store Connect API key** (Issuer ID, Key ID, `.p8` file).
3. Store the private key securely — Vercel env vars only, never in git.

### 4.2 Server notifications (webhook)

1. App Store Connect → your app → **App Information → App Store Server Notifications**.
2. Production URL:

   `https://ridgits-api.vercel.app/api/webhooks/app-store`

3. Use **Version 2** notifications.

The API route `ridgits-api/src/app/api/webhooks/app-store/route.ts` applies renewals, expirations, and revocations to Firestore.

### 4.3 Vercel environment variables

Set on the **ridgits-api** Vercel project:

| Variable | Description |
|----------|-------------|
| `FIREBASE_PROJECT_ID` | `ridgits-24f2d` |
| `FIREBASE_CLIENT_EMAIL` | Firebase Admin service account |
| `FIREBASE_PRIVATE_KEY` | Firebase Admin private key (escaped `\n`) |
| `APP_STORE_BUNDLE_ID` | `com.ridgits.app` |
| `APP_STORE_ISSUER_ID` | From App Store Connect API |
| `APP_STORE_KEY_ID` | IAP key ID |
| `APP_STORE_PRIVATE_KEY` | Contents of `.p8` (escaped `\n`) |
| `RIDGITS_BYPASS_EMAILS` | Optional comma-separated QA emails with full access |

Deploy after changing env vars:

```bash
cd ridgits-api && vercel --prod
```

Health check: `curl https://ridgits-api.vercel.app/api/health`

---

## 5. iOS app configuration

### 5.1 Secrets.plist

```xml
<key>ridgitsApiBaseURL</key>
<string>https://ridgits-api.vercel.app</string>
```

### 5.2 StoreKit testing

1. Xcode → **Product → Scheme → Edit Scheme → Run → Options → StoreKit Configuration** (optional local `.storekit` file), **or**
2. App Store Connect → **Users and Access → Sandbox → Sandbox Testers** for device testing.

### 5.3 Purchase flow (what happens)

1. User buys in app → StoreKit 2 `Product.purchase()`.
2. App sends signed JWS to `POST /api/iap/link-purchase` with Firebase ID token.
3. API verifies transaction with Apple, writes Firestore:
   - Membership: `subscriptionTier`, `subscriptionBillingPeriod`, `isSubscribed`, `subscriptionStatus`
   - Nearby: `hasNearbyAccess`, expiration
   - Packs: `purchasedPacks` / `unlockedPacks`
4. App refreshes entitlements via `RidgitsStore.refreshEntitlements()`.

---

## 6. Entitlement rules (product → access)

| Purchase | Firestore / app access |
|----------|------------------------|
| Ridgits+ / Premium / Ultra (active) | Tier features, assistant limits, Ridgit creation, **nearby matches** (any active membership unlocks nearby per API) |
| `RidgitsNearbyYear2999` | Nearby matches for 1 year (non-renewing) |
| Archetype pack / bundle | Unlocks pack quizzes in app |

**Upgrade-only:** API rejects linking a membership tier **lower** than the user’s current active tier.

---

## 7. Sandbox test plan

- [ ] New user → purchase Ridgits+ yearly (`Plus`) → tier shows Plus, features unlock
- [ ] Upgrade Plus → Premium → prorated charge, tier updates
- [ ] Attempt Premium → Plus purchase → blocked in app and API
- [ ] Cancel subscription in Sandbox Apple ID → access until period end, then expires via webhook
- [ ] Buy `RidgitsNearbyYear2999` without membership → nearby unlocks
- [ ] Buy single archetype pack → pack appears unlocked on dashboard
- [ ] Buy bundle → all packs unlocked
- [ ] Restore purchases on second device → entitlements sync

---

## 8. Web Stripe (optional, ridgits.com)

If you keep Stripe on the web:

- Stripe webhooks should continue writing the same Firestore fields (`subscriptionTier`, `subscriptionStatus`).
- iOS does **not** call Stripe; it reads Firestore via `RidgitsStore` / `/api/account/access`.
- Do not sell the same digital subscription outside IAP for features unlocked in the iOS app without offering IAP (Apple guideline 3.1.1).

---

## 9. App Store review notes

Include in **Review Notes**:

- Sandbox tester Apple ID credentials
- That memberships are upgrade-only; downgrades via Apple Subscriptions settings
- Ridgit quizzes are **in-app only** (`ridgits://ridgit/{id}` deep links)
- Nearby discovery uses location + optional Bluetooth (MultipeerConnectivity) for proximity alerts with nearby access

---

## 10. File reference

| Layer | File |
|-------|------|
| iOS product IDs | `Ridgits/Store/RidgitsProductID.swift` |
| iOS StoreKit | `Ridgits/Store/RidgitsStore.swift` |
| iOS paywalls | `Ridgits/Paywall/SubscriptionPaywallView.swift`, `NearbyPaywallView.swift`, `ArchetypePackPaywallView.swift` |
| API products | `ridgits-api/src/lib/ridgits-products.ts` |
| API link + webhook | `ridgits-api/src/lib/ridgits-iap.ts` |
