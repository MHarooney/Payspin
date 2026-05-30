# Payspin Mobile — Implementation Tracker

**Last updated:** 2026-05-23 (greenfield rebuild v2)

## Greenfield architecture (v2)

| Area | Status | Notes |
|------|--------|-------|
| Clean architecture layers | Done | `domain/` · `data/` · `presentation/` · `core/design_system/` |
| DI (`get_it`) + `go_router` | Done | `lib/app/di/injection.dart` · `lib/app/router.dart` |
| Design system 1:1 `screens.jsx` | Done | Tokens + onboarding shell + numpad + bottom nav |
| Onboarding flow (5 steps + credentials) | Done | Stub OTP; email/password API bridge |
| Home / Groepies / Profile | Done | Tikkies tab, FAB, settings group |
| Send flow | Done | Numpad amount → name → WhatsApp share |
| QR scan + link detail | Done | |

## API integration

| Endpoint | Use case |
|----------|----------|
| `POST /auth/register` | Onboarding credentials + complete |
| `POST /auth/login` | Login page |
| `GET/POST /bank-accounts` | Step 5 complete / profile |
| `GET/POST /links` | Home list + send flow |

## Run

```bash
./scripts/dev/payspin-dev start --mobile
# or
cd mobile && flutter run --dart-define=API_URL=http://localhost:3001/v1
```

## Deferred

- Real SMS OTP (backend)
- FCM push notifications
- Groepies / Circles product flows
