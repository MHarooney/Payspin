# Payspin Circles Phase 3 — Monerium, Blockchain & Missing Features

**Purpose:** Paste this prompt into a new agent session to implement **Monerium + on-chain ROSCA** for Circles/Groepies and close all remaining gaps from the MVP.

**Repo:** `git@github.com:MHarooney/Payspin.git` (monorepo)  
**Paths:** `backend/`, `mobile/`, `packages/`, `infrastructure/`  
**Do NOT edit:** `.cursor/plans/*.plan.md`

---

## Executive summary

Phase 1 (Tikkies) and Circles **MVP** are done: invite codes, activate/advance, MULTI payment-link contributions. Phase 3 upgrades Circles to the **Architecture B** design: Monerium KYC + virtual IBAN + EURe on **Gnosis Chain**, Yapily SEPA contributions to the circle's Monerium IBAN, smart-contract round logic, on-chain payout, Monerium burn → SEPA off-ramp.

Also implement **non-blockchain gaps** still missing from mobile/backend (member admin UI, per-member contribution status, real OTP, FCM, MULTI link creation, etc.).

---

## Mandatory reading (in order)

1. `AGENTS.md`, `docs/agents/architecture.md`, `docs/agents/conventions.md`
2. **`resources/docs/payspin-solution-architecture.md`** — §4.2 Architecture B, §4.3 smart contract, §8 Monerium/Circle, §9 Phase 3 scope
3. **`resources/docs/wireframe-spec.md`** — Circles screens **C01–C16**, Monerium flow **C09→C11→C12**, Profile **R03**
4. `docs/agents/circles-contribution-mvp.md` — current MVP (payment links); **replace** with on-chain flow when Phase 3 lands
5. `docs/agents/circles-implementation-prompt.md` — existing Circles API baseline
6. Existing code to mirror:
   - Yapily gateway: `packages/pisp-provider/`, `backend/src/infrastructure/yapily/`
   - Circles: `backend/src/application/use-cases/circles/`, `mobile/lib/presentation/circles/`
   - Open banking mobile: `step_connect_bank_page.dart` (OAuth web-auth pattern for Monerium)
7. **`docs/agents/circles-monerium-research.md`** — seed notes from prior research (agent must **re-verify live**)

---

## STEP 0 — Mandatory live Monerium API research (do this FIRST)

**Do not implement from memory or architecture doc alone.** Before writing integration code, the agent MUST:

1. **Fetch and read current official docs** (web search + browse):
   - https://docs.monerium.com/ (Getting Started, Authorization, API reference)
   - https://docs.monerium.com/api/ (OpenAPI — auth, profiles, IBANs, orders, webhooks)
   - https://docs.monerium.com/whitelabel/ vs https://docs.monerium.com/authorization/ (OAuth)
   - https://docs.monerium.com/packages/sdk/ (`@monerium/sdk` npm package)
2. **Register or use sandbox** at https://sandbox.monerium.dev/developers — create a test app, note which **plan type** you get (OAuth / Whitelabel / Private).
3. **Probe live sandbox API** with curl (no secrets in git):
   - `POST https://api.monerium.dev/auth/token` (client_credentials smoke test)
   - Document exact request/response shapes for `/auth`, `/auth/token`, `/ibans`, `/orders`, `/profiles`
4. **Write findings** to `docs/agents/circles-monerium-research.md` (append, do not overwrite seed):
   - Chosen integration path + why
   - Endpoint matrix (method, path, auth, request/response)
   - Sandbox vs production base URLs
   - Gaps vs `resources/docs/payspin-solution-architecture.md` — flag outdated assumptions
5. **Record decisions** in `docs/agents/circles-phase3-decisions.md` before coding.

### Critical product choice: OAuth vs Whitelabel (research required)

Monerium offers **three developer plans** (see docs.monerium.com Getting Started):

| Plan | User onboarding | Webhooks | IBAN | Best for Payspin |
|------|-----------------|----------|------|------------------|
| **OAuth** | Co-branded Monerium portal | **No** | Shared per user | Fastest sandbox / pilot |
| **Whitelabel** | Your UI + API-driven KYC | **Yes** | Dedicated per customer | Production ROSCA at scale |
| **Private** | Your own account only | Yes | Own | Internal testing only |

**Agent must evaluate and recommend one path**, with a fallback:

