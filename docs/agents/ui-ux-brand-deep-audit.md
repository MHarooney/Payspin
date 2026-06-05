# Payspin Brand UI/UX — Deep Audit Report

**Date:** 2026-06-05  
**Auditor role:** Senior product engineering / design-system review  
**Scope:** Flutter mobile (payee app), Next.js payer web, shared brand assets, motion, accessibility, edge cases  
**Method:** Static code review + `flutter test` / `flutter analyze` + chrome-devtools runtime + iOS Simulator (fresh debug build via mobile MCP)

---

## Executive verdict

| Platform | Grade | Summary |
|----------|-------|---------|
| **Payer web** | **A** | Dual theme, emblem swap, pay flow, error/callback/success states, FAQ animation, branded loader — all verified live. Minor polish only. |
| **Mobile (core flows)** | **A-** | Dark theme + brand motion ship correctly on fresh build. Light theme works on migrated screens; secondary flows still have token debt. |
| **Assets & QR** | **A** | Real RGBA emblems; branded QR tests pass; gradient centre @ EC H. Device scan still manual. |
| **Test hygiene** | **A** | **179/179** `flutter test` green after audit fixes; `next build` green. |

**Ship recommendation:** Safe to ship payer web and mobile dark-mode primary journeys. Light-mode on mobile is usable on main tabs but not pixel-perfect on every secondary screen (see P2 backlog).

---

## Audit methodology

### Automated
- `flutter test` — full suite (179 tests)
- `flutter analyze` — `design_system/`, `app/`, touched `presentation/`
- `next build` — production compile + type-check

### Runtime — payer web (chrome-devtools)
Verified with JS evaluation (not snapshot-only tools):

| Scenario | Result |
|----------|--------|
| Landing `/` dark + light toggle | ✅ `data-theme` flips; `localStorage` persists |
| Emblem swap header | ✅ white on dark, gradient on light |
| Pay page `/ftljy84w` | ✅ amount, CTA, FAQ, support |
| Invalid link `/zzzzzzzz` | ✅ “Link not found” + header/toggle |
| Callback cancelled `?error=cancelled` | ✅ error card + “Try again” + WebShell |
| Callback pending (no params) | ✅ branded loader + back link |
| Success `/ftljy84w/success` | ✅ confirmation copy |
| Loader emblem per theme | ✅ white spinner dark / gradient light |
| Emblem PNG assets | ✅ HTTP 200/304 both variants |
| Console errors | ✅ none on tested routes |

### Runtime — mobile (mobile MCP, iPhone 17 Pro simulator)
- Installed **fresh** `build/ios/iphonesimulator/Runner.app` (stale install showed wrong gradient emblem on dark — not a code bug)
- Cold start → welcome screen: **white emblem** on `#0B0B12`, gradient wordmark, pink→teal CTA ✅
- Accessibility tree: “Get started”, “Log in” buttons present ✅

### Not executed (documented gaps)
- Physical QR scan from `link_qr_page` (no camera harness in CI)
- Real iPhone device with fresh IPA (simulator used instead)
- Lighthouse / WCAG automated contrast sweep (manual spot-check only)

---

## Issues found & fixed in this audit

