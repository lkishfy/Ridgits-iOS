# Ridgits iOS

Native SwiftUI app for Ridgits — OkCupid-style matching questions, Geists-style auth, and Ridgits web parity for dashboard, nearby matches, and expiring messaging.

## Features

- **Auth** — Apple Sign In + Google (Firebase Auth), copied from Geists-iOS / Seen-iOS patterns
- **Quiz** — OkCupid-style flow: your answer → acceptable answers → importance → optional dealbreaker (includes intimacy/spicy questions from Ridgits quiz packs)
- **Dashboard** — Home hub with Ridgits Assistant, Quick Tools, archetypes, **Additional Archetype packs**, community invite, nationwide match preview, paywall CTA
- **Matches** — Nationwide preview free; **nearby radius locked** behind IAP
- **Messages** — Pending / awaiting / active sections; **24-hour timer + 16-message cap** after approval
- **Profile** — View/edit profile with square web styling; onboarding uses `ProfileSetupView`
- **Ridgit** — Create custom quiz challenges free on web (1 without subscription); on iOS: 1 (free/+), 3 (Premium), 10 (Ultra)
- **Nearby pings** — Bluetooth/local-network discovery (MultipeerConnectivity) alerts when another Ridgits member is close (requires nearby access)
- **IAP (StoreKit 2)** — Auto-renewable memberships: **Ridgits+** ($9.99/mo · $29.99/yr), **Premium** ($12.99/mo · $53.99/yr), **Ultra** ($19.99/mo · $69.99/yr). Upgrades only in-app; cancel via Apple. Plus nearby access ($29.99/yr) and archetype packs.

See **[PAYMENTS_SETUP.md](./PAYMENTS_SETUP.md)** for App Store Connect, webhooks, and sandbox testing.
- **Push engagement** — FCM remote notifications for pokes, messages, expiring chats, reminders; see **[NOTIFICATIONS_SETUP.md](./NOTIFICATIONS_SETUP.md)**

## Setup

1. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
2. From this directory: `xcodegen generate`
3. Open `Ridgits.xcodeproj` in Xcode
4. Add Firebase iOS app for bundle ID `com.ridgits.app` on project **`ridgits-24f2d`**
5. Download `GoogleService-Info.plist` → `Ridgits/GoogleService-Info.plist`
6. Copy `Secrets.example.plist` → `Secrets.plist` and add to target **Copy Bundle Resources**
7. Update `Info.plist` URL scheme with reversed Google client ID from Firebase  
   **Google Sign-In:** do not put placeholder OAuth client IDs in `Secrets.plist`. The app uses the iOS client from `GoogleService-Info.plist` (same as Geists). Only add optional `googleWebClientID` if Firebase Console gives you a separate Web client ID and sign-in fails without it.
8. Enable **Sign in with Apple** capability (entitlements already included)
9. Create IAP products in App Store Connect:
   - **Subscription group** `ridgits_membership` (ranked: Plus < Premium < Ultra):
     - `RidgitsPlusMonthly999` $9.99/mo · `RidgitsPlusYearly6000` $29.99/yr
     - `RidgitsPremiumMonthly1499` $12.99/mo · `RidgitsPremiumYearly9900` $53.99/yr
     - `RidgitsUltraMonthly1999` $19.99/mo · `RidgitsUltraYearly9900` $69.99/yr · `RidgitsUltraYearly14900` $149/yr (legacy)
   - `RidgitsNearbyYear2999` — Non-Renewing Subscription, 1 year, $29.99
   - Archetype pack non-consumables + `RidgitsArchetypeBundle5000`

## Backend (Vercel + Firebase today, Supabase later)

```
Ridgits iOS
    │
    ├── ridgits-api.vercel.app   ← all server logic (matching, messaging, IAP)
    │
    └── Firebase ridgits-24f2d   ← Auth + Firestore realtime only
```

| Today (Firebase) | Future (Supabase) |
|------------------|-------------------|
| Auth (Apple/Google) | Supabase Auth |
| Firestore reads/writes for quiz, profiles | Postgres + RLS |
| Realtime conversation listeners | Supabase Realtime or API polling |

The iOS app keeps calling the same Vercel URL when you migrate data — only `ridgits-api` changes internally.

Configure `ridgitsApiBaseURL` in `Secrets.plist` (see `Secrets.example.plist`). Bundled example defaults to `https://ridgits-api.vercel.app`.

## Logo

The app uses the official Ridgits logo from the web project:

`Ridgits/ridgits/src/assets/logo.png` → `Ridgits/Assets.xcassets/RidgitsLogo.imageset/logo.png`

Re-sync after web logo changes:

```bash
./scripts/sync_ridgits_logo.sh
```

## Architecture

```
RidgitsApp → ContentView
  ├── LoginView (Ridgits home page styling)
  ├── QuizView (Firestore quizProgress)
  ├── ProfileSetupView (Firestore users)
  └── DashboardView (TabView)

Services/
  ├── RidgitsAPIClient.swift   → ridgits-api (matching, messaging, IAP)
  └── RidgitsFirebaseClient.swift → Firestore + API delegation
```

## Backend

- **`ridgits-api/`** — Next.js on Vercel (all iOS server routes)
- **Firebase `ridgits-24f2d`** — Auth + Firestore only (web Cloud Functions unchanged for now)

## Styling

Monochromatic Ridgits palette (`#FAFAFA` feed, `#0A0A0A` headlines, black CTAs) — matches `Ridgits/ridgits` web and `SeenTheme.swift`.
