# Payspin Mobile — UI/UX Enhancement Prompt

**Purpose:** Paste this into Cursor (or hand to another agent) to make the Flutter payee app **beautiful, polished, and delightful** — grounded in the Payspin dark prototype but **not limited to it**. The product owner **welcomes all UI/UX ideas and accepts agent suggestions without prior approval**.

**Scope:** `mobile/` only — presentation layer + design system widgets. **No backend changes** unless a screen truly needs a new field (ask first).

### Creative mandate (read this first)

The prototype is a **baseline**, not a ceiling. You are explicitly encouraged to:

- **Exceed** the JSX/HTML where it looks flat, generic, or unfinished
- **Propose and implement** micro-interactions, motion, depth, and illustration upgrades
- **Invent** better empty states, Deals placeholders, success moments, and link-detail heroes
- **Unify** visual language across screens so the app feels like one premium fintech product
- **Document** every meaningful enhancement in `docs/agents/mobile-ui-audit.md` under an **“Enhancements beyond prototype”** section (brief rationale per idea)

**Do not ask permission** for visual improvements inside brand tokens — **just build the best version** and note what you changed. Only pause for product decisions that affect **business rules** (e.g. removing a real API action, changing payment flow).

**Design references (in order):**

1. **Floor (must match or beat):** `resources/Payspin Design System/screens.jsx` + `Payspin Prototype.html`
2. **Map:** `resources/docs/design-system-flutter-map.md`
3. **Tokens rule:** `.cursor/rules/payspin-design.mdc`
4. **Inspiration (optional):** [Claude design share](https://claude.ai/design/p/0e804e64-9500-4d7e-9fb9-598d971d0b82?file=Payspin+Prototype.html), Revolut/N26 dark fintech patterns, premium neobank motion — **always filtered through Payspin pink/mint/dark brand**

**Tagline (exact):** *"Your money, your community, and your peace of mind."*

---

## STEP 0 — Design audit (mandatory before coding)

1. Open the prototype HTML and walk every screen pill (Welcome → Send → Home → Groepies → Profile → Scan).
2. For each Flutter page in `mobile/lib/presentation/`, capture a side-by-side note: **match / partial / missing**.
3. Write findings to `docs/agents/mobile-ui-audit.md` (create if missing) — one section per screen: **gaps**, then **enhancement ideas** (minimum 2 per major screen).
4. Add a summary section **“Enhancements beyond prototype”** listing what you plan to add that is *better* than the JSX (motion, illustration, copy tweaks, layout).
5. Do **not** start refactors until the audit file exists.

Use Flutter MCP / simulator screenshots to verify **runtime** (not just static code reading).

---

## Design system (non‑negotiable)

| Token | Value | Flutter |
|-------|-------|---------|
| Page bg | `#0B0B12` | `PayspinTokens.bg` |
| Elevated card | `#15141F` | `PayspinTokens.bgElevated` |
| Glass | `rgba(255,255,255,0.06)` + border `0.08` | `PayspinTokens.glass` / `border` |
| Brand gradient CTA | `#FC00FF` → `#07D8DD` | `PayspinGradientPillButton`, `PayspinGradientCircleButton` |
| Mint accent | `#07D8DD` | tabs, status chips, links |
| Display font | Raleway 700–900 | `GoogleFonts.raleway` |
| Body font | Inter 400–600 | `GoogleFonts.inter` |

**Never:** flat purple Material AppBar, white modals, Tikkie-style light theme, hardcoded hex outside `payspin_tokens.dart`.

**Prefer:** extract repeated JSX patterns into reusable widgets under `mobile/lib/core/design_system/widgets/` rather than duplicating layout in pages.

---

## Known gaps vs prototype (fix these)

These were verified against `screens.jsx` and current Flutter — treat as P0 polish:

### Home — Tikkies tab

| Prototype | Current Flutter | Action |
|-----------|-----------------|--------|
| Empty: **3 stacked ghost Tikkie cards** + title + subtitle | Text-only empty state | Add `PayspinStackedTikkieIllustration` (or similar) |
| Empty title: *"Time for your first Tikkie!"* | *"Time for Your First Tikkie!"* | Match prototype casing/copy |
| List: gradient **Groepies promo card** at bottom | Missing | Add `PayspinGroepiesPromoCard` → navigates to Groepies tab |
| Tikkie rows: emoji tint, status pill, date | Partial via `PayspinTikkieRow` | Audit spacing, tints, typography |

### Home — Deals tab

| Prototype | Current Flutter | Action |
|-----------|-----------------|--------|
| Tab exists; no designed content in JSX | Plain *"Deals — coming soon"* | Add **designed placeholder**: illustration or icon, headline, 1-line copy, optional “Notify me” disabled chip — same visual weight as Groepies empty state |

### Home — Groepies tab

| Prototype (`GroepiesScreen`) | Current Flutter | Action |
|-------------------------------|-----------------|--------|
| **Stacked Groepie cards** (House bill / Weekend trip) | Missing | Add `PayspinStackedGroepieIllustration` |
| Title: *"Track group expenses?"* | *"Track Group Expenses?"* | Match copy |
| Subtitle: *"Keep track of costs together quickly and easily. And we'll do all the math."* | Different rotation copy | Match prototype for **empty** state; keep rotation copy for **list** header if needed |
| Secondary: **"How does it work?"** (white, bold) | *"Join with invite code"* (mint) | **Both:** primary secondary = How does it work (modal/bottom sheet explainer); keep Join as tertiary mint link or move to app bar |
| Header on standalone Groepies screen: center title "Groepies" | Groepies embedded in Home with Payspin header | **Keep tab-in-Home model** (matches HomeScreen tabs in JSX) — do not split to a separate route unless user asks |

### Circles (implemented — polish only)

- `create_circle_page.dart`, `join_circle_page.dart`, `circle_detail_page.dart` — style like onboarding shell + home cards; no raw `ListTile` defaults.
- `CircleRow` — match Tikkie row visual language (glass card, rounded 18, status chip).

### Onboarding + auth

| Screen | Prototype reference | Notes |
|--------|---------------------|-------|
| Welcome | radial glow, logo 110, gradient wordmark | Already close — verify glow and button shadow |
| Steps 1–5 + credentials | `PayspinOnboardingShell`, progress, step counter | Match underline fields, circle next button |
| OTP | 6 boxes | Keep honest “preview” copy; style boxes like prototype |
| Connect bank | not in original JSX | Match glass list + institution rows; loading skeleton |
| Login | bridge screen | Same dark scaffold + underline fields as credentials |
| Success | confetti / celebration | Match gradient CTA + copy |

### Send flow

- Amount numpad: large euro display, mint cursor, gradient FAB — `PayspinNumpad`
- Name step: underline field + share CTA
- Match prototype padding and bottom safe areas (FAB clears bottom nav)

### Profile

- Avatar gradient circle, IBAN gradient card, settings group — audit against `ProfileScreen` in JSX
- Row chevrons, dividers, logout destructive styling

### Scan QR

- Dark camera overlay frame, corner brackets, helper copy from prototype

### Link detail

- Status timeline / amount hero / cancel action — professional fintech feel; pull-to-refresh indicator uses pink

---

## UX quality bar (make it feel premium)

Apply across **all** screens — and push further where it improves delight:

1. **Loading:** shimmer/skeleton placeholders matching card layout; branded pink accent — never naked spinners on empty space.
2. **Empty states:** custom illustration (stacked cards, subtle parallax, or Lottie-style implicit motion via `AnimatedSlide`) + headline + body + CTA — **never text-only**.
3. **Errors:** friendly copy + retry; optional illustration; never raw exception strings in UI.
4. **Motion:** tab transitions, list item stagger (50ms offset), button press scale 0.98, success checkmark draw — keep 200–350ms, `Curves.easeOutCubic`.
5. **Depth:** layered backgrounds (radial pink/mint glows on welcome, home, success), glass blur on nav bar, gradient borders on promo cards.
6. **Typography:** clear hierarchy; occasional gradient headline words; generous whitespace — avoid cramped forms.
7. **Haptics:** `HapticFeedback.lightImpact()` on primary CTAs and successful payment/link actions (where platform supports).
8. **Accessibility:** semantic labels, 44×44 targets, respect `MediaQuery.textScaler` — beauty must not break a11y.

### Ideas the agent should consider implementing (all welcome)

| Area | Enhancement ideas |
|------|-------------------|
| Welcome | Animated radial glow pulse; logo subtle float; staggered fade-in of tagline + CTA |
| Onboarding | Step transitions slide + fade; OTP boxes auto-advance focus; progress bar spring |
| Home | Pull-to-refresh custom indicator; search expand animation; Tikkie row swipe hints |
| Groepies | Rotating stacked cards parallax; “How it works” bottom sheet with 3-step visuals |
| Deals | Beautiful “coming soon” with gradient lock icon + waitlist-style chip (UI only) |
| Send | Numpad key ripple; amount morph animation; share sheet preview card |
| Link detail | Status timeline with glowing active step; copy-link toast with mint check |
| Profile | Avatar ring gradient; IBAN card flip or shine sweep on appear |
| Circles | Round progress ring; member avatars overlap stack; host badge |
| Global | Consistent page transitions via `go_router` custom transitions for modals/pushes |

Pick the highest-impact ideas first; implement freely without waiting for sign-off.

---

## Architecture constraints

- **Do not** move business logic into widgets — pages call repos/use cases via `sl<>`.
- **Do not** break routes in `mobile/lib/app/router.dart`.
- **Do not** change API contracts or add mock data for production paths.
- **Do** add widget tests when introducing new shared components (`mobile/test/widgets_test.dart`).
- **Do** run `cd mobile && flutter analyze && flutter test` before finishing.
- **Minimal diff per PR area:** group changes by screen/phase; avoid unrelated refactors.
- **Creative diffs are OK:** new widgets, animations, and illustration code are in scope even if the prototype didn’t specify them.

---

## Suggested new shared widgets

Create only if used ≥2 times:

| Widget | Purpose |
|--------|---------|
| `PayspinStackedCardsIllustration` | Parameterized stacked cards for Tikkies / Groepies empty states |
| `PayspinGroepiesPromoCard` | Gradient border promo on Home list |
| `PayspinDealsPlaceholder` | Deals tab empty designed state |
| `PayspinTabStrip` | Tikkies / Deals / Groepies with mint underline |
| `PayspinHomeHeader` | QR + logo + search row |
| `PayspinStatusChip` | mint dot + label (Paid 2x, Active, etc.) |
| `PayspinExplainerSheet` | “How does it work?” bottom sheet for Groepies |

---

## Screen checklist (Definition of Done)

Mark each in `mobile-ui-audit.md` when done:

- [ ] Welcome
- [ ] Login
- [ ] Onboarding: name, phone, OTP, credentials, connect bank, IBAN, full name, success
- [ ] Home: Tikkies (empty + list + promo)
- [ ] Home: Deals placeholder
- [ ] Home: Groepies (empty illustration + copy + CTAs)
- [ ] Home: Groepies list (`CircleRow` polish)
- [ ] Send: amount, name
- [ ] Scan QR
- [ ] Link detail
- [ ] Profile
- [ ] Circles: create, join, detail
- [ ] Bottom nav + FAB visibility rules (`main_shell.dart`)
- [ ] Dark modals / bottom sheets everywhere

---

## Phased delivery (recommended order)

**Phase A — Design system + Home (highest visibility)**  
Stacked illustrations, Deals placeholder, Groepies empty polish, promo card, tab strip extraction.

**Phase B — Onboarding + auth polish**  
Shell consistency, OTP boxes, connect bank skeletons, success screen.

**Phase C — Send, scan, link detail, profile**  
Numpad polish, QR overlay, link detail hero, profile IBAN card.

**Phase D — Circles screens**  
Visual parity with home cards; contribution CTA styling.

---

## Verification

```bash
# Prototype side-by-side
open "resources/Payspin Design System/Payspin Prototype.html"

# App
./scripts/dev/payspin-dev start
cd mobile && flutter run --dart-define=API_URL=http://localhost:3001/v1

# Tests
cd mobile && flutter analyze && flutter test
```

**Manual smoke:** register → IBAN → home empty → create Tikkie → list + promo → Groepies tab → create/join circle → profile → logout.

---

## Anti-patterns (do not)

- Light theme or `#6200EE` Material defaults
- Generic `Card()` without glass/elevated styling
- `AlertDialog` with white background
- Replacing working flows with static mock UI
- Copy from Tikkie / iDEAL apps — stay on Payspin brand
- Large drive-by refactors outside presentation + design_system

---

## One-shot agent instruction

> Load `docs/agents/mobile-ui-ux-enhancement-prompt.md`. Run **STEP 0** audit → write `docs/agents/mobile-ui-audit.md` with gaps **and** enhancement ideas. The product owner **accepts all UI/UX suggestions** — make the app as beautiful and professional as possible; treat `screens.jsx` as a **floor**, not a cap. Implement **Phase A → D**, add motion, illustrations, and polish freely within Payspin brand tokens. Keep all API flows working. Document enhancements beyond prototype in the audit file. Run `flutter analyze` and `flutter test`. Verify with simulator/MCP: Welcome, Home (3 tabs), Groepies empty, link detail, onboarding success.
