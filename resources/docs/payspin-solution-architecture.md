# Payspin — Solution Architecture Document

### For Technical Partner — Initial Design & Architecture Reference

**Version:** 1.0 | **Date:** May 2026 | **Author:** Moustafa — Founder, Payspin.io | **Status:** Final for Phase 1 kickoff

-----

## 1. Product Overview

Payspin is a two-product fintech platform targeting Germany and the Netherlands, built on open banking and blockchain rails.

|                   |Service 1 — Payspin P2P                 |Service 2 — Payspin Circles                  |
|-------------------|----------------------------------------|---------------------------------------------|
|**What it is**     |Tikkie-style payment link service       |ROSCA (rotating savings circle) service      |
|**User analogy**   |“Tikkie but for Germany and Netherlands”|“Digital Tandas / Geldkring / Sparkreis”     |
|**Primary market** |DE + NL                                 |DE + NL + EU diaspora communities            |
|**Core technology**|Open banking (Yapily PISP)              |Blockchain (Monerium + Circle + Gnosis Chain)|
|**Launch phase**   |Phase 1                                 |Phase 3                                      |

-----

## 2. The Non-Custodial Principle — Read This First

**Payspin never holds user funds at any point.**

This is not a preference — it is the architectural foundation. It determines every technology decision in this document. Any design decision that results in Payspin holding, touching, or controlling user money must be escalated and approved before implementation.

- Payspin does not hold euros
- Payspin does not hold stablecoins
- Payspin does not operate a settlement account
- Payspin does not issue IBANs (Monerium does, in Phase 3)
- Payspin does not custody wallets (Circle MPC does, in Phase 3)

The regulatory consequence of this principle: Payspin operates as a software platform and commercial agent of licensed providers. No PI licence required to launch Phase 1.

-----

## 3. Architecture — Service 1: P2P Payment Links

### 3.1 User Experience Reference — Tikkie (the model to replicate)

Tikkie (ING Bank, Netherlands) is the UX benchmark. Study the Tikkie app before designing anything. Key UX principles to copy:

- Payee creates a link in under 10 seconds
- Link is shared via WhatsApp / SMS / any messenger — one tap
- Payer opens link in mobile browser — **zero app install, zero registration**
- Payer selects their bank from a picker
- Payer authenticates with their own bank (FaceID / fingerprint)
- Payment confirmed instantly
- Payee receives a push notification

The critical difference from Tikkie: Payspin works across Germany AND Netherlands (Tikkie is NL-only), supports any EU bank (not just ING customers), and is open banking native (not iDEAL-only).

### 3.2 Architecture A1 — Open Banking, Open-Loop

```
PAYEE (Payspin app)
     │
     │  1. Enters amount + description
     │  2. Taps "Create link"
     ▼
PAYSPIN BACKEND (NestJS)
     │
     │  3. Creates payment link record
     │  4. Generates short URL: pay.payspin.io/abc123
     │  5. Stores: { payeeIban, amount, reference, status }
     ▼
PAYEE shares link via WhatsApp/SMS
     │
     ▼
PAYER (mobile browser — no app needed)
     │
     │  6. Opens link
     │  7. Sees: amount + payee display name
     │  8. Taps "Pay with my bank"
     ▼
YAPILY (PISP)
     │
     │  9.  Bank picker loads (hosted by Yapily, white-labelled)
     │  10. Payer selects their bank
     │  11. Payer redirected to their own bank app/web
     │  12. Payer authenticates (SCA — FaceID / biometric)
     │  13. Payer confirms payment
     ▼
SEPA INSTANT NETWORK
     │
     │  14. Payer's bank executes SEPA Instant Credit Transfer
     │      Destination: Payee's personal IBAN
     │      Amount: as specified
     │      Time: ≤10 seconds
     │      Yapily never holds money
     ▼
PAYEE'S PERSONAL BANK ACCOUNT
     │
     │  15. Money arrives
     ▼
YAPILY WEBHOOK → PAYSPIN BACKEND
     │
     │  16. Webhook fires: payment status = COMPLETED
     │  17. Payspin updates link status
     │  18. Payspin sends FCM push notification to payee
     ▼
PAYEE RECEIVES PUSH NOTIFICATION
     "€25.00 received from [Payer's bank name]"
```

