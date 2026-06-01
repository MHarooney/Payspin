# Claude design prototype — source of truth

## Canonical URL

**https://claude.ai/design/p/0e804e64-9500-4d7e-9fb9-598d971d0b82?file=Payspin+Prototype.html**

This is the **dark-mode interactive mobile prototype** for Payspin (iOS frame, React + inline JSX). It is the design context product and agents should follow — not the older light wireframes in `resources/wireframes/` unless explicitly asked.

## Repo mirror (for MCP and offline)

| File | Role |
|------|------|
| `resources/Payspin Design System/Payspin Prototype.html` | Shell + nav pills + screen router |
| `resources/Payspin Design System/screens.jsx` | All screen components + `PS` tokens |
| `resources/Payspin Design System/ios-frame.jsx` | Device chrome |
| `resources/Payspin Design System/colors_and_type.css` | CSS tokens |

Agents with **`payspin-design` MCP** (see `.mcp.json`) read these paths directly. The Claude.ai URL is the same experience in the browser for humans and for Claude web chat when you paste the link.

## Screens in the prototype (14)

| Pill | Component | Flutter page |
|------|-----------|--------------|
| Welcome | `WelcomeScreen` | `welcome_page.dart` |
| 1: Name | `Step1Name` | `step_name_page.dart` |
| 2: Phone | `Step2Phone` | `step_phone_page.dart` |
| 3: OTP | `Step3OTP` | `step_otp_page.dart` |
| 4: IBAN | `Step4IBAN` | `step_iban_page.dart` |
| 5: Full Name | `Step5FullName` | `step_full_name_page.dart` |
| Success | `SuccessScreen` | `success_page.dart` |
| Home | `HomeScreen` | `home_page.dart` (+ tabs) |
| Groepies | `GroepiesScreen` | `groepies_page.dart` |
| Profile | `ProfileScreen` | `profile_page.dart` |
| Scan QR | `ScanQRScreen` | `scan_qr_page.dart` |
| Send: Amount | `SendAmountScreen` | `send_amount_page.dart` |
| Send: Label | `SendNameItScreen` | `send_name_page.dart` |

**Not in prototype** (implemented in app anyway):

| Flutter | Notes |
|---------|--------|
| `login_page.dart` | Email/password auth — backend requirement |
| `step_connect_bank_page.dart` | Yapily AIS — replaces prototype-only IBAN-only path for many users |
| `link_detail_page.dart` | **Swimming / payments screen** — product screen; prototype `onOpenTikkie` is a no-op |
| `notifications_page.dart`, Circles routes | Phase 2+ |

## Brand tokens (prototype `PS` = Flutter `PayspinTokens`)

| Token | Hex | Usage |
|-------|-----|--------|
| `bg` | `#0B0B12` | Page background |
| `bgElevated` | `#15141F` | Cards |
| `pink` | `#FC00FF` | Primary brand |
| `mint` | `#07D8DD` | Accent, paid status |
| CTA gradient | pink → mint | `PayspinGradientPillButton` |

## How to use per tool

| Tool | What to do |
|------|------------|
| **Claude.ai chat** | Paste the canonical URL in the first message: *"Match this prototype: …"* |
| **Claude Code** | Open repo; use `/payspin-design`; MCP reads local prototype files |
| **Cursor** | Enable **Figma** plugin only if using Figma frames; for this prototype use repo files + `payspin-design` MCP in `.mcp.json` |
| **Local QA** | `open "resources/Payspin Design System/Payspin Prototype.html"` |

## Browser MCP (Cursor) — tested 2026-06-01

The **claude.ai/design** URL is **not** usable by browser MCP: Cloudflare bot check → login redirect. Agents cannot scrape that link directly.

**Works:** serve the repo copy over HTTP, then open in browser MCP:

```bash
./scripts/dev/serve-design-prototype.sh
# → http://localhost:8765/Payspin%20Prototype.html
```

### Best context stack (ranked)

| Priority | Source | Why |
|----------|--------|-----|
| 1 | **`payspin-design` MCP** + `screens.jsx` | Exact tokens, layout code, copy — best for **implementing** Flutter |
| 2 | **`cursor-ide-browser`** on localhost prototype | **Screenshots** + rich a11y tree (e.g. tikkie row labels); **clicks nav pills** reliably |
| 3 | **`browsermcp`** on same localhost URL | **Screenshots** show full phone frame well; pill clicks were flaky in testing |
| 4 | **Claude design URL** (human / Claude web only) | Same UI when logged in; blocked for automation |
| 5 | **Figma MCP** | Not this prototype; Starter rate limits |

**Recommended Cursor setup for UI work:** `payspin-design` + `dart` + run `serve-design-prototype.sh` + ask agent to use **cursor-ide-browser** on `http://localhost:8765/Payspin%20Prototype.html` (jump pills: Home, Send: Label, etc.).

## Flutter vs prototype — quick diff

Full audit: `docs/agents/mobile-ui-audit.md`.

**Aligned:** dark theme, gradients, home tabs, send flow, share-via-WhatsApp on send-name, bottom nav + FAB.

**Prototype gaps filled in app:** link detail with hero card + payment timeline; connect-bank step; login; notifications bell.

**App still behind prototype polish (optional):** motion/entrance animations, some empty-state illustrations (stacked cards), Deals tab placeholder richness.

**Do not use for UI floor:** `resources/wireframes/index.html` (light P08 wireframes) — different visual era; only useful for flow IDs (P01–P14).
