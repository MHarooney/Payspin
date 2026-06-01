# Payspin — Claude Code

See [AGENTS.md](AGENTS.md) for architecture, ports, and workflows.

## Design (read before UI work)

Payspin uses the **dark prototype** design system — not Tikkie purple or white wireframes.

**Canonical interactive prototype (source of truth for UI):**

https://claude.ai/design/p/0e804e64-9500-4d7e-9fb9-598d971d0b82?file=Payspin+Prototype.html

Same app as the repo copy below — use the local files for MCP/agents; use the Claude link in chat when you want the hosted preview.

| Source | Path / link |
|--------|-------------|
| **Interactive prototype** | [Claude design — Payspin Prototype.html](https://claude.ai/design/p/0e804e64-9500-4d7e-9fb9-598d971d0b82?file=Payspin+Prototype.html) |
| Local copy (MCP / offline) | `resources/Payspin Design System/Payspin Prototype.html` + `screens.jsx` |
| Tokens & voice | `resources/Payspin Design System/README.md` |
| Flutter map | `resources/docs/design-system-flutter-map.md` |
| Gap analysis | `docs/agents/mobile-ui-audit.md` |
| **Hard audit (all screens + colors)** | `docs/agents/design-hard-audit.md` |
| Flutter tokens | `mobile/lib/core/design_system/` |
| Figma (partial — DS page only) | https://www.figma.com/design/QEy9wqxzUbvamVknKwc8Be |

**Brand:** `#FC00FF` + `#07D8DD` on `#0B0B12` / `#15141F`. CTAs: `PayspinPrimaryButton` + `pinkTealGradient`. Tagline: *Your money, your community, and your peace of mind.*

Use skill `/payspin-design` or MCP server `payspin-design` to read design files. Use MCP `figma` with a Figma link when implementing from frames.

## MCP servers (`.mcp.json`)

| Server | Purpose |
|--------|---------|
| `payspin-design` | Design system files, docs, Flutter `design_system/` |
| `figma` | Figma frames, variables, assets (OAuth via `/mcp`) |
| `dart` | Flutter/Dart analysis in `mobile/` |
| `playwright` / `browsermcp` | Payer web / prototype browser QA |

After clone: run `claude` in this repo, approve project MCP servers, then `/mcp` → authenticate **figma** and **notion** if needed.

Optional env in `~/.claude.json` (user scope): `FLUTTER_DART=/path/to/flutter/bin/dart`

Setup details: [docs/agents/claude-mcp-setup.md](docs/agents/claude-mcp-setup.md)