- **Pilot (recommended start):** OAuth + Authorization Code **PKCE** — mirror Yapily bank OAuth (`flutter_web_auth_2`, deep link callback). Users complete KYC in Monerium portal; Payspin stores tokens + IBAN/wallet from API.
  - **Workaround for no webhooks (OAuth plan):** poll `GET /orders`, or use Monerium **WebSocket** order notifications (`order.updated` states: `placed` → `pending` → `processed` / `rejected`). Do not assume HTTP webhooks exist on OAuth plan.
- **Production target:** Apply for **Whitelabel** partnership (monerium.com/invite/partners) for webhooks + branded onboarding + dedicated circle IBANs.

### Auth flows (verify against live API)

| Flow | Use when | Notes |
|------|----------|-------|
| **Authorization Code + PKCE** | Mobile app user links Monerium | `GET /auth` → 307 redirect → callback with `code` → `POST /auth/token` `grant_type=authorization_code`. Use **Authorization Code Flow client_id** (not client_credentials id). |
| **Client Credentials** | Server-to-server (Whitelabel admin) | `POST /auth/token` `grant_type=client_credentials`. **Never expose client_secret in mobile.** |
| **SIWE (Sign in with Ethereum)** | Users who already have Monerium + wallet | Optional shortcut — EIP-4361 message + signature in `/auth` instead of portal redirect. Evaluate vs Circle MPC / Safe wallets. |

**Refresh tokens:** access token ~1 hour; implement refresh via `grant_type=refresh_token` in gateway (encrypted storage server-side).

### Environments (verify — do not hardcode stale URLs)

| Env | Web | API (typical) |
|-----|-----|---------------|
| Sandbox | sandbox.monerium.app / sandbox.monerium.dev | `https://api.monerium.dev` |
| Production | monerium.app | `https://api.monerium.app` |

Accept header: Monerium API uses versioned media types — read current docs for exact `Accept` / `Content-Type` values.

### EURe + Gnosis (verify token addresses on docs.monerium.com/tokens)

Seed values (re-verify before deploy):

- Gnosis **mainnet** EURe: `0x420CA0f9B9b604cE0fd9C18EF134C705e5Fa3430`
- Gnosis **testnet** EURe: `0x7a47605930002CC2Cd2c3c408D1F33fc2a18aB71`

**Mint path (issue):** SEPA credit to linked IBAN → Monerium auto-creates **issue** order → EURe minted to linked wallet. Your app does **not** POST issue orders.

**Burn path (redeem):** App POST **redeem** order with wallet **signature** → EURe burned → SEPA to counterpart IBAN. Orders require EIP-191 / ERC-1271 signature from wallet owner (EOA or Safe).

### Wallet linking (critical for Circles)

Before IBAN + EURe work, user wallet must be **linked** on the correct chain:

- `POST` link address (message + signature) or `moveIban` / `requestIban` per SDK docs
- Chain must be **`gnosis`** (or `chiado` testnet equivalent — confirm in API enum)
- **Workaround if mobile has no wallet yet:** Phase 3A can use Monerium OAuth portal wallet creation first; defer Circle MPC / Safe to Phase 3B+ (`CIRCLE_MPC_ENABLED=false`)

### Order lifecycle (contribution reconciliation)

Subscribe to or poll:

- `order.created` — incoming SEPA detected (early signal)
- `order.updated` with `state=processed` — mint/burn complete; `meta.txHashes` for on-chain proof
- `order.updated` with `state=rejected` — log `meta.rejectedReason`, surface to host

Map Monerium orders to `CircleContribution` rows (reference, amount, member, round).

### Recommended integration approaches (agent picks one, documents why)

**Approach A — REST gateway only (matches Payspin Yapily pattern)**  
Implement `MoneriumGateway` in `backend/src/infrastructure/monerium/` using raw `fetch`/axios against OpenAPI. Best control, testable with MockClient pattern.

**Approach B — Wrap `@monerium/sdk` server-side only**  
Use npm SDK inside gateway adapter for token refresh + order helpers. Do **not** import SDK in Flutter.

**Approach C — Hybrid pilot**  
OAuth onboarding via redirect (A/B) + **WebSocket** order listener in backend worker for OAuth plan (no HTTP webhooks) + Yapily PIS for member SEPA → circle IBAN.

**Approach D — Whitelabel (production)**  
Full profile/IBAN/order API from your onboarding UI; HTTP webhooks with signature verification (mirror `yapily-webhooks.controller.ts`).

