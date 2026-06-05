# Payspin — Brand UI/UX master prompt (Phases 0→D, plan + implement end-to-end)

> **This is the only prompt you need.** Everything else is supporting context the agent should read automatically when you paste the master block below.

---

## Which prompt to use

| Goal | What to paste in chat |
|------|------------------------|
| **Full brand UI/UX overhaul** (logos, themes, glass, QR, motion, usability) — **plan + implement all phases** | **Master block below** ⬇️ |
| Baseline gaps only (read-only context) | `@docs/agents/ui-ux-brand-audit.md` — *do not use alone* |
| Payer web-only polish (already mostly done) | `@docs/agents/payer-web-ui-enhancement-prompt.md` — subset of this master |
| Repo architecture / ports / workflows | `@AGENTS.md` — always loaded in Cursor rules |

### Master block — copy-paste this entire message

```
@docs/agents/ui-ux-brand-enhancement-prompt.md
@docs/agents/ui-ux-brand-audit.md
@AGENTS.md

Execute the Payspin Brand UI/UX master workflow end-to-end:

1. PLAN — Produce docs/agents/ui-ux-brand-master-plan.md (unified Phase 0→D plan:
   logo audit table, asset pipeline, UX tap-count map, animation storyboard,
   screen migration list, file checklist, risks). Show me the plan summary, then continue.

2. IMPLEMENT — All phases in order (0→A→B→C→D) in one session without stopping
   after Phase A. Do not ask for permission between phases unless blocked.

3. TEST — Run the full test matrix (T0–T10): flutter test, flutter analyze on touched
   files, payer web browser smoke, QR scan note if no device.

4. REPORT — Final summary: what shipped per phase, screenshots checklist, known gaps.

Constraints: ease of use over decoration; reduced-motion fallbacks; minimal diffs;
no commit unless I ask. Attach user emblems Emblem_White-01 + Emblem_Gradient-01 if missing from repo.
```

### Optional context (attach when relevant)

| Attachment | When |
|------------|------|
| `@.cursor/skills/payspin/SKILL.md` | Local dev, builds, deploy |
| `@resources/Payspin Design System/README.md` | Token / voice questions |
| `@resources/Payspin Design System/Payspin Prototype.html` | Screen layout parity |
| `@docs/agents/mobile-ui-audit.md` | Per-screen Flutter gaps |
| User emblem PNGs | Logo processing STEP 0 |

---

**Purpose:** Single source of truth for upgrading **Payspin visual design** across **mobile (Flutter)** + **payer web (Next.js)**: transparent emblems, **light + dark themes**, **glassmorphism**, **branded QR**, **logo motion**, and **effortless UX** — planned and implemented as **one cohesive program** (Phases 0 through D).

**Tagline (exact):** *"Your money, your community, and your peace of mind."*

---

## Unified workflow (mandatory — do not split across sessions)

The agent runs **one continuous program**. Phase boundaries are for organization, not stop points.

```
┌─────────────┐    ┌──────────────────────────────────────────────────┐
│  PLAN FIRST │ →  │  ui-ux-brand-master-plan.md (all phases at once) │
└─────────────┘    └──────────────────────────────────────────────────┘
         │
         ▼
┌────┐   ┌────┐   ┌────┐   ┌────┐   ┌────┐
│ 0  │ → │ A  │ → │ B  │ → │ C  │ → │ D  │  →  TEST MATRIX  →  REPORT
└────┘   └────┘   └────┘   └────┘   └────┘
 audit   foundation  screens  motion  harden
```

