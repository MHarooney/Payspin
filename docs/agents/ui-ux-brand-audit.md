# Payspin UI/UX brand audit — logos, themes, glassmorphism

**Companion doc only.** For plan + implement all phases, use the **master prompt**:

→ **[ui-ux-brand-enhancement-prompt.md](ui-ux-brand-enhancement-prompt.md)** (copy the master block at the top)

The agent writes findings into **`docs/agents/ui-ux-brand-master-plan.md`** then implements Phases 0→D.

**Date:** 2026-06-05  
**Scope:** Mobile (Flutter), payer web (Next.js), QR branding, design tokens  
**Canonical emblems:** `Emblem_White-01` (dark surfaces), `Emblem_Gradient-01` (light surfaces / QR centre)

---

## Executive summary

**Status: Phases 0→D shipped (2026-06-05).** Mobile `flutter test` 176 pass / 3 pre-existing
network-timer failures (unrelated to this work, confirmed identical at HEAD); payer-web
production build green; live browser smoke passes in both themes.

| Area | Before | Gap | Phase | Status |
|------|--------|-----|-------|--------|
| Logo assets | Legacy `payspin_ic*.png` (mixed quality) | Official transparent emblems + STEP 0 pipeline | **0 → A** | ✅ shipped |
| Theme | Dark-only (`ThemeMode.dark` locked) | Light theme + user toggle | **A** | ✅ shipped |
| Glassmorphism | Ad-hoc `PayspinTokens.glass` fills | Shared `PayspinGlassSurface` | **A** | ✅ shipped |
| QR branding | `payspin_ic_opaque` centre | Gradient emblem + glass plate | **A** | ✅ shipped |
| Payer web | Dark-only CSS vars | Light theme + emblem swap | **A** | ✅ shipped |
| Screen migration | ~40 screens hardcode `PayspinTokens.bg` | Must adopt `ThemeExtension` | **B** | ✅ listed screens migrated |
| Motion / polish | Static glows | Logo spin loader, card micro-interactions | **C** | ✅ shipped |
| **Logo asset quality** | JPEG mislabeled PNG; possible bg bleed | Detect, trim, PNG-24 alpha, optional SVG layers | **0** | ✅ real RGBA PNGs (SVG deferred) |
| **Logo animation** | None | Splash assemble, spin loader, success bounce | **C** | ✅ shipped |
| **Ease of use** | Mostly OK; some dead controls | Task tap-count audit; one primary CTA rule | **B** | ✅ shipped |
| Figma parity | Partial | Full wireframe pass per screen | **D** | ⚠️ deferred (manual) |

---

## Logo inventory

| Asset | Path | Use |
|-------|------|-----|
| Emblem white | `mobile/assets/images/payspin_emblem_white.png` | Dark bg, splash, nav on `#0B0B12` |
| Emblem gradient | `mobile/assets/images/payspin_emblem_gradient.png` | Light bg, QR centre, payer web light |
| Legacy opaque | `payspin_ic_opaque.png` | App icon only (launcher) |
| Payer web | `frontend/public/payspin-emblem-{white,gradient}.png` | Header by theme |

**Rule:** `PayspinLogo(style: auto)` → white on dark, gradient on light. Never stretch; always `BoxFit.contain`.

**Note:** Source files may be JPEG with `.png` extension — run STEP 0 detection in [ui-ux-brand-enhancement-prompt.md](ui-ux-brand-enhancement-prompt.md) before shipping. Export true PNG-24 with alpha from Figma; optional SVG layer split (upper arc + lower loop) for splash/loader animation.

---

## Logo processing checklist (Phase 0 — plan only)

| Step | Action | Done when |
|------|--------|-----------|
| Detect | `file`, alpha check, visual on `#0B0B12` / `#F9F9F9` | Table documented |
| Trim | Crop to content + 8% safe padding | No halo on either theme |
| Export | PNG @1x/2x/3x white + gradient | Committed to mobile + frontend public |
| QR test | Centre emblem @ ~19% width, EC H | Scans on 2 devices |
| Vector (optional) | Split arrows for animation | SVG or `CustomPainter` spec in plan |

---