Agent must implement **at least Approach A or C for sandbox** and document migration path to D.

### Payspin-specific workarounds (evaluate during research)

1. **Circle pot IBAN:** MVP uses host's Monerium IBAN or dedicated Whitelabel IBAN per circle — confirm Monerium allows SEPA to same IBAN from multiple Yapily payers with reference/memo matching for `CircleContribution`.
2. **No webhooks on OAuth:** Backend BullMQ job polls orders every N seconds OR WebSocket subscriber; idempotent on `order.id`.
3. **Wallet signatures on mobile:** Burn/redeem needs wallet signature — may require embedded wallet (Circle MPC) or redirect to Monerium signing flow; research `GET /signatures` pending signature API.
4. **Smart contract vs Monerium-only pilot:** If contract audit blocks 3B, ship **Monerium-only ROSCA** (IBAN + EURe tracking off-chain in Postgres) as interim with feature flag `CIRCLES_ONCHAIN_ENABLED=false`.
5. **Yapily + Monerium handoff:** Member pays via existing `PIS_GATEWAY` to beneficiary IBAN = circle Monerium IBAN; reconcile via Monerium issue orders, not Yapily webhook alone.

### Research deliverable checklist (blocks Phase 3A coding)

- [ ] Sandbox app created; plan type documented
- [ ] curl PoC: token exchange works
- [ ] curl PoC: list IBANs / profiles after test user onboarded
- [ ] Order states documented with sample JSON
- [ ] Webhook **or** WebSocket **or** poll strategy chosen with rationale
- [ ] `circles-monerium-research.md` updated
- [ ] `circles-phase3-decisions.md` created with chosen approach

---

## What already exists (do not redo)

| Layer | Done |
|-------|------|
| Tikkies | Full API + payer web + mobile |
| Circles MVP | CRUD/join/activate/advance, invite codes, contribution **payment links** |
| Prisma | `Circle.smartContractAddress`, `CircleMember.moneriumIban`, `CircleMember.walletAddress` (nullable, unused) |
| Mobile Groepies | List, create, join, detail, host actions |
| Tests | Backend 41+, mobile 84+ |

---

## Phase 3A — Monerium integration (backend first)

### Gateway pattern (non-negotiable)

Mirror Yapily: define interfaces in `packages/` (e.g. `@payspin/monerium-provider` or extend `pisp-provider`), implement HTTP adapter in `backend/src/infrastructure/monerium/`, inject via symbol (`MONERIUM_GATEWAY`). **Use cases never call Monerium HTTP directly.**

Suggested interface surface:

```typescript
interface MoneriumGateway {
  buildAuthorizationUrl(params: { redirectUri: string; state: string }): string;
  exchangeCode(params: { code: string; redirectUri: string }): Promise<MoneriumTokens>;
  getProfile(accessToken: string): Promise<MoneriumProfile>; // iban, wallet address
  initiateBurn(params: { ... }): Promise<MoneriumOrderId>;
  // webhook verification + order status
}
```

### API routes (suggested — align with live OpenAPI after STEP 0)

| Method | Route | Purpose |
|--------|-------|---------|
| GET | `/v1/monerium/connect` | Start OAuth PKCE (returns `authorizationUrl`, `state`) |
| GET | `/v1/monerium/callback` | Server callback → redirect `payspin://monerium-callback` |
| POST | `/v1/monerium/complete` | Exchange code + PKCE verifier; store encrypted tokens + profile |
| GET | `/v1/monerium/status` | Link status (iban last4, wallet, kycState, chain) |
| POST | `/v1/monerium/refresh` | Refresh access token (server-side) |
| POST | `/v1/monerium/orders/redeem` | Create redeem order (requires wallet signature from client or MPC) |
| POST | `/webhooks/monerium` | **Whitelabel only** — `order.updated`, `profile.updated` (`@SkipThrottle()`) |
| WS / worker | internal | **OAuth plan fallback** — WebSocket or poll `/orders` |

### Data model extensions (Prisma migration)

Add as needed (align with Monerium API):

- `UserMoneriumProfile` — userId, encrypted tokens, ibanLast4, walletAddress, kycStatus, linkedAt
- Extend `Circle` — moneriumIban, chainId, contractAddress, pot metadata
- `CircleContribution` — circleId, round, memberId, amountCents, yapilyPaymentId, moneriumOrderId, status, paidAt
- `CircleRound` (optional) — roundNumber, recipientMemberId, status, timestamps

