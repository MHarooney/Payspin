# Payspin Design System → Flutter Map (v2 greenfield)

**Source:** [`resources/Payspin Design System/screens.jsx`](../Payspin%20Design%20System/screens.jsx)  
**App:** Clean architecture under `mobile/lib/`

## Architecture

| Layer | Path |
|-------|------|
| Design tokens & widgets | `lib/core/design_system/` |
| Domain (entities, use cases) | `lib/domain/` |
| Data (API, repositories) | `lib/data/` |
| UI (pages) | `lib/presentation/` |
| DI + router | `lib/app/` |

## Screen map (1:1 prototype)

| JSX | Flutter page |
|-----|----------------|
| `WelcomeScreen` | `presentation/welcome/welcome_page.dart` |
| `Step1Name` | `presentation/onboarding/pages/step_name_page.dart` |
| `Step2Phone` | `presentation/onboarding/pages/step_phone_page.dart` |
| `Step3OTP` | `presentation/onboarding/pages/step_otp_page.dart` |
| *(bridge)* | `presentation/onboarding/pages/step_credentials_page.dart` |
| `Step4IBAN` | `presentation/onboarding/pages/step_iban_page.dart` |
| `Step5FullName` | `presentation/onboarding/pages/step_full_name_page.dart` |
| `SuccessScreen` | `presentation/onboarding/pages/success_page.dart` |
| `HomeScreen` | `presentation/home/home_page.dart` |
| `GroepiesScreen` | `presentation/home/groepies_page.dart` |
| `ProfileScreen` | `presentation/profile/profile_page.dart` |
| `ScanQRScreen` | `presentation/scan/scan_qr_page.dart` |
| `SendAmountScreen` | `presentation/send/send_amount_page.dart` |
| `SendNameItScreen` | `presentation/send/send_name_page.dart` |
| Login | `presentation/auth/login_page.dart` |
| Link detail (API) | `presentation/links/link_detail_page.dart` |

## Widget map

| JSX | Dart |
|-----|------|
| `GradientText` | `PayspinGradientText` |
| `GradientPillButton` | `PayspinGradientPillButton` |
| `GradientCircleButton` | `PayspinGradientCircleButton` |
| `OnboardingShell` | `PayspinOnboardingShell` |
| `BottomNav` | `PayspinBottomNav` |

## Auth note

Prototype phone/OTP is **UI-only** (`VerifyOtpUseCase` stub). Real auth uses email/password on `step_credentials_page` → existing NestJS `/auth/register`.

## Visual QA

```bash
open "resources/Payspin Design System/Payspin Prototype.html"
cd mobile && flutter run --dart-define=API_URL=http://localhost:3001/v1
```