## Motion & UX gaps (for prompt agent)

| Gap | Target |
|-----|--------|
| Splash | Emblem assemble ≤ 900 ms, skippable |
| API loading | Branded spin loader 2.4 s loop + reduced-motion fallback |
| Pay success | Check draw + emblem bounce — no confetti |
| Usability | ≤ 2 taps to QR; one gradient CTA per screen |
| Reduced motion | Static logo when OS requests reduce |

Full spec: [ui-ux-brand-enhancement-prompt.md § Motion design system](ui-ux-brand-enhancement-prompt.md#motion-design-system)

---

## Theme tokens

### Dark (canonical prototype)

| Token | Value |
|-------|-------|
| bg | `#0B0B12` |
| bgElevated | `#15141F` |
| glass fill | `rgba(255,255,255,0.06)` |
| glass border | `rgba(255,255,255,0.10)` |
| text primary | `#FFFFFF` |

### Light (design system README)

| Token | Value |
|-------|-------|
| bg | `#F9F9F9` |
| bgElevated | `#FFFFFF` |
| glass fill | `rgba(255,255,255,0.72)` |
| glass border | `rgba(10,13,19,0.08)` |
| text primary | `#0A0D13` |

Both themes share brand accents: pink `#FC00FF`, mint `#07D8DD`, gradient CTAs unchanged.

---

## Glassmorphism spec

Professional glass = **blur + translucent fill + hairline border + optional brand glow**.

| Property | Dark | Light |
|----------|------|-------|
| Blur σ | 18–24 | 18–24 |
| Fill | white @ 6% | white @ 72% |
| Border | white @ 10% | black @ 8% |
| Shadow | pink/mint soft glow | neutral + subtle pink |

Widget: `PayspinGlassSurface` — use for cards, icon buttons, bottom nav (Phase B migration).

---

## QR code spec

- Error correction **H** (non-negotiable — centre logo)
- White plate with glass shadow (pink glow dark / neutral light)
- Data modules: `#1A1230` on white plate
- Finder eyes: pink circles
- Centre: **gradient emblem** @ ~19% of QR width
- Verified: `mobile/test/branded_qr_test.dart`, manual scan from `link_qr_page`

---

## Files targeted (implementation via prompt — not started)

See [ui-ux-brand-enhancement-prompt.md](ui-ux-brand-enhancement-prompt.md) file map. Partial scaffold files may exist in repo from exploration; treat prompt as source of truth when executing.

---

## Test matrix — results (2026-06-05)

| # | Case | Method | Result |
|---|------|--------|--------|
| 1 | `PayspinLogo` / theme extension resolves white + gradient | `flutter test` (`theme_and_loader_test`) | ✅ pass |
| 2 | `ThemeModeController` loads + persists mode | `flutter test` | ✅ pass |
| 3 | Light theme: readable text, gradient emblem in header | browser smoke (chrome-devtools) | ✅ pass |
| 4 | Branded QR encodes URL, EC level H, gradient centre | `flutter test` (`branded_qr_test`) | ✅ pass |
| 5 | `PayspinEmblemLoader` spins / static under reduced motion | `flutter test` | ✅ pass |
| 6 | Payer-web no-flash respects `prefers-color-scheme` | browser (`data-theme=light` on load) | ✅ pass |
| 7 | Payer-web toggle swaps CSS vars + emblem + persists | browser (light↔dark, `localStorage`) | ✅ pass |
| 8 | Pay page renders fully (amount, CTA, FAQ) both themes | browser smoke | ✅ pass |
| 9 | FAQ accordion grid-rows + opacity animation | browser (open item expands) | ✅ pass |
| 10 | Payer-web production build (type-check + lint) | `next build` | ✅ pass |
| — | QR scan from printed/on-screen code | physical device | ⚠️ manual — no device attached |
| — | Full Figma wireframe parity per screen | manual review | ⚠️ deferred |

**Known pre-existing failures (not from this work):** `screens_smoke_test` →
`onboarding connect bank`, `send name`, `notifications` leave a pending 3s timer from
`readSecureStorage` network calls in `initState`. Verified identical at HEAD with all
changes stashed.
