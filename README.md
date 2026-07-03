# Ridgits iOS

Native SwiftUI app for Ridgits — OkCupid-style matching questions, Geists-style auth, and Ridgits web parity for dashboard, nearby matches, and expiring messaging.

## Features

- **Auth** — Apple Sign In + Google (Firebase Auth), copied from Geists-iOS / Seen-iOS patterns
- **Quiz** — OkCupid-style flow: your answer → acceptable answers → importance → optional dealbreaker (includes intimacy/spicy questions from Ridgits quiz packs)
- **Dashboard** — Home hub with nationwide match preview, paywall CTA, messaging rules
- **Matches** — Nationwide preview free; **nearby radius locked** behind IAP
- **Messages** — Pending / awaiting / active sections; **24-hour timer + 16-message cap** after approval (matches Ridgits web)
- **IAP** — `RidgitsNearbyYear2999` — $29.99 for 12 months of nearby access (configure as non-renewing subscription in App Store Connect)

## Setup

1. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
2. From this directory: `xcodegen generate`
3. Open `Ridgits.xcodeproj` in Xcode
4. Add Firebase iOS app for bundle ID `com.ridgits.app` on project **`ridgits-24f2d`**
5. Download `GoogleService-Info.plist` → `Ridgits/GoogleService-Info.plist`
6. Copy `Secrets.example.plist` → `Secrets.plist` and add to target **Copy Bundle Resources**
7. Update `Info.plist` URL scheme with reversed Google client ID from Firebase
8. Enable **Sign in with Apple** capability (entitlements already included)
9. Create IAP product `RidgitsNearbyYear2999` — Non-Renewing Subscription, 1 year, $29.99 USD

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
