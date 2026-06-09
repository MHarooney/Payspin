# Payspin — Payment links without Yapily (full-context ChatGPT brainstorm)

**Purpose:** Paste the **COPY BLOCK** below into **ChatGPT** (no repo access needed). It contains the full Payspin product, architecture, data model, API, flows, Yapily dependency, and constraints so the AI can brainstorm **alternative rails** (free / low fixed cost) while keeping **link-based P2P payment logic**.

---

## How to use

1. Copy everything inside **COPY BLOCK** (from `You are a senior…` to the end).
2. Paste into a **new ChatGPT chat** (GPT-4o or o1 recommended for compliance reasoning).
3. Add your personal constraints at the bottom (markets, volume, manual OK?, budget).
4. Follow up: *"Deep dive option 2"* / *"Design Phase 0 payer page wireframe"* / *"Compare Mollie vs SEPA QR at 500 tx/month"*.

---

## ⬇️ COPY BLOCK — paste entire section into ChatGPT

```
You are a senior fintech product strategist, payments architect, and EU regulatory analyst. You have NO access to my codebase — everything you need is in this prompt. Think step by step, challenge assumptions, and be legally honest.

================================================================================
PART 1 — PRODUCT: WHAT PAYSPIN IS
================================================================================

**Payspin** is a European P2P payment-link app (similar to Tikkie in the Netherlands).

**Core user story:**
1. **Payee** (person who wants money) uses the **Flutter mobile app** (iOS/Android).
2. Payee connects a bank account (IBAN) or enters IBAN manually.
3. Payee creates a **payment link**: fixed amount OR "open amount" + optional description (e.g. "Pizza night", "€25").
4. Payee shares the link via WhatsApp, QR code, SMS, etc.
5. **Payer** (person who pays) opens a **public web page** — no app install, no login required.
6. Payer taps Pay → redirected to their **bank** (open banking / iDEAL-style) → authorises payment.
7. Money goes **directly from payer's bank to payee's bank** (SEPA credit transfer / Faster Payments / iDEAL).
8. Payee sees **"Paid"** in the mobile app + push notification + in-app notification.

**Non-custodial (critical):**
- Payspin **never holds customer funds**.
- We are NOT a wallet, NOT an EMI, NOT a bank.
- We orchestrate payment initiation + status tracking only.
- Payee IBAN is stored encrypted; payer never sees full IBAN on web (only "Verified payee" badge).

**Tagline:** "Your money, your community, and your peace of mind."

**Target markets (priority):** Netherlands, Germany, UK/EUR-SEPA, expanding EU.

**Comparable products:**
- Tikkie (ABN AMRO — bank-owned, not replicable without banking licence)
- Splitwise (expense tracking, not money movement)
- Revolut / Wise payment requests (closed ecosystems)
- PayPal.me / Stripe Payment Links (card/wallet rails, not pure bank-to-bank)

================================================================================
PART 2 — TECH STACK (for architecture proposals)
================================================================================

Monorepo:

| Component | Technology | Role |
|-----------|------------|------|
| **backend/** | NestJS 11, Prisma, PostgreSQL, Redis, BullMQ | REST API at `/v1` |
| **frontend/** | Next.js 15 App Router | Public payer web — no auth |
| **mobile/** | Flutter 3.5+ | Payee iOS/Android app |
| **packages/shared-types** | TypeScript | DTOs shared across apps |
| **packages/validators** | Zod | Input validation |
| **packages/pisp-provider** | TypeScript | `PIS_GATEWAY` / `AIS_GATEWAY` interfaces |
| **ops-portal/** | NestJS + Next.js | Internal admin (separate `/admin/v1`) |
| **infrastructure/** | Docker, Hetzner CX23 | Production deploy |

**Architecture rule:** Business logic in `application/use-cases/`. Banking only via injected gateways — never direct HTTP from use cases.

**Production URLs (today):**
- API: `https://pay.payspin.io/v1` (also raw IP `http://178.105.118.225/v1` for mobile builds)
- Payer web: `https://pay.payspin.io/{shortCode}`
- Mobile API: `--dart-define=API_URL=https://pay.payspin.io/v1`

================================================================================
PART 3 — DATA MODEL (PostgreSQL / Prisma)
================================================================================

**User** (payee accounts)
- id, email, passwordHash, displayName, phoneE164, phoneVerifiedAt
- Relations: bankAccounts[], paymentLinks[], notifications[], supportThreads[]

