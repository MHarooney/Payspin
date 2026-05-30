# Payspin Mobile — Agent Implementation Prompt

**Purpose:** Paste this file (or link it in Cursor rules / agent context) when implementing **`git@github.com:payspin/Payspin-mobile.git`** — the standalone Flutter payee app that connects to the Payspin platform API (Part 1 monorepo: backend + payer web + infra).

**Product:** Payspin is a non-custodial P2P payments platform with two complementary pillars:

1. **Payment links (Tikkies)** — payee creates a link; payer pays via public web + Yapily/iDEAL. **Shipped in Part 1 API; mobile must reach production parity.**
2. **Circles (Groepies)** — community rotating savings groups (tontines): members contribute on a schedule; each member receives a payout in rotation. **Schema + UI shell exist; full stack is Phase 2.**

Tagline (design system): *"Your money, your community, and your peace of mind."*

---

## Repo split

| Part | Repository | Stack | Role |
|------|------------|-------|------|
| **Platform** | Payspin monorepo (`backend/`, `frontend/`, `packages/`, `infrastructure/`) | NestJS, Prisma, Postgres, Redis, Yapily, Next.js | API `/v1`, payer web, deploy |
| **Mobile (this repo)** | `git@github.com:payspin/Payspin-mobile.git` | Flutter 3.5+, standalone | Payee iOS/Android |

Mobile **never** connects to Postgres/Redis directly. All data flows through REST `/v1` with JWT.

---

## Infrastructure alignment

| Environment | API base | Mobile config |
|-------------|----------|---------------|
| Local | `http://localhost:3001/v1` | `--dart-define=API_URL=...` (Android emulator: `http://10.0.2.2:3001/v1`) |
| Production | `https://<domain>/v1` | Caddy routes `/v1` → API; **no localhost in release builds** |

**Open banking deep link:** `payspin://bank-callback?consent=...`  
Backend: `GET /v1/bank-accounts/connect/callback` → 302 to `MOBILE_CONNECT_REDIRECT`.

**Local stack (monorepo):** `./scripts/dev/payspin-dev start --web` · Postgres `:5435` · Redis `:6381`.

**Production account:** Hetzner / Docker Hub → `payspin.app@gmail.com` only.

---

## Database model (source of truth — read via API only)

Understand Prisma schema in Part 1 (`backend/prisma/schema.prisma`) so mobile UI matches server rules.

### Pillar 1 — Payment links (live API)

```
User
  └── BankAccount (ibanLast4, verified, verificationSource: MANUAL | YAPILY)
  └── PaymentLink (shortCode, amountCents?, currency, status, linkType, maxUses, useCount, expiresAt)
        └── Payment (amountCents, status, payerBankName?, initiatedAt, completedAt)
```

**Enums:** `PaymentLinkStatus` ACTIVE | COLLECTING | EXPIRED | CANCELLED | SETTLED · `PaymentLinkType` SINGLE | MULTI · `PaymentStatus` AWAITING_AUTHORIZATION | PENDING | PROCESSING | COMPLETED | FAILED | CANCELLED

**Rules mobile must enforce in UI:**
- No link creation without a bank account.
- SINGLE → one completed payment then SETTLED; MULTI → `useCount` / `maxUses`, may show COLLECTING.
- Open-amount links: `amountCents == null`; payer enters amount on web.
- IBAN never returned in full — only `ibanLast4`.

### Pillar 2 — Circles / Groepies (schema ready, API deferred)

```
Circle
  name, hostUserId, memberCount, contributionCents, cycleDurationDays
  smartContractAddress?, status (default DRAFT), currentRound
  └── CircleMember
        userId, moneriumIban?, walletAddress?, payoutOrder, status (default ACTIVE)
```

**Product intent (from design system):** Users create or join a circle, contribute recurring installments (e.g. monthly), and receive scheduled rotation payouts. Host/admin manages members and payout order. Copy in app uses **"Groepie"** tab label; domain model is **Circle**.

