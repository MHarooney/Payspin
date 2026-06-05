# Payspin — Payer web UI/UX enhancement + branded QR (Tikkie-inspired, Payspin-branded)

**Purpose:** Paste this file (or `@docs/agents/payer-web-ui-enhancement-prompt.md`) when upgrading the **public payer web** (`pay.payspin.io`) and the **payee QR display** (mobile P07) to a polished, Tikkie-quality experience — **without copying Tikkie purple/green**. Use Payspin dark tokens, pink→mint gradient CTAs, and professional fintech UX.

**Live references (study before coding):**

| What | URL / path |
|------|------------|
| **Current Payspin payer page** | https://pay.payspin.io/{shortCode} (e.g. create a fresh link locally — prod links expire) |
| **Tikkie payer UX reference** | https://tikkie.me/pay/dj7ma29iqj87oo53qb4q |
| **Tikkie QR reference asset** | `resources/assets/ref-tikkie-p2p-qr-payer-01.jpeg` |
| **Payspin wireframes W01–W06** | `resources/wireframes/index.html` (#web) |
| **Dark design prototype** | `resources/Payspin Design System/Payspin Prototype.html` |
| **Design tokens** | `resources/Payspin Design System/README.md` |

**User-provided screenshots (Jun 2026):** Tikkie payer landing, message field, FAQ accordion, payee QR screen, branded QR close-up — adapt layout and interaction, **not** Tikkie colors or copy.

**Tagline (exact):** *"Your money, your community, and your peace of mind."*

---

## Agent mandate

Act as a **senior full-stack engineer + product designer**. Do not stop at a mockup — **plan, implement, test, and verify** end-to-end.

1. **Audit** current payer web + mobile QR gap (STEP 0).
2. **Write a short implementation plan** in the PR description or a comment block before large edits.
3. **Implement** in minimal, reviewable phases (see [Phased delivery](#phased-delivery)).
4. **Hard-test** every scenario in [Test matrix](#test-matrix-mandatory) — local stack + Browser MCP / Playwright where available.
5. **Deploy** only when the user asks; otherwise leave changes ready with clear verification steps.

**Creative mandate:** Match or exceed Tikkie usability (trust, clarity, FAQ, optional message) while staying **100% Payspin brand** (`#0B0B12` page, `#15141F` cards, `#FC00FF` → `#07D8DD` CTAs, Raleway + Inter).

---

## Non-negotiables (read first)

1. Read [AGENTS.md](../../AGENTS.md), [architecture.md](architecture.md), [conventions.md](conventions.md), [frontend-nextjs.mdc](../../.cursor/rules/frontend-nextjs.mdc).
2. **Payer web has no auth** — public `GET /v1/pay/:code` only; never expose IBAN or payee PII beyond `payeeDisplayName`.
3. Yapily only via backend `PIS_GATEWAY` — frontend never calls Yapily directly.
4. Validation via Zod in `@payspin/validators` inside use cases.
5. **Minimal diffs** — no drive-by refactors outside payer web + QR scope.
6. **Do not copy Tikkie branding** (purple card, green buttons, “Pay with TIKKIE” wordmark). Use Payspin assets under `mobile/assets/images/` and design tokens below.
7. **Do not commit** `.env` or secrets.

---

## Current state (verified baseline — re-audit in STEP 0)

### Payer web (`frontend/`)

| File | Today | Gap vs Tikkie / wireframe W01 |
|------|-------|-------------------------------|
| `app/layout.tsx` | Light gray `#f9fafb` body | Should be dark `#0B0B12` + fonts |
| `app/[code]/page.tsx` | White card, inline styles, minimal copy | Missing header logo, hero hierarchy, FAQ, message, verified payee row |
| `app/[code]/pay-button.tsx` | Gradient CTA, open-amount input | Missing iDEAL/Yapily trust row, loading states, optional message |
| `app/[code]/callback/page.tsx` | Basic text + link | Not on-brand; needs dark shell + poller UX |
| `app/[code]/success/page.tsx` | Green check, light page | Needs amount, payee, reference — match W05 |
| `lib/api.ts` | `PaymentLinkView`, initiate/complete/status | Types mirror `@payspin/shared-types` — extend only if API changes |
| Tests | **None** | Add Playwright or component tests for status branches |

**API surface (unchanged unless payer message is added):**

```
GET  /v1/pay/:code              → PublicPaymentLinkView
POST /v1/pay/:code/initiate     → { amountCents? }
POST /v1/pay/:code/complete     → { paymentId, consentToken? }
GET  /v1/pay/:code/status/:id   → PaymentPublicStatus
```

Key backend: `get-public-payment-view.use-case.ts`, `initiate-payer-payment.use-case.ts`, `complete-payer-payment.use-case.ts`.

### Mobile QR (P07 — payee shows QR to payer)

| Item | Today | Gap |
|------|-------|-----|
| `qr_flutter` in `pubspec.yaml` | Dependency present | **No `QrImageView` usage** — P07 not implemented |
| `send_name_page.dart` | QR circle button `onPressed: () {}` | Dead control — must open QR screen |
| `link_detail_page.dart` | Copy link + share | Missing “Show QR” entry |
| `scan_qr_page.dart` | Payer scans QR (mobile) | Works — QR **generation** must encode `payUrl` |

---

## STEP 0 — Audit (mandatory before coding)

Use **Browser MCP** or local browser to capture side-by-side:

1. Open Tikkie reference: https://tikkie.me/pay/dj7ma29iqj87oo53qb4q  
   - Note: header, card hierarchy, “+ Add message?”, FAQ accordions, footer, cookie banner (optional for Payspin).
2. Open Payspin payer page with a **valid local link**:
   ```bash
   ./scripts/dev/payspin-dev start --web
   # Create link via mobile or e2e script, then open http://localhost:3000/{shortCode}
   ```
3. Document gaps in `docs/agents/payer-web-audit.md` (create if missing):
   - One section per screen: **W01 landing**, **W04 callback/processing**, **W05 success**, **W06 failed**, **P07 QR**
   - Columns: **Tikkie pattern** | **Payspin today** | **Planned change**
4. Do **not** start UI refactors until `payer-web-audit.md` exists.

---

## Design spec — Payspin payer web (Tikkie-inspired layout)

### Tokens (required — do not use Tikkie purple `#5f5fc4` or Tikkie green `#00a884`)

| Token | Hex | Usage |
|-------|-----|--------|
| Page bg | `#0B0B12` | Full viewport |
| Elevated card | `#15141F` | Payment card, FAQ items |
| Card accent gradient | `#FC00FF` → `#07D8DD` at ~14% opacity | Card header band (like Tikkie’s tinted card, but Payspin) |
| Glass border | `rgba(255,255,255,0.08)` | Card + FAQ outlines |
| Text primary | `#FFFFFF` | Headings, amount |
| Text muted | `rgba(255,255,255,0.55)` | Labels, footer |
| CTA | `linear-gradient(90deg, #FC00FF, #07D8DD)` | “Pay with my bank” pill |
| Success | `#10B981` | Verified check, success state |
| Warning | `#FFC408` | “Not paid yet” chips (mobile QR screen) |
| Error | `#EF4444` | Errors |

**Typography:** Raleway 700–900 (title, amount), Inter 400–600 (body). Load via `next/font/google` in `layout.tsx`.

**Logo:** Use Payspin wordmark/emblem from `mobile/assets/images/payspin_ic_white.png` (copy to `frontend/public/` if needed) — header: **“Pay with Payspin”** (sentence case).

### W01 — Link landing (primary deliverable)

Structure (top → bottom):

```
┌─────────────────────────────────────┐
│        [logo] Pay with Payspin      │  ← header, centered
├─────────────────────────────────────┤
│  ┌───────────────────────────────┐  │
│  │ {description or "Payment"}    │  │  ← h1, Raleway
│  │ To {payeeDisplayName} ✓       │  │  ← mint verified dot
│  │                               │  │
│  │         € XX,XX               │  │  ← hero amount (40–48px)
│  │                               │  │
│  │  [+ Add message?]  (toggle)   │  │  ← optional; see backend note
│  │  [ open amount input if null] │  │
│  │                               │  │
│  │  [ iDEAL · Yapily ] Pay now   │  │  ← gradient pill CTA
│  │                               │  │
│  │  By using Payspin, you accept │  │  ← legal footer in card
│  │  Terms of use                 │  │
│  └───────────────────────────────┘  │
│                                     │
│  Any questions?                     │
│  ▸ What is open banking?            │  ← accordion
│  ▸ How does this work?              │
│  ▸ Is Payspin secure?               │
│  ▸ Is it free?                      │
│                                     │
│  Having trouble?                    │
│  [ Contact support ]                │  ← mailto or help URL
│                                     │
│  © Payspin · Terms | Privacy        │
└─────────────────────────────────────┘
```

**Interaction details (match Tikkie quality):**

- **Verified payee:** Green/mint circle + check next to name (cosmetic trust signal — no KYC claim).
- **Description:** If `link.description` empty, title = “Payment request” (not blank h1).
- **Open amount:** Keep existing validation; styled dark input inside card.
- **Blocked states** (`SETTLED`, `CANCELLED`, `EXPIRED`, unknown status): Same card shell but replace CTA with clear notice (existing copy in `unavailableMessage()` — polish styling only).
- **404 / API error:** Dark page + empathetic copy (keep current messages).
- **FAQ content:** Write original Payspin copy (non-custodial, Yapily, SEPA, no app install). Do not paste Tikkie text.

### Optional payer message (Tikkie “Have a message for …?”)

**Product:** Collapsed pill “+ Add message?” → expands textarea (max **35** chars — SEPA reference limit), placeholder “E.g. thanks for lunch”.

**Backend (required if message should reach payee):**

1. Extend `initiatePaymentSchema` with optional `payerMessage: z.string().max(35).optional()`.
2. In `initiate-payer-payment.use-case.ts`, append to Yapily `reference` (respect bank field limits):
   - Fixed link: `{description} — {payerMessage}` or payer-only if no description.
3. Optionally persist `payerMessage` on `payments` table (migration) for payee inbox — **only if user/product wants persistence**; otherwise reference-only is enough for MVP.

If backend change is out of scope for a slice, ship UI disabled behind “Coming soon” **only** with explicit user approval — prefer shipping end-to-end.

### W04 — Callback / processing

- Reuse dark `PayspinWebShell` layout.
- `CallbackStatusPoller.tsx`: branded spinner + “Confirming with your bank…” + auto-redirect to success (already polls — style only).
- Cancelled / failed: W06 styling + “Try again” → `/{code}`.

### W05 — Success

- Show formatted amount, payee name, optional “You’re done — safe to close this page”.
- Link back to home unnecessary; optional “Pay another time” only for MULTI links if API exposes `linkType` (future — do not block on this).

### W06 — Failed / unavailable

- Distinct from success; red accent; preserve “do not pay again” copy on complete errors.

---

## Branded QR code (mobile P07 + shared spec)

**Goal:** Tikkie-style QR — rounded white plate, **Payspin-colored modules** (pink `#FC00FF` or gradient feel via single hue), **center emblem overlay** (`payspin_ic_opaque.png`), high error correction.

### Implementation (Flutter)

1. Create `mobile/lib/core/design_system/widgets/payspin_branded_qr.dart`:
   - `QrImageView` from `qr_flutter`
   - `data`: full `payUrl` (HTTPS in prod)
   - `errorCorrectionLevel: QrErrorCorrectLevel.H` (logo overlay)
   - `eyeStyle: QrEyeStyle(...)` — rounded module style if supported
   - `dataModuleStyle: QrDataModuleStyle(color: PayspinTokens.pink)` 
   - `embeddedImage`: `AssetImage('assets/images/payspin_ic_opaque.png')`
   - `embeddedImageStyle: QrEmbeddedImageStyle(size: Size(48, 48))`
   - White container: `BorderRadius.circular(24)`, padding 16, subtle shadow
2. Create `mobile/lib/presentation/links/link_qr_page.dart`:
   - Route: `/links/:id/qr` or `/qr?url=…` (prefer link id → load `payUrl` from repo)
   - Show: description, amount, status chip (“Not paid yet”), validity (`expiresAt`), “Share again”, optional “Delete” only on link detail (not here)
   - Match Tikkie **layout** from user screenshot: title, amount subtitle, QR hero, metadata rows, primary “Share again” gradient button
3. Wire entry points:
   - `link_detail_page.dart` — “Show QR” button
   - `send_name_page.dart` — QR circle opens QR page after link creation (or from share step)
4. **Regression:** Existing `scan_qr_page.dart` must decode URLs produced by branded QR (integration test or manual smoke).

### Optional: QR on payer web

Only if product asks — desktop payers sometimes scan from another device. Default scope is **mobile payee QR** only.

---

## Frontend architecture (match repo patterns)

```
frontend/
├── app/
│   ├── layout.tsx              ← dark bg, fonts, metadata
│   ├── globals.css             ← CSS variables for tokens (optional but preferred)
│   └── [code]/
│       ├── page.tsx            ← server component: fetch link, compose shell
│       ├── pay-button.tsx      ← client: initiate + message + open amount
│       ├── callback/...
│       ├── success/...
│       └── components/         ← NEW: PaymentCard, FaqAccordion, PayspinHeader, etc.
├── lib/
│   └── api.ts
└── public/
    └── payspin-logo-white.png
```

**Patterns:**

- Server Component for `fetchPaymentLink` (keep).
- Client Components only for interactivity (pay button, FAQ accordion, message toggle).
- Prefer **CSS modules** or `globals.css` + variables over huge inline `styles` objects — but stay consistent with existing files if a small diff is enough.
- Types from `@payspin/shared-types` — re-export in `lib/api.ts`, don’t duplicate DTOs.

---

## Test matrix (mandatory)

Run `./scripts/dev/payspin-dev doctor` first. Create **`frontend/e2e/`** Playwright tests **or** document manual Browser MCP runs — prefer automated for regression.

### Payer web — link states

| # | Scenario | Setup | Expected UI |
|---|----------|-------|-------------|
| 1 | Active fixed amount | Link €1.00 ACTIVE | Amount, payee, CTA enabled |
| 2 | Open amount | `amountCents: null` | Input visible; reject 0 / empty |
| 3 | With description | description set | Title = description |
| 4 | No description | null | Title = “Payment request” |
| 5 | SETTLED | Completed single link | Notice, no CTA |
| 6 | CANCELLED | Cancelled link | Notice, no CTA |
| 7 | EXPIRED status | status EXPIRED | Expired copy |
| 8 | Expired by date | `expiresAt` past | Same as expired |
| 9 | COLLECTING | MULTI link open | CTA enabled |
| 10 | 404 code | bogus shortCode | “Link not found”, no crash |
| 11 | API down | stop backend | “Something went wrong”, no stack trace |

### Payer web — payment flow

| # | Scenario | Expected |
|---|----------|----------|
| 12 | Initiate success | Redirect to Yapily/sandbox callback URL |
| 13 | Initiate conflict | Second pay on SINGLE in-flight → error toast |
| 14 | Open amount initiate | POST body includes `amountCents` |
| 15 | Callback cancelled | `?error=` → W06 + try again |
| 16 | Callback complete | Success path → `/success` |
| 17 | Callback pending | Poller runs ≤2 min then timeout message |
| 18 | Payer message (if implemented) | Reference includes message; max 35 enforced |

### Payer web — UX / a11y

| # | Check |
|---|--------|
| 19 | Mobile viewport 390×844 — no horizontal scroll |
| 20 | CTA min height 48px, focus visible |
| 21 | FAQ keyboard navigable (button/accordion) |
| 22 | Dark contrast — muted text still WCAG AA on `#15141F` |
| 23 | `prefers-reduced-motion` — disable fancy animations |

### Mobile QR

| # | Scenario | Expected |
|---|----------|----------|
| 24 | QR encodes `payUrl` | String equals API `payUrl` |
| 25 | Scan from `scan_qr_page` | Navigates/opens payer URL |
| 26 | Share again | Opens share sheet with message + URL |
| 27 | Expired link QR | Still shows QR but payer web shows expired (optional warning chip) |
| 28 | Widget test | `payspin_branded_qr` renders without overflow |

### Commands

```bash
# Local stack
pnpm install
./scripts/dev/payspin-dev start --web

# Frontend typecheck
pnpm --filter @payspin/frontend typecheck

# Backend tests (if payer message added)
pnpm --filter @payspin/backend test

# Mobile
cd mobile && flutter analyze && flutter test

# E2E API smoke (creates real link)
./scripts/dev/e2e-register-iban-link.sh
```

---

## Phased delivery

**Phase A — Design foundation + W01 landing**  
Dark layout, header, payment card, pay button polish, blocked states, FAQ, footer. Update `payer-web-audit.md`.

**Phase B — Callback + success + error (W04–W06)**  
Shared shell, poller styling, success amount/payee.

**Phase C — Branded QR (mobile P07)**  
Widget + page + router + link detail / send entry points + flutter tests.

**Phase D — Payer message (optional)**  
Validators → use case → pay-button → backend test → E2E #18.

**Phase E — Automated regression**  
Playwright in `frontend/` or extend existing scripts; CI hook if repo has pattern.

---

## Definition of Done

- [ ] `docs/agents/payer-web-audit.md` completed
- [ ] W01 matches design spec on mobile + desktop
- [ ] W04–W06 visually consistent
- [ ] Branded QR scannable from `ScanQrPage`
- [ ] All [Test matrix](#test-matrix-mandatory) scenarios pass (automated or documented with screenshots)
- [ ] `pnpm --filter @payspin/frontend typecheck` clean
- [ ] `cd mobile && flutter analyze && flutter test` clean
- [ ] No Tikkie colors, logos, or verbatim copy
- [ ] Minimal diff — no unrelated refactors

---

## Anti-patterns (do not)

- Tikkie purple card or green CTA
- White `#fff` payer page background (legacy wireframe W01 is light — **override with dark prototype** per CLAUDE.md)
- Light-theme cookie banner that clashes (if added, dark variant only)
- Calling Yapily from Next.js client
- Duplicating `PublicPaymentLinkView` fields in frontend only
- Large refactor of backend unrelated to payer message
- Shipping QR with low error correction and broken scans after logo overlay

---

## Production notes

| Item | Value |
|------|--------|
| Payer web | https://pay.payspin.io |
| API | Configured via `NEXT_PUBLIC_API_URL` at build time |
| Deploy | User-triggered — `./infrastructure/hetzner/deploy.sh` or frontend pipeline |

After deploy, verify with a **fresh payment link** — expired/missing codes (e.g. `izjegrk1`) correctly show “Link not found”.

---

## How to invoke this prompt

```
@docs/agents/payer-web-ui-enhancement-prompt.md

Execute STEP 0 audit, write the plan, then implement Phases A→E.
Use Browser MCP to compare pay.payspin.io and tikkie.me payer pages.
Hard-test every row in the test matrix before marking done.
```