**Money path:** Payer’s Bank → SEPA Instant → Payee’s Personal Bank
**Hops:** 1
**Settlement:** ≤10 seconds
**Payspin in money path:** Never

### 3.3 PISP Provider — Yapily

- **Licence:** Bank of Lithuania (LB002045) for EU / FCA for UK
- **Coverage:** 2,000+ banks across 19 EU countries
- **DE banks confirmed:** Deutsche Bank, Commerzbank, DKB, ING-DiBa, N26, Sparkasse network, Volksbanken network
- **NL banks confirmed:** ING, ABN AMRO, Rabobank, Knab, ASN Bank, SNS Bank
- **Payspin licence required:** None — operates under Yapily’s PI licence
- **Product used:** Yapily Connect (no-licence model) → upgrade to direct API after PI licence obtained
- **Pricing (quoted):** €250/month platform + €500 per 1,500 transactions (~€0.33/tx)
- **Key commercial question still open:** Confirm beneficiary IBAN is a per-transaction parameter (open-loop confirmation pending)
- **Sandbox:** Available at yapily.com — start here before production integration

-----

## 4. Architecture — Service 2: Payspin Circles (ROSCA)

### 4.1 What a ROSCA is

A ROSCA (Rotating Savings and Credit Association) is a group savings mechanism:

- N members each contribute a fixed amount per cycle (e.g. €100/month)
- Each cycle, one member receives the full pot (N × €100)
- The rotation continues until every member has received the pot once
- Example: 10 members × €100/month = €1,000 pot. Month 1 → Member 1. Month 2 → Member 2. Etc.

Known as: Geldkring (NL), Sparkreis (DE), Tanda (Mexico), Hui (China), Chit (India).

### 4.2 Architecture B — PISP + Monerium + Blockchain

```
PHASE A — PAYEE ONBOARDING (one-time)

PAYEE (Payspin app)
     │
     │  1. Registers on Payspin (Firebase Auth)
     │  2. Taps "Connect bank for Circles"
     ▼
MONERIUM OAUTH FLOW
     │
     │  3. Monerium OAuth popup opens (hosted by Monerium)
     │  4. Payee completes KYC: name, ID, address (2–5 min)
     │  5. Monerium creates:
     │     - Personal virtual IBAN (DE/NL format)
     │     - EVM wallet address on Gnosis Chain
     │     - Links IBAN ↔ wallet address
     ▼
PAYSPIN BACKEND
     │
     │  6. Receives Monerium OAuth callback
     │  7. Stores: { userId, moneyiumIban, walletAddress }
     │  8. Payee is now "Circles-enabled"

─────────────────────────────────────────────

PHASE B — CONTRIBUTION (monthly, from each member)

CIRCLE MEMBER (Payspin app)
     │
     │  1. App shows "Your contribution is due: €100"
     │  2. Member taps "Pay now"
     ▼
PAYSPIN BACKEND
     │
     │  3. Creates payment request via Yapily API
     │     Beneficiary IBAN: Smart contract's Monerium IBAN
     │     Amount: €100
     ▼
YAPILY (PISP)
     │
     │  4. Bank picker loads
     │  5. Member selects their bank, authenticates
     │  6. SEPA Instant: Member's Bank → Circle Smart Contract IBAN
     ▼
MONERIUM
     │
     │  7. Receives SEPA credit at Circle's IBAN
     │  8. AML check passes
     │  9. Mints EURe on Gnosis Chain
     │  10. EURe sent to ROSCA Smart Contract address
     ▼
GNOSIS CHAIN — ROSCA SMART CONTRACT
     │
     │  11. Contract records: member X contributed €100
     │  12. Checks if all members have contributed this round
     │  13. If yes → triggers payout to this round's recipient

─────────────────────────────────────────────

PHASE C — PAYOUT (to recipient of this round)

ROSCA SMART CONTRACT
     │
     │  1. Round complete — all members contributed
     │  2. Contract calls: transfer(recipientWallet, fullPot)
     │  3. EURe transferred to recipient's EVM wallet (≤5 seconds)
     ▼
RECIPIENT (Payspin app)
     │
     │  4. EURe arrives in wallet
     │  5. Choice A: Keep as EURe (earn yield on Aave V3)
     │  6. Choice B: Burn to fiat — tap "Withdraw to bank"
     ▼
MONERIUM (burn flow)
     │
     │  7. Recipient initiates burn via Monerium API
     │  8. EURe burned on-chain
     │  9. Monerium initiates SEPA bank transfer to recipient's
     │     personal IBAN (the real bank account)
     │  10. Time: ≤10 seconds via SEPA Instant
     ▼
RECIPIENT'S PERSONAL BANK ACCOUNT
```