Encrypt sensitive tokens/IBANs like existing `BankAccount.ibanEncrypted` pattern.

### Env vars (document in `backend/.env.production.example`)

```
MONERIUM_CLIENT_ID=
MONERIUM_CLIENT_SECRET=
MONERIUM_REDIRECT_URI=https://api.payspin.app/v1/monerium/callback
MOBILE_MONERIUM_REDIRECT=payspin://monerium-callback
MONERIUM_WEBHOOK_SECRET=
GNOSIS_RPC_URL=
ROSCA_CONTRACT_ADDRESS=
```

---

## Phase 3B — Smart contract (Gnosis Chain)

### Contract responsibilities (from architecture doc)

Solidity ROSCA contract in `infrastructure/contracts/rosca/`:

- `createCircle(memberCount, contributionAmount, cycleDuration)` → circleId
- `contribute(circleId)` — accept EURe, mark member paid for round
- `claimPayout(circleId)` — current recipient only
- `getCircleState(circleId)` — members, round, paid bitmap, recipient
- `pauseCircle(circleId)` — admin/multisig (defer multisig if needed)

### Backend chain gateway

`CHAIN_GATEWAY` (ethers/viem): deploy circle on-chain at **activate**, store `smartContractAddress` on `Circle`. Read state for mobile detail (paid/unpaid per member).

**Sandbox only until audit:** mainnet deploy requires external audit (€30k–60k per architecture doc). Use Gnosis Chiado + Monerium sandbox.

### Circle MPC wallets (optional sub-phase)

Architecture mentions **Circle Programmable Wallets + Gas Station**. If too large for one pass:

1. Ship Monerium OAuth + store `walletAddress` from Monerium profile first
2. Defer Circle MPC with feature flag `CIRCLE_MPC_ENABLED=false`

---

## Phase 3C — Contribution flow (replace payment-link MVP)

**Target flow** (Architecture B §4.2 Phase B):

1. Member sees "Contribution due: €X" on circle detail (C08)
2. Member taps Pay → backend creates **Yapily payment** with beneficiary = **circle's Monerium IBAN**
3. Member completes bank auth (reuse PIS gateway; new `InitiateCircleContributionUseCase`)
4. Monerium webhook: SEPA received → EURe minted → transfer to contract
5. Contract marks member paid; when all paid → payout to round recipient

**Backend:**

- `POST /v1/circles/:id/contribute` — member initiates (returns Yapily redirect)
- `GET /v1/circles/:id/contributions?round=N` — paid status per member
- Gate legacy `POST /circles/:id/contribution-link` behind `CIRCLES_LEGACY_LINK_CONTRIBUTIONS=true`

**Mobile:** C08 contribution screen with per-member checklist for current round.

---

## Phase 3D — Payout & off-ramp

1. Round complete → recipient wallet receives EURe
2. Mobile C13 Payout: balance + "Withdraw to bank"
3. `POST /v1/monerium/burn` → Monerium burn → SEPA
4. Webhook confirms; update round state + FCM notify

**Gelato automation (optional):** auto-trigger payout when all contributions detected — document if deferred.

---

## Phase 3E — Mobile UI (wireframes C01–C16, R03)

| Screen | Route / location | Notes |
|--------|------------------|-------|
| C06 Members | Circle detail | Reorder/remove → existing PATCH API |
| C07 History | `/circles/:id/history` | Past rounds |
| C08 Contribution | Circle detail | Pay now + paid ticks |
| C09–C11 Monerium onboarding | `/monerium/onboarding` | `flutter_web_auth_2`, `payspin://monerium-callback` |
| C12 Wallet | Profile or `/wallet` | EURe balance, truncated address |
| C13 Payout | From wallet/circle | Burn to bank |
| C14 Paused | Circle detail | Contract paused state |
| C15 Join | Exists — Monerium gate if required |
| C16 Locked teaser | Pre-KYC users | "Complete Monerium to join Circles" |
| R03 Profile Monerium | Profile page | Link status, re-link |

**Gating:** Users without Monerium profile cannot join blockchain circles (403 + route to C09).

Add `payspin://monerium-callback` to Android/iOS manifests (mirror bank callback).

---

## Phase 3F — Other missing features (non-blockchain)

