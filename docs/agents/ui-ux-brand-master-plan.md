# Payspin — Brand UI/UX master plan (Phases 0→D)

**Date:** 2026-06-05
**Author:** Brand UI/UX program (agent)
**Source prompt:** [ui-ux-brand-enhancement-prompt.md](ui-ux-brand-enhancement-prompt.md)
**Companion audit:** [ui-ux-brand-audit.md](ui-ux-brand-audit.md)
**Tagline (exact):** *"Your money, your community, and your peace of mind."*

> Single source of truth for the unified brand UI/UX program across **mobile (Flutter)** and **payer web (Next.js)**. Implemented as one continuous pass: 0 → A → B → C → D → tests → report.

---

## 1. Executive summary

- **Scope:** Real transparent emblem pipeline, dual light/dark theme wiring (currently dark-locked), glassmorphism adoption, gradient-emblem branded QR, listed-screen migration to semantic colors, signature motion with reduced-motion fallbacks — mobile + payer web.
- **Biggest risks:** Light-theme WCAG contrast on ~22 migrated screens; Android blur performance with `PayspinGlassSurface`; QR scannability with gradient center; large Phase B diff surface.
- **Estimated files touched:** ~45–55 (mobile ~35, web ~12, docs/assets ~8).
- **Theme strategy:** Register `PayspinSemanticColors` as a `ThemeData` extension on both `PayspinTheme.dark()`/`.light()`; drive `MaterialApp.themeMode` from `ThemeModeController` (persisted). Web: `[data-theme]` + `ThemeProvider`.
- **Motion approach:** **Bitmap** (`Transform.rotate` + scale/opacity) for mobile loaders/splash and **CSS keyframes** for web — no Lottie/SVG vector this pass (vector deferred, documented in §3). Crisp at @3x source (1067px).

---

## 2. Logo asset audit table

| File | Format (actual) | Alpha | Trim needed | Action |
|------|-----------------|-------|-------------|--------|
| `mobile/assets/images/payspin_emblem_white.png` (in-repo) | **JPEG renamed .png**, 1024² | **No** | n/a | **Replace** with real source |
| `mobile/assets/images/payspin_emblem_gradient.png` (in-repo) | **JPEG renamed .png**, 1024² | **No** | n/a | **Replace** with real source |
| `frontend/public/payspin-emblem-white.png` (in-repo) | **JPEG renamed .png**, 1024² | **No** | n/a | **Replace** with real source |
| `frontend/public/payspin-emblem-gradient.png` (in-repo) | **JPEG renamed .png**, 1024² | **No** | n/a | **Replace** with real source |
| `~/Downloads/my-signature_files/Emblem_White-01.png` (source) | **PNG-24 RGBA**, 1067² | **Yes** | trim + 8% pad | Process → repo (white) |
| `~/Downloads/my-signature_files/Emblem_Gradient-01.png` (source) | **PNG-24 RGBA**, 1067² | **Yes** | trim + 8% pad | Process → repo (gradient + QR center) |
| `mobile/assets/images/payspin_ic_opaque.png` (legacy) | PNG opaque | No (intended) | no | Keep for launcher |

Verified visually: gradient = pink→cyan interlocking "spin" arrows on transparent bg; white = transparent white silhouette. Both clean, no halo.

---

## 3. Asset pipeline decisions

- **Tooling:** `brew install imagemagick` (approved). Use `convert -trim +repage -bordercolor none -border 8%` then resize to 1024² PNG-24 with alpha.
- **Export paths:**
  - `mobile/assets/images/payspin_emblem_white.png`, `payspin_emblem_gradient.png` (single high-res; Flutter scales via `BoxFit.contain`).
  - `frontend/public/payspin-emblem-white.png`, `payspin-emblem-gradient.png`.
- **QR variant:** Use the gradient emblem as QR center at ~19% width with white safe-padding plate; only export a bolder `*_qr` variant if a device scan fails (decision: **start without**, add if T0b fails).
- **SVG / CustomPainter:** **Deferred.** Bitmap `Transform.rotate` on the gradient emblem is explicitly acceptable per spec and is crisp at 1067px source. Documented as a known follow-up.
- **Launcher:** Keep existing opaque `payspin_ic_opaque.png` (iOS strips alpha); no change.
- **pubspec:** Register both emblem PNGs in `mobile/pubspec.yaml` `flutter.assets` (currently missing → runtime crash for mark variant).