### 4.3 Smart Contract — ROSCA Logic

The smart contract handles all group mechanics on-chain. Key functions:

```
contribute(circleId, memberId)
  → Accepts EURe from member
  → Marks member as paid for this round
  → Checks if all members paid → triggers payout

claimPayout(circleId)
  → Callable by current round recipient only
  → Transfers full pot to recipient wallet

defaultMember(circleId, memberId)
  → Admin/multisig only
  → Handles non-paying member — proportional refund to others

getCircleState(circleId)
  → Returns: members, round number, paid status, recipient

pauseCircle(circleId)
  → Emergency pause — 3-of-5 multisig required
```

Smart contract chain: **Gnosis Chain** (low gas ~$0.001/tx, EURe native)
Automation: **Gelato Web3 Functions** (cron-based poke() for missed contributions)
Audit: Mandatory before mainnet — budget €30,000–60,000

### 4.4 Blockchain Partners

|Partner                |Role                                                            |Licence                        |What Payspin does                   |
|-----------------------|----------------------------------------------------------------|-------------------------------|------------------------------------|
|**Monerium**           |Fiat ↔ EURe bridge. Issues virtual IBANs. KYC on payees.        |EMI (Iceland CBI) + MiCA Art.48|OAuth integration + webhook listener|
|**Circle (MPC Wallet)**|Non-custodial wallet infrastructure. Gas Station for gasless tx.|N/A — infrastructure           |SDK integration for wallet creation |
|**Gnosis Chain**       |L2 blockchain network. EURe native. ~$0.001 gas.                |N/A — public chain             |Deploy smart contracts here         |
|**Aave V3 (Gnosis)**   |Yield on idle ROSCA funds (~4% APY)                             |N/A — DeFi protocol            |Optional Phase 3+                   |

-----

## 5. Full Technology Stack

### 5.1 Core Stack Decision

|Layer             |Technology                  |Why                                                    |
|------------------|----------------------------|-------------------------------------------------------|
|Mobile app        |Flutter                     |Single codebase for iOS + Android. Native performance.|
|Payer web page    |Next.js 14 App Router       |Server-side rendered, fast load, edge runtime          |
|Backend API       |NestJS (Node 20, TypeScript)|Modular, decorator-based, production-proven for fintech|
|Database          |PostgreSQL 16               |Transactions, ACID compliance, IBAN encryption at rest |
|Auth              |PostgreSQL + JWT (NestJS)   |Email/password. Users stored in Postgres. bcrypt hashes.|
|Push notifications|APNs / FCM (Phase 2)        |Deferred — not required for Phase 1 P2P links          |
|Job queue         |BullMQ + Redis              |Async webhook processing, retry logic                  |
|Smart contracts   |Solidity 0.8.24 + Foundry   |Industry standard, Foundry for testing                 |
|Blockchain        |Gnosis Chain                |EURe native, low gas, EVM compatible                   |
|Cloud             |GCP Cloud Run (europe-west1)|Serverless, auto-scale, Frankfurt region               |
|Repo              |Turborepo monorepo          |Shared types, unified CI/CD                            |

### 5.2 Monorepo Structure