| Feature | Where | Acceptance |
|---------|-------|------------|
| Member reorder/remove UI | Mobile C06 | Host uses PATCH member API |
| Per-round contribution tracking | Backend + C08 | PAID/PENDING/FAILED per member |
| MULTI / expiry link creation | Mobile send flow | Match `createPaymentLinkSchema` |
| Real SMS OTP | Backend + mobile | Twilio/MessageBird; rate limit |
| FCM push | Backend BullMQ + mobile | Payment, contribution due, payout ready |
| Deals tab | Home | Hide or scaffold per product |
| Release signing | mobile/android, ios | Fastlane docs unless certs provided |
| Circle integration tests | backend/test | FakeMonerium + FakeChain |
| E2E script | scripts/dev/e2e-circles-monerium.sh | Sandbox happy path |

---

## Architecture rules

1. Zod in `@payspin/validators`; types in `@payspin/shared-types`
2. Use cases in `application/use-cases/` — no logic in controllers
3. Monerium, Chain, Yapily only via injected gateways
4. Mobile: repository pattern; `apiErrorMessage()`; 401 clears JWT
5. Webhooks: signature verify + BullMQ (mirror Yapily webhooks)
6. Encrypt IBAN/tokens at rest; never log secrets
7. Non-custodial: Payspin never holds fiat

---

## Testing

**Backend:** OAuth, webhooks, contribution beneficiary = circle Monerium IBAN, round completion, auth guards, fake gateways in CI.

**Mobile:** Monerium onboarding states, contribution UI, member admin, new mappers.

**Manual sandbox:** Monerium KYC → create/activate circle → contribute → payout → burn.

---

## Recommended order

```
0  LIVE Monerium API research + sandbox PoC + decision doc (BLOCKS all coding)
3A Monerium gateway + OAuth PKCE + mobile C09–C11, R03
3B Contract + CHAIN_GATEWAY + link on activate (or Monerium-only flag if blocked)
3C Yapily → circle Monerium IBAN + C08 + CircleContribution + order reconciliation
3D Payout + redeem order + C12–C13 + webhooks/WebSocket/poll
3E C06, C07, polish
3F OTP, FCM, MULTI links, E2E, docs
```

Do not block 3A on contract audit — testnet/sandbox only.

---

## Out of scope (unless requested)

- Mainnet before smart contract audit
- Aave V3 yield
- 3-of-5 Safe multisig (stub only)
- Payspin-portal admin
- Separate Payspin-mobile repo
- Replacing JWT with Firebase auth (add FCM only)

---

## Docs to create

- `docs/agents/circles-monerium-research.md` — **live API findings** (updated in STEP 0)
- `docs/agents/circles-monerium-setup.md` — sandbox accounts, env, callback URLs
- `docs/agents/circles-phase3-decisions.md` — chosen approach + tradeoffs
- Update `docs/agents/circles-contribution-mvp.md`
- `infrastructure/contracts/rosca/README.md`

---

## Definition of done

- [ ] **STEP 0 complete:** live Monerium docs researched, sandbox PoC curl logs in research doc, approach chosen
- [ ] Monerium OAuth PKCE E2E (mobile → backend → callback → stored profile + wallet/IBAN)
- [ ] Order reconciliation works (webhook **or** WebSocket **or** poll — per chosen plan)
- [ ] Circle activates with on-chain contract on testnet **or** `CIRCLES_ONCHAIN_ENABLED=false` documented interim
- [ ] Yapily contributions to circle Monerium IBAN; per-member status in UI
- [ ] Recipient redeem/burn to bank (sandbox)
- [ ] Member admin UI + history
- [ ] `pnpm test` + `flutter test` green
- [ ] No secrets in git
- [ ] Sandbox E2E script documented

---

## Agent start command

> Load `docs/agents/circles-phase3-blockchain-prompt.md`. **Start with STEP 0:** use web search and live requests against Monerium sandbox API (`api.monerium.dev`) to verify auth, IBAN, and order flows; update `docs/agents/circles-monerium-research.md` and `circles-phase3-decisions.md` with the best integration approach (OAuth vs Whitelabel, webhooks vs WebSocket vs poll). Only then implement **3A→3D**. Compare findings to `resources/docs/payspin-solution-architecture.md` and flag conflicts. Mirror Yapily gateway patterns. **Sandbox/testnet only.** Run `pnpm test` and `cd mobile && flutter test` before finishing.