---

## 4. UX task map

| Task | Current taps | Target | Screen fixes |
|------|--------------|--------|--------------|
| Payee: create link | Home → FAB → amount → name/label → share (≤4) | ≤4 | FAB already prominent; keep one CTA per step |
| Payee: show QR | Link detail → Show QR (2) | ≤2 | Already 2; add QR plate scale-in only |
| Payer: pay link | Open URL → Pay (2) | ≤2 | Keep single CTA; never block CTA with motion |
| Onboarding | Welcome → name → phone → otp → iban → connect (linear) | linear + progress | `PayspinOnboardingShell` already shows progress; verify on all steps |
| Scan QR | Bottom nav tab → camera (1) | ≤1 | Bottom nav present |
| Change theme | (none today) | ≤2: Profile → Appearance | Add Appearance row + System/Dark/Light selector |

Usability heuristics enforced: one primary gradient CTA/screen; human-readable errors; ≥44pt touch targets; AA contrast both themes; reduced-motion honored; splash skippable.

---

## 5. Animation storyboard

| Screen | Trigger | Animation | Duration | Reduced motion |
|--------|---------|-----------|----------|----------------|
| Splash | App open | Emblem opacity 0→1 + scale 0.85→1, wordmark fade-up | ≤1200ms, skippable | Instant emblem |
| Welcome | Enter | Fade up + 8px slide | 400ms | Static |
| Loader (API wait) | Pending | Gradient emblem `Transform.rotate` 360° linear | 2400ms loop | Static emblem + progress |
| Primary button | Press / loading | Scale 0.97 (100ms) + haptic; loading mini-spinner | 100ms / loop | Opacity only |
| Pay/link success | Success | Emblem scale 0→1.1→1.0 spring + mint check draw | 400ms | Instant check |
| QR screen | Open | Plate scale 0.92→1 ease-out | 350ms | Instant |
| Web loader | Pending | CSS `payspin-spin` on emblem | 800ms loop | 2s slow |
| Web FAQ | Toggle | height + opacity ease | 280ms | No transition |
| Web page | Route enter | shell fade + 12px translateY | 300ms | None |

Motion tokens: `motionFast` 200, `motionMedium` 350, `motionSlow` 600, `motionLoop` 2400; `easeEnter` easeOutCubic, `easeExit` easeInCubic, `stagger` 60–80ms.

---

## 6. Theme map

**Mobile**
- `PayspinSemanticColors` (dark+light, already defined) registered via `extensions:` on `PayspinTheme.dark()`/`.light()`.
- `ThemeModeController` (shared_preferences key `payspin_theme_mode`) in DI; `MaterialApp.router` driven by `ListenableBuilder` → `theme: light()`, `darkTheme: dark()`, `themeMode: controller.mode`.
- Toggle location: Profile → Appearance (System | Dark | Light).
- `bootstrap.dart` `SystemChrome` overlay follows resolved brightness.
- Logo: `PayspinLogo(style: auto)` → white on dark, gradient on light.

**Web**
- `globals.css`: keep `:root`/`[data-theme="dark"]` dark vars; add `[data-theme="light"]` block (`--ps-bg #F9F9F9`, `--ps-bg-elevated #FFFFFF`, glass white@72%, border black@8%, text `#0A0D13`).
- `ThemeProvider.tsx`: localStorage + `prefers-color-scheme`, sets `data-theme` on `<html>`; toggle in header/footer.
- `PayspinEmblem.tsx`: swaps white↔gradient by theme; header uses it instead of legacy `/payspin-logo.png`.

---

## 7. Screen migration checklist (Phase B)

