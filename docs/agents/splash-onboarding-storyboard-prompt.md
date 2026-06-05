# Payspin — Splash + Onboarding Storyboard Animation (Agent Prompt)

**Use this document as the full implementation brief** for an AI agent (Cursor, Claude Code, etc.) building the Payspin mobile splash, a Wise-style onboarding intro, vector-drawn logo animation, and **app-wide** theme + language controls.

**Skill:** `.cursor/skills/payspin/SKILL.md` + `.claude/skills/payspin-design/SKILL.md`  
**Design prototype:** `resources/Payspin Design System/Payspin Prototype.html`  
**Reference style:** Wise app intro screens — clean, modern, highly visual, short motion loops per scene.

---

## Copy-paste prompt (give this to the agent)

```
You are a senior Flutter engineer + motion designer working on Payspin mobile.

## Goal
Replace the broken splash emblem (currently renders as a white RING — wrong) with a 
**vector-drawn, stroke-animated Payspin logo** matching the official two-arrow emblem,
then build a **5-scene Wise-style intro storyboard** for splash + pre-onboarding,
and wire **theme + language pickers on every major screen** with smooth animated transitions.

## Non-negotiables
- Read docs/agents/splash-onboarding-storyboard-prompt.md (this file) end-to-end first.
- Read CLAUDE.md design section + resources/Payspin Design System/README.md.
- Logo MUST match official assets — NOT hand-guessed closed Bézier loops.
- Use context.psColors / context.l10n on every touched screen — never hardcoded PayspinTokens for text/bg.
- flutter test must pass; verify on iOS simulator via mobile-mcp or dart MCP.
- Minimal diffs; no unrelated refactors.

## Phase A — Fix the logo (root cause of the “ring”)
1. Canonical logo sources (ONLY these):
   - White emblem (dark bg): resources/Payspin Design System/assets/Emblem_White-01.png
     OR mobile/assets/images/payspin_emblem_white.png
   - Gradient emblem (light bg): resources/Payspin Design System/assets/Emblem_Gradient-01.png
     OR mobile/assets/images/payspin_emblem_gradient.png
   - User reference screenshots in workspace assets/ (Emblem_White-01, Emblem_Gradient-01)

2. The bug: mobile/lib/core/design_system/widgets/payspin_emblem_paths.dart uses 
   **closed cubic paths** that render as circles/rings. The real logo is TWO OPEN paths:
   - **Loop path**: diagonal tail bottom-left → large right-hand loop → arrowhead pointing back
   - **Arc path**: upper-left semi-circular arc → arrowhead pointing right
   Both have stroke + triangular arrowheads; gradient runs pink (#FC00FF) → mint (#07D8DD).

3. Fix approach (pick best, document choice):
   a) Export SVG from Figma (QEy9wqxzUbvamVknKwc8Be) → parse to Path via path_drawing package, OR
   b) Trace official PNG in Figma/Illustrator → SVG path data → PayspinEmblemPaths, OR
   c) Use ImageMagick edge trace ONLY as bootstrap, then hand-adjust control points against PNG overlay.

4. Implement in:
   - payspin_emblem_paths.dart — open paths + arrowhead geometry
   - payspin_emblem_vector.dart — stroke trim, gradient shader along path, theme-aware colors
   - payspin_emblem_assemble.dart — splash timing (arc then loop stagger)
   - payspin_emblem_loader.dart — vector spin (optional: separate rotation from draw)

5. Visual QA gate: side-by-side screenshot of vector render vs payspin_emblem_white.png 
   at 104px and 240px. Max deviation: recognizably same logo (two arrows, not a ring).

## Phase B — 5-scene storyboard (splash + onboarding intro)

Map the product script to Flutter scenes. Total intro ≤ 25s skippable; reduced motion = static frame per scene.

| Scene | Script | Flutter implementation |
|-------|--------|------------------------|
| 1 | Bill → Paid → flying link envelopes | `IntroScene1`: paper bill morphs to 3–5 stylized link cards flying upward; emblem draws in center at end |
| 2 | Europe map, DE → NL/ES/FR/AT/CH, money returns | `IntroScene2`: minimalist EU map (CustomPainter), letters fly from DE pin to 5 countries, coin sparks return |
| 3 | Phone, letter lands, one-tap Pay → Success | `IntroScene3`: phone frame mock, Payspin pay link UI, single tap, success check + haptic |
| 4 | Badge cycles Easy → Quick → Free → All over EU | `IntroScene4`: rotating ring or 4 icon chips with cross-fade; brand gradient accent |
| 5 | Photographer / Tradesperson / Freelancer split | `IntroScene5`: 3-panel rapid cut, minimalist line icons |

**Where it lives:**
- `lib/presentation/intro/payspin_intro_flow.dart` — PageView or staged AnimationController
- Splash (`splash_page.dart`): Scene 1 emblem draw + wordmark OR hand off to intro flow
- New route `/intro` after splash for new users (no session); skip → `/welcome`
- Optional: first-launch only via SharedPreferences `payspin_intro_seen`

**Motion tokens:** `PayspinMotion.splashAssemble`, `PayspinMotion.splashMinimum` — extend with `introScene` duration per scene (~4–5s each).

**Localization:** Every scene title/subtitle in `payspin_localizations.dart` (en, nl, de, ar).

## Phase C — Theme + language on ALL screens

### Why user doesn't see it everywhere today
- Pickers exist ONLY on Profile → Settings (`profile_page.dart`).
- Shared sheets exist: `lib/core/preferences/payspin_preferences_sheets.dart`
  (`context.showAppearanceSheet()`, `context.showLanguageSheet()`)
- Many screens still use hardcoded English + `PayspinTokens.textPrimary` (dark-only).
- No global app-bar affordance — user must navigate to Profile.

### Required fix
1. Create `PayspinQuickSettings` widget (glass icon button → bottom sheet with Appearance + Language).
2. Mount on EVERY top-level screen app bar / header:
   - welcome_page, login_page, home_page header, main_shell, onboarding shell,
     send_*, scan_qr, link_detail, link_qr, notifications, lock_screen (post-unlock), profile
3. Migrate remaining screens to `context.psColors` (grep `PayspinTokens.text` — 15+ files).
4. Expand `payspin_localizations.dart` for onboarding, send, scan, lock, link detail, circles.
5. Keep `PayspinThemeTransition` in app.dart; ensure new scenes use `context.psColors.bg`.

## Phase D — Testing (mandatory)

```bash
cd mobile
flutter pub get
flutter analyze lib/presentation/intro lib/core/design_system/widgets/payspin_emblem*
flutter test
flutter run --dart-define=API_URL=http://localhost:3001/v1  # iOS simulator
```

**Simulator QA checklist:**
- [ ] Splash shows TWO-ARROW emblem drawing (not a ring)
- [ ] Dark theme: white emblem; light theme: gradient emblem
- [ ] Tap splash skips; intro skip works
- [ ] All 5 intro scenes play with correct copy in EN; switch to NL/DE/AR — copy updates
- [ ] Appearance sheet reachable from Home, Welcome, Onboarding — smooth color cross-fade
- [ ] Language sheet reachable from same screens — RTL for Arabic
- [ ] Hot restart (`R`) — no GetIt crash (configureDependencies resets GetIt)

**MCP:** Use `user-mobile-mcp` or `project-0-Payspin-dart` to run analyzer; capture simulator screenshots for before/after.

## Deliverables
- Fixed vector emblem paths + screenshot proof vs official PNG
- `payspin_intro_flow.dart` + 5 scene widgets
- Router + first-launch persistence
- `PayspinQuickSettings` on all major screens
- l10n strings for all new copy
- Tests: emblem painter, intro smoke, l10n scene strings
- Short audit note in docs/agents/splash-onboarding-storyboard-audit.md
```