**Current state:**
- Prisma models exist; **no Nest use cases or controllers yet** (`Circle` / `CircleMember` are out of scope for Part 1 API).
- Mobile has a **placeholder** Groepies tab (`groepies_page.dart` — "Create Groepie" button is no-op).
- `IMPLEMENTATION_TRACKER.md` lists Groepies/Circles as **deferred**.

**When implementing Circles:** follow the same clean-arch pattern as payment links — Zod validators + use cases + controller in Part 1 monorepo first, then mobile repos/screens. Do **not** implement circle business logic only on the client. Fields like `moneriumIban` / `smartContractAddress` suggest future Monerium/blockchain integration; treat as optional until product confirms.

---

## API surface

### Shipped today (mobile must integrate)

| Area | Routes |
|------|--------|
| Auth | `POST /auth/register`, `POST /auth/login` |
| User | `GET /users/me`, `PATCH /users/me` |
| Bank | `GET/POST /bank-accounts`, `POST /bank-accounts/connect`, `POST /connect/complete`, `GET /open-banking/institutions` |
| Links | `GET/POST /links`, `GET /links/:id`, `DELETE /links/:id` |

### Planned for Circles (implement in Part 1 before mobile wiring)

Design these to mirror payment-link patterns; suggested shape (adjust during backend design):

| Route | Purpose |
|-------|---------|
| `POST /circles` | Create circle (host) — name, contributionCents, cycleDurationDays, initial members? |
| `GET /circles` | List circles for current user (host + member) |
| `GET /circles/:id` | Detail + members + round status |
| `POST /circles/:id/join` | Join with invite code or host approval |
| `PATCH /circles/:id/members/:memberId` | Update payout order / status (host only) |
| `POST /circles/:id/advance-round` | Host advances rotation (or cron/webhook later) |

Payment collection inside a circle may reuse **payment links** per round or a dedicated contribution endpoint — decide in Part 1 use-case design; mobile consumes whatever DTO `@payspin/shared-types` exposes.

### Error contract (mandatory)

```json
{ "statusCode": 400, "error": "Bad Request", "message": "...", "issues": [{ "path": "email", "message": "..." }] }
```

Parse `message` and first `issues[].message` for 400; friendly fallbacks for 401 / 409 / 429 / 502. Clear JWT on 401 → redirect to welcome/login.

---

## Mobile architecture (non-negotiable)

```
lib/
├── app/                 router.dart, di/injection.dart
├── core/                network, storage, errors, design_system
├── domain/              entities, repositories (abstract), usecases, validators
├── data/                PayspinApiClient, mappers, repository impls
└── presentation/        auth, onboarding, home, send, links, profile, circles/
```

| Concern | Choice |
|---------|--------|
| Routing | `go_router` + guards (session, bank account, onboarding) |
| DI | `get_it` → `sl` |
| State | `Cubit` for multi-step onboarding only; else repos/use cases |
| HTTP | Single `PayspinApiClient`; no API calls from widgets |
| Auth | `flutter_secure_storage` |
| Open banking | `flutter_web_auth_2` + `payspin://` (Android + iOS URL scheme) |
| UI | Dark prototype — `PayspinTheme`, `PayspinTokens` (see `.cursor/rules/payspin-design.mdc`) |

**Anti-patterns:** hardcoded localhost in release · fake OTP as real SMS · ignoring link status enums · business logic in widgets · calling Yapily from mobile (always via backend).

---

## User flows

### A. Payment links (Phase 1 — production gate)

1. Welcome → register/login → connect bank (Yapily AIS) or manual IBAN  
2. Home **Tikkies** tab → list links, pull-to-refresh, FAB create  
3. Create link: fixed or open amount, description (max 140), optional MULTI/maxUses/expiry when API supports  
4. Share link (WhatsApp / copy); link detail with payments + cancel + refresh/poll  
5. Profile: user, masked IBAN, logout (clear token + local flags)

