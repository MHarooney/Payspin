# Monerium API — Research seed (agent must re-verify live)

**Status:** Seed notes from architecture review + public docs (May 2026).  
**Rule:** Implementing agent MUST browse https://docs.monerium.com/ and run sandbox curl PoCs before coding. Update this file with live findings.

---

## Official sources

| Resource | URL |
|----------|-----|
| Getting started | https://docs.monerium.com/ |
| API reference (OpenAPI) | https://docs.monerium.com/api/ |
| Authorization | https://docs.monerium.com/authorization/ |
| Whitelabel guide | https://docs.monerium.com/whitelabel/ |
| JS SDK | https://www.npmjs.com/package/@monerium/sdk · https://monerium.github.io/sdk/ |
| Go SDK (client credentials only) | https://github.com/monerium/go-sdk |
| Sandbox developer portal | https://sandbox.monerium.dev/developers |
| Partnership (production) | https://monerium.com/invite/partners |

---

## Developer plan comparison (verify on Getting Started page)

| Feature | OAuth | Whitelabel | Private |
|---------|-------|------------|---------|
| User onboarding | Monerium co-branded portal | Your API/UI | Own account only |
| HTTP webhooks | **No** | **Yes** | Yes |
| Dedicated IBAN per customer | Shared | Dedicated | Own |
| SEPA + bridging | Yes | Yes | Yes |
| Pricing | Free tier | Custom | Free |

**Implication for Payspin:** OAuth is fastest for pilot but needs **WebSocket or polling** for order status. Whitelabel needed for production webhooks + branded KYC.

---

## Environments (verify before hardcoding)

| | Web UI | API base |
|---|--------|----------|
| Sandbox | sandbox.monerium.app / sandbox.monerium.dev | `https://api.monerium.dev` |
| Production | monerium.app | `https://api.monerium.app` |

---

## Auth flows

### Authorization Code + PKCE (mobile / payer-facing)

1. Backend generates PKCE `code_verifier` + `code_challenge` (S256), stores verifier keyed by `state`
2. Redirect user to `POST/GET https://api.monerium.dev/auth` with **Authorization Code Flow client_id**
3. User completes KYC in Monerium portal; redirect to `redirect_uri?code=...&state=...`
4. Backend `POST /auth/token` with `grant_type=authorization_code`, `code`, `code_verifier`, `redirect_uri`
5. Store `access_token` + `refresh_token` encrypted; refresh hourly via `grant_type=refresh_token`

**Alternative:** SIWE (EIP-4361) in `/auth` for users with existing Monerium + wallet — evaluate for power users.

### Client credentials (server / Whitelabel)

- `POST /auth/token` with `grant_type=client_credentials`, Whitelabel `client_id` + `client_secret`
- Never use in Flutter/mobile

---

## Core API surfaces (confirm paths in OpenAPI)

| Area | Typical endpoints | Notes |
|------|-------------------|-------|
| Profiles | GET profiles | KYC state |
| IBANs | GET/POST ibans, moveIban, requestIban | Link wallet on `gnosis` chain |
| Addresses | POST link address | Requires wallet signature |
| Orders | GET orders, POST orders | **Issue** auto on SEPA in; **Redeem** requires signature |
| Signatures | GET /signatures | Pending wallet signatures (orders, linkAddress) |
| Webhooks | POST your URL | Whitelabel only; verify signature per docs |

---

## EURe on Gnosis (re-verify at docs.monerium.com/tokens)

| Network | EURe contract (seed) |
|---------|---------------------|
| Gnosis mainnet | `0x420CA0f9B9b604cE0fd9C18EF134C705e5Fa3430` |
| Gnosis testnet | `0x7a47605930002CC2Cd2c3c408D1F33fc2a18aB71` |

**Issue (mint):** SEPA → linked IBAN → Monerium creates issue order → EURe to linked wallet.  
**Redeem (burn):** POST redeem order + wallet signature → EURe burned → SEPA to counterpart IBAN.

---

## Order states (for CircleContribution reconciliation)

| State | Meaning |
|-------|---------|
| `placed` | Created, not processed |
| `pending` | Awaiting mint/burn/SEPA |
| `processed` | Complete — check `meta.txHashes` |
| `rejected` | Failed — check `meta.rejectedReason` |

Events: `order.created`, `order.updated` (Whitelabel webhooks or WebSocket).

---

## Payspin integration options (agent decides)

| ID | Approach | Pros | Cons |
|----|----------|------|------|
| A | Raw REST gateway | Matches Yapily pattern; fully testable | More boilerplate |
| B | `@monerium/sdk` in backend adapter | Faster token/order helpers | SDK version lock-in |
| C | OAuth + WebSocket/poll (pilot) | Works without Whitelabel webhooks | More moving parts |
| D | Whitelabel + webhooks (prod) | Best UX + realtime | Partnership approval |

---

## Sandbox PoC checklist (agent fills in results)

```bash
# 1. Token (client credentials — Whitelabel/Private app)
curl -X POST 'https://api.monerium.dev/auth/token' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'client_id=YOUR_ID&client_secret=YOUR_SECRET&grant_type=client_credentials'

# 2. After OAuth user test — list IBANs (user access token)
# curl -H "Authorization: Bearer $ACCESS" https://api.monerium.dev/ibans

# 3. List orders
# curl -H "Authorization: Bearer $ACCESS" https://api.monerium.dev/orders
```

Record response JSON samples below:

### PoC results (agent append)

- [ ] Sandbox app plan type: ___
- [ ] Token exchange: ___
- [ ] Test user profile ID: ___
- [ ] Linked IBAN last4: ___
- [ ] Linked wallet + chain: ___
- [ ] Sample issue order JSON: ___
- [ ] Chosen reconciliation: webhook / WebSocket / poll

---

## Conflicts with internal architecture doc

Agent should compare live API to `resources/docs/payspin-solution-architecture.md` §4.2 and note:

- [ ] Firebase Auth mentioned in architecture vs JWT in codebase — keep JWT
- [ ] Circle MPC wallet timing — defer or integrate?
- [ ] Gelato automation — required for MVP or manual advance-round?

---

## Links

- EURe product page: https://monerium.com/eure/
- Gnosis Pay case study (IBAN + EURe flow): https://monerium.com/case-studies/gnosispay/
