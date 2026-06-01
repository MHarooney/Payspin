# Claude MCP setup (Payspin + design)

Project MCP config: [`.mcp.json`](../../.mcp.json) (shared via git). Claude Code loads it when you run `claude` from the repo root.

Official reference: [Connect Claude Code to tools via MCP](https://code.claude.com/docs/en/mcp)

## Quick start (Claude Code CLI)

```bash
cd /path/to/Payspin
claude
```

1. Approve **project-scoped** servers when prompted.
2. Run `/mcp` → authenticate **figma** (browser OAuth) and **notion** if you use it.
3. Invoke design skill: `/payspin-design` or ask Claude to read `resources/Payspin Design System/README.md` via the `payspin-design` server.

Verify:

```bash
claude mcp list
```

## Servers in this repo

| Server | Type | Role |
|--------|------|------|
| `payspin-design` | stdio (filesystem) | Design system, docs, Flutter tokens, cursor rules |
| `figma` | HTTP | Figma file context, assets, Code Connect |
| `dart` | stdio | Flutter MCP (`dart mcp-server`) |
| `playwright` | stdio | Browser automation / payer web QA |
| `browsermcp` | stdio | Lightweight browser control |
| `notion` | HTTP | Notion workspace (optional) |

### Figma (recommended for design fidelity)

**Option A — plugin (skills + MCP):**

```bash
claude plugin install figma@claude-plugins-official
```

Then in Claude Code: `/plugin` → Installed → **figma** → authorize.

**Option B — already in `.mcp.json`:**

Remote server `https://mcp.figma.com/mcp` — run `/mcp` and complete OAuth.

**Payspin Figma file:** [Mobile Wireframes v1](https://www.figma.com/design/QEy9wqxzUbvamVknKwc8Be)

Copy a frame link (right-click → Copy link) and paste it in your prompt when asking Claude to implement a screen.

### Dart / Flutter path

Set once (user scope) if `dart` MCP fails to start:

```bash
claude mcp add --scope user --transport stdio dart-env -- echo ok  # placeholder to open config
```

Or add to `~/.claude.json` under your user `env`:

```json
"FLUTTER_DART": "/Users/you/flutter/bin/dart"
```

Project `.mcp.json` defaults to `/Users/mahmoudalharoon/flutter/bin/dart` if `FLUTTER_DART` is unset.

## Claude.ai (web) — [claude.ai/new](https://claude.ai/new)

Web chat does **not** read `.mcp.json` from your disk. Add connectors at:

**[claude.ai/customize/connectors](https://claude.ai/customize/connectors)**

Suggested connectors for Payspin work:

- **Figma** — same wireframes file as above
- **Notion** — if specs live there
- **GitHub** — if you attach repo context via integration

For full repo + design filesystem access, use **Claude Code** in the Payspin directory (not only the web UI).

## Claude Desktop (macOS)

Import from Desktop or merge into  
`~/Library/Application Support/Claude/claude_desktop_config.json`:

```bash
claude mcp add-from-claude-desktop
```

Or copy the `mcpServers` block from `.mcp.json` (use full paths instead of `${CLAUDE_PROJECT_DIR}` for Desktop).

## Cursor vs Claude

Your global Cursor config (`~/.cursor/mcp.json`) is separate. This repo’s `.mcp.json` is tuned for **Payspin design** (filesystem roots + Figma). Keep Cursor’s extra servers (excel, linkedin, etc.) in Cursor only — avoid duplicating secrets into git.

## Security

- Do **not** commit API keys into `.mcp.json`.
- Rotate any keys that were pasted into chat or shared configs.
- Approve project MCP servers only for repos you trust.

## Canonical design (Claude design share)

**https://claude.ai/design/p/0e804e64-9500-4d7e-9fb9-598d971d0b82?file=Payspin+Prototype.html**

- **Claude.ai web:** paste this URL in chat — that is the design context you want.
- **Claude Code / MCP:** same content lives under `resources/Payspin Design System/`; server `payspin-design` reads it locally.
- Details: [claude-design-prototype.md](./claude-design-prototype.md)

## Example prompts

```text
Match the Payspin dark prototype:
https://claude.ai/design/p/0e804e64-9500-4d7e-9fb9-598d971d0b82?file=Payspin+Prototype.html
Implement Home empty state from the "With history" / "Empty" toggles on Home.
```

```text
/payspin-design
Implement Step2Phone from screens.jsx in step_phone_page.dart. Use PayspinOnboardingShell.
```

```text
Read docs/agents/mobile-ui-audit.md and align link_detail_page.dart with SendNameItScreen + add payment timeline polish.
```