| ID | Severity | Finding | Fix |
|----|----------|---------|-----|
| **F1** | **High** | `SystemChrome` status/nav bar set once in `bootstrap.dart`; changing Appearance in Profile left wrong bar colors in light mode | Added `PayspinSystemChrome` widget; wired in `MaterialApp.builder` |
| **F2** | **Medium** | Profile → Appearance detail label did not update after theme change (no listener) | `ThemeModeController` listener on `ProfilePage` |
| **F3** | **Medium** | `NotificationBell` (home header) hardcoded dark glass tokens — broken in light mode | Migrated to `context.psColors` |
| **F4** | **Medium** | `showPayspinSnackBar` hardcoded dark elevated colors | Migrated to `context.psColors` |
| **F5** | **Medium** | Web `PayspinLoader` always showed gradient emblem (wrong on dark surfaces) | Dual-image loader + CSS theme swap (matches `PayspinEmblem`) |
| **F6** | **Low** | Web `ThemeProvider` initialized React state to `'dark'` before `useEffect` sync → toggle label flash | Lazy `useState(() => resolveInitialTheme())` |
| **F7** | **Low** | `screens_smoke_test` 3 failures: pending 3s secure-storage timer in `initState` | Pump +4s after mount; **179/179** pass |
| **F8** | **Low** | `payspin_emblem_loader.dart` missing `PayspinEmblemStyle` import (compile error in tests) | Import added (prior session) |
| **F9** | **Medium** | `PayspinPasscodeDots` + `SetupLockPage` dark-only tokens (lock/setup flows in light mode) | Migrated to `context.psColors` |

---

## Mobile — screen & component coverage

### Fully theme-aware (verified in code + tests/simulator)

| Area | Files |
|------|-------|
| App shell | `app.dart`, `bootstrap.dart`, `payspin_system_chrome.dart`, `payspin_theme.dart` |
| Navigation | `main_shell.dart`, `payspin_bottom_nav.dart`, `payspin_scaffold.dart` |
| Auth / onboarding | `welcome`, `login`, `splash`, `step_connect_bank`, `success` |
| Money flows | `home`, `send_amount`, `send_name`, `link_detail`, `link_qr`, `scan_qr` |
| Profile | `profile_page` (+ Appearance sheet) |
| Security | `lock_screen`, `setup_lock_page`, `payspin_passcode_dots` |
| Notifications | `notifications_page`, `notification_bell` |
| Design system | `payspin_logo`, `payspin_branded_qr`, `payspin_emblem_loader`, `payspin_snackbar`, shared shells/fields/nav |

### Partially migrated (still mix `PayspinTokens` + `psColors`)

These screens work in **dark** (default) but will show dark-surface colors if user selects **light**:

| File | Risk |
|------|------|
| `step_phone_page.dart`, `step_otp_page.dart` | Onboarding mid-flow |
| `step_iban_page.dart`, `step_full_name_page.dart` | Onboarding |
| `payspin_phone_input_row.dart` | Country picker overlay |
| `payspin_otp_boxes.dart` | OTP entry |
| `circle_detail_page.dart`, `circle_row.dart`, `groepies_page.dart` | Circles feature |
| `bank_accounts_page.dart` | Profile sub-flow |
| `payspin_accent_circle_button.dart`, `payspin_labeled_field.dart` | Shared widgets |
| `payspin_explainer_sheet.dart` | Modals |

**P2 backlog:** migrate remaining files when light mode is promoted beyond Profile toggle.

### Brand emblem rules (mobile)

| Surface | Expected | Fresh simulator |
|---------|----------|-----------------|
| Dark welcome/splash | White emblem (`auto` → `emblemStyle.white`) | ✅ verified |
| Light surfaces | Gradient emblem | ✅ via `PayspinLogo(style: auto)` |
| QR centre | Gradient @ ~19% | ✅ `branded_qr_test` |
| Loader | Gradient spin (brand motion spec) | ✅ `theme_and_loader_test` |

---

## Payer web — edge-case matrix

| Route / state | Header + toggle | Theme vars | CTA clickable | Notes |
|---------------|-----------------|------------|---------------|-------|
| `/` landing | ✅ | ✅ | N/A | Empty-state card |
| `/[code]` active link | ✅ | ✅ | ✅ gradient CTA | FAQ accordion animates |
| `/[code]` 404 | ✅ | ✅ | N/A | Error icon + copy |
| `/[code]` settled/expired | ✅ | ✅ | Blocked notice | `unavailableMessage()` |
| `/[code]/callback` pending | ✅ | ✅ | Back link | Loader aria-label |
| `/[code]/callback?error=cancelled` | ✅ | ✅ | Try again | |
| `/[code]/success` | ✅ | ✅ | N/A | Checkmark + amount |

