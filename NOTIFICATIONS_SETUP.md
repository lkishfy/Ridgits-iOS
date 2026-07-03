# Ridgits notifications setup

Manual checklist for **Apple Push Notification service (APNs)**, **Firebase Cloud Messaging (FCM)**, and the **ridgits-api** engagement system.

The app uses **notification-heavy engagement**: pokes, message requests, new messages, expiring chats, poke reminders, profile nudges, plus local Bluetooth nearby pings.

---

## Architecture

```
iOS app
  ├── Registers APNs token → Firebase Messaging → FCM token
  ├── POST /api/notifications/register-device  → Firestore users/{uid}/devices/{deviceId}
  └── Receives push → deep link to Matches / Messages / Ridgit

ridgits-api (Vercel)
  ├── Messaging + pokes → sendEngagementPush() via firebase-admin/messaging
  ├── Hourly cron → /api/notifications/cron (expiring chats, reminders, nudges)
  └── Stores preferences in users/{uid}/notificationPreferences/default
```

---

## 1. Apple Developer — Push Notifications capability

1. Open [Apple Developer](https://developer.apple.com) → **Certificates, Identifiers & Profiles**.
2. Select App ID **`com.ridgits.app`**.
3. Enable **Push Notifications**.
4. In Xcode → target **Ridgits** → **Signing & Capabilities** → add **Push Notifications** if not present.

The repo includes `aps-environment` in `Ridgits/Ridgits.entitlements`:

- **`development`** — for debug builds and sandbox APNs
- Change to **`production`** for App Store / TestFlight release builds (or use Xcode to manage automatically)

---

## 2. Firebase Console — Cloud Messaging

Project: **`ridgits-24f2d`**

### 2.1 Upload APNs authentication key (recommended)

1. Firebase Console → **Project settings** → **Cloud Messaging** tab.
2. Under **Apple app configuration**, select iOS app `com.ridgits.app`.
3. Upload your **APNs Authentication Key** (`.p8`):
   - Create in Apple Developer → **Keys** → enable **Apple Push Notifications service (APNs)**
   - Note **Key ID** and **Team ID**
4. Enter Key ID, Team ID, and upload the `.p8` file.

Alternatively, upload APNs **certificates** (legacy) — auth key is preferred.

### 2.2 Verify GoogleService-Info.plist

Ensure `Ridgits/GoogleService-Info.plist` includes:

- `GCM_SENDER_ID` / Firebase messaging sender ID
- `BUNDLE_ID` = `com.ridgits.app`

---

## 3. iOS app — already wired (verify after setup)

| File | Purpose |
|------|---------|
| `Ridgits/Push/RidgitsPushNotificationService.swift` | FCM delegate, APNs token, notification tap routing |
| `Ridgits/Push/NotificationPreferencesView.swift` | Per-category opt-in/out |
| `Ridgits/Engagement/RidgitsPokeInbox.swift` | Realtime poke inbox + tab badge |
| `Ridgits/RidgitsApp.swift` | `registerForRemoteNotifications`, device token forwarding |
| `project.yml` | `FirebaseMessaging` dependency |

After Firebase + capability setup:

1. Run `xcodegen generate`
2. Build on a **physical device** (push does not work on Simulator)
3. Sign in → accept notification permission
4. Confirm Firestore: `users/{yourUid}/devices/{deviceId}` with `fcmToken`

---

## 4. ridgits-api — environment variables

Add to Vercel (same Firebase Admin creds as IAP):

| Variable | Description |
|----------|-------------|
| `FIREBASE_PROJECT_ID` | `ridgits-24f2d` |
| `FIREBASE_CLIENT_EMAIL` | Firebase Admin service account |
| `FIREBASE_PRIVATE_KEY` | Admin private key (escaped `\n`) |
| `CRON_SECRET` | Random secret for hourly engagement cron |

Firebase Admin SDK uses these for **FCM send** via `firebase-admin/messaging` — no separate FCM server key needed when using Admin SDK.

Deploy:

```bash
cd ridgits-api && vercel --prod
```

---

## 5. Vercel Cron — scheduled engagement

`vercel.json` runs **`GET /api/notifications/cron` every hour**.

Vercel sends `Authorization: Bearer ${CRON_SECRET}` when `CRON_SECRET` is set in project env.

### Cron sends

| Job | Trigger | Notification |
|-----|---------|--------------|
| Expiring conversations | Active chat expires within 2 hours | "Chat ending soon" |
| Pending message requests | Pending > 6 hours | "Message waiting for you" |
| Unseen poke reminders | Unseen poke > 1 hour | "Still thinking about it?" |
| Profile nudges | Incomplete profile > 24 hours | "Finish your Ridgits profile" |

Manual test:

```bash
curl -H "Authorization: Bearer YOUR_CRON_SECRET" \
  https://ridgits-api.vercel.app/api/notifications/cron
```

---

## 6. Real-time push events (API-triggered)

| Event | API route | Push type |
|-------|-----------|-----------|
| Poke sent | `POST /api/pokes/send` | `poke` |
| Message request | `POST /api/messaging/start` | `message_request` |
| Conversation approved | `POST /api/messaging/approve` | `conversation_approved` |
| New message | `POST /api/messaging/send` | `message` |

### iOS poke flow

iOS now sends pokes through the API (not direct Firestore writes) so push is always delivered.

---

## 7. Firestore collections (new)

| Path | Purpose |
|------|---------|
| `users/{uid}/devices/{deviceId}` | FCM tokens per device |
| `users/{uid}/notificationPreferences/default` | Category opt-in/out |
| `notificationEvents` | Delivery + open analytics |

### Default preferences

All categories **on** except `marketing: false`. Users edit in **Profile → Notification Settings**.

---

## 8. Firestore indexes (create if queries fail)

In Firebase Console → **Firestore → Indexes**, add composite indexes if cron logs index errors:

| Collection | Fields |
|------------|--------|
| `conversations` | `status` ASC, `expiresAt` ASC |
| `conversations` | `status` ASC, `createdAt` ASC |
| `pokes` | `seen` ASC, `createdAt` ASC |
| `pokes` | `fromUserId` ASC, `toUserId` ASC |

---

## 9. Notification categories (iOS)

APNs categories registered in-app:

- `RIDGITS_POKE`
- `RIDGITS_MESSAGE`
- `RIDGITS_MESSAGE_REQUEST`
- `RIDGITS_CONVERSATION_EXPIRING`
- `RIDGITS_CONVERSATION_APPROVED`
- `RIDGITS_NEARBY`
- `RIDGITS_RIDGIT`
- `RIDGITS_GENERAL`

Tap routing uses payload `route` + optional `conversationId`, `fromUserId`, `ridgitId`.

---

## 10. Local vs remote notifications

| Type | Source |
|------|--------|
| **Remote (FCM)** | Pokes, messages, cron reminders — requires sections 1–4 |
| **Local** | Bluetooth nearby peer detection (`RidgitsNearbyPresenceService`) — works without FCM; toggle in Profile |

---

## 11. Sandbox testing checklist

- [ ] APNs key uploaded to Firebase
- [ ] Push capability enabled in Xcode
- [ ] Physical device, signed in, notifications allowed
- [ ] `users/{uid}/devices/...` document created with token
- [ ] Send poke from second account → push received
- [ ] Start message request → recipient gets push
- [ ] Approve conversation → initiator gets push
- [ ] Send message in active chat → recipient gets push
- [ ] Tap notification → opens correct tab (Matches / Messages / Ridgit)
- [ ] Toggle off "Pokes" in settings → poke push suppressed
- [ ] Cron endpoint returns `{ ok: true, result: { ... } }`
- [ ] Invalid FCM token removed from `devices` subcollection on send failure

---

## 12. API routes reference

| Method | Path | Auth |
|--------|------|------|
| POST | `/api/notifications/register-device` | Bearer |
| DELETE | `/api/notifications/register-device` | Bearer |
| GET | `/api/notifications/preferences` | Bearer |
| PATCH | `/api/notifications/preferences` | Bearer |
| POST | `/api/notifications/preferences` | Bearer (record open) |
| GET/POST | `/api/notifications/cron` | `CRON_SECRET` |
| POST | `/api/pokes/send` | Bearer |
| POST | `/api/pokes/seen` | Bearer |
| POST | `/api/pokes/unpoke` | Bearer |

---

## 13. App Store review notes

Mention:

- Push is used for dating/social engagement (pokes, timed messaging, nearby discovery)
- Users can disable categories in **Profile → Notification Settings**
- Bluetooth nearby alerts are separate local notifications with their own toggle

---

## Related docs

- [PAYMENTS_SETUP.md](./PAYMENTS_SETUP.md) — IAP subscriptions and App Store webhooks
- [README.md](./README.md) — iOS project overview
