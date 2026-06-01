# Payspin — Hard design audit (all screens + all colors)

**Canonical UI:** [Claude design prototype](https://claude.ai/design/p/0e804e64-9500-4d7e-9fb9-598d971d0b82?file=Payspin+Prototype.html) = `resources/Payspin Design System/screens.jsx` (`PS` tokens)

**Do not use for dark mobile UI:** `colors_and_type.css` root tokens (`--color-bg-page: #F9F9F9`, etc.) — that file documents the **light** design system / portal; the interactive prototype uses **`PS` in screens.jsx** only.

**Flutter tokens:** `mobile/lib/core/design_system/tokens/payspin_tokens.dart`

**Audit date:** 2026-06-01 (automated token + file cross-check)

---

## 1. Color token matrix (prototype `PS` ↔ Flutter)

| Token | Prototype (`screens.jsx`) | Flutter `PayspinTokens` | Match |
|-------|---------------------------|-------------------------|-------|
| Page background | `#0B0B12` | `bg` `0xFF0B0B12` | ✅ |
| Elevated card | `#15141F` | `bgElevated` `0xFF15141F` | ✅ |
| Glass fill | `rgba(255,255,255,0.06)` | `glass` `0x0FFFFFFF` (~6%) | ✅ |
| Border | `rgba(255,255,255,0.08)` | `border` `0x14FFFFFF` (~8%) | ✅ |
| Border active | `rgba(252,0,255,0.45)` | `borderActive` `0x73FC00FF` (~45%) | ✅ |
| Text primary | `#FFFFFF` | `textPrimary` | ✅ |
| Text body | `rgba(255,255,255,0.85)` | `textBody` `0xD9FFFFFF` | ✅ |
| Text muted | `rgba(255,255,255,0.55)` | `textMuted` `0x8CFFFFFF` | ✅ |
| Text hint | `rgba(255,255,255,0.35)` | `textHint` `0x59FFFFFF` | ✅ |
| Pink / primary | `#FC00FF` | `pink` | ✅ |
| Mint / secondary | `#07D8DD` | `mint` | ✅ |
| Purple | `#8E0FF2` | `purple` | ✅ |
| Blue | `#5C7AEA` | `blue` | ✅ |
| Mustard (pending) | `#FFC408` | `mustard` | ✅ |
| CTA gradient | `135deg #FC00FF → #07D8DD` | `gradientPink` | ✅ |
| Tri gradient (promo) | `#07D8DD → #5C7AEA → #FC00FF` | `gradientTri` | ✅ |
| Progress gradient | `#D94DF8 → #6B96EA → #48ADE5 → mint` | `progressGradient` | ✅ |
| FAB shadow | pink 32% + mint 18% blur | `fabShadow` | ✅ |
| Tikkie row tints | pink/mint/mustard/blue @ 18% | `_tints` `0x2E…` (~18%) | ✅ |
| Error semantic | (pink highlights) | `error` = `pink` | ✅ (by design) |

### Semantic colors NOT in `PS` (wireframe doc only — ignore for dark app)

| Wireframe spec | Hex | Use in Flutter? |
|----------------|-----|-----------------|
| Success (light doc) | `#10B981` | ❌ use `mint` for paid |
| Error (light doc) | `#EF4444` | ❌ use `pink` / `mustard` |

---

## 2. Typography & spacing (prototype ↔ Flutter)

| Element | Prototype | Flutter | Match |
|---------|-----------|---------|-------|
| Display font | Raleway | `GoogleFonts.raleway` | ✅ |
| Body font | Inter | `GoogleFonts.inter` | ✅ |
| Screen title (onboarding) | Raleway 800, ~30px | `PayspinOnboardingShell` | ✅ |
| Welcome wordmark | Raleway 900, 48px | ~match in `welcome_page` | 🟡 verify 48px |
| Welcome tagline | Inter 15px, `textBody` | Inter, `textBody` | ✅ |
| Amount (send) | large display | `send_amount_page` numpad | 🟡 |
| Link detail amount | — (no screen) | Raleway 40 w800 | — |
| Button height | 56px pill | `btnHeightLg` 56 | ✅ |
| Card radius | 16–18px | `radiusCard` 16 | ✅ |
| Input radius | 10px (CSS) | `radiusInput` 10 | ✅ |
| Pill radius | 100 | `radiusPill` 100 | ✅ |
| Spacing unit | 4px grid | `space1`–`space6` | ✅ |

---

## 3. Hard check — every prototype screen

Legend: ✅ match · 🟡 partial · ❌ missing · ➕ app-only (no prototype)

| # | Prototype | Flutter | Colors | Layout / components | Notes |
|---|-----------|---------|--------|---------------------|-------|
| 1 | `WelcomeScreen` | `welcome_page.dart` | ✅ | ✅ | Tagline matches; glow may be static vs animated |
| 2 | `Step1Name` | `step_name_page.dart` | ✅ | ✅ | Mint typed text via `PayspinUnderlineField` (theme-isolated) |
| 3 | `Step2Phone` | `step_phone_page.dart` | ✅ | ✅ | Country picker added (🟡 richer than prototype dropdown) |
| 4 | `Step3OTP` | `step_otp_page.dart` | ✅ | 🟡 | `PayspinOtpBoxes` vs single field — **better** than prototype |
| 5 | `Step4IBAN` | `step_iban_page.dart` | ✅ | ✅ | |
| 6 | `Step5FullName` | `step_full_name_page.dart` | ✅ | ✅ | |
| 7 | `SuccessScreen` | `success_page.dart` | ✅ | 🟡 | Confetti/check animation polish |
| 8 | `HomeScreen` (list) | `home_page.dart` | ✅ | 🟡 | Rows + promo; empty state improved |
| 9 | `HomeScreen` (empty) | `home_page.dart` | ✅ | 🟡 | Stacked cards widget added |
| 10 | `GroepiesScreen` | `groepies_page.dart` | ✅ | 🟡 | Explainer sheet vs prototype copy |
| 11 | `ProfileScreen` | `profile_page.dart` | ✅ | 🟡 | Gradient avatar ring |
| 12 | `ScanQRScreen` | `scan_qr_page.dart` | 🟡 | 🟡 | `Colors.black` scaffold (camera); frame overlay OK |
| 13 | `SendAmountScreen` | `send_amount_page.dart` | ✅ | 🟡 | Numpad + open amount toggle |
| 14 | `SendNameItScreen` | `send_name_page.dart` | ✅ | ✅ | WhatsApp CTA matches |

### App screens with no prototype frame

| Flutter | Colors | vs brand | Action |
|---------|--------|----------|--------|
| `login_page.dart` | ✅ dark | ➕ | Keep; not in prototype |
| `step_connect_bank_page.dart` | ✅ | ➕ | Yapily flow; not in prototype |
| `link_detail_page.dart` | ✅ | ➕ | **Product screen** — extend brand (hero gradient OK) |
| `notifications_page.dart` | ✅ | ➕ | |
| `create/join/detail_circle_page.dart` | ✅ | ➕ | `PayspinLabeledField` + `PayspinScaffold` (2026-06-01) |
| `circle_row.dart` | ✅ | ➕ | |

---

## 4. Color violations / drift risks

### Shared primitives (2026-06-01 unification pass)

| Widget | Role |
|--------|------|
| `PayspinTokens.onBrand` / `surfaceRaised` / `surfaceMuted` | Semantic aliases for `rgba(255,255,255,…)` |
| `PayspinScaffold` | `bg` + optional app bar |
| `PayspinFlowHeader` | Send/onboarding glass back + help |
| `PayspinGlassIconButton` | 40×40 header actions |
| `PayspinLabeledField` | Caption + underline field |
| `PayspinAccentCircleButton` | Send QR secondary CTA |
| `showPayspinSnackBar` | Floating elevated toasts |
| `PayspinTheme.dark()` | Unfilled default `TextField`; mint via underline widget |

### Acceptable (semantic white on dark)

Use `PayspinTokens.onBrand` (not raw `Colors.white`) on icons/CTAs over gradients — matches prototype `#fff` on buttons.

### Should use `PayspinTokens` (minor drift)

| File | Issue | Fix |
|------|-------|-----|
| ~~`create_circle_page.dart`~~ | ~~raw `TextField`~~ | ✅ Fixed — `PayspinLabeledField` |
| `scan_qr_page.dart` | `backgroundColor: Colors.black` | OK for camera; optional `PayspinTokens.bg` under overlay |
| `payspin_bottom_nav.dart` | `Color(0xD90B0B12)` scrim | OK — 85% `bg` for blur bar |

### No stray brand hex found outside `payspin_tokens.dart` + tints

All `Color(0xFF…)` in `lib/` are either in `payspin_tokens.dart` or the four tikkie tint constants (correct).

---

## 5. Best workflow for a **hard** check (all screens, all colors)

Use this order every release or before a UI PR:

### Step A — Token diff (5 min, exact)

```bash
# Prototype tokens (source of truth)
grep -E "^  [a-z].*:" "resources/Payspin Design System/screens.jsx" | head -20

# Flutter tokens
cat mobile/lib/core/design_system/tokens/payspin_tokens.dart

# Hunt rogue hex in UI code
rg "Color\(0x" mobile/lib --glob "*.dart"
```

### Step B — Screen-by-screen (interactive)

```bash
./scripts/dev/serve-design-prototype.sh
```

In Cursor, ask agent:

```text
Open http://localhost:8765/Payspin%20Prototype.html with cursor-ide-browser.
For each nav pill (Welcome … Send: Label), screenshot and note PS colors used.
Cross-check mobile/lib/presentation/<matching>_page.dart uses PayspinTokens only.
```

### Step C — Flutter runtime

```bash
cd mobile && flutter run --dart-define=API_URL=http://178.105.118.225/v1
```

Walk: Welcome → onboarding → Home (empty + list) → Send → Link detail → Profile.

### Step D — Update this file

Add a row per screen with ✅/🟡/❌ and any new hex drift.

---

## 6. MCP stack for hard audits

| Priority | Tool | Role |
|----------|------|------|
| 1 | `screens.jsx` + `payspin-design` MCP | **All colors & layout truth** |
| 2 | `rg` / read Flutter pages | Per-screen token usage |
| 3 | `cursor-ide-browser` @ localhost:8765 | Visual proof per pill |
| 4 | `dart` MCP `analyze_files` | After fixes |

**Not for hard color audit:** claude.ai/design URL (bot-blocked), Figma file (incomplete), `colors_and_type.css` light tokens.

---

## 7. Summary

- **Core palette:** Flutter matches prototype `PS` on all 15 dark tokens — **no wrong brand hex** in presentation layer.
- **All 14 prototype screens** have Flutter implementations; most are ✅ or 🟡 polish-only.
- **Gaps:** Circles create form styling; scan page uses pure black; link detail / login / connect-bank are **app-only** (intentional).
- **For your request (“hard check every screen, every color”):** use **Step A + B + C** above; this doc is the checklist to fill on each run.