| Step | Action | Stop? |
|------|--------|-------|
| **1. Plan** | Write `docs/agents/ui-ux-brand-master-plan.md` using [Master plan template](#master-plan-template-required-output) | Pause only to show summary if user asked; otherwise continue |
| **2. Phase 0** | Logo detect/process; UX audit tables; update audit doc findings | No |
| **3. Phase A** | Tokens, themes, logo widget, glass, QR, payer web theme | No |
| **4. Phase B** | Migrate all high-traffic screens; usability fixes | No |
| **5. Phase C** | Splash, loader, button loading, success motion; reduced motion | No |
| **6. Phase D** | Tests, analyze, performance sanity, doc sync | No |
| **7. Verify** | Full [test matrix](#test-matrix-mandatory) | Done |

**Do not** treat Phase A as “done enough” and stop. **Do not** defer motion to a future PR unless physically blocked (document blocker in plan).

---

## Master plan template (required output)

Before writing production UI code, create **`docs/agents/ui-ux-brand-master-plan.md`** with these sections:

### 1. Executive summary (5 bullets)
- Scope, biggest risks, estimated files touched, theme strategy, motion approach (bitmap vs vector)

### 2. Logo asset audit table
| File | Format | Alpha | Trim needed | Action |
|------|--------|-------|-------------|--------|

### 3. Asset pipeline decisions
- Export paths, QR variant yes/no, SVG/CustomPainter yes/no, fallback if vector deferred

### 4. UX task map
| Task | Current taps | Target | Screen fixes |

### 5. Animation storyboard
| Screen | Trigger | Animation | Duration | Reduced motion |
|--------|---------|-----------|----------|----------------|

### 6. Theme map
- Mobile: `PayspinSemanticColors`, toggle location, system UI
- Web: CSS vars, `data-theme`, emblem swap rules

### 7. Screen migration checklist (Phase B)
Check every row — mobile + frontend:

| Screen / route | Semantic colors | Glass | Logo | Motion | Done |
|----------------|-----------------|-------|------|--------|------|
| `welcome_page` | ☐ | ☐ | ☐ | ☐ | ☐ |
| `login_page` | ☐ | ☐ | ☐ | ☐ | ☐ |
| onboarding steps 1–5 | ☐ | ☐ | ☐ | ☐ | ☐ |
| `home_page` | ☐ | ☐ | ☐ | ☐ | ☐ |
| send flow | ☐ | ☐ | ☐ | ☐ | ☐ |
| `link_detail_page` / `link_qr_page` | ☐ | ☐ | ☐ | ☐ | ☐ |
| `profile_page` | ☐ | ☐ | ☐ | ☐ | ☐ |
| `scan_qr_page` | ☐ | ☐ | ☐ | ☐ | ☐ |
| payer `/{code}`, callback, success | ☐ | ☐ | ☐ | ☐ | ☐ |

### 8. File checklist (all phases)
- List every file to create/modify (from [File map](#file-map-implementation-target))

### 9. Test plan
- Map T0–T10 to commands and manual steps

### 10. Risks & mitigations
- JPEG logos, blur perf on Android, QR scannability, theme contrast

---

## Agent mandate

1. **Write master plan** (`ui-ux-brand-master-plan.md`) covering **all phases 0→D** before UI code.
2. **Implement sequentially** 0 → A → B → C → D in the **same session**.
3. **Migrate screens holistically** — when touching a flow (e.g. onboarding), migrate **all steps** in that flow, not one file.
4. **Test** full matrix before reporting done.
5. **Do not commit** unless user asks; never commit secrets.

**Creative bar:** Premium fintech — glass with restraint, pink→mint energy, logo motion that sells “spin” without circus effects.

**Usability bar:** Beauty never adds steps. One primary CTA per screen. Animations ≤ 600 ms for transitions; loaders loop calmly.

---

## References (agent reads automatically via master block)

| What | Path / link |
|------|-------------|
| **Baseline audit (companion)** | [ui-ux-brand-audit.md](ui-ux-brand-audit.md) |
| **Master plan output** | `docs/agents/ui-ux-brand-master-plan.md` *(agent creates)* |
| **Design system README** | `resources/Payspin Design System/README.md` |
| **Interactive prototype** | [Payspin Prototype.html](https://claude.ai/design/p/0e804e64-9500-4d7e-9fb9-598d971d0b82?file=Payspin+Prototype.html) |
| **Local prototype** | `resources/Payspin Design System/Payspin Prototype.html` |
| **Brand logo preview** | `resources/Payspin Design System/preview/brand-logos.html` |
| **Flutter token map** | `resources/docs/design-system-flutter-map.md` |
| **Mobile gap analysis** | `docs/agents/mobile-ui-audit.md` |
| **Payer web (subset)** | [payer-web-ui-enhancement-prompt.md](payer-web-ui-enhancement-prompt.md) — already partially shipped |
| **Source emblems (user)** | `Emblem_White-01.png`, `Emblem_Gradient-01.png` |
| **Target mobile assets** | `mobile/assets/images/payspin_emblem_{white,gradient}.png` |
| **Target web assets** | `frontend/public/payspin-emblem-{white,gradient}.png` |

**Tagline (exact):** *"Your money, your community, and your peace of mind."*

---

## Agent mandate (detail)

1. **STEP 0 — Audit** logo files, motion opportunities, usability — populate master plan §2–§5.
2. **Implement** Phases 0→D per [Unified phase spec](#unified-phase-spec-0d).
3. **Update** `ui-ux-brand-audit.md` executive summary when done (gap → shipped).
4. **Test** [Test matrix](#test-matrix-mandatory).
5. **Do not commit** unless user asks.

---

## STEP 0 — Logo detection & asset pipeline (mandatory before UI work)

The Payspin emblem is two interlocking curved arrows (P/S spin metaphor). Source files may be JPEG, wrong extension, or non-transparent backgrounds — **detect and fix before wiring UI**.

### 0.1 Detect (automated + visual)

For each source file (`Emblem_White-01`, `Emblem_Gradient-01`, legacy `payspin_ic*.png`):

| Check | Tool / method | Pass criteria |
|-------|---------------|---------------|
| Real format | `file`, `identify -verbose` (ImageMagick) | Know PNG vs JPEG vs WebP |
| Alpha channel | `identify -format '%A'` | Transparent background for UI overlays |
| Dimensions & DPI | metadata | Square ≥ 512 px; note @2x/@3x exports |
| Bounding box | trim preview (`-trim +repage`) | No excess padding > 8% of canvas |
| Background bleed | visual on `#0B0B12` and `#FFFFFF` | No visible box/halo |
| Gradient integrity | sample edge pixels | Gradient emblem: pink left → cyan right |

**Document findings** in the audit doc or PR plan (table per file).

### 0.2 Cut, clean, export (professional asset pass)

If detection fails any pass criteria, **process assets** (do not ship raw uploads):

1. **Remove background** — Figma/Photoshop or `rembg`/ImageMagick flood-fill; verify on both theme backgrounds.
2. **Crop to content** — trim transparent bounds; keep **8% safe padding** for glow/shadow in animations.
3. **Re-export PNG-24 with alpha** — `@1x` 256, `@2x` 512, `@3x` 1024 into:
   - `mobile/assets/images/payspin_emblem_white.png`
   - `mobile/assets/images/payspin_emblem_gradient.png`
   - `frontend/public/` mirrors
4. **QR variant** — optional `payspin_emblem_gradient_qr.png` with slightly bolder strokes if scan tests fail at small sizes.
5. **Launcher only** — keep opaque square `payspin_ic_opaque.png` for app icon (iOS removes alpha).

### 0.3 Optional — vectorize / layer split for animation

For **professional logo animation**, prefer **drawn vectors** over spinning a flat bitmap:

| Approach | When | Output |
|----------|------|--------|
| **SVG paths** | Web payer loading, CSS motion | `frontend/public/payspin-emblem.svg` with separate paths for upper arc + lower loop |
| **Figma export** | Source of truth | Two layers: `arrow-top`, `arrow-loop` |
| **Flutter CustomPainter** | Mobile splash / loader | `PayspinEmblemPainter` tracing same geometry as PNG |
| **Lottie** | Only if complex orchestration | `assets/lottie/payspin_spin.json` — keep < 80 KB |

**Layer split guidance (from brand geometry):**

- **Layer A — upper arc:** short arrow, rotates ~15° or slides in from left (200 ms).
- **Layer B — lower loop:** larger sweep, continuous **360° spin** at 2–3 s/rotation for loaders OR single 180° ease for splash reveal.
- **Together:** stagger 80 ms — upper leads, loop follows (“transaction flow”).

If vectorizing is out of scope for a phase, use **bitmap + `Transform.rotate`** on gradient emblem for loaders — still acceptable if crisp @3x.

### 0.4 Logo usage rules (after asset pass)

| Variant | Asset | When |
|---------|-------|------|
| White emblem | `payspin_emblem_white.png` | Dark theme surfaces |
| Gradient emblem | `payspin_emblem_gradient.png` | Light theme, QR centre, marketing |
| Auto | theme-aware widget | Default — `PayspinLogo(style: auto)` |
| Animated | vector painter / Lottie / CSS | Splash, loading, empty states only |

**Never:** stretch, add drop-shadow that changes brand colors, or animate on every screen (motion fatigue).

---

## STEP 0 — Usability & “easy to use” audit

Before visual polish, map **core tasks** and score each screen:

| Task | Ideal path | Max taps | Must be obvious |
|------|------------|----------|-----------------|
| Payee: create link | Home → FAB → amount → share | ≤ 4 | FAB visible on home |
| Payee: show QR | Link detail → Show QR | ≤ 2 | QR on link screen |
| Payer: pay link | Open URL → Pay | ≤ 2 | Amount + one CTA |
| Onboarding | Welcome → phone → OTP → done | linear | Progress indicator |
| Scan QR | Tab → camera | ≤ 1 | Bottom nav |

**Heuristics to enforce in every phase:**

- **One primary action** per screen (gradient pill); secondary actions text-only or glass ghost.
- **Progress visible** on multi-step flows (onboarding, send, bank connect).
- **Errors human-readable** — no raw Firebase/API strings; recovery button always visible.
- **Touch targets** ≥ 44×44 pt (mobile), ≥ 48 px (web).
- **Contrast** WCAG AA for body text in both themes.
- **Reduce motion** — honor `MediaQuery.disableAnimations` / `prefers-reduced-motion: reduce` (static logo, no spin).
- **No animation blocking input** — splash max 1.2 s skippable; loaders don’t cover CTAs.

Document gaps in plan; fix usability **before** decorative glass on broken flows.

---

## Non-negotiables

1. [AGENTS.md](../../AGENTS.md), [architecture.md](architecture.md), design skill `.cursor/skills/payspin-design/SKILL.md`.
2. Complete **STEP 0 logo pipeline** before wiring logos into screens.
3. **Theme rules** — `PayspinSemanticColors` / `context.psColors`; no new hardcoded dark bg in touched files.
4. **Glass rules** — `PayspinGlassSurface` (blur + fill + border); no flat gray boxes.
5. **QR rules** — EC level H, gradient emblem centre, device scan verification.
6. **Motion rules** — see [Motion design system](#motion-design-system); reduced-motion fallback mandatory.
7. **Usability rules** — see STEP 0; never add steps for aesthetics.
8. **Minimal diffs** — no unrelated refactors.

---

## Logo system — placement map

| Surface | Logo | Size | Animation (if any) |
|---------|------|------|---------------------|
| Splash | white + glow | 96–110 px | Layer reveal or gentle spin (once) |
| Welcome | white / gradient by theme | 110 px | Fade up + 8 px slide (400 ms) |
| Loading / API wait | gradient | 40–48 px | Slow spin or pulse glow |
| App header | theme auto | 28–32 px | None |
| Lock screen | white | 64 px | Subtle breathe scale 1→1.04 |
| Pay success | gradient | 48 px | Scale bounce + mint flash |
| QR centre | gradient | ~19% QR width | None (static) |
| Payer web header | theme swap | 28 px | None |
| Empty states | gradient | 64 px | Optional idle float ±4 px |

---

## Dual theme architecture

### Mobile

```
PayspinSemanticColors (dark | light)
ThemeModeController → Profile → Appearance: System | Dark | Light
PayspinTheme.dark() / .light() + ThemeExtension
PayspinApp: theme, darkTheme, themeMode
SystemChrome overlay follows brightness
```

### Payer web

```css
:root, [data-theme="dark"] { --ps-bg: #0B0B12; … }
[data-theme="light"]  { --ps-bg: #F9F9F9; … }
```

`ThemeProvider`: `localStorage`, `prefers-color-scheme`, toggle in header/footer.

### Logo swap by theme

- Dark → white emblem PNG/SVG  
- Light → gradient emblem PNG/SVG  
- Implement via CSS `[data-theme]` display swap or Flutter `PayspinLogo(style: auto)`

---

## Glassmorphism components

Professional glass = **blur (18–24σ) + translucent fill + 1 px hairline border + optional brand glow**.

```dart
PayspinGlassSurface(
  borderRadius: 16,
  padding: EdgeInsets.all(16),
  glow: true,
  blur: 20,
  child: …,
)
```

**Anti-patterns:** opaque white cards on dark bg; blur > 30σ; glass on every list row (performance + noise).

---

## Motion design system

### Principles

1. **Brand metaphor:** “Spin” = flow, exchange, community circle — not literal carnival spinning.
2. **Modern & cool:** ease-out cubic (`Curves.easeOutCubic` / `cubic-bezier(0.22, 1, 0.36, 1)`), subtle blur/glow shifts, staggered children.
3. **Short & purposeful:** transitions 250–400 ms; splash ≤ 1200 ms; loop loaders 2–3 s/rotation.
4. **Accessible:** full static fallback when reduced motion requested.
5. **Performant:** prefer `Transform` + `Opacity`; avoid animating blur radius every frame.

### Motion tokens (define in code during implementation)

| Token | Value | Use |
|-------|-------|-----|
| `motionFast` | 200 ms | Button press, icon toggle |
| `motionMedium` | 350 ms | Page push, card expand |
| `motionSlow` | 600 ms | Splash reveal |
| `motionLoop` | 2400 ms | Loader spin period |
| `easeEnter` | ease-out cubic | Elements entering |
| `easeExit` | ease-in cubic | Elements leaving |
| `stagger` | 60–80 ms | List/grid children |

### Signature animations (implement in Phase C)

#### 1. Splash — “Emblem assemble” (preferred)

- Background: radial pink/mint glow (existing `PayspinRadialGlow`).
- **Upper arrow** fades + slides from `-12 px` left (200 ms).
- **Lower loop** draws or fades in with 80 ms delay (280 ms).
- Wordmark “Payspin” gradient text fades up (200 ms, delay 300 ms).
- Total ≤ 900 ms → navigate; skip on tap.

**Fallback (bitmap):** single emblem scale 0.85→1 + opacity 0→1.

#### 2. Loader — “Spin flow”

- Gradient emblem rotates **360°** in 2.4 s, linear loop.
- Optional: outer ring gradient sweep (CSS `conic-gradient` / Flutter `SweepGradient` rotation).
- Pair with skeleton glass cards — never blank white screen.

#### 3. Primary button

- Press: scale 0.97, 100 ms + light haptic.
- Loading state: replace label with **mini emblem spinner** (16 px) + “Processing…”

#### 4. Success / paid

- Mint check draws (stroke animation 300 ms).
- Emblem scale 0→1.1→1.0 spring (400 ms).
- Confetti **not** used — stay fintech sober.

#### 5. QR screen

- QR plate scales 0.92→1 on open (350 ms ease-out).
- Emblem in centre static (EC level H).

#### 6. Payer web

- CSS `@keyframes payspin-spin` on SVG loader only.
- FAQ accordion: height + opacity 280 ms ease.
- Page enter: shell fade + 12 px translateY.

### Reduced motion fallback

| Animation | Fallback |
|-----------|----------|
| Splash spin | Instant emblem visible |
| Loader spin | Static emblem + progress bar |
| Button scale | Opacity only |
| QR scale-in | Instant show |

Flutter: `MediaQuery.disableAnimationsOf(context)`  
Web: `@media (prefers-reduced-motion: reduce) { animation: none !important; }`

---

## QR branding

- `QrErrorCorrectLevel.H`
- White/glass plate; pink finder eyes; dark modules `#1A1230`
- Centre: **processed gradient emblem** (~19% width)
- Verify scan at 30 cm on iOS + Android
- File: `payspin_branded_qr.dart`, pages: `link_qr_page.dart`

---

## Unified phase spec (0→D)

All phases ship in **one implementation pass**. Checkboxes are for the master plan and final report.

### Phase 0 — Discovery & assets (implement findings, not plan-only)

- [ ] Logo detection table (`file`, alpha, trim preview)
- [ ] Process & commit PNG emblems → mobile + `frontend/public/`
- [ ] Optional SVG / `PayspinEmblemPainter` decision documented in master plan
- [ ] UX task map with current vs target tap counts
- [ ] Animation storyboard signed off in master plan §5

### Phase A — Design system foundation

- [ ] `PayspinSemanticColors` + `PayspinTheme.light()` / `.dark()`
- [ ] `ThemeModeController` + Profile → Appearance (System / Dark / Light)
- [ ] `PayspinLogo` with `auto | white | gradient`
- [ ] `PayspinGlassSurface` (+ migrate `PayspinGlassIconButton` to use it)
- [ ] `PayspinBrandedQr` → gradient emblem, theme-adaptive plate
- [ ] Payer web: `[data-theme]`, `ThemeProvider`, emblem swap in header
- [ ] `pubspec.yaml` + frontend public assets registered

### Phase B — Screen migration + usability (complete list)

**Mobile** — every row must use `context.psColors` (no raw `PayspinTokens.bg` on migrated files):

- [ ] `splash_page`, `welcome_page`, `login_page`
- [ ] Onboarding: `step_name`, `step_phone`, `step_otp`, `step_iban`, `step_connect_bank`
- [ ] `home_page`, `main_shell`, `payspin_bottom_nav`
- [ ] Send: `send_amount`, `send_name`, `send_label` pages
- [ ] Links: `link_detail_page`, `link_qr_page`
- [ ] `scan_qr_page`, `notifications_page`, `profile_page`, `lock_screen`
- [ ] Fix dead controls / tap-count issues from STEP 0

**Payer web:**

- [ ] `layout.tsx`, `globals.css`, `WebShell`, header/footer
- [ ] `[code]/page`, `pay-button`, `callback/*`, `success/page`, landing `page.tsx`
- [ ] Glass cards (`.ps-glass-card`), theme toggle visible

### Phase C — Motion & delight (all signature animations)

- [ ] `payspin_motion.dart` tokens
- [ ] `PayspinEmblemLoader` (spin) + reduced-motion static variant
- [ ] Splash emblem assemble (or bitmap fallback)
- [ ] Welcome enter animation
- [ ] Primary button press scale + loading mini-spinner
- [ ] Pay/link success bounce
- [ ] QR plate scale-in on `link_qr_page`
- [ ] Payer web: loader SVG/CSS, FAQ spring, page enter
- [ ] `MediaQuery.disableAnimations` + `prefers-reduced-motion` verified

### Phase D — Hardening & parity

- [ ] `flutter test` (logo, QR, theme, loader widgets)
- [ ] `flutter analyze` clean on `mobile/lib/core/design_system/` + touched presentation
- [ ] Payer web browser smoke (dark + light, pay page renders)
- [ ] QR device scan note (or document manual step)
- [ ] Update `ui-ux-brand-audit.md` gaps → resolved
- [ ] Sync `mobile-ui-audit.md` rows for migrated screens (brief)

---

## Legacy phased notes (superseded by unified spec above)

<details>
<summary>Old per-phase descriptions (reference only)</summary>

### Phase 0 — Discovery

Logo detection, asset pipeline, UX map, animation storyboard.

### Phase A — Foundation

Tokens, themes, logo, glass, QR, payer web theme.

### Phase B — Screen migration

High-traffic screens + usability.

### Phase C — Motion

Splash, loader, buttons, success.

### Phase D — Hardening

Tests, performance, Figma parity.

</details>

---

## Test matrix (mandatory)

| ID | Scenario | How |
|----|----------|-----|
| T0 | Logo alpha on dark + light bg | Visual + `identify -format '%A'` |
| T0b | QR scan after emblem overlay | Device 30 cm |
| T1 | Logo widget loads both variants | `flutter test` |
| T2 | Theme persistence | Kill app, reopen |
| T3 | Light theme WCAG AA body text | Contrast checker |
| T4 | Splash duration ≤ 1.2 s skippable | Stopwatch |
| T5 | Loader respects reduced motion | OS setting on/off |
| T6 | Glass scroll 60 fps | Profile mid Android |
| T7 | Payer web theme + emblem swap | Browser MCP |
| T8 | Core task tap counts | Manual script |
| T9 | `flutter analyze` clean | CI |
| T10 | No animation blocks pay CTA | Payer web pay flow |

---

## File map (implementation target)

```
mobile/lib/core/design_system/
  theme/payspin_semantic_colors.dart
  theme/theme_mode_controller.dart
  theme/payspin_motion.dart              ← durations, curves (Phase C)
  widgets/payspin_logo.dart
  widgets/payspin_emblem_painter.dart     ← optional vector (Phase C)
  widgets/payspin_emblem_loader.dart    ← spin loader (Phase C)
  widgets/payspin_glass_surface.dart
  widgets/payspin_branded_qr.dart

frontend/app/
  globals.css                             — themes + motion keyframes
  components/PayspinEmblem.tsx            ← SVG or img swap
  components/PayspinLoader.tsx
  components/ThemeProvider.tsx
```

---

## Copy / voice

- Warm, community-first, trustworthy — no emoji in product UI
- Sentence case body; Title Case screen titles (Raleway)
- CTAs: “Get started”, “Next”, “Pay now”

---

## Out of scope

- Payspin-portal admin UI
- Backend API changes
- Rebrand away from pink/mint
- Heavy 3D / particle effects
- Auto-playing sound

---

## Appendix — quick logo processing commands

```bash
# Detect format
file mobile/assets/images/payspin_emblem_white.png

# Check alpha (ImageMagick)
identify -format '%A %wx%h' mobile/assets/images/payspin_emblem_gradient.png

# Trim preview (don't overwrite until verified)
convert payspin_emblem_white.png -trim +repage png32:emblem_white_trim.png

# Verify on brand backgrounds (compose test)
convert -size 200x200 xc:'#0B0B12' emblem_white_trim.png -gravity center -composite preview_dark.png
convert -size 200x200 xc:'#F9F9F9' emblem_gradient_trim.png -gravity center -composite preview_light.png
```

Use Figma export when automated trim damages anti-aliased edges.