```
payspin/
├── apps/
│   ├── api/              ← NestJS backend (Cloud Run)
│   ├── web/              ← Next.js payer landing pages (Vercel)
│   └── mobile/           ← Flutter (App Store + Play Store)
├── packages/
│   ├── shared-types/     ← TypeScript interfaces used across all apps
│   └── pisp-provider/    ← Yapily abstraction (swap providers easily)
├── contracts/
│   ├── src/              ← Solidity smart contracts
│   └── test/             ← Foundry tests (invariant + fuzz)
├── infrastructure/
│   └── sql/              ← Database migrations
└── turbo.json
```

### 5.3 Key Architectural Abstractions

**PisProvider interface** — The most important abstraction in the codebase. All PISP calls go through this interface. Changing from Yapily to IbanXS or Token.io is a config change, not a code change.

```typescript
interface PisProvider {
  initiatePayment(params: {
    amountCents: number;
    currency: string;
    beneficiaryIban: string;    // ← This is the open-loop key
    beneficiaryName: string;
    reference: string;
    redirectUri: string;
    paymentLinkId: string;
  }): Promise<{ tokenId: string; redirectUrl: string }>;

  getPaymentStatus(tokenId: string): Promise<PaymentStatus>;
  verifyWebhookSignature(payload: string, sig: string): boolean;
}
```

**MoneyPath interface** — Used in Phase 3. Routes between fiat (Yapily only) and blockchain (Yapily + Monerium) based on the payee’s account type.

-----

## 6. Database Schema — Core Tables

```sql
-- Users (payees registered on Payspin)
users (id, email, password_hash, display_name, created_at)

-- Bank accounts (payee's personal IBAN — AES-256 encrypted at rest)
bank_accounts (id, user_id, iban_encrypted, iban_last4,
               account_holder, bank_name, verified)

-- Payment links
payment_links (id, short_code, payee_user_id, bank_account_id,
               amount_cents, currency, description, status,
               link_type, max_uses, use_count, expires_at)
-- status: ACTIVE | EXPIRED | CANCELLED | SETTLED | COLLECTING
-- link_type: SINGLE (P2P) | MULTI (Verein, events)

-- Payments (one per payer per link)
payments (id, payment_link_id, yapily_payment_id,
          amount_cents, status, payer_bank_name,
          initiated_at, completed_at, webhook_raw)

-- Webhook idempotency (prevents double-processing)
webhook_events (id, event_type, processed_at, payload)

-- Phase 3: ROSCA circles
circles (id, name, host_user_id, member_count,
         contribution_cents, cycle_duration_days,
         smart_contract_address, status, current_round)

circle_members (id, circle_id, user_id, monerium_iban,
                wallet_address, payout_order, status)
```

-----

## 7. Security Requirements (Non-Negotiable)

Every item below must be implemented before production:

|Requirement                        |Implementation                                   |
|-----------------------------------|-------------------------------------------------|
|IBAN encryption at rest            |AES-256-GCM, per-record IV, key from env var     |
|Webhook signature verification     |HMAC-SHA256, timing-safe comparison              |
|Webhook idempotency                |webhook_events table, check before processing    |
|Short code unpredictability        |crypto.randomBytes(), not sequential             |
|IBAN never in API response to payer|Only server-side, never in browser               |
|No PII in logs                     |Never log IBAN, full reference, or user data     |
|Firebase token expiry              |1 hour max, refresh on resume                    |
|Rate limiting                      |10 req/min per IP on public endpoints            |
|AML velocity checks                |>10 payments/24h or >€5,000/24h → compliance flag|

-----

## 8. Third-Party Integrations Summary

### Yapily (Phase 1, 2, 3)

- **What:** PISP payment initiation
- **Docs:** docs.yapily.com
- **Auth:** OAuth2 client credentials
- **Key endpoint:** POST /payments (with beneficiary IBAN per request)
- **Webhook:** X-Yapily-Signature HMAC header
- **Sandbox:** Available immediately — start here
- **Contact:** Katie Hayton (via current thread) for production access

### Monerium (Phase 3)

