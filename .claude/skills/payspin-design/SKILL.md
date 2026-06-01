---
name: payspin-design
description: Payspin dark mobile design system — tokens, JSX prototype, Flutter widgets, Figma wireframes. Use before any UI or visual work in mobile or HTML mocks.
user-invocable: true
---

# Payspin design skill

## When to use

- Building or changing **mobile** screens (`mobile/lib/presentation/`)
- Creating **HTML mocks** or marketing visuals
- Comparing implementation to **Figma** or the **JSX prototype**
- Reviewing **brand** (colors, type, voice)

## Canonical prototype (interactive)

**Hosted:** https://claude.ai/design/p/0e804e64-9500-4d7e-9fb9-598d971d0b82?file=Payspin+Prototype.html

**Repo (for MCP — same screens):** `resources/Payspin Design System/Payspin Prototype.html` loads `screens.jsx` + `ios-frame.jsx`. Use nav pills to jump: Welcome → steps 1–5 → Success → Home → Groepies → Profile → Scan → Send amount/label.

## Read first (via MCP `payspin-design` or repo paths)

1. `resources/Payspin Design System/README.md` — voice, colors, components
2. `resources/Payspin Design System/screens.jsx` — canonical screen layout (same as prototype)
3. `resources/docs/design-system-flutter-map.md` — JSX → Dart mapping
4. `docs/agents/mobile-ui-audit.md` — match / partial / missing per Flutter screen
5. `mobile/lib/core/design_system/payspin_theme.dart` — implemented tokens

Local visual QA: `open "resources/Payspin Design System/Payspin Prototype.html"`

## Rules (non‑negotiable)

- **Dark prototype only:** `PayspinTheme.bgDark` (`#0B0B12`), `bgElevatedDark` (`#15141F`)
- **Gradients:** pink `#FC00FF` → cyan `#07D8DD` on primary CTAs — never flat purple AppBar
- **Scaffold:** `PayspinDarkScaffold(glow: true)` for welcome/login/onboarding
- **Modals:** dark elevated background — never `Colors.white`
- **Type:** Raleway headings, Inter body

## Figma

Wireframes file: https://www.figma.com/design/QEy9wqxzUbvamVknKwc8Be

Paste a **frame URL** (with `node-id`) into chat when using the **figma** MCP server so Claude loads the correct context.

## Flutter implementation checklist

- [ ] Matches `screens.jsx` structure for the screen
- [ ] Uses existing widgets under `lib/core/design_system/widgets/`
- [ ] No new icon packages if Figma MCP provides asset URLs
- [ ] `flutter analyze` clean on touched files
