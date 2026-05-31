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