---

## Why the current splash looks like a ring (diagnosis)

| What you see | Root cause |
|--------------|------------|
| White circle/ring on black | `PayspinEmblemPaths.arc()` and `.loop()` are **closed** cubic curves that loop back to their start point |
| Not the Payspin logo | Real logo = **two open strokes** with **arrowheads** (see Emblem_White-01 / Emblem_Gradient-01) |
| PNG split layers were better | Previous PNG arc/loop assets (`payspin_emblem_arc_white.png`, etc.) were closer; vector paths were hand-guessed incorrectly |

**Correct logo anatomy (from official assets):**

1. **Main loop (lower/right):** Straight diagonal from bottom-left → curves into large right loop → ends with **left-pointing arrowhead**
2. **Upper arc (top/left):** Semi-circular arc → ends with **right-pointing arrowhead**
3. **Colors:** White on dark (`#FFFFFF`); gradient pink→mint on light (`#FC00FF` → `#07D8DD`)
4. **Stroke:** Thick, round caps, consistent weight

---

## Official logo asset map

| Asset | Path |
|-------|------|
| White emblem (canonical) | `resources/Payspin Design System/assets/Emblem_White-01.png` |
| Gradient emblem (canonical) | `resources/Payspin Design System/assets/Emblem_Gradient-01.png` |
| Mobile white | `mobile/assets/images/payspin_emblem_white.png` |
| Mobile gradient | `mobile/assets/images/payspin_emblem_gradient.png` |
| Split layers (fallback) | `mobile/assets/images/payspin_emblem_arc_*.png`, `payspin_emblem_loop_*.png` |
| **Wrong file to tune** | `mobile/lib/core/design_system/widgets/payspin_emblem_paths.dart` |

---

## Existing code the agent must extend (not rewrite blindly)

| File | Today |
|------|-------|
| `splash_page.dart` | Emblem assemble + wordmark + route to welcome/home |
| `payspin_emblem_vector.dart` | CustomPainter stroke trim (paths wrong) |
| `payspin_motion.dart` | `splashAssemble` 2.4s, `splashMinimum` 5.2s |
| `payspin_preferences_sheets.dart` | `showAppearanceSheet` / `showLanguageSheet` |
| `payspin_localizations.dart` | Partial — welcome, home, nav, QR, profile only |
| `app.dart` | `ListenableBuilder` + `PayspinThemeTransition` + locale delegates |

