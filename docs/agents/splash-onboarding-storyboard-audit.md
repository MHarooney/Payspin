# Splash + Onboarding + Global Theme/Language — Audit

Implementation note for the work specified in
[`splash-onboarding-storyboard-prompt.md`](./splash-onboarding-storyboard-prompt.md).

## P0 — Emblem bug fix (white ring → two open arrows)

**Root cause:** `payspin_emblem_paths.dart` generated the mark from two *closed
cubic loops*, so the painter filled a ring instead of the official two open
arrow paths.

**Fix:**
- Traced the official `Emblem_White-01.png` with `potrace` → SVG, then normalised
  the path data into a `100×100` viewBox via a one-off Python script.
- Replaced `loop()`/`arc()` with filled outline paths `arcFill()` / `loopFill()`
  (the exact mark) plus open center-lines `arcSpine()` / `loopSpine()` used only
  to drive the draw-on reveal.
- Rewrote `_PayspinEmblemPainter` in `payspin_emblem_vector.dart`:
  - Renders the **filled** path (gradient or solid white).
  - Animates by clipping to a growing ribbon built from overlapping discs sampled
    along the spine (replaces a `BlendMode.dstIn` approach that did not work in
    `PictureRecorder`/test contexts).
  - Removed the now-unused `strokeWidth` param.

**Proof:** simulator welcome screen renders the two open arrows (gradient in
light, solid white in dark) — not a ring. See verification below.

## P2 — 5-scene intro storyboard

`lib/presentation/intro/`:
- `payspin_intro_flow.dart` — `PageView` orchestrator, Skip + Next/Get started,
  page-indicator dots, marks `IntroStore.markSeen()` and routes to `/welcome`.
- `scenes/intro_scene_1_bill_to_links.dart` — bill → "PAID" → flying link cards.
- `scenes/intro_scene_2_europe_map.dart` — request envelopes across an EU map.
- `scenes/intro_scene_3_one_tap_pay.dart` — phone UI, tap Pay → success check.
- `scenes/intro_scene_4_value_loop.dart` — Easy / Quick / Free / All over Europe.
- `scenes/intro_scene_5_use_cases.dart` — profession silhouettes light up.
- All scenes honour `MediaQuery.disableAnimations` (reduced motion → static frame).

Persistence + routing:
- `core/onboarding/intro_store.dart` — `SharedPreferences`-backed `hasSeen()` /
  `markSeen()`.
- `app/router.dart` — new `/intro` route, bypasses auth redirect.
- `splash/splash_page.dart` — first launch with no session → `/intro`.

Localized **en / nl / de / ar**.

## P1 — Global theme + language quick settings

- `payspin_quick_settings.dart` — `tune` glass button opening the existing
  appearance + language preference sheets. Uses `PayspinLocalizations.maybeOf`
  so it degrades gracefully when no delegate is present (isolated widget tests).
- Mounted on: welcome, login, home, onboarding shell, send (amount + name via
  `PayspinFlowHeader.showQuickSettings`), scan, link detail, link QR, notifications,
  lock screen.
- Localized hardcoded copy on notifications / scan / send and added the
  corresponding keys for all four locales in `payspin_localizations.dart`.

## P3 — Tests & verification

- `flutter test` → **200 / 200 pass**.
- `flutter analyze lib test` → only pre-existing warnings remain (unused `body`
  in `payspin_theme.dart`, legacy unused imports in `screens_smoke_test.dart` /
  `widgets_test.dart`, `main_driver.dart`, `progress_bar`). No new issues from
  this work.
- New tests: `emblem_paths_test.dart` (paths distinct/open/scaled + painter
  renders without exception), `intro_flow_test.dart` (scene l10n for en/nl/de/ar
  + Skip/Next navigation).
- iOS simulator (mobile-mcp): verified the welcome emblem = two arrows;
  Quick Settings → Appearance → Dark performs a clean cross-fade; gradient
  "Get started" CTA intact; emblem becomes solid white in dark mode.
- Hot restart does not crash `GetIt` (DI guarded in bootstrap).