| Screen / route | Semantic colors | Glass | Logo | Motion | Done |
|----------------|-----------------|-------|------|--------|------|
| `splash_page` | ☐ | — | ☐ | ☐ | ☐ |
| `welcome_page` | ☐ | ☐ | ☐ | ☐ | ☐ |
| `login_page` | ☐ | ☐ | ☐ | — | ☐ |
| onboarding `step_name/phone/otp/iban/connect_bank` + shell | ☐ | ☐ | — | — | ☐ |
| `home_page` | ☐ | ☐ | ☐ | — | ☐ |
| `main_shell` + `payspin_bottom_nav` | ☐ | ☐ | — | — | ☐ |
| send `send_amount` / `send_name` (+label) | ☐ | ☐ | — | ☐ | ☐ |
| `link_detail_page` / `link_qr_page` | ☐ | ☐ | ☐ | ☐ | ☐ |
| `profile_page` (+ Appearance) | ☐ | ☐ | — | — | ☐ |
| `scan_qr_page` | ☐ | ☐ | — | — | ☐ |
| `notifications_page` | ☐ | ☐ | — | — | ☐ |
| `lock_screen` | ☐ | ☐ | ☐ | ☐ | ☐ |
| payer `/{code}`, `callback/*`, `success`, landing | ☐ | ☐ | ☐ | ☐ | ☐ |

---

## 8. File checklist (all phases)

**Create**
- `docs/agents/ui-ux-brand-master-plan.md` (this file)
- `mobile/lib/core/design_system/theme/payspin_motion.dart`
- `mobile/lib/core/design_system/widgets/payspin_emblem_loader.dart`
- `frontend/app/components/ThemeProvider.tsx`
- `frontend/app/components/PayspinEmblem.tsx`
- `frontend/app/components/PayspinLoader.tsx`
- mobile test(s): theme + loader (extend existing `branded_qr_test.dart`)

**Modify (mobile)**
- `mobile/pubspec.yaml` (assets)
- `theme/payspin_theme.dart` (light() + extensions), `app/app.dart`, `app/di/injection.dart`, `bootstrap.dart`
- `widgets/payspin_branded_qr.dart` (gradient emblem), `widgets/payspin_gradient_pill_button.dart` (press scale + mini spinner)
- Presentation: splash, welcome, login, onboarding steps + shell, home, main_shell, bottom_nav, send_amount, send_name, link_detail, link_qr, scan_qr, notifications, profile, lock_screen
- Replace 4 emblem image files (assets)

**Modify (web)**
- `app/globals.css`, `app/layout.tsx`, `components/WebShell.tsx`, `PayspinHeader.tsx`, `PayspinFooter.tsx`, `FaqAccordion.tsx`, `[code]/page.tsx`, `[code]/pay-button.tsx`, `[code]/callback/*`, `[code]/success/page.tsx`, `page.tsx`
- Replace 2 emblem image files (public)

**Docs**
- `docs/agents/ui-ux-brand-audit.md` (gaps → shipped)

---

## 9. Test plan (T0–T10)

| ID | Scenario | Command / method |
|----|----------|------------------|
| T0 | Logo alpha on dark + light bg | `identify -format '%A'` + compose preview |
| T0b | QR scan after emblem overlay | Manual device 30cm (note if no device) |
| T1 | Logo widget loads both variants | `flutter test` |
| T2 | Theme persistence | controller unit/widget test; manual kill-reopen note |
| T3 | Light theme WCAG AA body text | contrast check on tokens |
| T4 | Splash ≤1.2s skippable | code review + manual |
| T5 | Loader respects reduced motion | `MediaQuery.disableAnimations` test |
| T6 | Glass scroll 60fps | manual profile note |
| T7 | Payer web theme + emblem swap | browsermcp dark+light |
| T8 | Core task tap counts | manual script (§4) |
| T9 | `flutter analyze` clean | analyze on touched dirs |
| T10 | No animation blocks pay CTA | browsermcp pay flow |

---

## 10. Risks & mitigations

| Risk | Mitigation |
|------|------------|
| JPEG-fake emblems (no alpha) | Replace with verified RGBA sources (done in Phase 0) |
| Light-theme contrast regressions | Use semantic text tokens; spot-check AA per migrated screen |
| Android blur perf | Cap blur 18–24σ; no glass on list rows; reuse `PayspinGlassSurface` |
| QR scannability | EC level H + gradient center ≤19%; device/manual scan; bolder variant fallback |
| Large Phase B diff | Scope strictly to listed screens + shared shells; minimal diffs |
| Theme rebuild fllicker | `ListenableBuilder` around `MaterialApp.router`; persisted mode loaded pre-runApp |

---

## Status log

- 2026-06-05: Plan written. Proceeding 0→A→B→C→D in one pass.