- **What:** EMI bridge. Issues virtual IBANs. Mints/burns EURe on Gnosis Chain.
- **Docs:** monerium.dev
- **Auth:** OAuth2 (hosted KYC flow for end users)
- **Key flow:** User completes Monerium OAuth → receives IBAN + wallet address
- **Webhook:** order.processed event = EURe minted
- **Sandbox:** monerium.dev/sandbox

### Circle (Phase 3)

- **What:** MPC wallet infrastructure. Gas Station for gasless transactions.
- **Docs:** developers.circle.com
- **Auth:** API key
- **Key product:** Programmable Wallets + Gas Station
- **Sandbox:** Available immediately

### Firebase (Phase 1, 2, 3)

- **What:** Auth, Firestore, FCM push notifications
- **Docs:** firebase.google.com/docs
- **Auth:** Service account JSON
- **Free tier:** 10k MAU, 50k Firestore reads/day, FCM free

-----

## 9. Phased Delivery Plan

### Phase 1 — P2P MVP (Target: 8 weeks to production)

**Goal:** Working Tikkie-equivalent app in Germany and Netherlands, live on App Store and Play Store.

**Scope:**

- Payee registers, adds personal IBAN
- Creates payment link (fixed or variable amount)
- Shares link via native share sheet / WhatsApp
- Payer pays in browser (zero install)
- Yapily PISP integration (payment initiation)
- Webhook handler (payment confirmation)
- FCM push notification to payee
- Payment history screen
- Link management (view, cancel, expiry)

**Out of scope for Phase 1:**

- Blockchain / EURe / Monerium
- ROSCA circles
- Yield
- Business features (DATEV export, invoicing)
- Cross-border beyond DE + NL

**Week-by-week:**

|Week|Deliverable                                                             |
|----|------------------------------------------------------------------------|
|1   |Monorepo scaffold, Postgres schema, JWT auth (register/login)           |
|2   |IBAN storage (encrypted), payment links CRUD, short URL generation      |
|3   |Yapily sandbox integration — payment initiation + redirect flow         |
|4   |Webhook handler + idempotency + AML velocity checks                     |
|5   |Next.js payer landing page + bank picker + callback handler             |
|6   |Flutter app — auth, IBAN onboarding, link creation, share sheet         |
|7   |FCM push, payment history, end-to-end integration testing (10 scenarios)|
|8   |GCP Cloud Run deploy, Vercel deploy, App Store submission, mainnet test |

**First euro on mainnet target:** Day 42–45

-----

### Phase 2 — P2P Enhancement (Target: Weeks 9–16)

**Goal:** Polish the P2P experience, improve conversion, add business value features.

**Scope:**

- Push notification improvements (real-time balance, history)
- Link analytics (how many people opened, how many paid)
- Multi-use links (Verein dues, event tickets)
- QR code generation for in-person use
- DATEV-compatible CSV export (critical for German freelancers)
- Recurring payment links (retainer, tutor, cleaner)
- IBAN verification via Yapily AIS (optional step at registration)
- Variable Recurring Payments (VRP) for scheduled contributions (Yapily supports this)
- Language: German and Dutch full localisation
- Upgrade to Yapily direct API (after PI licence — replaces Connect tier)

-----

### Phase 3 — Payspin Circles / ROSCA (Target: Weeks 17–32)

**Goal:** Launch ROSCA product on blockchain. Monerium + Circle + Gnosis Chain.

**Scope:**

- Monerium OAuth integration (payee KYC + virtual IBAN issuance)
- Circle MPC wallet creation per user
- ROSCA smart contract (Solidity) — contribute, claim, default, pause
- Gelato automation for round management
- Smart contract audit (mandatory pre-mainnet — budget €30,000–60,000)
- EURe contribution flow (Yapily initiates SEPA to Monerium IBAN)
- On-chain payout to recipient wallet
- Fiat off-ramp via Monerium burn → SEPA
- Optional: Aave V3 yield on idle circle funds (MiCA opt-in required)
- Optional: Emergency multisig (3-of-5 Safe) for contract pause

-----

## 10. Compliance Architecture

Payspin’s non-custodial design means a minimal compliance footprint. Here is what is required and what is delegated:

|Requirement            |Who handles it   |How                                          |
|-----------------------|-----------------|---------------------------------------------|
|KYC on payers          |Not required     |Payers never register on Payspin             |
|KYC on payees (Phase 1)|Payspin          |Light: email + IBAN verification             |
|KYC on payees (Phase 3)|Monerium         |Full KYC via OAuth flow (delegated)          |
|AML monitoring         |Payspin + Yapily |Velocity checks in backend + Yapily’s own AML|
|SEPA AML               |Payer’s bank     |Banks do their own AML on debited accounts   |
|MiCA compliance (EURe) |Monerium         |EURe is MiCA Art.48 compliant EMT            |
|GDPR                   |Payspin          |IBAN encrypted, minimal data retention       |
|Travel Rule (>€1,000)  |Yapily + Monerium|Both providers handle Travel Rule metadata   |

**AML minimum implementation (Phase 1):**

- Payee velocity: >10 distinct payers in 24h → compliance_flags table + alert
- Amount velocity: >€5,000 received in 24h → flag
- IP rate limit: >20 payment attempts from same IP in 1h → block + flag

-----

## 11. Legal Entity Structure

|Entity          |Type          |Purpose                                                                  |Status                                           |
|----------------|--------------|-------------------------------------------------------------------------|-------------------------------------------------|
|**Payspin B.V.**|Dutch B.V.    |Operating company. Contracts with Yapily, Monerium, Circle. Employs team.|Incorporate immediately via Firm24.nl            |
|**Payspin UAB** |Lithuanian UAB|Regulated entity. Holds PI licence from Bank of Lithuania.               |Incorporate in Month 2, apply for licence Month 3|

**PI Licence (Lithuania):**

- Regulator: Bank of Lithuania
- Licence type: Payment Initiation Services only (PSD2 Annex I point 7)
- Capital required: €50,000
- Application fee: €898
- Timeline: 3–6 months
- Unlocks: Direct Yapily API (replacing Connect tier), Token.io, Enable Banking

-----

## 12. Open Items — Decisions Pending

The following must be resolved before or during Phase 1 development:

|Item                                                   |Owner           |Deadline      |Impact if delayed                     |
|-------------------------------------------------------|----------------|--------------|--------------------------------------|
|Yapily open-loop confirmation (beneficiary IBAN per tx)|Moustafa / Katie|This week     |Blocks all Phase 1 architecture       |
|Yapily pricing negotiation                             |Moustafa        |Before signing|Cost structure for unit economics     |
|Payspin B.V. incorporation                             |Moustafa        |This week     |Required for Yapily due diligence form|
|Bunq Business bank account                             |Moustafa        |Week 2        |Required for Yapily form              |
|AML policy document (1 page)                           |Moustafa + Tech |Week 2        |Required for Yapily onboarding        |
|Smart contract audit firm selection                    |Tech            |Phase 3 start |Mandatory before mainnet Circles      |
|Monerium developer account                             |Tech            |Phase 3 start |Required for ROSCA architecture       |
|Circle developer account                               |Tech            |Phase 3 start |Required for MPC wallets              |

-----

## 13. Reference Links

|Resource                        |URL                     |
|--------------------------------|------------------------|
|Yapily API docs                 |docs.yapily.com         |
|Yapily sandbox signup           |yapily.com/pricing      |
|Monerium developer docs         |monerium.dev            |
|Circle developer docs           |developers.circle.com   |
|Gnosis Chain docs               |docs.gnosischain.com    |
|Gelato automation               |docs.gelato.network     |
|Firebase docs                   |firebase.google.com/docs|
|GCP Cloud Run                   |cloud.google.com/run    |
|Foundry (smart contract testing)|book.getfoundry.sh      |
|OpenZeppelin contracts          |docs.openzeppelin.com   |
|Bank of Lithuania PI licence    |lb.lt/en/licences       |
|Firm24 NL B.V. incorporation    |firm24.nl               |

-----

*Document version 1.0 — Payspin.io — May 2026*
*For internal use only. Do not distribute outside the founding team.*