**BankAccount** (payee destination account)
- id, userId
- ibanEncrypted + ibanIv (AES — never store plain IBAN)
- ibanLast4, accountHolder, bankName
- verified (boolean), isPrimary (one primary per user for new links)
- verificationSource: manual entry vs `YAPILY` (open banking connect)
- yapilyConnectionId, yapilyInstitutionId (if connected via AIS)

**BankConnection** (AIS session — payee bank connect flow)
- status: PENDING → COMPLETED
- institutionId, yapilyAuthId, bankAccountId

**PaymentLink** (the "Tikkie" / request)
- id, shortCode (unique, 8 chars, URL-safe — e.g. `kefu1u2o`)
- payeeUserId, bankAccountId
- amountCents (nullable = **open amount**), currency (default EUR)
- description (nullable)
- status: ACTIVE | EXPIRED | CANCELLED | SETTLED | COLLECTING
- linkType: SINGLE (one payment) | MULTI (collect multiple payments, optional maxUses)
- maxUses, useCount, expiresAt
- payUrl: constructed as `{PAYER_WEB_URL}/{shortCode}`

**Payment** (one payer attempt on a link)
- id, paymentLinkId
- yapilyPaymentId, yapilyAuthRequestId, yapilyConsentToken (Yapily-specific today)
- paymentRequestSnapshot (JSON — redacted copy of what was sent to gateway)
- amountCents, currency
- status: AWAITING_AUTHORIZATION | PENDING | PROCESSING | COMPLETED | FAILED | CANCELLED
- payerBankName (optional), idempotencyKey
- initiatedAt, completedAt, webhookRaw

**WebhookEvent** (idempotent Yapily event log)
- eventId (unique), eventType, payload, processedAt

**Notification** (payee in-app inbox + FCM trigger)
- type: payment.received | payment.failed | link.expired | support.reply

**SupportThread / SupportMessage** (payee ↔ ops admin chat — separate feature, already built)

================================================================================
PART 4 — API SURFACE (what exists today)
================================================================================

**Authenticated (payee mobile) — JWT required:**

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/v1/auth/register` | Email/password signup |
| POST | `/v1/auth/login` | Session |
| POST | `/v1/links` | Create payment link |
| GET | `/v1/links` | List payee's links |
| GET | `/v1/links/:id` | Link detail + payment history |
| DELETE | `/v1/links/:id` | Cancel link |
| POST | `/v1/bank-accounts/connect` | Start Yapily AIS bank connect |
| GET | `/v1/bank-accounts/connect/callback` | AIS OAuth callback |
| POST | `/v1/bank-accounts/connect/complete` | Save IBAN from Yapily accounts |
| GET | `/v1/notifications` | In-app notification feed |
| POST | `/v1/support/threads` | Support chat (consumer) |

**Public (payer web) — no auth, rate-limited:**

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/v1/pay/:code` | Public link view (amount, payee name, status) |
| POST | `/v1/pay/:code/initiate` | Start payment → returns `{ paymentId, redirectUrl }` |
| POST | `/v1/pay/:code/complete` | After bank redirect — create Yapily payment |
| GET | `/v1/pay/:code/status/:paymentId` | Poll payment status |
| POST | `/v1/pay/:code/abandon` | Cancel stuck AWAITING_AUTHORIZATION payment |

**Webhooks:**

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/v1/webhooks/yapily` | Yapily payment status events → BullMQ → reconcile → notify payee |

================================================================================
PART 5 — END-TO-END PAYMENT FLOW (Yapily PIS — current production rail)
================================================================================

```
┌─────────────┐     POST /links      ┌──────────┐
│ Payee app   │ ───────────────────► │ Backend  │  creates PaymentLink (ACTIVE)
│ (Flutter)   │                      │ + Prisma │
└─────────────┘                      └────┬─────┘
                                          │ payUrl = pay.payspin.io/{shortCode}
┌─────────────┐     GET /{code}        │
│ Payer web   │ ◄───────────────────────┤
│ (Next.js)   │     GET /pay/:code     │
└──────┬──────┘                        │
       │ POST /pay/:code/initiate      │
       ▼                               ▼
  Backend:                             │
  1. Load link + decrypt payee IBAN    │
  2. resolvePayeeAccount(iban):        │
     - GB → SORT_CODE + ACCOUNT_NUMBER (GBP) │
     - SEPA → IBAN (EUR)               │
  3. resolveInstitutionForIban(country)    │
  4. PIS_GATEWAY.createPaymentAuthRequest()  ──► Yapily API
  5. Create Payment row (AWAITING_AUTHORIZATION)
  6. Return redirectUrl (authorisationUrl)
       │
       ▼
