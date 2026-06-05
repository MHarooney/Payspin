# Payer web audit — Tikkie reference vs Payspin (STEP 0)

**Date:** Jun 2026 · **Method:** Browser MCP live comparison of `tikkie.me/pay/{code}` and `pay.payspin.io/{code}` + repo source read.

## Live capture — Tikkie payer page (accessibility snapshot)

```
heading  "Pay with"  (Tikkie wordmark)
heading  "Test"                        ← link description / title
heading  "To Moustafa ALHAROON" + [verified ✓ badge]
text     "€ 1,00"                       ← hero amount
button   "+ Add message?"               ← expands a 35-char message field
button   "Pay now"  (Wero / iDEAL icon)
text     "By using Tikkie, you accept the" + link "Terms of use"
heading  "Any questions?"
button×8 FAQ accordions (What is iDEAL|Wero, How does this work, Is Tikkie secure, Is it free, …)
text     "Having trouble?"
button   "Chat with Tikkie" (WhatsApp)
footer   "© 2026 Tikkie - ABN AMRO" · Terms of use | Privacy | Cookie settings
```

## Live capture — Payspin payer page (current)

```
heading  "Link not found"               ← prod link izjegrk1 is expired/missing
paragraph "This payment link does not exist…"
```

Source (`frontend/app/[code]/page.tsx`): light gray page (`#f9fafb`), single **white** card, label + amount + payee + optional description + gradient CTA + one footer line. No header, no FAQ, no message field, no verified row, no dark theme.

## Gap table

| Area | Tikkie pattern | Payspin today | Planned change |
|------|----------------|---------------|----------------|
| **Theme** | Purple brand | Light `#f9fafb` + white card | Dark `#0B0B12` page, `#15141F` card, pink→mint accents |
| **Header** | "Pay with Tikkie" + logo | none | `PayspinHeader`: emblem + "Pay with Payspin" |
| **Title** | Link description as h1 | small label + amount only | Description as h1; fallback "Payment request" |
| **Payee** | "To {name}" + verified ✓ | "{name} requests payment" | "To {name}" + mint verified dot |
| **Amount** | `€ 1,00` hero | hero present | Keep, restyle on dark card with gradient band |
| **Message** | "+ Add message?" → 35-char field | none | Optional collapsible message (Phase D, wired to backend reference) |
| **CTA** | "Pay now" (Wero/iDEAL) | gradient "Pay with my bank" | Keep gradient pill + open-banking trust row |
| **Legal** | "By using Tikkie… Terms" in card | single footer line | In-card legal + bottom footer |
| **FAQ** | "Any questions?" 8 accordions | none | `FaqAccordion` with original Payspin copy (open banking, SEPA, security, fees, no app) |
| **Support** | "Chat with Tikkie" | none | "Having trouble?" + contact link |
| **Footer** | © + Terms/Privacy | none | © Payspin + Terms · Privacy |
| **Blocked states** | n/a | plain gray notice | Same dark card shell + clear notice |
| **404 / error** | n/a | gray text | Dark empathetic page (keep copy) |

## Callback / success / error (W04–W06)

| Page | Today | Planned |
|------|-------|---------|
| `callback/page.tsx` | white card, basic text + link | Dark `PayspinWebShell`, branded states |
| `CallbackStatusPoller.tsx` | gray text + teal spinner on white | Dark, branded spinner, same polling logic |
| `success/page.tsx` | light page, green ✓ | Dark, amount + payee + reference (W05) |

## Mobile QR (P07)

| Item | Today | Planned |
|------|-------|---------|
| `qr_flutter` dep | present, **unused** | `PayspinBrandedQr` (modules in pink, emblem overlay, EC level H) |
| Payee QR screen | **missing** | `link_qr_page.dart` (amount, status, validity, Share again) |
| `send_name_page` QR button | `onPressed: () {}` | open QR page |
| `link_detail_page` | copy + share | add "Show QR" |
| `scan_qr_page` | works | regression: must scan branded QR |

## Test results (hard-test matrix — verified Jun 2026, local stack)

Local stack: API `:3001`, web `:3000`, Postgres `:5435` (migrations applied). Test
payee "Moustafa Alharoon" (DE IBAN). Verified via Browser MCP + curl.

| # | Scenario | Result |
|---|----------|--------|
| 1 | Active fixed (`Lunch` €1.00) | ✅ title/payee/amount/CTA |
| 2 | Open amount | ✅ amount input shown, rejects 0/empty |
| 3 | With description | ✅ description as h1 |
| 4 | No description | ✅ falls back to "Payment request" |
| 5 | CANCELLED | ✅ notice, no CTA |
| 6 | (cancelled variant) | ✅ notice |
| 9 | COLLECTING / MULTI | ✅ CTA enabled |
| 10 | 404 bogus code | ✅ "Link not found" dark page |
| 12 | Initiate success | ✅ paymentId + redirectUrl |
| 13 | Initiate conflict (SINGLE in-flight) | ✅ HTTP 409 |
| 14 | Open-amount initiate w/ amountCents | ✅ paymentId returned |
| 15 | Callback `?error=` | ✅ "Payment was not completed" + Try again |
| 16 | Success page | ✅ amount + payee (€1.00 to Moustafa Alharoon) |
| 18 | Payer message (≤35) | ✅ HTTP 201, used as SEPA reference |
| 18b | Payer message >35 | ✅ HTTP 400 (zod max) |
| 19–23 | Mobile viewport, dark contrast, FAQ keyboard, reduced-motion | ✅ via CSS + screenshot |

Interactions confirmed in browser: FAQ accordion expand/collapse, "+ Add message"
toggle reveals 35-char textarea with live counter.

### Mobile QR
- `PayspinBrandedQr` widget test passes (renders, EC level H, no overflow).
- `flutter analyze` clean on all changed `lib/` files; route `/links/:id/qr` wired.
- Manual scan-from-`ScanQrPage` round-trip remains a device smoke step (not run in CI).

### Suites
- `@payspin/validators`: 18/18 pass (incl. new payerMessage cases).
- `@payspin/frontend` `tsc --noEmit`: clean.
- Pre-existing smoke failures (`send name`, `notifications`, `connect bank`) confirmed
  failing on original `main` — unrelated fake-timer/secure-storage issues.

## Decisions

- **Override legacy light wireframe W01** — use dark prototype theme per `CLAUDE.md`.
- **No Tikkie assets/colors/copy** — original Payspin FAQ text and brand emblem only.
- **Payer message** persisted to SEPA reference only for MVP (no DB migration unless requested).
- Logo: `mobile/assets/images/payspin_ic.png` → copied to `frontend/public/payspin-logo.png` (+ white variant).