### Accessibility spot-check
- Theme toggle: `aria-label` reflects target mode ✅
- Loader: `role="status"`, `aria-live="polite"` ✅
- FAQ: `aria-expanded` on buttons ✅
- Reduced motion: CSS disables spin, FAQ transition, page-enter ✅

---

## Motion & reduced-motion

| Effect | Mobile | Web |
|--------|--------|-----|
| Emblem loader spin | `PayspinMotion.reduced(context)` → static | `prefers-reduced-motion` → no spin |
| Splash assemble | Skippable tap; reduced → instant | N/A |
| Button press scale | `PayspinGradientPillButton` | `.ps-cta:active` (reduced off) |
| QR scale-in | `link_qr_page` Tween | N/A |
| FAQ reveal | N/A | `grid-template-rows` 0fr→1fr |
| Page enter | N/A | `.ps-enter` fade/slide |

---

## Test results (final)

```
flutter test     → 179 passed, 0 failed
flutter analyze  → 0 errors (1 pre-existing info in payspin_progress_bar.dart)
next build       → success
```

New/updated tests: `theme_and_loader_test.dart` (7), `screens_smoke_test.dart` (timer drain).

---

## Screenshot evidence checklist

| # | Capture | Status |
|---|---------|--------|
| 1 | Web landing dark | ✅ chrome-devtools |
| 2 | Web landing light | ✅ |
| 3 | Web pay page dark | ✅ |
| 4 | Web pay page light + FAQ open | ✅ |
| 5 | Web callback loader dark | ✅ |
| 6 | Web 404 / cancelled / success | ✅ |
| 7 | Mobile welcome dark (fresh build) | ✅ simulator MCP |
| 8 | Mobile light theme home/profile | ⚠️ needs logged-in session |
| 9 | Mobile QR scan device | ⚠️ manual |
| 10 | Mobile Appearance sheet | ⚠️ needs logged-in session |

---

## Remaining gaps & recommendations

### P1 — before marketing light mode on mobile
1. Migrate onboarding phone/OTP/IBAN pages to `context.psColors`
2. Migrate `payspin_phone_input_row` + `payspin_otp_boxes`

### P2 — quality
3. Circles + bank accounts sub-flows
4. Replace Flutter default app icon with branded launcher asset
5. SVG emblem layers for splash assemble (deferred in master plan)

### P3 — verification
6. Manual QR scan on 2 devices (iOS + Android)
7. Real-device iPhone test with release build
8. WCAG contrast automation on light theme migrated screens

---

## Files changed in deep audit

**Mobile**
- `lib/core/design_system/theme/payspin_system_chrome.dart` (new)
- `lib/app/app.dart`
- `lib/presentation/profile/profile_page.dart`
- `lib/presentation/notifications/notification_bell.dart`
- `lib/presentation/notifications/notifications_page.dart`
- `lib/core/design_system/widgets/payspin_snackbar.dart`
- `lib/core/design_system/widgets/payspin_passcode_dots.dart`
- `lib/presentation/security/setup_lock_page.dart`
- `test/screens_smoke_test.dart`

**Web**
- `app/components/PayspinLoader.tsx`
- `app/components/ThemeProvider.tsx`
- `app/globals.css`

**Docs**
- `docs/agents/ui-ux-brand-audit.md` (test matrix updated)
- `docs/agents/ui-ux-brand-deep-audit.md` (this report)

---

## Sign-off

The Payspin Brand UI/UX program (Phases 0→D) is **complete for dark-first production** on both platforms. Payer web is **production-ready in dual theme**. Mobile dual theme is **functionally shipped** with known P2 token debt on secondary screens — not blocking dark-mode launch.

*Next recommended action:* run manual QR scan on a physical device, then schedule P1 light-mode migration sprint for onboarding screens.