┌─────────────┐
│ Payer bank  │  OAuth / consent UI (Model Bank sandbox: mits/mits)
│ (redirect)  │
└──────┬──────┘
       │ redirect to payer web /{code}/callback?paymentId=&consent=
       ▼
  POST /pay/:code/complete { paymentId, consentToken }
       │
       ▼
  PIS_GATEWAY.createPayment(consentToken, paymentRequest)
       │
       ▼
  Status: PENDING | PROCESSING | COMPLETED | FAILED
       │
       ├──► Yapily webhook → reconcile → COMPLETED
       │         └──► NotifyPaymentReceived (DB notification + FCM push)
       └──► Payer web polls GET /pay/:code/status/:paymentId
```

**Payee bank connect (AIS — separate from payer payment):**
```
Mobile → POST /bank-accounts/connect
      → AIS_GATEWAY.createAccountAuthRequest()
      → Bank login redirect
      → GET /bank-accounts/connect/callback?consent=
      → 302 payspin://bank-callback
      → POST /bank-accounts/connect/complete
      → AIS_GATEWAY.getAccounts(consent)
      → Encrypt IBAN → bank_accounts row
```

================================================================================
PART 6 — GATEWAY ABSTRACTION (how we'd swap Yapily)
================================================================================

**PIS_GATEWAY interface** (`packages/pisp-provider`):

```typescript
interface PisGateway {
  createPaymentAuthRequest(params: {
    applicationUserId: string;
    institutionId?: string;
    callbackUrl: string;
    paymentRequest: {
      type: string;
      paymentIdempotencyId: string;
      reference: string;
      amount: { amount: number; currency: string };
      payee: {
        name: string;
        accountIdentifications: Array<{ type: string; identification: string }>;
      };
    };
  }): Promise<{ authRequestId: string; authorisationUrl: string }>;

  createPayment(params: {
    consentToken: string;
    paymentRequest: ...;
    idempotencyKey: string;
  }): Promise<{ paymentId: string; status: PaymentStatus }>;

