# Payspin Ops Admin Portal

Internal operations portal for Payspin — monitor payments, circles, users,
compliance, reconciliation, support, system health, remote app config, and a
platform kill switch. Payspin dark brand (pink `#FC00FF` + teal `#07D8DD`).

- **Ops API:** NestJS 11 — `http://localhost:3002/admin/v1`
- **Ops UI:** Next.js 15 — `http://localhost:3003`
- **Shared infra:** same Postgres (`:5435`) and Redis (`:6381`) as the consumer stack.

> Separate from the consumer `backend/` (`/v1`) and payer `frontend/` (`:3000`).

## Quick start (under 5 minutes)

```bash
# 0. From repo root — install the whole workspace
pnpm install

# 1. Start shared infra (Postgres + Redis)
./scripts/dev/payspin-dev start          # or: pnpm db:up

# 2. Generate Prisma client + apply the additive admin migration
cd backend
pnpm prisma generate
pnpm prisma migrate dev --name admin_portal

# 3. Seed the admin user, feature flags, config, and Phase 2 demo data
pnpm ops:seed-admin
cd ..

# 4. Env files
cp ops-portal/backend/.env.example  ops-portal/backend/.env
cp ops-portal/frontend/.env.example ops-portal/frontend/.env.local

# 5. Run the ops API and UI (two terminals)
pnpm --filter @payspin/ops-backend dev      # :3002
pnpm --filter @payspin/ops-frontend dev     # :3003
```

Open http://localhost:3003 and sign in.

### Default credentials (seed)

| Field | Value |
|-------|-------|
| Email | `admin@payspin.app` |
| Password | `PayspinOps!2026` |

Override with `ADMIN_SEED_EMAIL` / `ADMIN_SEED_PASSWORD` before running the seed.
**Change these before any non-local deployment.**

## Architecture

Mirrors the consumer backend clean architecture:

```
HTTP Controller → Use Case (application/) → PrismaService / Redis
                       ↓
                  Zod (@payspin/validators) + mappers → @payspin/shared-types DTOs
```

- Admin JWT auth (`ADMIN_JWT_SECRET`), roles `SUPER_ADMIN | OPS | SUPPORT | READ_ONLY`.
- Every mutating action writes an immutable `AdminAuditEvent`.
- Kill switch is a privileged `FeatureFlag` (`platform_kill_switch`) — SUPER_ADMIN only, reason required.

## Environment

### `ops-portal/backend/.env`
| Var | Default | Notes |
|-----|---------|-------|
| `DATABASE_URL` | postgres@:5435 | shared with consumer stack |
| `REDIS_URL` | redis://:6381 | shared |
| `OPS_API_PORT` | 3002 | ops API (dedicated var so it never collides with the consumer backend's `PORT=3001`) |
| `ADMIN_JWT_SECRET` | — | min 32 chars in prod |
| `ADMIN_JWT_EXPIRES_IN` | 15m | access token TTL |
| `OPS_CORS_ORIGIN` | http://localhost:3003 | UI origin |
| `YAPILY_APPLICATION_ID` | — | optional, system-health reporting only |

### `ops-portal/frontend/.env.local`
| Var | Default |
|-----|---------|
| `NEXT_PUBLIC_OPS_API_URL` | http://localhost:3002/admin/v1 |

## Phase status

- **Phase 1 (real Postgres data):** auth, dashboard KPIs + volume, transactions
  (list/detail/retry), users (list + KYC/freeze), circles (list/detail), system
  health, config + feature flags, kill switch, audit log, global search.
- **Phase 2 (`Preview` badge — real seedable models / synthesized series):**
  reports, compliance, disputes, reconciliation, messages, app controls.

## Production deploy

Ops uses **separate Docker images** from the payer stack:

| Image | Service |
|-------|---------|
| `payspin/ops-api:latest` | NestJS admin API (`:3002`) |
| `payspin/ops-web:latest` | Next.js admin UI (`:3003`) |

After the payer stack is on Hetzner (`deploy.sh`), deploy ops only:

```bash
export PAYSPIN_SERVER_IP='178.105.118.225'
export OPS_SITE_ADDRESS='ops.payspin.io'
./infrastructure/hetzner/deploy-ops.sh
```

Requires DNS `ops` A record → server IP and an existing `/opt/payspin/.env.production`
from the payer deploy. Re-run `deploy-ops.sh` whenever you change ops portal code;
consumer `deploy.sh` does not touch ops images.

## Production QA

After deploy, run the cloud smoke test (uses one login — wait 60s if you hit rate limit):

```bash
./ops-portal/scripts/cloud-smoke-test.sh
```

Requires `jq` on your machine.

## Next features (agent prompts)

| Prompt | Purpose |
|--------|---------|
| [docs/agents/ops-portal-data-explorer-prompt.md](../docs/agents/ops-portal-data-explorer-prompt.md) | Schema/relations viewer, table data browser, Users 360°, UI polish |
| [docs/agents/ops-portal-preprod-focus-prompt.md](../docs/agents/ops-portal-preprod-focus-prompt.md) | **Pre-prod focus:** webhooks, payment links ops, real reports, consumer flag enforcement |

## Known gaps / Phase 2 wiring

- **Reports** series are synthesized deterministically — swap `GetReportSeriesUseCase`
  generators for SQL aggregates to go live.
- **Reconciliation** surfaces in-progress payments; true ledger-vs-Yapily variance
  needs the settlement feed.
- **Yapily health** is config-presence only (the ops portal holds no Yapily HTTP
  client — those live in the consumer backend via `PIS_GATEWAY`).
- **Messages** reply send and **2FA** on the kill switch are stubbed.

## Prisma models added (additive only)

`AdminUser`, `AdminAuditEvent`, `FeatureFlag`, `PlatformConfig`, `UserAdminState`,
`ComplianceAlert`, `Dispute`, `SupportThread`, `SupportMessage`. No existing
consumer tables were modified. Migrations are generated from `backend/`.
