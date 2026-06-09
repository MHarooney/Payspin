# Payspin Mobile — Premium Home Screen Redesign

**Purpose:** Paste this file (or `@docs/agents/mobile-home-premium-redesign-prompt.md`) when upgrading the Flutter **Home** tab to a **premium dark fintech dashboard** — richer sections, glassmorphism, neon gradients, and smart shortcuts — while staying **100% on-brand** and **wired to real Payspin data/actions**.

**Visual reference:** User screenshot (TestFlight home, Jun 2026) — flat vertical link list, glass header, gradient FAB, pill bottom nav. Target is **Revolut/Wise-level polish** with Payspin’s **futuristic pink→teal** identity.

**Scope:** `mobile/` presentation + design-system widgets only. **No backend/API changes** unless you document a future need and get explicit approval. **No git push. No cloud deploy. No commit** unless the user asks.

---

## How to use

### Option A — Full implementation (recommended)

1. New Agent chat.
2. Paste the **COPY BLOCK** at the bottom.
3. Say: **“Execute end-to-end as a senior mobile product designer + Flutter engineer. Do not push or deploy.”**

### Option B — Audit first

**“Run STEP 0–1 only; write docs/agents/mobile-home-redesign-plan.md, then stop.”**

---

## Non-negotiables

1. Read [AGENTS.md](../../AGENTS.md), [mobile-ui-ux-enhancement-prompt.md](mobile-ui-ux-enhancement-prompt.md), [design-hard-audit.md](design-hard-audit.md).
2. Load design skill: `.cursor/skills/payspin-design/SKILL.md`.
3. **Tokens only** from `PayspinTokens` / `payspin_semantic_colors.dart` — no random hex in pages.
4. **Fonts:** Raleway (display), Inter (body) — already project standard.
5. **Tagline (exact):** *"Your money, your community, and your peace of mind."*
6. **Business logic stays real** — no fake “Paid” states, no buttons that do nothing without disabled state + honest copy.
7. **Minimal diffs** outside home + new reusable widgets + tests.
8. **Test locally:** `dart analyze`, widget/smoke tests, simulator walkthrough.
9. **Do not push git or deploy to Hetzner/TestFlight.**

---

## Current state (baseline — your screenshot)

| Element | Today | File |
|---------|-------|------|
| Header | QR + search toggle + centered Payspin wordmark + notification bell + profile | `mobile/lib/presentation/home/home_page.dart` |
| Body | Single vertical list of `PayspinTikkieRow` | same |
| FAB | Gradient `+` → `/send/amount` | `main_shell.dart` + `PayspinGradientFab` |
| Bottom nav | Home \| Payspin (Groepies) pill | `PayspinBottomNav` |
| Search | Inline glass TextField when search icon tapped | `home_page.dart` |
| Empty state | Emoji + CTA “Create Tikkie” | `PayspinEmptyState` |
| Icons | Emoji from description via `PaymentVisuals` | `payment_visuals.dart` |
| Data | `PaymentLinkRepository.listLinks()` | no favorites API |

**Prototype note:** JSX `HomeScreen` had Tikkies / Deals / Groepies **tabs**. Flutter moved Groepies to bottom-nav tab 2. **Keep bottom nav model** — do not reintroduce 3 top tabs unless you merge Deals as a home section (see suggestions).

---

## Target design (user brief → Payspin mapping)

Premium dark fintech home (`#0B0B12`), neon pink `#FC00FF` → teal `#07D8DD`, glass cards, soft glow, uncluttered spacing.

### Section map