  getPaymentStatus(paymentId: string, consentToken?: string): Promise<PaymentStatus>;
  verifyWebhookSignature(rawBody: string, signature: string): boolean;
}
```

**AIS_GATEWAY interface:**
```typescript
interface AisGateway {
  listInstitutions(country: string): Promise<InstitutionSummary[]>;
  createAccountAuthRequest(...): Promise<{ connectionId: string; authorisationUrl: string }>;
  getAccounts(consentToken: string): Promise<YapilyAccount[]>;
}
```

**Today:** `YapilyPisGateway` and `YapilyAisGateway` implement these. Use cases inject `PIS_GATEWAY` token only.

**Proposed generalization:** `PaymentRailGateway` or multiple adapters:
- `YapilyPisGateway` (paid OB aggregator)
- `SepaQrRail` (no API — returns QR payload + reference)
- `ManualTransferRail` (returns IBAN + reference + "I paid" UX)
- `StripeCheckoutRail` (redirect to Stripe Payment Link)
- `MollieIdealRail` (NL iDEAL via Mollie)

================================================================================
PART 7 — PAYMENT & LINK STATUS LIFECYCLE
================================================================================

**PaymentLinkStatus:**
- ACTIVE — accepting payments
- COLLECTING — MULTI link, partially paid
- SETTLED — SINGLE paid or MULTI complete
- EXPIRED — past expiresAt or stale
- CANCELLED — payee cancelled

**PaymentStatus:**
- AWAITING_AUTHORIZATION — redirect started, payer at bank
- PENDING / PROCESSING — submitted to scheme, settlement in flight
- COMPLETED — money confirmed (webhook or poll)
- FAILED / CANCELLED — terminal errors

**SINGLE link rule:** Only one in-flight payment at a time; stale AWAITING rows expire/abandon.

**Notifications on COMPLETED:**
- DB row in `notifications` table
- BullMQ → FCM push to payee devices
- Mobile polls link detail (5s) when on screen

================================================================================
PART 8 — PAYER WEB UX (Next.js)
================================================================================

Route: `frontend/app/[code]/page.tsx`
- Server-side fetch GET `/v1/pay/:code`
- Shows: description, amount or "Open amount", payee display name + verified badge
- PayButton → client POST initiate → window.location = redirectUrl
- Callback: `frontend/app/[code]/callback/page.tsx` → POST complete → success/error/processing UI
- FAQ accordion, dark Payspin brand (#0B0B12, pink #FC00FF, teal #07D8DD)
- **Critical:** Many payers open links from **WhatsApp in-app browser** on iPhone — fragile redirects, no bank app deep links sometimes

================================================================================
PART 9 — MOBILE PAYEE UX (Flutter)
================================================================================

- Home: list of payment links (premium dashboard with favorites, active request hero, recommended cards — or simple list)
- Send flow: amount numpad → name/description → creates link → share sheet (WhatsApp)
- Link detail: QR code, share, cancel, payment history, status polling
- Profile: IBAN card, settings, Help & Support → chat with ops
- Push notifications via Firebase Cloud Messaging
- Auth: email/password + phone OTP (Firebase stub/partial)
- Bank connect: Yapily AIS redirect flow

================================================================================
PART 10 — YAPILY DEPENDENCY (THE PROBLEM)
================================================================================

**What Yapily provides today:**
1. **PIS** — Payment Initiation (payer bank redirect, consent, create payment)
2. **AIS** — Account Information (payee bank connect, list accounts, get IBAN)
3. **Institution directory** — modelo-sandbox (GB), NL/DE live banks need eIDAS certs
4. **Webhooks** — async settlement when payer closes browser before COMPLETED

**Yapily Console app:** `53b0d904-21b3-41a7-ba2b-e440ab460bf9`
**Sandbox:** Model Bank @ `auth1.obie.uk.ozoneapi.io`, login `mits`/`mits`
**Production institution today:** mainly `modelo-sandbox` (GB) — NL/DE live banks not fully enabled
**Hosted Pages:** returns 403 (scope not enabled on Yapily app)

**Cost pain:**
- Commercial **subscription** + **per-API-call** pricing
- Too expensive for bootstrap / early stage (~500 payments/month MVP target)
- Sandbox works; production economics and institution coverage block NL/DE launch

**Known production issues (even with Yapily):**
- Mobile/WhatsApp browser: `/complete` sometimes fails with Yapily 424 "Error from Institution"
- Payments stuck AWAITING_AUTHORIZATION until abandon
- Webhook registration required for reliable COMPLETED without payer staying on page

================================================================================
PART 11 — WHAT WE WANT TO KEEP vs CHANGE
================================================================================

**KEEP (product logic):**
- Short shareable link with code
- Fixed or open amount + description
- Payee mobile app + public payer web
- Status: pending / paid / expired / cancelled
- Share via WhatsApp + QR
- Non-custodial — direct to payee IBAN
- Push + in-app notification when "paid"
- Encrypted IBAN storage
- Ops portal for support/admin
- Gateway abstraction (swap rail without rewriting use cases)

**WILLING TO CHANGE:**
- How payer actually sends money (OB API vs manual transfer vs QR vs Stripe/Mollie)
- How "paid" is detected (webhook vs reference matching vs honor system vs payer self-confirm)
- Automation level (fully automatic vs semi-manual MVP)
- Payee bank verification (manual IBAN entry only vs AIS)
- Per-transaction fees OK if no fixed monthly OB subscription

**NOT OK:**
- Becoming custodial / holding funds without EMI licence
- Illegal unlicensed payment services in EU/UK
- UX that breaks WhatsApp mobile browser without fallback

================================================================================
PART 12 — FOUNDER CONSTRAINTS (edit these numbers)
================================================================================

- Primary markets: **Netherlands + Germany** (then UK)
- MVP volume: **~500 payments/month**
- Team: **small startup** (2–3 people), limited compliance budget year 1
- **No EMI / PI licence** in year 1 if avoidable
- **$0/month fixed** open-banking aggregator subscription target
- **1–2% per transaction** acceptable if automatic and reliable
- **Manual confirmation OK for v1** if ships in 2 weeks
- WhatsApp share is **critical** distribution channel
- Must work on **iPhone in-app browser**

================================================================================
PART 13 — CATEGORIES YOU MUST EXPLORE
================================================================================

**A — No paid OB API: "Smart payment request"**
- SEPA **EPC QR code** (Girocode) on payer page: IBAN + amount + beneficiary + reference
- Copy IBAN + structured **payment reference** tied to paymentId (e.g. `Payspin kefu1u2o` or RF creditor reference)
- Payer uses **own banking app** (ideal for NL/DE)
- Payer taps **"I've sent the payment"** → payee notified → payee confirms or auto-match later
- **Receipt/screenshot upload** (optional OCR)
- Pros/cons, fraud, chargebacks, dispute UX

**B — Third-party payment links (not Yapily, pay-per-txn)**
- **Stripe Payment Links / Checkout** — card + some bank methods, fees ~1.5%+€0.25
- **Mollie** (NL) — iDEAL, SEPA, payment links API
- **Adyen**, **Pay.nl**, **MultiSafepay** — NL entry costs
- **PayPal.me**, **Revolut.me**, **Wise request** — redirect out, limited status API
- Compare **500 tx/month @ €25 average** vs Yapily subscription

**C — Direct scheme / bank (no aggregator)**
- **iDEAL** direct via acquirer (scheme membership, bank contract)
- **SEPA Credit Transfer** via corporate bank API + Creditor Identifier (CI)
- **UK Faster Payments** / **Pay by Bank** (OBIE)
- **Berlin Group** direct to ASPSPs — realistic for startup?
- **Tikkie model** — why it requires ABN AMRO

**D — Hybrid orchestrator (recommended architecture)**
- One link page, **multiple rails**: SEPA QR (free) + optional "Pay with iDEAL" (Mollie) + "I paid manually"
- **Reference matching**: incoming SEPA credits matched by remittance info / End-to-End ID
- **AIS read-only** alternatives to Yapily (Nordigen/GoCardless Bank Account Data free tier? — verify current pricing)
- **CSV bank export import** for payee reconciliation
- How to extend `payments` table: `railType`, `externalReference`, `payerConfirmedAt`, `payeeConfirmedAt`

**E — Compliance (PSD2, NL, DE)**
- Payment initiation vs payment **request** — regulatory difference
- When does matching incoming transfers require a licence?
- Consumer vs micro-merchant payees
- GDPR + IBAN display rules on payer page
- PSD2 exemptions for **single payment initiation** under agent model

**F — Detecting "paid" without Yapily webhooks**
- Structured reference in SEPA remittance information (ISO 20022)
- Periodic AIS poll on **payee** account for incoming credits
- Email notification parsing (fragile)
- Manual ops reconciliation in admin portal
- SLA expectations per method

================================================================================
PART 14 — REQUIRED OUTPUT FORMAT
================================================================================

**1. Executive summary** (≤10 bullets)
Best 2–3 directions for bootstrap MVP with $0/month fixed OB cost.

**2. Option matrix** (minimum 8 rows)

| Option | Money movement | Paid confirmation | Fixed €/month | Payer UX 1-5 | NL/DE fit | Compliance risk | Dev weeks | Non-custodial? |

Include at least one from A, B, C, D.

**3. Deep dives** (top 3 options)
For each: payee journey, payer journey, schema changes vs tables above, failure modes, fraud, migration from PIS_GATEWAY.

**4. Phased roadmap**
- Phase 0 (2 weeks): ship manual/QR
- Phase 1 (1–2 months): semi-auto reference matching
- Phase 2: optional premium automatic rail
What stays on Yapily vs replaced.

**5. Payer page wireframe (text)**
For your #1 recommendation: sections, buttons, copy, WhatsApp browser considerations.

**6. Cost model**
500 payments/month × €25 avg — compare Yapily vs top 3 alternatives (monthly + variable).

**7. Numbered questions for founder**
Decisions only I can make.

**8. Red flags**
Options that sound free but aren't (licensing, chargebacks, support load, NL iDEAL rules).

================================================================================
PART 14 — CHALLENGE THESE ASSUMPTIONS
================================================================================

- "We must replicate Tikkie's one-tap bank pay to launch"
- "Open banking is the only EU-native rail"
- "Manual confirmation kills the product"
- "Stripe is not 'real' bank-to-bank" (is it acceptable for MVP?)
- "We need AIS if we drop PIS"

Do NOT write production code. Strategic product + architecture design only. Be specific to Payspin's existing tables, API routes, and gateway pattern.

If the honest best MVP is **SEPA EPC QR + unique reference + payer 'I sent it' + payee confirm + optional AIS matching later**, design that properly end-to-end including the exact fields to add to `payments` and `payment_links` and the payer web page flow.
```

---

## Optional add-ons (paste after the block)

**Volume scenario:**
```
Assume 500 payments/month, average €30, 80% NL, 20% DE, 90% mobile payer.
```

**Keep Yapily as premium tier:**
```
Design a dual-rail product: "Lite" (free QR/manual) and "Instant" (Yapily/Mollie paid).
```

**Legal review trigger:**
```
Flag anything that needs a Dutch AFM or DNB consultation before launch.
```

---

## After ChatGPT responds

| Step | Action |
|------|--------|
| 1 | Save conclusion to `docs/agents/payment-rail-decision.md` (in repo) |
| 2 | Paste back into Cursor with `@docs/agents/architecture.md` for implementation spike |
| 3 | Phase 0 spike: payer page SEPA QR only (no Yapily change) |
| 4 | Legal review if handling B2B or >€10k/month |

**Related repo docs (for Cursor agents with code access):** `resources/docs/yapily-console-setup.md`, `docs/agents/payment-notifications-yapily-prompt.md`, `AGENTS.md`.
