# Payspin Mobile (Flutter)

Flutter mobile app for Payspin P2P payment links — Phase 1.

## Stack

- **Flutter 3.5+** / Dart 3
- **flutter_secure_storage** — JWT access token storage
- **http** — REST client to NestJS API (`/v1`)
- **share_plus** / **url_launcher** — WhatsApp + native share (P06)
- **qr_flutter** — payer QR codes (P07)

Auth is **PostgreSQL-only** via the API (`POST /auth/register`, `POST /auth/login`). No Firebase.

API models in [`lib/core/api/models.dart`](lib/core/api/models.dart) mirror [`packages/shared-types`](../packages/shared-types).

Full setup, troubleshooting, and device-specific API URLs: **[Local development runbook](../resources/docs/local-development-runbook.md)**.

## Setup

```bash
cd mobile
flutter pub get

flutter run --dart-define=API_URL=http://localhost:3001/v1
```

For **Android emulator**, use `http://10.0.2.2:3001/v1`.  
For **iOS simulator**, `http://localhost:3001/v1` works.

## Features (Phase 1)

- Email register / login → JWT from API
- IBAN onboarding (S08) — international IBANs, Mod-97 validation, encrypted at rest on API
- Bank account settings (R02)
- Create payment link with amount + description (P03–P05)
- Share sheet: WhatsApp, QR, copy, native share (P06)
- QR screen for in-person payers (P07)
- Link detail with payment stats + cancel (P08)
- List payment links on home with status pills (P01)

## User flow

```
Login → Session gate → (no IBAN?) IBAN onboarding → Success → Create link → Share (P06) → Home
                     → (has IBAN)  Home → tap link → Detail (P08) / QR (P07)
```