| # | User spec | Payspin implementation |
|---|-----------|------------------------|
| **Header** | QR, search, logo, notifications badge, profile | **Keep existing** — polish spacing/glow only if needed |
| **1 · Quick actions** | 6 shortcuts in horizontal row | **Agent must decide** — see [Quick actions decision tree](#quick-actions-decision-tree) |
| **2 · Favorites** | Horizontal scroll cards + star | **Client-side only** — `SharedPreferences` pinned link IDs (max 8); long-press or star on row/detail |
| **3 · Recommended** | 2 large gradient promo cards | **Heuristic CTAs** from link history — no ML, no backend |
| **4 · Active requests** | One highlighted card, progress e.g. “2/3 paid” | **Derive from `PaymentLink`:** MULTI + `COLLECTING`/`ACTIVE`, or SINGLE with pending payment (if detectable from list fields) |
| **5 · Recent links** | Vertical list (current rows) | **Reuse/enhance `PayspinTikkieRow`** — exclude links already shown in Favorites/Active hero |
| **FAB** | Gradient + glow | **Keep** — still primary “New link”; don’t duplicate if Quick actions includes New link |
| **Bottom nav** | Home active, Payspin tab | **Keep `PayspinBottomNav`** — optional subtle glow polish |

---

## Quick actions decision tree

**Product rule:** Every visible shortcut must **do something real today** or show as **disabled** with tooltip (“Coming soon”).

Audit existing routes/actions before drawing UI:

| Spec action | Real today? | Route / behavior |
|-------------|-------------|------------------|
| New link | ✅ | `context.push('/send/amount')` — **same as FAB** |
| Split bill | 🟡 | Groepies tab `/home/groepies` — circles exist but group split is early |
| Request payment | ✅ | **Duplicate of New link** — merge, don’t show twice |
| Copy link | 🟡 | Needs **target link** — copy `payUrl` of **most recent ACTIVE** link, or last created; snackbar on success |
| Share link | 🟡 | Use `ShareService` on same target as copy — see `link_detail_page.dart` |
| Scan QR | ✅ | `context.push('/scan')` — **duplicate of header QR** |

### Recommended agent decision (default)

**Include a compact row of 4 actions** (not 6):

1. **New link** — `/send/amount`
2. **Scan** — `/scan`
3. **Share last** — share most recent payable link (disabled + hint if none)
4. **Groepies** — `/home/groepies` (label “Split” or “Groepies” per l10n)

**Exclude from v1:** standalone “Request payment”, “Copy link” as separate tiles (fold into link detail + long-press on row). **Rationale:** avoids FAB + quick-action duplication and confusing “which link gets copied?”.

**Alternative (minimal):** **Skip Quick actions entirely** if FAB + header QR cover creation/scan — replace with a single-line **“Shortcuts”** subtitle only when user has 3+ links. Agent must **document choice** in plan with 2–3 sentences.

**Creative freedom:** Design gradient icon tiles (44–52px rounded squares) with labels under — match Dribbble spec — but **justify inclusion** in the plan.

---

## Data logic (no new backend)

### Favorites (local)

- Store `Set<String>` link IDs in `SharedPreferences` key `payspin_favorite_link_ids`.
- New small service: `FavoriteLinksStore` (mirror `intro_store.dart` pattern).
- Star toggle on `PayspinTikkieRow` and/or link detail overflow menu.
- Favorites section: horizontal `ListView` of compact `PayspinFavoriteLinkCard` widgets.
- Hide section when empty (don’t show empty favorites strip for new users).

### Active requests (computed)

Pick **at most one hero card** — highest priority:

1. MULTI link, status `COLLECTING` or `ACTIVE`, `useCount < maxUses` → show `usageLabel` + `PayspinProgressBar`
2. Else SINGLE `ACTIVE` with `amountCents != null` and age &lt; 7 days
3. Else hide section

Tap → `/links/:id`.

### Recommended for you (computed)

Two cards max, examples:

| Card | When | Action |
|------|------|--------|
| **Create a dinner split** | User has food-related link in last 30 days OR ≥2 links total | `/send/amount` with optional query `?hint=dinner` (UI prefill description only — optional) |
| **Request again** | Most recent **SETTLED** link with description | `/send/amount` prefill amount + description from that link |
| **Try Groepies** | User has 0 circles but ≥1 link | `/home/groepies` |
| **Share your last link** | Latest ACTIVE link exists | Share sheet |

Use `PayspinGlassSurface` + `gradientTri` border glow — extract `PayspinPromoGradientCard`.

### Recent links

- All links sorted by `createdAt` desc.
- **Dedupe:** omit IDs shown in Favorites horizontal strip and Active hero.
- Section header: “Recent links” (l10n EN + NL).
- Keep pull-to-refresh on whole scroll view.

### Empty home (new user)

When `_links.isEmpty`:

- **Do not** show Quick actions row, Favorites, Recommended, Active, or Recent sections.
- Show enhanced empty state: stacked ghost cards (`PayspinStackedCardsIllustration`) + gradient CTA — match prototype spirit.
- Optional: single hero “Create your first link” gradient card instead of 6 quick tiles.

---

## UI/UX specification

### Visual language

- **Background:** `PayspinAmbientBackground` (already in shell) — add subtle radial glow behind Active hero only.
- **Cards:** `PayspinGlassSurface` tiers — `flat` for rows, `raised` for hero/recommended.
- **Borders:** default `border`; active/favorite use `borderActive` pink glow at ~28–45% alpha.
- **Icons:** Prefer **gradient-filled rounded squares** with Material symbols **or** keep emoji avatars for link rows (user likes current emoji idea — **enhance**, don’t replace unless better).
- **Improve emoji tiles:** optional gradient ring behind emoji, or category-colored glyph from `PaymentVisuals` + subtle neon edge.
- **Typography:** Section titles — Raleway 18–20 w800; subtitles Inter 13 `textMuted`.
- **Spacing:** 20px horizontal padding; 24px between sections; 12px between rows.

### New widgets (extract to design system)

Create under `mobile/lib/core/design_system/widgets/`:

| Widget | Role |
|--------|------|
| `PayspinHomeSectionHeader` | Title + optional “See all” |
| `PayspinQuickActionTile` | Gradient icon + label |
| `PayspinQuickActionsRow` | Horizontal scroll of tiles |
| `PayspinFavoriteLinkCard` | Compact horizontal card + star |
| `PayspinPromoGradientCard` | Large recommended CTA |
| `PayspinActiveRequestHero` | Progress + amount + status |
| `PayspinLinkIconAvatar` | Shared emoji/glyph tile (refactor from Tikkie row) |

### Header polish (optional P1)

- Notification badge already on `NotificationBell` — verify matches screenshot (purple badge).
- Consider collapsing QR + Search into same row density as screenshot — don’t shrink tap targets below 44pt.

### Accessibility

- Semantics labels on every shortcut and card.
- Sufficient contrast on `textMuted` over glass.
- Haptic on star toggle and quick actions (`HapticFeedback.selectionClick`).

### Localization

Add EN + NL strings in `payspin_localizations.dart` for all new section titles, quick action labels, recommended card copy, empty hints.

### Motion (P1 polish)

- Staggered fade-in for sections on first load (`PayspinMotion.fast`).
- Star toggle scale animation.
- Respect reduced motion if platform setting detected.

---

## Architecture

```
home_page.dart
  ├── loads PaymentLinkRepository.listLinks()
  ├── FavoriteLinksStore (prefs)
  ├── computes: favorites, activeHero, recommended[], recent[]
  └── CustomScrollView slivers:
        SliverToBoxAdapter(header)
        SliverToBoxAdapter(quick actions?) 
        SliverToBoxAdapter(favorites?)
        SliverToBoxAdapter(active hero?)
        SliverToBoxAdapter(recommended?)
        SliverToBoxAdapter(section header)
        SliverList(recent rows)
```

- Keep `LinksRefreshNotifier` listener — home refreshes when link created elsewhere.
- Search: when query non-empty, **hide dashboard sections** and show filtered list only (current behavior extended).

**Do not break:** `MainShell` FAB, bottom nav routes, profile/notifications navigation.

---

## Creative suggestions (implement subset)

Agent should pick **at least 3** beyond baseline:

| Idea | Priority | Notes |
|------|----------|-------|
| Long-press row → Copy / Share / Favorite sheet | P1 | Power users |
| “Open amount” links show mint accent | P1 | Visual distinction |
| Groepies promo at bottom of recent list | P2 | `PayspinGroepiesPromoCard` exists — re-home if not duplicated |
| Deals teaser section (static placeholder) | P3 | One glass card “Deals — soon” — no backend |
| Time-based greeting under logo (“Good evening”) | P3 | Subtle, Inter 13 muted |
| Skeleton loaders per section | P1 | Not just row skeletons |
| Swipe favorite on row | P2 | Optional Dismissible |

Document choices in `docs/agents/mobile-ui-audit.md` under **“Home premium redesign”**.

---

## Implementation phases

### STEP 0 — Visual audit (mandatory)

1. Open user screenshot + `resources/Payspin Design System/screens.jsx` `HomeScreen`.
2. List gap vs target sections in `docs/agents/mobile-home-redesign-plan.md`.
3. Record **Quick actions decision** with rationale.

### STEP 1 — Widgets

Build reusable widgets first; snapshot in widget tests where cheap.

### STEP 2 — Home composition

Refactor `home_page.dart` to sliver sections; preserve search + refresh + error states.

### STEP 3 — Favorites store + star UI

Wire star on row; persist IDs.

### STEP 4 — Share/copy last link

Reuse `ShareService`; clipboard via `Clipboard.setData`.

### STEP 5 — Polish

Glow, motion, l10n, empty states.

### STEP 6 — Test matrix (mandatory)

Run all rows; fix before done.

### STEP 7 — Report

Structured summary + screenshots description + “not pushed/deployed”.

---

## Test matrix

| # | Scenario | Expected |
|---|----------|----------|
| 1 | New user, 0 links | Empty state only; no orphan sections |
| 2 | 1 ACTIVE link | Recent list shows it; Active hero may show; Share last works |
| 3 | 5+ links | All sections render; scroll smooth; FAB not obscured |
| 4 | Favorite star tap | Persists after kill/relaunch |
| 5 | Unfavorite | Removed from Favorites strip |
| 6 | MULTI COLLECTING 2/3 | Active hero shows progress |
| 7 | Search open | Sections hidden; filter works |
| 8 | Pull refresh | Reloads from API |
| 9 | Quick action New link | Opens send flow |
| 10 | Quick action Scan | Opens scan |
| 11 | Quick action Share last | Share sheet or disabled state |
| 12 | Tap recent row | `/links/:id` |
| 13 | Tap recommended card | Correct navigation |
| 14 | NL locale | All new strings translated |
| 15 | Light theme (if supported) | Readable — semantic colors |
| 16 | `dart analyze mobile` | No new errors |
| 17 | `flutter test` | Existing + any new tests pass |
| 18 | Bottom nav Groepies | Still works |
| 19 | Notification bell | Still navigates |
| 20 | Offline / API error | Error empty state + retry |

---

## Key files

| Path | Role |
|------|------|
| `mobile/lib/presentation/home/home_page.dart` | Main refactor target |
| `mobile/lib/presentation/shell/main_shell.dart` | FAB + nav — touch lightly |
| `mobile/lib/core/design_system/widgets/payspin_tikkie_row.dart` | Row + star |
| `mobile/lib/core/design_system/widgets/payspin_bottom_nav.dart` | Nav polish |
| `mobile/lib/core/design_system/widgets/payspin_groepies_promo_card.dart` | Optional promo |
| `mobile/lib/core/utils/payment_visuals.dart` | Icons/emoji |
| `mobile/lib/data/services/share_service.dart` | Share |
| `mobile/lib/domain/entities/payment_link.dart` | Status/usage helpers |
| `resources/Payspin Design System/screens.jsx` | Prototype floor |
| `docs/agents/design-hard-audit.md` | Token compliance |

---

## Definition of done

- [ ] Home matches **premium fintech** spec: glass, glow, gradients, clear hierarchy.
- [ ] **Quick actions** either thoughtfully included (≤4 real actions) or excluded with documented rationale.
- [ ] Favorites, Active hero, Recommended, Recent sections work off **real link data**.
- [ ] No fake interactions; disabled states honest.
- [ ] EN + NL l10n for new copy.
- [ ] Widget tests or smoke tests for favorites store + section visibility logic.
- [ ] `dart analyze` + `flutter test` pass.
- [ ] Manual test matrix 1–20 verified on simulator.
- [ ] `docs/agents/mobile-ui-audit.md` updated.
- [ ] **No git push, no cloud deploy, no commit** unless user asks.

---

## ⬇️ COPY BLOCK — paste into Agent chat

```
@docs/agents/mobile-home-premium-redesign-prompt.md
@docs/agents/mobile-ui-ux-enhancement-prompt.md
@docs/agents/design-hard-audit.md
@AGENTS.md
@CLAUDE.md
@.cursor/skills/payspin/SKILL.md
@.cursor/skills/payspin-design/SKILL.md
@mobile/lib/presentation/home/home_page.dart
@mobile/lib/presentation/shell/main_shell.dart
@mobile/lib/core/design_system/widgets/payspin_tikkie_row.dart
@mobile/lib/core/design_system/widgets/payspin_bottom_nav.dart
@mobile/lib/core/design_system/tokens/payspin_tokens.dart
@mobile/lib/core/utils/payment_visuals.dart
@mobile/lib/domain/entities/payment_link.dart
@mobile/lib/data/services/share_service.dart
@resources/Payspin Design System/screens.jsx
@resources/Payspin Design System/README.md

You are a senior Flutter engineer and fintech product designer. Redesign the Payspin mobile Home tab into a premium dark-mode dashboard matching the user brief: glassmorphism, pink→teal neon gradients, soft glow, Revolut/Wise-level polish — while staying on Payspin tokens and real business logic.

Read the prompt file completely. Compare against the current TestFlight home (flat link list + header + FAB + bottom nav).

CRITICAL PRODUCT DECISION — Quick actions:
- Audit which shortcuts are real today vs duplicates (New link = FAB; Scan = header QR; Request payment = New link).
- Either show a max-4 row (New link, Scan, Share last, Groepies) OR skip Quick actions entirely with written rationale. Never show 6 tiles where half are redundant or broken.

Implement without backend changes:
- Favorites via SharedPreferences star toggle
- Active request hero from MULTI/COLLECTING progress
- Recommended cards from heuristics (request again, dinner split, Groepies)
- Recent links list (enhanced PayspinTikkieRow)
- Keep header, FAB, bottom nav behavior

Extract new widgets to core/design_system. Add EN+NL l10n. Update docs/agents/mobile-ui-audit.md.

Execute STEP 0–7 in ONE session. Write docs/agents/mobile-home-redesign-plan.md after STEP 0, then implement.

TESTING MANDATORY: run the 20-row test matrix, dart analyze, flutter test. Fix all failures.

CONSTRAINTS:
- Do NOT git push
- Do NOT deploy (Hetzner, TestFlight, Shorebird)
- Do NOT commit unless I explicitly ask
- mobile/ scope only

End with: section-by-section screenshot checklist, quick-actions decision summary, test results table, confirmation nothing was pushed/deployed.
```
