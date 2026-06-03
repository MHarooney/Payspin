# Mobile release & OTA (Shorebird)

Payspin mobile uses **Shorebird** as its over-the-air (OTA) code-push system — the
Flutter equivalent of Expo EAS Update for React Native. Ship Dart/UI/compliance
hotfixes to installed builds **without** waiting on App Store / Play review.

- **Console:** [Shorebird org 49026 → Apps](https://console.shorebird.dev/orgs/49026/apps)
- **Account:** `payspin.app@gmail.com`
- **Config file:** `mobile/shorebird.yaml` (`app_id` written by `shorebird init`)

## Release vs patch — decision tree

| Change | Action |
|--------|--------|
| Dart logic, UI, copy, assets bundled in the app | **`shorebird patch`** (OTA, no store) |
| New native plugin / dependency | **`shorebird release`** (new store binary) |
| `Info.plist` / `AndroidManifest` / permissions / entitlements | **`shorebird release`** |
| Firebase or Shorebird init changes | **`shorebird release`** |
| Flutter / Dart SDK upgrade | **`shorebird release`** |
| `pubspec.yaml` version bump | **`shorebird release`** |

> Rule of thumb: if it only changes `.dart` files or bundled assets, it can be a
> patch. Anything that touches native config needs a new release.

## One-time setup

```bash
# Install CLI (macOS / Linux)
curl --proto '=https' --tlsv1.2 \
  https://raw.githubusercontent.com/shorebirdtech/install/main/install.sh -sSf | bash

shorebird login        # browser OAuth — payspin.app@gmail.com
shorebird doctor       # must pass: api, console, Flutter

cd mobile
shorebird init         # writes the real app_id into shorebird.yaml — COMMIT IT
```

## Cloud-connected release (baseline)

Always pin the production API so testers hit the live VM:

```bash
cd mobile
shorebird release android --artifact apk \
  --dart-define=API_URL=https://pay.payspin.io/v1
# Output APK → copy to mobile/dist/ for sideload testers (dist/ is gitignored)

# iOS (once signing is unblocked, team 5HNF7DY6G7)
shorebird release ios \
  --dart-define=API_URL=https://pay.payspin.io/v1 \
  --export-options-plist=ios/ExportOptions.plist
```

The `--release-version` is taken from `pubspec.yaml` (`0.1.0+1`).

## Pushing an OTA patch

After a Dart-only change (e.g. notification copy, inbox layout):

```bash
cd mobile
shorebird patch android --release-version 0.1.0+1
shorebird patch ios     --release-version 0.1.0+1   # when iOS released
```

Verify on a device that already has the baseline installed:

1. Force-quit the app.
2. Reopen — the Shorebird engine downloads & applies the patch on next launch.
3. Confirm the new UI without reinstalling the APK.
4. Check the patch + adoption in the [console](https://console.shorebird.dev/orgs/49026/apps).

## CI (optional, document-only unless requested)

`shorebird login:ci` produces a token → store as GitHub secret `SHOREBIRD_TOKEN`
(never commit). A workflow can then run `shorebird patch android` on `main`.

## Firebase Remote Config (complements Shorebird)

Remote Config carries values that should change **without** any code push:

| Key | Purpose |
|-----|---------|
| `min_app_version` | Force a store update when a native release is required |
| `min_shorebird_patch` | Minimum required OTA patch number |
| `payer_poll_interval_ms` | Tune payer/web + mobile polling cadence |
| `feature_circles_enabled` | Feature flag |
| `notification_empty_copy` | Inbox empty-state copy |

Read on app start in `mobile/lib/bootstrap.dart` via `RemoteConfigService`.
Defaults live in `mobile/lib/core/config/remote_config_service.dart`, so the app
works even before the Firebase project is provisioned.
