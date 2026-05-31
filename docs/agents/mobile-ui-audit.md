# Payspin Mobile — UI/UX Audit (STEP 0)

**Date:** 2026-05-31
**Source of truth:** `resources/Payspin Design System/screens.jsx` + `Payspin Prototype.html`
**Scope of work:** `mobile/lib/presentation/` + `mobile/lib/core/design_system/` (Phases A–C; Circles/Phase D deferred per product owner)
**Mandate:** Prototype is a floor, not a cap. All polish/motion/illustration suggestions accepted within Payspin brand tokens.

Legend: ✅ match · 🟡 partial · ❌ missing/text-only

---

## Cross-cutting findings

**Strong today:** dark tokens (`#0B0B12`/`#15141F`), Raleway+Inter, pink→mint gradients, glass cards, `PayspinOnboardingShell`, blurred bottom nav.

**Weak today (global gaps):**
- Empty states are text-only (Home Tikkies, Deals, Groepies illustration missing).
- Loading = bare centered spinner; no skeletons.
- No motion: no entrance animations, tab transitions, list stagger, press feedback, or haptics.
- Errors via default `SnackBar` (dark theme inherits, but no branding/illustration).
- Several missing shared widgets the prototype implies (stacked cards, promo card, deals placeholder, OTP boxes, scan frame, status chip).

---

## Per-screen audit

### Welcome — 🟡
- **Gaps:** static radial glow; tagline copy differs from exact brand line; no entrance animation.
- **Enhancements:** animated glow pulse; staggered fade/slide for logo → wordmark → tagline → CTA; light haptic on Get started.

### Login — 🟡
- **Gaps:** plain `AppBar`; no glow shell; error inline only.
- **Enhancements:** match credentials/onboarding visual; subtle glow background; friendly error block with icon.

### Onboarding steps 1–5 + credentials — 🟡
- **Gaps:** OTP is a single letter-spaced `TextField`, not 6 boxes; no step transition animation.
- **Enhancements:** `PayspinOtpBoxes` (6 cells, auto-advance, active mint border); keep honest "preview" copy; press feedback on circle-next.

### Connect bank — 🟡
- **Gaps:** outside onboarding shell; no skeleton while institutions load.
- **Enhancements:** institution row skeletons; consistent header; glass list rows.

### Success — 🟡
- **Gaps:** confetti is static rectangles; no checkmark moment.
- **Enhancements:** animated draw-in checkmark/badge; gentle confetti drift; glow.

### Main shell / bottom nav — ✅/🟡
- **Gaps:** no body transition between tabs.
- **Enhancements:** `AnimatedSwitcher` cross-fade; keep FAB visibility rules intact.

### Home — Tikkies tab — ❌ empty / 🟡 list
- **Gaps:** empty state text-only ("Time for Your First Tikkie!" wrong casing); no stacked ghost cards; no Groepies promo card at list bottom; abrupt search toggle.
- **Enhancements:** `PayspinStackedCardsIllustration`; `PayspinGroepiesPromoCard`; skeleton list while loading; `AnimatedSize` search reveal; list item stagger.

### Home — Deals tab — ❌
- **Gaps:** plain "Deals — coming soon" string.
- **Enhancements:** `PayspinDealsPlaceholder` — gradient lock/spark icon, headline, 1-line copy, disabled "Notify me" chip.

### Home — Groepies tab — 🟡
- **Gaps:** no stacked illustration; copy/CTA differ from prototype ("How does it work?").
- **Enhancements:** stacked Groepie cards; prototype copy *"Track group expenses?"* + *"Keep track of costs together…"*; primary Create + secondary "How does it work?" sheet (`PayspinExplainerSheet`) + tertiary Join link; skeleton + retry.

### Send — amount — 🟡
- **Gaps:** default `SwitchListTile`; numpad has no press feedback; help noop.
- **Enhancements:** glass styled toggle row; numpad key ripple + light haptic; amount scale-in.

### Send — name — 🟡
- **Gaps:** duplicated share button logic.
- **Enhancements:** use `PayspinGradientPillButton`; success haptic on share.

