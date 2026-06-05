# Firebase mobile setup (FCM push, SMS OTP, Remote Config)

Payspin uses one Firebase project for the mobile app:

- **Console:** [console.firebase.google.com](https://console.firebase.google.com)
- **Account:** `payspin.app@gmail.com`
- **Suggested project:** `payspin-mobile`
- **Android package:** `io.payspin.payspin_mobile`
- **iOS bundle id:** `payspin.app`

The codebase is written to **degrade gracefully**: until the config files below
exist, Firebase init fails silently and push / SMS / Remote Config are disabled
(`FirebaseBootstrap.available == false`). The app still runs. Everything
activates automatically once the files are added — no code changes required.

## 1. Create the project & apps

### Option A — FlutterFire CLI (preferred)

```bash
npm i -g firebase-tools
firebase login                       # payspin.app@gmail.com
firebase projects:create payspin-mobile --display-name "Payspin Mobile"

cd mobile
dart pub global activate flutterfire_cli
flutterfire configure \
  --project=payspin-mobile \
  --platforms=android,ios \
  --ios-bundle-id=payspin.app \
  --android-package-name=io.payspin.payspin_mobile
```

This generates `mobile/lib/firebase_options.dart` and the native config files.
After it runs, switch `FirebaseBootstrap.ensureInitialized()` to use the
generated options (see step 4).

### Option B — Console UI

1. **Add project** → `payspin-mobile`.
2. **Add Android app** → package `io.payspin.payspin_mobile` → download
   `google-services.json` → place in `mobile/android/app/`.
3. **Add iOS app** → bundle `payspin.app` → download `GoogleService-Info.plist`
   → place in `mobile/ios/Runner/` (add to the Xcode target).

## 2. Enable services

- **Build → Cloud Messaging:** note the **Sender ID**. For iOS, upload an
  **APNs key** (Apple Developer → Keys → Apple Push Notifications) under
  Cloud Messaging → Apple app configuration.
- **Authentication → Sign-in method → Phone:** enable. Add **test phone
  numbers** for CI / simulator so no real SMS is sent.

## 2a. Phone Auth device verification (REQUIRED for SMS on Android) ⚠️

**Symptom:** OTP step shows *"We couldn’t verify this device with Google …"*
(previously *"Phone verification could not finish …"*). Root cause: the app's
**signing-key SHA fingerprint is not registered** in Firebase, so Android
Phone Auth can't pass Play Integrity / SafetyNet and the reCAPTCHA fallback
fails on a sideloaded APK. Confirmed by `google-services.json` having an empty
`"oauth_client": []`.

### Current test APK signing key (Android debug keystore)

The `flutter`/`shorebird` release APK is signed with the **debug keystore**
(`android/app/build.gradle.kts` → `signingConfig = signingConfigs.getByName("debug")`),
so register THIS machine's debug fingerprints:

| Type | Fingerprint |
|------|-------------|
| SHA-1 | `F8:D1:6B:D0:26:85:4A:AF:EA:B7:CC:0C:1B:18:0D:E6:DE:86:88:BB` |
| SHA-256 | `3F:B1:8B:E8:8B:33:CB:06:2A:C7:44:3A:98:AD:E4:3E:28:A5:8B:8D:F8:93:D9:A7:91:57:16:15:B9:57:2F:31` |

Re-extract any time (the debug keystore differs per machine):

```bash
keytool -list -v -keystore ~/.android/debug.keystore \
  -alias androiddebugkey -storepass android -keypass android | grep -E "SHA1|SHA256"
# or, straight from a built APK:
"$ANDROID_HOME"/build-tools/35.0.0/apksigner verify --print-certs \
  mobile/dist/payspin-0.1.0+2-release.apk
```

### Fix (console — `payspin.app@gmail.com`)

1. **Project settings → Your apps → Android (`io.payspin.payspin_mobile`) →
   Add fingerprint** → paste **both** SHA-1 and SHA-256 above → Save.
2. **Download the refreshed `google-services.json`** → replace
   `mobile/android/app/google-services.json` (it will now contain
   `oauth_client` entries). Rebuild the APK.
3. **Enable Play Integrity:** [Google Cloud Console](https://console.cloud.google.com/apis/library/playintegrity.googleapis.com)
   → project `payspin-mobile` → **Enable**. (Authentication → Settings →
   *SMS / app verification* should show Play Integrity active.)

### Fastest path for testers — test phone numbers (no SMS, no Integrity)

**Authentication → Sign-in method → Phone → Phone numbers for testing** → add e.g.
`+49 1517 0000000` → code `123456`. These bypass real SMS **and** device
verification, so onboarding works on any APK/emulator immediately. Use these
for QA builds; real numbers need the SHA + Play Integrity steps above.

## 2b. iOS Phone Auth — reCAPTCHA "Verifying you're not a robot" ⚠️

**Symptom:** After tapping **Next** on the phone step, Safari opens
`payspin-mobile.firebaseapp.com` with *"Verifying you're not a robot…"*.

**Why:** Firebase Phone Auth tries **silent device verification** first (APNs
push to the app). When that fails, it falls back to a **reCAPTCHA web view**.
Moving SMS off the OTP screen only changes *when* this runs — it does not remove
reCAPTCHA unless silent verification succeeds.

**Root cause in this repo (fixed in code):** The iOS target had
`registerForRemoteNotifications()` in `AppDelegate` but **no Push Notifications
entitlement** (`aps-environment`). Without it, iOS never delivers a usable APNs
token → silent auth always fails → reCAPTCHA every time on TestFlight.

**Fix checklist (`payspin.app@gmail.com`):**

1. **Entitlements in Xcode** — `Runner/Runner.entitlements` (`production`) and
   `RunnerDebug.entitlements` (`development`) are wired in the Runner target.
   Re-open the project in Xcode once so **Signing & Capabilities** shows
   **Push Notifications** (automatic signing adds it to the App ID).
2. **Regenerate provisioning profiles** if you use manual Debug signing — the
   profile must include the Push Notifications capability.
3. **Firebase Console → Project settings → Cloud Messaging → Apple app
   configuration** — upload the **APNs Authentication Key** (.p8) from Apple
   Developer → Keys. Without this, Firebase cannot send the silent verification
   push even when the app registers for notifications.
4. **Rebuild and re-upload TestFlight** — entitlements are baked into the IPA;
   V1.7f and earlier builds cannot pick this up retroactively.
5. **QA bypass:** same **test phone numbers** as Android (step 2a) skip
   reCAPTCHA entirely.

**Expected after fix:** On a physical iPhone with Push enabled, tapping **Next**
should send SMS with **no** Safari/reCAPTCHA sheet (you may see a brief system
notification permission prompt on first launch).

### Stable distribution (recommended follow-up)

The debug keystore is per-machine and not Play-Store valid. Create a dedicated
**release keystore**, wire `android/key.properties` + a `release` `signingConfig`,
then register that keystore's SHA-1/256 in Firebase instead. Ask the agent to
set this up when you're ready to ship beyond sideload.

## 3. Backend service account (server only — never commit)

1. **Project settings → Service accounts → Generate new private key** → JSON.
2. On the VM (`/opt/payspin/.env.production`):

   ```env
   FIREBASE_PROJECT_ID=payspin-mobile
   # base64 of the JSON, OR a path to the JSON inside the container
   FIREBASE_SERVICE_ACCOUNT_JSON=<base64-or-path>
   ```

   ```bash
   base64 -i payspin-mobile-service-account.json | tr -d '\n'   # macOS
   ```
3. `docker compose -f /opt/payspin/docker-compose.yml restart api`

The backend reads this in `FirebaseAdminService` (lazy init). When unset, FCM
push and `/v1/auth/verify-phone` are disabled but the API keeps serving.

## 4. Wire generated options (after FlutterFire)

Once `firebase_options.dart` exists, update the bootstrap to pass options:

```dart
// mobile/lib/core/firebase/firebase_bootstrap.dart
import '../../firebase_options.dart';
// ...
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

`firebase_options.dart` is safe to commit (the apiKey is a public client key).
**Never** commit the service-account JSON.

## 5. iOS / Android native bits

- iOS: enable **Push Notifications** capability in Xcode; APNs key uploaded
  (step 2). See [FCM Flutter client](https://firebase.google.com/docs/cloud-messaging/flutter/client).
- Android: `google-services.json` in place; a default notification channel is
  created by `firebase_messaging` automatically.

## What the app does with Firebase

| Feature | Where |
|---------|-------|
| FCM token registration | `PushService.init()` → `POST /v1/notifications/device-token` |
| Foreground push → refresh inbox/home | `PushService` listeners → `NotificationsRefreshNotifier` / `LinksRefreshNotifier` |
| Background tap → open link | `PushService.openLinkRequests` → `MainShell` navigates `/links/:id` |
| SMS OTP | `PhoneAuthService` (onboarding `step_otp_page.dart`) → `POST /v1/auth/verify-phone` |
| Remote Config | `RemoteConfigService` (read in `bootstrap.dart`) |