---

## 5-scene script → UX copy (localize all)

### Scene 1 — Introduction
- **Headline:** Split bills without the friction
- **Body:** Turn any invoice into a payment link — free, instant, across Europe
- **Motion:** Bill → PAID stamp → envelopes fly; emblem stroke-draw completes

### Scene 2 — Pan-European network
- **Headline:** Request across borders
- **Body:** Send from Germany. Get paid in the Netherlands, France, Spain, and more
- **Motion:** Map pins + flying letters + return sparks

### Scene 3 — One-click payoff
- **Headline:** Paid in one tap
- **Body:** Recipients pay from their own bank — no app install, no signup
- **Motion:** Phone + Pay CTA + success flash

### Scene 4 — Value loop
- **Headline:** Easy. Quick. Free. All over Europe.
- **Body:** The simplest way to settle small debts
- **Motion:** Rotating badge cycling four words/icons

### Scene 5 — Universal use cases
- **Headline:** Built for everyone
- **Body:** Photographers, tradespeople, freelancers — anyone who needs to get paid
- **Motion:** Three profession silhouettes, fast cuts

---

## Theme + language — architecture the agent must finish

```
MaterialApp.router
  └─ ListenableBuilder(theme + locale)
       └─ PayspinThemeTransition
            └─ [each screen]
                 ├─ context.psColors.*   ← semantic colors (light/dark)
                 ├─ context.l10n.*       ← en / nl / de / ar
                 └─ PayspinQuickSettings   ← NEW: sun/globe icon in header
```

**Screens still missing quick settings (must add):**

- `welcome_page.dart`, `login_page.dart`, `home_page.dart` (header row)
- `payspin_onboarding_shell.dart` (all onboarding steps)
- `send_amount_page.dart`, `send_name_page.dart`, `scan_qr_page.dart`
- `link_detail_page.dart`, `link_qr_page.dart`, `notifications_page.dart`

**Screens still using `PayspinTokens.text*` (must migrate to `context.psColors`):**

Run: `rg "PayspinTokens\.(text|bg)" mobile/lib/presentation mobile/lib/core/design_system`

---

## How to extract accurate vector paths (recommended workflow)

1. Open Figma brand file or place `Emblem_White-01.png` on canvas
2. Pen-tool trace **centerline** of each stroke (not outline)
3. Export SVG path `d="..."` for `loop` and `arc`
4. Add `path_drawing` to `pubspec.yaml` if using SVG import:
   ```yaml
   path_drawing: ^1.0.1
   ```
5. Parse into `Path` objects in `PayspinEmblemPaths`
6. Add arrowheads as small `Path.lineTo` triangles at path end (tangent-aligned)
7. Unit test: render to `PictureRecorder` → compare bounding box + path length ratio vs PNG

**Fallback if SVG blocked:** Overlay PNG at 50% opacity in a dev-only `EmblemDebugPage` while tuning Bézier points.

---

## Testing protocol (mobile-mcp / dart MCP)

| Step | Command / action |
|------|------------------|
| Analyzer | `flutter analyze` on touched paths |
| Unit | `flutter test test/theme_and_loader_test.dart test/l10n_test.dart` |
| Emblem | New test: `payspin_emblem_vector_test.dart` — path length > 0, not closed loop |
| Simulator | `flutter run` → device `iPhone 17 Pro` |
| Screenshot | Capture splash + scene 1 + theme toggle + language NL |
| Hot restart | Press `R` — confirm no `LocaleController` GetIt error |
| Reduced motion | iOS Settings → Accessibility → Reduce Motion → static emblem |

**Acceptance:** User reference image 2/3 (two-arrow emblem) matches simulator screenshot within brand tolerance.

---

## Suggested file tree (new)

```
mobile/lib/
  presentation/intro/
    payspin_intro_flow.dart
    scenes/
      intro_scene_1_bill_to_links.dart
      intro_scene_2_europe_map.dart
      intro_scene_3_one_tap_pay.dart
      intro_scene_4_value_loop.dart
      intro_scene_5_use_cases.dart
  core/design_system/widgets/
    payspin_quick_settings.dart
    payspin_emblem_paths.dart      # FIX paths here
    payspin_emblem_vector.dart
  core/l10n/
    payspin_localizations.dart     # add scene strings
```

---

## Priority order for the agent

1. **P0** — Fix emblem paths (ring → real logo) — blocks everything else
2. **P1** — `PayspinQuickSettings` on all major screens + finish l10n/psColors migration
3. **P2** — Intro flow scenes 1–5 + router + first-launch flag
4. **P3** — Polish motion, haptics, reduced-motion, audit doc

---

## Related docs

- [ui-ux-brand-enhancement-prompt.md](ui-ux-brand-enhancement-prompt.md) — brand tokens, glass, QR
- [ui-ux-brand-master-plan.md](ui-ux-brand-master-plan.md) — phased program
- [mobile-ui-ux-enhancement-prompt.md](mobile-ui-ux-enhancement-prompt.md) — screen-by-screen UI