### Scan QR — 🟡
- **Gaps:** no scan frame/brackets; flash/help noop.
- **Enhancements:** `PayspinScanFrame` corner brackets + dim vignette; wire flash toggle (mobile_scanner controller).

### Link detail — 🟡
- **Gaps:** flat amount + status; payments are plain rows; default SnackBar.
- **Enhancements:** amount hero card; `PayspinStatusChip`; payment status timeline with glowing active step; mint copy-link/share toast.

### Profile — 🟡
- **Gaps:** flat avatar; settings rows partly noop.
- **Enhancements:** gradient avatar ring; IBAN card shine sweep on appear; section spacing polish.

### Circles (create/join/detail) — DEFERRED (Phase D)
- Not in this pass per product owner. No changes.

---

## New shared widgets to build (Phases A–C)

| Widget | File | Used by |
|--------|------|---------|
| `PayspinStackedCardsIllustration` | `widgets/payspin_stacked_cards_illustration.dart` | Home Tikkies empty, Groepies empty |
| `PayspinGroepiesPromoCard` | `widgets/payspin_groepies_promo_card.dart` | Home Tikkies list |
| `PayspinDealsPlaceholder` | `widgets/payspin_deals_placeholder.dart` | Home Deals |
| `PayspinTabStrip` | `widgets/payspin_tab_strip.dart` | Home header |
| `PayspinStatusChip` | `widgets/payspin_status_chip.dart` | Tikkie row, link detail |
| `PayspinExplainerSheet` | `widgets/payspin_explainer_sheet.dart` | Groepies "How does it work?" |
| `PayspinSkeleton` / `PayspinSkeletonRow` | `widgets/payspin_skeleton.dart` | Home, link detail, connect bank |
| `PayspinEmptyState` | `widgets/payspin_empty_state.dart` | Tikkies/Groepies/Deals empties |
| `PayspinRadialGlow` | `widgets/payspin_radial_glow.dart` | Welcome, Login, Success, empties |
| `PayspinOtpBoxes` | `widgets/payspin_otp_boxes.dart` | OTP step |
| `PayspinScanFrame` | `widgets/payspin_scan_frame.dart` | Scan QR |

---

## Enhancements beyond prototype (accepted)

These exceed the static JSX and are intentionally added for a premium feel:

1. **Motion system:** entrance stagger (logo/CTA), tab cross-fade, list item stagger (50ms), button press scale 0.98, success checkmark draw.
2. **Haptics:** `HapticFeedback.lightImpact()` on primary CTAs, numpad keys, share success.
3. **Skeleton loading:** shimmer placeholders matching card layout instead of bare spinners.
4. **Animated radial glow:** slow breathing glow on Welcome/Success/empty states.
5. **Link detail timeline:** vertical status timeline with glowing active node (not in prototype).
6. **Deals placeholder:** fully designed coming-soon state (prototype had none).
7. **Profile IBAN shine:** one-shot gradient sweep highlight when card appears.
8. **Copy-link toast:** mint check confirmation on share/copy.

---

## Screen checklist (Definition of Done)

- [ ] Welcome (glow + stagger)
- [ ] Login (glow + styling)
- [ ] Onboarding OTP boxes
- [ ] Connect bank skeleton
- [ ] Success animation
- [ ] Home Tikkies (empty illustration + list + promo + skeleton)
- [ ] Home Deals placeholder
- [ ] Home Groepies (empty illustration + copy + CTAs + explainer)
- [ ] Send amount (toggle + numpad feedback)
- [ ] Send name (shared button)
- [ ] Scan QR frame
- [ ] Link detail (hero + timeline + toast)
- [ ] Profile (avatar ring + IBAN shine)
- [ ] Bottom nav transition
- [ ] flutter analyze + test green
- [ ] MCP verify: Welcome, Home (3 tabs), Groepies empty, link detail, success

---

## Runtime verification log

Filled in during phases (simulator/MCP screenshots + notes).

- Phase A: _pending_
- Phase B: _pending_
- Phase C: _pending_
