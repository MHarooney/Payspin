# Payspin — Payment settlement, Firebase (push/SMS/in-app), webhooks & IBAN routing

**Purpose:** Paste this file (or `@docs/agents/payment-notifications-yapily-prompt.md`) when implementing **production payment settlement** (Yapily webhooks → DB → notifications), **Firebase** (FCM push + SMS OTP + in-app inbox), **Shorebird OTA** (Expo EAS–style Dart patches), **payer web status polling**, and **IBAN-based country / institution routing**.

**Product context:** Payspin is non-custodial P2P payment links. After a payer authorises at the bank (sandbox: Model Bank / Ozone), status may stay `PENDING` or `PROCESSING` until Yapily confirms settlement. The payee must see **Paid** in the mobile app, get a **system push**, and see an **in-app notification** (React-style notification feed). Onboarding phone OTP is currently **stub-only** — replace with **Firebase Phone Auth (SMS)**. Mobile releases use **Shorebird** for OTA patches without waiting on App Store review for Dart/UI fixes. Today the payer web shows *“Payment is being processed — you can safely close this page”* but **Firebase is not wired on Flutter**, **webhooks may not be registered on production**, **Shorebird is not initialized**, and there is **no in-app notification inbox**.

**Accounts (all providers):** Use **payspin.app@gmail.com** unless noted. Agent may provision apps via **Firebase CLI**, **Shorebird CLI**, **SSH/deploy scripts**, and **Browser MCP** (see [Console provisioning checklist](#console-provisioning-checklist-browser-mcp--cli)).

---

## Non-negotiables (read first)

1. Read [AGENTS.md](../../AGENTS.md), [architecture.md](architecture.md), [conventions.md](conventions.md).
2. Business logic in `backend/src/application/use-cases/` — not controllers.
3. Yapily only via `PIS_GATEWAY` / `AIS_GATEWAY` from `@payspin/pisp-provider`.
4. Validation via Zod in `@payspin/validators`.
5. **Minimal diffs** — no drive-by refactors.
6. **Do not commit** `.env`, Firebase service account JSON, or Yapily secrets.
7. Production accounts: **payspin.app@gmail.com** (Hetzner, Docker Hub, Apple, Yapily, Firebase, **Shorebird org [49026](https://console.shorebird.dev/orgs/49026/apps)**).
8. Mobile cloud builds **must** use `--dart-define=API_URL=http://178.105.118.225/v1` until HTTPS domain exists.
9. **Test everything** on cloud VM + Shorebird APK before marking done (Scenarios 1–10).

---

## Production environment (agent must use)

| Item | Value |
|------|--------|
| API (public) | `http://178.105.118.225/v1` |
| Payer web | `http://178.105.118.225` |
| Health | `http://178.105.118.225/v1/health/ready` |
| Hetzner VM | `payspin-api`, CX23, fsn1 |
| SSH | `ssh -i ~/.ssh/id_ed25519_payspin root@178.105.118.225` |
| Server env | `/opt/payspin/.env.production` |
| Yapily app | [Console → Payspin](https://console.yapily.com/applications/53b0d904-21b3-41a7-ba2b-e440ab460bf9) |
| Yapily app ID | `53b0d904-21b3-41a7-ba2b-e440ab460bf9` |
| Default sandbox institution | `modelo-sandbox` (Model Bank @ `auth1.obie.uk.ozoneapi.io`) |
| Sandbox bank login | `mits` / `mits` |
| Test payee (prod DB) | `test@payspin.dev` / `password123` |
| GitHub remote (SSH) | `git@github.com-mharooney:MHarooney/Payspin.git` |
| **Shorebird org** | [console.shorebird.dev/orgs/49026/apps](https://console.shorebird.dev/orgs/49026/apps) (org ID **49026**) |
| Mobile package / bundle | Android `io.payspin.payspin_mobile` · iOS `payspin.app` |
| Production mobile API | `--dart-define=API_URL=http://178.105.118.225/v1` |

Deploy pipeline: `./infrastructure/hetzner/deploy.sh` (build locally → Docker Hub → server pull).

Mobile OTA pipeline: **Shorebird release** (store/sideload baseline) → **Shorebird patch** (OTA Dart updates to installed baselines).

---

## Current architecture (what already exists)

### Payment flow (PIS)

```
Payer web → POST /v1/pay/:code/initiate
         → Yapily POST /payment-auth-requests
         → Redirect to bank (authorisationUrl)
         → Bank redirects → /{code}/callback?paymentId=&consent=
         → POST /v1/pay/:code/complete (creates Yapily payment)
         → status may be PENDING | PROCESSING | COMPLETED
```

Key files:

| Layer | Path |
|-------|------|
| Initiate | `backend/src/application/use-cases/payments/initiate-payer-payment.use-case.ts` |
| Complete | `backend/src/application/use-cases/payments/complete-payer-payment.use-case.ts` |
| Payer callback UI | `frontend/app/[code]/callback/page.tsx` |
| Webhook ingress | `backend/src/interfaces/webhooks/yapily-webhooks.controller.ts` |
| Webhook worker | `backend/src/infrastructure/queue/yapily-webhook.processor.ts` |
| Mobile link polling | `mobile/lib/presentation/links/link_detail_page.dart` (5s, only on that screen) |

### Bank connect flow (AIS — separate from payer payment)

```
Mobile → POST /v1/bank-accounts/connect
      → Yapily POST /account-auth-requests
      → Model Bank login
      → GET /v1/bank-accounts/connect/callback?consent=
      → 302 payspin://bank-callback?consent=
      → POST /v1/bank-accounts/connect/complete
      → Yapily GET /accounts (Consent header)
      → Encrypted IBAN saved to bank_accounts
```

Key files: `connect-bank-account.use-case.ts`, `complete-bank-connection.use-case.ts`, `bank-accounts.controller.ts`, `mobile/.../step_connect_bank_page.dart`.

### Data storage (PostgreSQL on VM)

| Table | Purpose |
|-------|---------|
| `users` | Payee accounts |
| `bank_accounts` | `iban_encrypted`, `iban_iv`, `iban_last4`, `yapily_institution_id` |
| `payment_links` | Short code, amount, status |
| `payments` | Status lifecycle, `yapily_payment_id`, `webhook_raw` |
| `webhook_events` | Idempotent Yapily event log |
| `bank_connections` | AIS session PENDING → COMPLETED |

Consent tokens are **not** stored long-term — used once at complete.

### What is missing (this prompt’s scope)

| Gap | Impact |
|-----|--------|
| Yapily webhook URL not registered / secret not on prod | Payments stuck at `PENDING` |
| No Firebase / FCM on Flutter | Payee never notified when app closed |
| No in-app notification inbox | No React-style feed; user must hunt link detail |
| Phone OTP is stub (`verify_otp_usecase.dart`) | SMS not real; onboarding misleading |
| Payer callback page static after “processing” | Payer sees no final success without refresh |
| Institution/country hardcoded (`modelo-sandbox`, `GB`/`NL`) | Wrong sandbox for DE payees; no IBAN-driven routing |
| Mobile home does not refresh on push | Payee must open link detail manually |
| Shorebird not initialized | No OTA; every Dart fix needs full APK/IPA rebuild |

---

## Console provisioning checklist (Browser MCP + CLI)

Agent **must** provision and verify all providers. Use **Browser MCP** (connect extension first) for consoles; use **CLI** where faster. If a login wall appears, ask the user to sign in as **payspin.app@gmail.com**, then continue.

| Provider | Console URL | Agent actions |
|----------|-------------|---------------|
| **Yapily** | [Application Payspin](https://console.yapily.com/applications/53b0d904-21b3-41a7-ba2b-e440ab460bf9) | Register `modelo-sandbox`; add redirect URIs + webhook URL; copy webhook secret to VM |
| **Firebase** | [Firebase Console](https://console.firebase.google.com) | Create/use `payspin-mobile`; add Android + iOS apps; enable Phone Auth; FCM + APNs; download service account for API |
| **Shorebird** | [Org 49026 apps](https://console.shorebird.dev/orgs/49026/apps) | Create app **Payspin** (or link existing); run `shorebird init` locally; first **release** + test **patch** |
| **Hetzner** | [console.hetzner.com](https://console.hetzner.com) | Verify VM `178.105.118.225` healthy; env vars on server (read-only unless deploying) |
| **Docker Hub** | [hub.docker.com](https://hub.docker.com) | Verify `payspin/api` + `payspin/web` images pull on VM |
| **Apple Developer** | [developer.apple.com](https://developer.apple.com) | APNs key → upload to Firebase; signing for Shorebird iOS release (team `5HNF7DY6G7`) |

**End-state:** Backend on cloud serves webhooks + notifications; payer web on cloud; mobile APK/IPA built with production `API_URL` + Shorebird baseline; OTA patch provably applies on tester device.

---

## Flutter vs React Native — delivery & notifications (read before coding)

React Native apps often use **Expo EAS Update** for OTA JS patches. Payspin Flutter uses **Shorebird** as the deliberate equivalent.

| Capability | React Native (Expo) | Flutter (Payspin) — **required** |
|------------|---------------------|----------------------------------|
| OTA code patches | Expo EAS Update | **[Shorebird](https://shorebird.dev)** — org [49026](https://console.shorebird.dev/orgs/49026/apps) |
| Remote copy / feature flags | Often bundled with Expo | **Firebase Remote Config** — strings, poll intervals, min version |
| System push | FCM | **FCM** via `firebase_messaging` |
| In-app notification feed | Firestore / REST | **Postgres `notifications` + REST** + FCM refresh signal |
| SMS OTP | Firebase Phone Auth | **Firebase Phone Auth** |
| Store baseline | EAS build | **`shorebird release`** → APK/IPA/TestFlight; patches via **`shorebird patch`** |
| Native-only changes | Still needs store | Still needs new **release** (not patchable: new plugins, permissions, entitlements) |

**Goal:** React-like UX (**push**, **inbox**, **SMS OTP**) plus **Expo-like OTA** via Shorebird for Dart/UI/compliance hotfixes on cloud-connected tester builds.

**Shorebird limits (document in `resources/docs/mobile-release.md`):** Patches update **Dart + assets** only. Cannot OTA: new native dependencies, `Info.plist` / manifest changes, Firebase/Shorebird init without new release. See [Shorebird docs](https://docs.shorebird.dev/code-push/release/).

**Existing Firebase project (legacy portal):** `payspin-app` — see `Payspin-portal/scripts/config.ts`. **Do not expand Payspin-portal.** Prefer new **`payspin-mobile`** Firebase project.

---

## Firebase platform setup (push + SMS + in-app)

Agent may use **Firebase CLI** (terminal) and/or **Browser MCP** ([Firebase Console](https://console.firebase.google.com) — sign in as **payspin.app@gmail.com**).

### Option A — Firebase CLI (preferred for Flutter)

```bash
# Install if missing: npm i -g firebase-tools
firebase login   # payspin.app@gmail.com

# List existing projects
firebase projects:list

# Create NEW project (if not reusing payspin-app)
firebase projects:create payspin-mobile --display-name "Payspin Mobile"

# FlutterFire — generates mobile/lib/firebase_options.dart (gitignore secrets in options is OK — apiKey is public)
cd mobile
dart pub global activate flutterfire_cli
flutterfire configure \
  --project=payspin-mobile \
  --platforms=android,ios \
  --ios-bundle-id=payspin.app \
  --android-package-name=io.payspin.payspin_mobile
```

Add to `.gitignore` if needed: only service account JSON — `firebase_options.dart` is normally committed.

### Option B — Browser MCP (Console UI)

1. Connect Browser MCP extension → open [Firebase Console](https://console.firebase.google.com)
2. Sign in: **payspin.app@gmail.com**
3. **Add project** → `payspin-mobile` (or open existing `payspin-app`)
4. **Project settings → General → Your apps:**
   - Add **Android** app: package `io.payspin.payspin_mobile` (match `mobile/android/.../build.gradle`)
   - Add **iOS** app: bundle ID `payspin.app`
   - Download `google-services.json` → `mobile/android/app/`
   - Download `GoogleService-Info.plist` → `mobile/ios/Runner/`
5. **Build → Cloud Messaging:** note **Sender ID**; upload **APNs key** (Apple Developer → Keys → Apple Push Notifications) for iOS push
6. **Authentication → Sign-in method → Phone** → Enable (for SMS OTP)
7. **Project settings → Service accounts → Generate new private key** → store on server only as `FIREBASE_SERVICE_ACCOUNT_JSON` (base64 or path on VM) — **never commit**

### Backend env (VM `/opt/payspin/.env.production`)

```env
FIREBASE_PROJECT_ID=payspin-mobile
# Base64-encoded service account JSON OR path inside container
FIREBASE_SERVICE_ACCOUNT_JSON=
```

### Flutter packages (mobile)

```yaml
# pubspec.yaml additions
firebase_core:
firebase_messaging:
firebase_auth:          # Phone Auth SMS OTP
firebase_remote_config: # Feature flags / copy without store release
```

### iOS / Android native setup

Follow [FCM Flutter client](https://firebase.google.com/docs/cloud-messaging/flutter/client):
- iOS: enable Push Notifications capability, upload APNs to Firebase Console
- Android: `google-services.json`, default notification channel

Document steps in `resources/docs/firebase-mobile-setup.md` (create during implementation).

---

## Shorebird OTA setup (required — Phase G)

**Console:** [Shorebird org 49026 → Apps](https://console.shorebird.dev/orgs/49026/apps)  
**Docs:** [Shorebird Quick Start](https://docs.shorebird.dev/getting-started/) · [Create a Release](https://docs.shorebird.dev/code-push/release/)

Shorebird is Payspin’s **Expo EAS Update equivalent**: ship Dart/UI fixes to testers on cloud builds without App Store review. **First `shorebird release`** creates the baseline; **`shorebird patch`** pushes OTA updates.

### Option A — Shorebird CLI (preferred)

```bash
# Install CLI (macOS)
curl --proto '=https' --tlsv1.2 \
  https://raw.githubusercontent.com/shorebirdtech/install/main/install.sh -sSf | bash

shorebird login          # Browser OAuth — payspin.app@gmail.com
shorebird doctor         # Must pass: api, console, Flutter

cd mobile
shorebird init           # Creates shorebird.yaml with app_id — commit this file

# Production cloud baseline (Android sideload / testers)
shorebird release android --artifact apk \
  --dart-define=API_URL=http://178.105.118.225/v1

# iOS (when signing works)
shorebird release ios \
  --dart-define=API_URL=http://178.105.118.225/v1 \
  --export-options-plist=ios/ExportOptions.plist

# OTA patch (after a visible Dart change, e.g. notification copy)
shorebird patch android --release-version 0.1.0+1
shorebird patch ios --release-version 0.1.0+1
```

**CI token (optional):** `shorebird login:ci` → store as GitHub secret `SHOREBIRD_TOKEN` — never commit.

### Option B — Browser MCP (Console UI)

1. Connect Browser MCP → open [console.shorebird.dev/orgs/49026/apps](https://console.shorebird.dev/orgs/49026/apps)
2. Sign in (same account as `shorebird login`)
3. **Create app** → name **Payspin** (if not already created by `shorebird init`)
4. Note **App ID** matches `mobile/shorebird.yaml`
5. After CLI release/patch: verify **Releases** and **Patches** appear in console; check adoption metrics

### Repo files to add/update

| File | Purpose |
|------|---------|
| `mobile/shorebird.yaml` | App ID from Shorebird (commit) |
| `resources/docs/mobile-release.md` | Release vs patch workflow, cloud API_URL, tester install |
| `mobile/dist/` | Output APK/IPA for testers (gitignored) |
| `.github/workflows/shorebird-patch.yml` | Optional CI patch on `main` (document only unless user asks) |

### Cloud-connected release rules

- **Always** pass production API: `--dart-define=API_URL=http://178.105.118.225/v1`
- Match `pubspec.yaml` version (`0.1.0+1`) with `--release-version` when patching
- **Android testers:** `--artifact apk` for direct install (same as existing `mobile/dist/payspin-test-*.apk` flow)
- **iOS testers:** Shorebird release IPA + TestFlight optional; patches require installed Shorebird baseline
- After OTA patch: force-quit app → reopen → confirm UI change without reinstalling APK

### Phase G tasks (implementation)

1. Run `shorebird init` in `mobile/`; commit `shorebird.yaml`
2. Create first **Android release** with cloud `API_URL`; copy APK to `mobile/dist/`
3. Make a trivial visible Dart change (e.g. notification empty-state copy)
4. Run `shorebird patch android`; verify on physical device against cloud API
5. Add **Firebase Remote Config** keys: `min_app_version`, `min_shorebird_patch`, notification strings
6. Document release vs patch decision tree in `resources/docs/mobile-release.md`
7. iOS Shorebird release when signing unblocked (same org app)

**Acceptance:**

- [ ] `shorebird doctor` passes locally
- [ ] App visible in [org 49026 console](https://console.shorebird.dev/orgs/49026/apps)
- [ ] At least one **release** + one **patch** on Android proven on device hitting `178.105.118.225`
- [ ] Remote Config fetch works on app start
- [ ] `resources/docs/mobile-release.md` documents OTA vs store release boundaries

---

## Implementation phases

### Phase A — Yapily webhooks on production (PENDING → COMPLETED)

**Goal:** When Yapily settles a payment, `payments.status` becomes `COMPLETED` even if the payer closed the browser.

**Tasks:**

1. **Verify webhook endpoint is live**
   - `POST http://178.105.118.225/v1/webhooks/yapily`
   - HMAC via `YAPILY_WEBHOOK_SECRET` (`yapily-pis.gateway.ts` → `verifyWebhookSignature`)
   - BullMQ queue `yapily-webhooks` must be running (Redis on VM)

2. **Configure Yapily Console** (use **Browser MCP** — connect extension first)
   - App: `53b0d904-21b3-41a7-ba2b-e440ab460bf9`
   - Webhooks → add endpoint: `http://178.105.118.225/v1/webhooks/yapily`
   - Copy signing secret → server `YAPILY_WEBHOOK_SECRET`
   - Subscribe to payment status events (per [Yapily webhook docs](https://docs.yapily.com))

3. **Server env** (SSH to VM — do not commit values)
   ```bash
   ssh -i ~/.ssh/id_ed25519_payspin root@178.105.118.225
   # Edit /opt/payspin/.env.production — set YAPILY_WEBHOOK_SECRET
   # docker compose restart api worker (if separate)
   ```

4. **Harden processor if needed**
   - Confirm `yapily-webhook.processor.ts` maps Yapily payload fields to `yapilyPaymentId`
   - Log unknown payloads; add unit test with sample Yapily webhook JSON (search Yapily docs if shape unclear)

5. **Redeploy** if code changes: `./infrastructure/hetzner/deploy.sh`

**Acceptance:**

- [ ] Synthetic webhook (signed with secret) returns `{ received: true }` and updates a test `payments` row
- [ ] Duplicate webhook returns `{ duplicate: true }` without double-counting `useCount`
- [ ] Real sandbox payment: after payer completes, status reaches `COMPLETED` within 2 minutes (webhook or poll fallback)

---

### Phase B — Firebase FCM (system push) when payment completes

**Goal:** Payee receives OS notification *“€X.XX received”* when payment settles (app backgrounded or killed).

**Architecture (React-like dual channel):**

```
Yapily webhook → payment COMPLETED
              → Create in-app notification row (Phase E)
              → firebase-admin.messaging().send()  (Phase B)
              → Mobile: background handler OR foreground → refresh inbox + LinksRefreshNotifier
```

**Tasks:**

1. **Backend**
   - Prisma `device_tokens` table: `userId`, `fcmToken`, `platform`, `updatedAt` (unique on `userId`+`fcmToken`)
   - Prisma `notifications` table (Phase E — create here if not separate)
   - `POST /v1/users/device-token` (JWT) — register/update token from mobile
   - `SendPushNotificationUseCase` — wraps `firebase-admin` `messaging.send()`
   - `SendPaymentReceivedNotificationUseCase` — builds FCM payload + calls push use case
   - Trigger from `yapily-webhook.processor.ts` (and `complete-payer-payment` when immediately `COMPLETED`)
   - Enqueue via BullMQ queue `notifications` (do not block webhook ACK)
   - Credentials: `FIREBASE_SERVICE_ACCOUNT_JSON` — **never commit JSON**

2. **FCM payload contract** (data message — works foreground + background):

   ```json
   {
     "notification": { "title": "Payment received", "body": "€8.00 from a payer" },
     "data": {
       "type": "payment.received",
       "paymentId": "...",
       "linkId": "...",
       "amountCents": "800",
       "currency": "EUR"
     }
   }
   ```

3. **Mobile (Flutter)**
   - `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`
   - `firebase_messaging`: request permission (iOS), `getToken()`, listen `onMessage`, `onMessageOpenedApp`, `getInitialMessage`
   - On login/register: `POST /users/device-token`
   - Foreground: show in-app banner (Phase E) + `LinksRefreshNotifier.bump()`
   - Background tap: `go_router` → `/links/:id`
   - Profile: show real push status (not placeholder)

**Acceptance:**

- [ ] Payee device receives **system push** within ~30s of sandbox payment completion
- [ ] Tap push opens link detail with status **Paid**
- [ ] Token re-registration on app restart works
- [ ] iOS + Android tested (or document iOS blocker if APNs pending)

---

### Phase E — In-app notification center (React-style feed)

**Goal:** When app is **open**, user sees a notification bell / inbox like a React dashboard app — not only OS push.

**Tasks:**

1. **Backend**
   - Prisma `notifications`:
     - `id`, `userId`, `type` (`payment.received`, `payment.failed`, `link.expired`, …)
     - `title`, `body`, `data` (JSON: `paymentId`, `linkId`, …)
     - `readAt`, `createdAt`
   - `GET /v1/notifications` (paginated, JWT)
   - `POST /v1/notifications/:id/read` and `POST /v1/notifications/read-all`
   - Create notification row in same use case as FCM send (single transaction)

2. **Mobile UI**
   - `NotificationsPage` or bottom-sheet inbox (match `PayspinTheme` dark UI)
   - Home app bar bell icon with unread badge count
   - On FCM `data` message (foreground): insert via API fetch or optimistic local bump
   - Tap row → navigate to `/links/:id`
   - Pull-to-refresh; mark read on open
   - Wire profile row “Push notifications” → permission settings + inbox link

3. **Parity with React mental model**
   - **REST inbox** = source of truth (like React app fetching `/notifications`)
   - **FCM** = realtime “invalidate cache” signal (like React Query refetch on websocket/push)
   - Do **not** require Firestore for Phase E unless user explicitly wants portal unification

**Acceptance:**

- [ ] After payment, payee sees unread badge + inbox entry without leaving app
- [ ] Mark-as-read works; badge decrements
- [ ] Works when push permission denied (inbox still populated via polling on home focus)

---

### Phase F — Firebase Phone Auth (SMS OTP for onboarding)

**Goal:** Replace stub OTP in `verify_otp_usecase.dart` / `step_otp_page.dart` with real SMS verification.

**Current state:** `VerifyOtpUseCase` accepts any 6 digits; copy says “coming soon”.

**Tasks:**

1. **Firebase Console:** Enable **Phone** sign-in provider (Browser MCP or CLI project settings)

2. **Mobile**
   - Collect phone in E.164 format (`step_phone_page.dart`)
   - `FirebaseAuth.instance.verifyPhoneNumber(...)` → SMS code
   - User enters code in `payspin_otp_boxes.dart` → `PhoneAuthProvider.credential` → `signInWithCredential`
   - On success: obtain `idToken` → send to backend OR store verified phone on user profile

3. **Backend** (choose one — document in PR):
   - **Option 1 (recommended):** Keep **email/password JWT** as primary auth; add `POST /v1/auth/verify-phone` that verifies Firebase ID token via `firebase-admin.auth().verifyIdToken()`, stores `phoneVerifiedAt` + hashed phone on `users` table
   - **Option 2:** Full Firebase Auth as identity (larger migration — **out of scope** unless user asks)

4. **Prisma migration:** `users.phoneE164`, `users.phoneVerifiedAt` (optional fields)

5. **Dev/testing:** Firebase test phone numbers in Console (no SMS cost) for CI; real SMS on device test

**Acceptance:**

- [ ] Real SMS received on physical device (or test number in Console)
- [ ] Invalid code rejected; valid code marks phone verified
- [ ] Onboarding flow completes through to bank connect
- [ ] `flutter test` updated; stub use case removed or dev-only behind flag

**Note:** Firebase Phone Auth SMS is for **verification**, not arbitrary transactional SMS (payment receipts). Payment alerts use **FCM**, not SMS.

---

### Phase G — Shorebird OTA + Firebase Remote Config

**See [Shorebird OTA setup](#shorebird-ota-setup-required--phase-g)** for full CLI/Console steps. This phase is **required**, not optional.

**Remote Config** (complements Shorebird):

- `min_app_version` — force store update when native release required
- `payer_poll_interval_ms`, `feature_circles_enabled`, notification copy
- Fetch on app start in `mobile/lib/main.dart` or dedicated bootstrap service

**Store update nudge:** If `min_app_version` > current build → blocking screen with store/download link.

---

### Phase C — Payer web callback polling (optional but recommended)

**Goal:** Payer who sees *“Payment is being processed”* gets auto-updated to **Payment sent** without manual refresh.

**Tasks:**

1. Convert `frontend/app/[code]/callback/page.tsx` processing branch to a **client component** (or add `CallbackStatusPoller.tsx`)
2. Poll `GET /v1/pay/:code/status/:paymentId` every 3–5s until terminal (`COMPLETED` | `FAILED` | `CANCELLED`)
3. On `COMPLETED` → redirect to `/{code}/success`
4. Max poll duration ~2 minutes, then show “Still processing — you can close this page”

**Acceptance:**

- [ ] Sandbox payment: payer page transitions from processing → success without user action
- [ ] Failed payment shows error state

---

### Phase D — IBAN country auto-detection & institution routing

**Goal:** Derive country from payee IBAN and pick Yapily institution/country for AIS/PIS instead of hardcoding `modelo-sandbox` + single `YAPILY_DEFAULT_COUNTRY`.

**Tasks:**

1. **Shared utility** in `packages/shared-types` or `backend/src/domain/utils/iban-country.ts`
   - Parse ISO 13616 country code from IBAN (first 2 letters after validation)
   - Map: `NL` → Netherlands, `DE` → Germany, `GB` → UK, etc.
   - Unit tests: `NL13ABNA0885334361` → `NL`, `DE89370400440532013000` → `DE`

2. **Use at initiation**
   - `initiate-payer-payment.use-case.ts`: decrypt payee IBAN → country → pass to `createPaymentAuthRequest({ institutionId, ... })`
   - `connect-bank-account.use-case.ts`: if no `institutionId` in body, default institution from user country or IBAN

3. **Institution selection policy** (env + fallback)

   | IBAN country | Sandbox (now) | Production (later) |
   |--------------|---------------|-------------------|
   | NL | `modelo-sandbox` or Yapily NL sandbox if registered | ING / ABN / Rabobank via Yapily |
   | DE | `deutschebank-sandbox` when certs registered; else `modelo-sandbox` | Deutsche Bank, etc. |
   | GB | `modelo-sandbox` | UK banks |

   Env vars (example):
   ```env
   YAPILY_INSTITUTION_NL=modelo-sandbox
   YAPILY_INSTITUTION_DE=modelo-sandbox
   YAPILY_INSTITUTION_GB=modelo-sandbox
   YAPILY_DEFAULT_INSTITUTION=modelo-sandbox
   ```

4. **`list-institutions` API**: default `country` query from authenticated user’s primary bank account IBAN country

**Deferred (document only, do not block Phases A–C):**

- Register `deutschebank-sandbox` in Yapily Console (requires eiDAS certs)
- Switch production to real NL/DE live institutions

**Acceptance:**

- [ ] Payee with NL IBAN → payment auth uses NL-appropriate institution config
- [ ] Unit tests for IBAN → country mapping
- [ ] No regression for existing `test@payspin.dev` flow

---

## Agent tooling — how to work

### Terminal / VM

```bash
# Local dev
./scripts/dev/payspin-dev doctor
./scripts/dev/payspin-dev start --web

# Production health
curl -s http://178.105.118.225/v1/health/ready | jq

# E2E smoke (local)
./scripts/dev/e2e-register-iban-link.sh

# Deploy after backend changes
export PAYSPIN_SERVER_IP=178.105.118.225
./infrastructure/hetzner/deploy.sh

# SSH logs
ssh -i ~/.ssh/id_ed25519_payspin root@178.105.118.225 'docker compose -f /opt/payspin/docker-compose.yml logs -f api --tail=100'
```

### Browser MCP

Use for **all console provisioning** (connect extension first):

| Console | URL |
|---------|-----|
| Yapily | [Payspin app](https://console.yapily.com/applications/53b0d904-21b3-41a7-ba2b-e440ab460bf9) |
| Firebase | [Firebase Console](https://console.firebase.google.com) |
| **Shorebird** | [Org 49026 apps](https://console.shorebird.dev/orgs/49026/apps) |
| Payer web test | `http://178.105.118.225/{shortCode}` |
| Apple Developer | APNs key → Firebase; iOS signing |

If Google/Apple/Yapily login appears → **stop and ask user to sign in** as **payspin.app@gmail.com**, then resume.

### CLI quick reference

```bash
# Firebase
firebase login && firebase projects:list
cd mobile && flutterfire configure --project=payspin-mobile ...

# Shorebird
shorebird login && shorebird doctor
cd mobile && shorebird init
shorebird release android --artifact apk --dart-define=API_URL=http://178.105.118.225/v1
shorebird patch android --release-version 0.1.0+1

# Cloud backend
export PAYSPIN_SERVER_IP=178.105.118.225 && ./infrastructure/hetzner/deploy.sh
curl -s http://178.105.118.225/v1/health/ready
```

### Internet search

Use when:

- Yapily webhook payload shape / event types change
- FCM + Flutter + iOS APNs setup
- Firebase Phone Auth Flutter flow
- Shorebird vs store release policy
- Yapily sandbox institution IDs for NL/DE

Prefer official docs: [docs.yapily.com](https://docs.yapily.com), [FCM Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/client), [Phone Auth Flutter](https://firebase.google.com/docs/auth/flutter/phone-auth), [Remote Config Flutter](https://firebase.google.com/docs/remote-config/flutter/get-started).

### Mobile verification

- Flutter simulator or physical device with `--dart-define=API_URL=http://178.105.118.225/v1`
- MCP Flutter driver if available; otherwise `flutter test` + manual device test

---

## End-to-end test plan (agent MUST run before marking done)

Run **all** scenarios; fix failures before finishing.

### Scenario 1 — Webhook signature & idempotency

1. Create payment in DB or via initiate API (status `AWAITING_AUTHORIZATION` or `PENDING`)
2. POST signed webhook to `/v1/webhooks/yapily` with `COMPLETED` status
3. Assert DB: `payments.status = COMPLETED`, `payment_links.useCount` incremented
4. Replay same webhook → no double increment

### Scenario 2 — Full payer journey (browser)

1. Log in mobile / API as payee; create link (e.g. €8.00)
2. Open payer URL on phone browser: `http://178.105.118.225/{code}`
3. Pay → Model Bank → `mits`/`mits` → authorise
4. Assert callback page shows processing then **success** (Phase C)
5. Assert API: `GET /v1/pay/{code}/status/{paymentId}` → `COMPLETED`

### Scenario 3 — Payee system push (Phase B)

1. Payee app logged in, FCM token registered
2. Complete Scenario 2
3. Assert **OS notification** received on payee device
4. Assert home / link detail shows **Paid** without manual refresh

### Scenario 4 — In-app notification inbox (Phase E)

1. Payee app **foreground** during payment completion
2. Assert bell badge increments; inbox shows “Payment received”
3. Tap notification → link detail; mark read → badge clears

### Scenario 5 — Payee app closed (push)

1. Force-quit payee app
2. Payer completes payment
3. Webhook fires → push still delivered
4. Tap push → app opens link detail with **Paid**

### Scenario 6 — SMS OTP (Phase F)

1. Onboarding: enter real phone (or Firebase test number)
2. Receive SMS (or use Console test code)
3. Complete OTP → credentials step → bank connect still works

### Scenario 7 — IBAN country routing (Phase D)

1. Payee bank account with NL IBAN → initiate payment → verify institution/country in Yapily request (logs or mock)
2. Repeat logic test for DE IBAN in unit tests

### Scenario 8 — Shorebird OTA (Phase G)

1. Install Shorebird baseline APK (`shorebird release android --artifact apk`) on test device
2. Confirm app hits cloud API (`178.105.118.225`)
3. Change visible Dart string (e.g. inbox empty state)
4. `shorebird patch android --release-version 0.1.0+1`
5. Force-quit app → reopen → **new copy visible without APK reinstall**
6. Verify patch listed in [Shorebird console](https://console.shorebird.dev/orgs/49026/apps)

### Scenario 9 — Full cloud stack (integration)

1. Yapily webhook registered; payment completes on VM
2. FCM push + in-app notification on payee device (Shorebird-built app)
3. Payer web polling shows success
4. Optional: push OTA patch with notification UI tweak; payee receives next payment with updated UI

### Scenario 10 — Regression

```bash
pnpm --filter @payspin/backend test
cd mobile && flutter test
cd frontend && pnpm build  # if frontend changed
```

---

## Definition of done

- [ ] Firebase project configured (`payspin-mobile` or `payspin-app` + Flutter apps); `firebase_options.dart` + native config files in place
- [ ] Yapily webhook registered on production with valid secret
- [ ] `PENDING`/`PROCESSING` → `COMPLETED` via webhook in live sandbox test
- [ ] FCM system push to payee on completion; device token API documented
- [ ] In-app notification inbox + unread badge (Phase E)
- [ ] Firebase Phone Auth SMS OTP replaces stub (Phase F)
- [ ] Payer callback auto-polls until terminal state (Phase C)
- [ ] IBAN → country utility + used in payment/bank connect initiation (Phase D)
- [ ] **Shorebird:** `shorebird.yaml` committed; release + patch proven on Android cloud build ([org 49026](https://console.shorebird.dev/orgs/49026/apps))
- [ ] Firebase Remote Config integrated
- [ ] `resources/docs/firebase-mobile-setup.md` + `resources/docs/mobile-release.md` created; `yapily-console-setup.md` updated
- [ ] All Scenarios 1–10 passed; test commands recorded in PR/commit message
- [ ] No secrets committed (service account JSON, `.env`)

---

## Out of scope (unless user explicitly asks)

- `Payspin-portal/` expansion (may reuse same Firebase project ID only)
- Twilio / MessageBird for marketing SMS (Firebase Phone Auth covers verification OTP)
- Full migration from JWT to Firebase Auth as sole identity
- Real NL/DE **live** bank registration (only document steps)
- TestFlight / IPA build (unless needed to test push on device)
- HTTPS custom domain (nice-to-have; IP + ATS exception works for now)
- Circles / Groepies / Monerium
- GitHub Actions Shorebird CI (unless user asks)

---

## Quick reference — redirect URIs (Yapily Console)

Must include on app `53b0d904-21b3-41a7-ba2b-e440ab460bf9`:

```
http://178.105.118.225/v1/bank-accounts/connect/callback
http://178.105.118.225/*/callback
http://localhost:3001/v1/bank-accounts/connect/callback
http://localhost:3000/*/callback
```

Webhook:

```
http://178.105.118.225/v1/webhooks/yapily
```

---

## Suggested implementation order

1. **Console provisioning** — Browser MCP: Yapily webhooks, Firebase project, Shorebird app ([org 49026](https://console.shorebird.dev/orgs/49026/apps))
2. **Shorebird init + first Android cloud release** — baseline APK for all mobile testing (Phase G partial)
3. **Phase A** — Yapily webhooks on VM
4. **Phase C** — payer polling
5. **Phase E** — in-app notifications API + UI
6. **Phase B** — FCM push
7. **Phase F** — Firebase Phone Auth SMS OTP
8. **Phase D** — IBAN country routing
9. **Phase G complete** — prove OTA patch + Remote Config on cloud build
10. **Scenario 9** — full cloud integration test

After each phase: deploy backend if changed; run relevant scenarios on **178.105.118.225** and **Shorebird-built APK**.

---

## Agent kickoff prompt (copy-paste)

```
@docs/agents/payment-notifications-yapily-prompt.md

Implement all phases. Use payspin.app@gmail.com for every provider console.

Provision via Browser MCP + CLI:
- Yapily: webhooks + redirects on app 53b0d904-21b3-41a7-ba2b-e440ab460bf9
- Firebase: payspin-mobile (FCM, Phone Auth, Remote Config, service account on VM)
- Shorebird: org 49026 https://console.shorebird.dev/orgs/49026/apps — init, release, patch
- Hetzner VM 178.105.118.225: deploy backend, verify health

Mobile must use Shorebird for OTA (Expo EAS equivalent):
  shorebird release android --artifact apk --dart-define=API_URL=http://178.105.118.225/v1
  shorebird patch android after Dart fixes

Requirements:
- Yapily webhooks → PENDING → COMPLETED
- FCM push + in-app notification inbox
- Firebase Phone Auth SMS OTP (replace stub)
- Payer web callback polling
- IBAN country auto-detection
- Shorebird OTA patch tested on device against cloud API

Test ALL scenarios 1–10. Do not mark done until tests pass.
```