### B. Circles / Groepies (Phase 2 — after Part 1 API)

1. Home **Groepies** tab (already in nav alongside Tikkies / Deals)  
2. Empty state → "Create Groepie" → circle setup (name, contribution amount, cycle length, member invite)  
3. Circle dashboard: members, payout order, current round, next recipient, contribution status  
4. Host admin: reorder payout, invite/remove members, advance round (permissions server-side)  
5. Notifications placeholder → FCM when backend supports  

**UX copy (design system):** warm, community-first, Title Case headings, EUR with commas ("1,800 EUR"). Tab label **Groepies**; API/domain **Circle**.

Reference UI shell: `mobile/lib/presentation/home/groepies_page.dart` (replace placeholder when API exists).

---

## Reference implementation (monorepo `mobile/`)

Migrate from monorepo; do not greenfield unless repo is empty.

| Area | Path |
|------|------|
| API client | `data/datasources/payspin_api_client.dart` |
| Errors | `core/errors/api_exception.dart` |
| Bank connect | `presentation/onboarding/pages/step_connect_bank_page.dart` |
| Router | `app/router.dart` |
| DI | `app/di/injection.dart` |
| Groepies shell | `presentation/home/groepies_page.dart`, `home_page.dart` (HomeTab.groepies) |
| Design system | `core/design_system/`, `resources/Payspin Design System/` |

**Known gaps to fix in Phase 1:** credentials Next button (`setState` on fields) · home refresh after create · link detail polling · MULTI/COLLECTING labels · remove/gate stub OTP · release signing · prod `API_URL`.

---

## Phased delivery

### Phase 0 — Bootstrap
Repo layout, CI (`flutter analyze`, `flutter test`), `ApiConfig`, DI, theme, error parsing.

### Phase 1 — Payment links (must ship for pilot)
Auth, onboarding + open banking, home/list/create/share/detail, profile, 401 handling. **Definition of done:** real payee completes full Tikkie flow against staging API.

### Phase 2 — Circles backend (Part 1 monorepo)
Zod schemas → use cases → `interfaces/http/circles/` → Prisma (existing models; add migrations if fields missing) → `@payspin/shared-types` DTOs. Host/member authorization on every mutation.

### Phase 3 — Circles mobile
`CircleRepository`, entities, mappers, replace Groepies placeholder, circle create/join/detail/admin screens, wire Home tab. Reuse list/card patterns from `PayspinTikkieRow` where appropriate.

### Phase 4 — Hardening
Integration tests, push notifications (FCM), optional Monerium/smart-contract fields only when product specifies.

---

## Cross-app payment flow (links only)

```
Mobile:  POST /links → shortCode
Payer:   GET /pay/:code → POST initiate → Yapily → callback → POST complete
Webhook: POST /webhooks/yapily (async status)
```

Circles may later trigger payer links per contribution round — design in Part 1, not duplicated in mobile.

---

## Constraints

- Minimal diffs; match monorepo naming (`docs/agents/conventions.md`).
- No secrets in git; no `.env` in commits.
- API gaps → PR to Part 1 monorepo (validators → use case → controller), never client-only rules.
- `Payspin-portal/` admin UI remains deferred unless requested.
- **Phase 1 agent focus:** payment links + bank onboarding. **Do not block Phase 1 on Circles API** — keep Groepies tab as empty/coming-soon until Phase 2, or implement read-only mocks only behind a feature flag.

---

## Agent start command

> Clone `git@github.com:payspin/Payspin-mobile.git`. Load this prompt. Use monorepo `mobile/` as migration baseline and `backend/prisma/schema.prisma` + live `/v1` routes as contract truth. Implement Phase 0–1 completely (payment links + open banking). For Groepies/Circles: respect existing schema and UI tab; implement backend API in Part 1 first (Phase 2), then wire mobile (Phase 3). Parse backend `{ message, issues }` errors. Run against `http://localhost:3001/v1` with `./scripts/dev/payspin-dev start` from the platform repo.
