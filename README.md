# Payspin Monorepo

Backend-first TypeScript monorepo + Flutter mobile app.

## Structure

| Path | Stack | Purpose |
|------|-------|---------|
| [`backend/`](backend/) | NestJS, Prisma, PostgreSQL, Redis, Yapily | API — payment links, webhooks |
| [`frontend/`](frontend/) | Next.js 15 | Payer web — `pay.payspin.io/{code}` |
| [`mobile/`](mobile/) | **Flutter** | Payee mobile app (iOS + Android) |
| [`packages/`](packages/) | TypeScript | shared-types, validators, pisp-provider |
| [`Payspin-portal/`](Payspin-portal/) | React + Firebase | Admin portal (deferred) |

## Quick start

```bash
pnpm install
./scripts/dev/payspin-dev setup
./scripts/dev/payspin-dev start
```

API health: http://localhost:3001/v1/health

```bash
./scripts/dev/payspin-dev start --web          # + payer web :3000
./scripts/dev/payspin-dev start --mobile       # + Flutter (foreground)
cd mobile && flutter run --dart-define=API_URL=http://localhost:3001/v1
```

Or use pnpm: `pnpm dev:setup`, `pnpm dev:start`, `pnpm dev:status`, `pnpm dev:stop:all`

## Docs

### For AI agents

- **[AGENTS.md](AGENTS.md)** — start here (repo map, architecture principles, Cursor rules)
- **[docs/README.md](docs/README.md)** — full documentation index
- **Cursor skill:** `.cursor/skills/payspin/SKILL.md`

### Development & product

- **[Local development runbook](resources/docs/local-development-runbook.md)** — how to run API, DB, mobile, payer web
- **[Dev scripts](scripts/README.md)** — `payspin-dev` CLI (start / stop / restart / status)
- [Backend architecture](resources/docs/backend-architecture.md)
- [Solution architecture](resources/docs/payspin-solution-architecture.md)
- [Wireframes](resources/docs/wireframe-spec.md)
