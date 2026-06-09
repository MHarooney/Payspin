# Payspin Mobile — Home Premium Redesign Plan (STEP 0)

**Date:** 2026-06-09
**Scope:** `mobile/` presentation + design-system widgets + l10n + tests. **No backend changes. No git push. No deploy. No commit.**
**Reference:** TestFlight screenshot (flat link list + glass header + gradient FAB + pill bottom nav) vs. `resources/Payspin Design System/screens.jsx` `HomeScreen` (Tikkies list + promo) and the user brief (Revolut/Wise-level premium dark dashboard).

---

## 1. Baseline audit (current Home)

| Element | Today | Verdict |
|---------|-------|---------|
| Header | QR + search toggle + centered wordmark + bell + profile | Keep — polish only (add time-based greeting line) |
| Body | Single `SliverList` of `PayspinTikkieRow` | Replace with sectioned `CustomScrollView` |
| Search | Inline glass `TextField` toggled by header icon | Keep; when active, hide dashboard sections, show filtered list |
| Loading | 4 bare `PayspinSkeletonRow` | Upgrade to per-section skeleton |
| Empty | `PayspinEmptyState` (stacked cards + CTA) | Keep; suppress all dashboard sections when 0 links |
| Error | `PayspinEmptyState` + retry | Keep |
| FAB | Gradient `+` → `/send/amount` (in `MainShell`) | Keep unchanged |
| Bottom nav | Home \| Payspin pill | Keep unchanged |
| Data | `PaymentLinkRepository.listLinks()` | Keep; no new endpoints |

**Gap vs. premium target:** no favorites, no active-request hero, no recommended cards, no quick actions, no visual hierarchy beyond one flat list. All glass/gradient/token primitives already exist (`PayspinGlassSurface`, `gradientPink`/`gradientTri`, `PayspinProgressBar`, `PayspinStatusChip`, `PaymentVisuals`).

---

## 2. Quick actions decision (CRITICAL)

**Decision: INCLUDE a compact 4-tile row** (not 6), shown only when the user has ≥1 link.

| Tile | Route / behavior | Real today? | Why included |
|------|------------------|-------------|--------------|
| **New link** | `context.push('/send/amount')` | ✅ | Duplicates FAB, but FAB is draggable/can be moved off-screen; a labeled tile is the primary discoverable create affordance on premium dashboards |
| **Scan** | `context.push('/scan')` | ✅ | Duplicates header QR, but the header icon is tiny; a labeled 44pt tile is clearer |
| **Share last** | `ShareService` on most-recent payable link; **disabled + hint** when none | 🟡→ now real | Genuinely new capability not reachable elsewhere from Home |
| **Groepies** | `context.push('/home/groepies')` | ✅ | One-tap into the community tab; nav tab is the only other path |

**Excluded (with rationale):**
- **Request payment** — identical to *New link*; showing both is the exact redundancy the brief warns against. Folded into New link.
- **Copy link** — ambiguous ("which link?") as a standalone tile. Folded into the row **long-press sheet** and link detail (which already has Copy).
- **Split bill** as a separate tile — Groepies already covers the community/split entry; group split is early, so a dedicated tile would over-promise.

Net: every visible tile does something real today; *Share last* shows an honest disabled state with a hint when no payable link exists. No 6-tile clutter, no dead buttons.

---

## 3. Sections (composition)

`home_page.dart` → `CustomScrollView` slivers (in order), each conditionally rendered:

1. **Header** (existing) + time-based greeting subtitle.
2. **Quick actions** — `PayspinQuickActionsRow` (4 tiles). Hidden when 0 links or search active.
3. **Active request hero** — at most one (`PayspinActiveRequestHero`). Hidden if none.
4. **Favorites** — horizontal `ListView` of `PayspinFavoriteLinkCard`. Hidden when none pinned.
5. **Recommended** — up to 2 `PayspinPromoGradientCard`. Hidden when none apply.
6. **Recent links** — section header + `PayspinTikkieRow` list, **deduped** (excludes active-hero id + favorite ids).
7. Search active → only the filtered list (sections 2–5 hidden).
8. 0 links → only `PayspinEmptyState`.

### Active hero priority (≤1)
1. MULTI + status `COLLECTING`/`ACTIVE` + (`useCount < maxUses` or uncapped) → show `usageLabel` + `PayspinProgressBar` (`useCount/maxUses` when capped).
2. else SINGLE `ACTIVE` with `amountCents != null` and age < 7 days.
3. else hide. Tap → `/links/:id`.

### Recommended heuristics (≤2, deduped by type, client-side only)
1. **Request again** — newest `SETTLED` link with a description → `/send/amount` (opens create flow; no prefill since route takes no args — copy stays honest "Start a similar request").
2. **Split with Groepies** — user has ≥1 link → `/home/groepies`.
3. **Dinner split** — ≥2 links total → `/send/amount`.

### Favorites
- `FavoriteLinksStore` (`ChangeNotifier`, `SharedPreferences` key `payspin_favorite_link_ids`, max 8).
- Star toggle on `PayspinTikkieRow` + long-press sheet; haptic on toggle.
- Favorites strip lists pinned links that still exist in the loaded set.

---

## 4. New / changed files

**New widgets** (`mobile/lib/core/design_system/widgets/`):
- `payspin_home_section_header.dart` — title + optional "See all".
- `payspin_link_icon_avatar.dart` — shared emoji/glyph tile (extracted from row), optional gradient ring + open-amount mint accent.
- `payspin_quick_action_tile.dart` + `payspin_quick_actions_row.dart`.
- `payspin_favorite_link_card.dart` — compact card + star.
- `payspin_promo_gradient_card.dart` — gradient-border recommended CTA.
- `payspin_active_request_hero.dart` — progress + amount + status, radial glow.

**New store:** `mobile/lib/core/storage/favorite_links_store.dart` (+ DI registration in `injection.dart`).

**Changed:**
- `payspin_tikkie_row.dart` — star toggle, long-press sheet (Copy/Share/Favorite), open-amount mint accent, uses shared avatar.
- `home_page.dart` — sliver dashboard composition.
- `payspin_localizations.dart` — EN+NL+de+ar for all new copy.
- `mobile-ui-audit.md` — "Home premium redesign" section.

**Untouched:** `main_shell.dart` (FAB + nav), bottom nav routes, backend, packages.

## 5. Creative picks (≥3)
1. Long-press row → Copy / Share / Favorite sheet (P1).
2. Open-amount links get a mint accent on the avatar (P1).
3. Per-section skeleton loaders (P1).
4. Time-based greeting under the wordmark (P3).

## 6. Tests
- `favorite_links_store_test.dart` — toggle, persist, max-8 cap, isFavorite.
- `home_sections_test.dart` — pure section-logic helpers (active hero pick, recommended, dedupe) extracted to a testable function.
- l10n additions covered by extending `l10n_test.dart`.
- `dart analyze` + `flutter test` must pass.
