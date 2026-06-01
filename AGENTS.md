# Payspin — Agent Guide

Entry point for AI agents (Cursor, Claude Code, etc.) working on this monorepo.

**Claude Code:** see [CLAUDE.md](CLAUDE.md) and [docs/agents/claude-mcp-setup.md](docs/agents/claude-mcp-setup.md) for MCP + design context.

## Product

**Payspin** — P2P payment links (Tikkie-style). Payee uses Flutter app; payer uses public web link → Yapily/iDEAL redirect. **Non-custodial**: we never hold funds.

## Repo map

| Path | Stack | Workspace | Role |
|------|-------|-----------|------|
| `backend/` | NestJS 11, Prisma, BullMQ | pnpm | REST API `/v1` |
| `frontend/` | Next.js 15 App Router | pnpm | Payer web `/{code}` |
| `mobile/` | Flutter 3.5+ | standalone | Payee iOS/Android |
| `packages/` | TypeScript | pnpm | shared-types, validators, pisp-provider |
| `infrastructure/` | Docker, Hetzner | — | local DB + prod deploy |
| `scripts/dev/` | Bash | — | `payspin-dev` CLI |
| `resources/docs/` | Markdown | — | specs, runbooks, architecture |

**Out of scope for Phase 1 changes:** `Payspin-portal/` (deferred admin).

## Before you code

1. Read [docs/agents/architecture.md](docs/agents/architecture.md) for layer rules.
2. Read [docs/agents/conventions.md](docs/agents/conventions.md) for naming and patterns.
3. Use skill `.cursor/skills/payspin/SKILL.md` for end-to-end workflows (feature, deploy, E2E).
4. Run `./scripts/dev/payspin-dev doctor` after env or infra changes.

## Local stack (default ports)

| Service | URL |
|---------|-----|
| API | http://localhost:3001/v1 |
| Payer web | http://localhost:3000 |
| Postgres | localhost:5435 |
| Redis | localhost:6381 |

```bash
pnpm install
./scripts/dev/payspin-dev setup
./scripts/dev/payspin-dev start --web
cd mobile && flutter run --dart-define=API_URL=http://localhost:3001/v1
```

## Architecture principles (non‑negotiable)

1. **Backend:** use cases in `application/`, HTTP in `interfaces/`, Prisma/Yapily in `infrastructure/`. No business logic in controllers.
2. **Gateways:** inject `PIS_GATEWAY` / `AIS_GATEWAY` from `@payspin/pisp-provider` — never call Yapily HTTP directly from use cases.
3. **Validation:** Zod schemas in `@payspin/validators` inside use cases (not Nest DTO classes for domain rules).
4. **Mobile:** domain repos (abstract) → data impls → presentation. Design tokens from `PayspinTheme` (see `.cursor/rules/payspin-design.mdc`).
5. **Scope:** minimal diffs; match existing naming; no drive-by refactors.

## Common tasks

| Task | Where to look |
|------|----------------|
| New API endpoint | `backend/src/application/use-cases/` + `interfaces/http/<feature>/` |
| New payer page | `frontend/app/` |
| New mobile screen | `mobile/lib/presentation/` + route in `app/router.dart` |
| Shared types | `packages/shared-types/` |
| Deploy backend | `infrastructure/hetzner/README.md` |
| Yapily setup | `resources/docs/yapily-console-setup.md` |

## Cursor rules (auto-loaded)

| Rule | Scope |
|------|--------|
| `payspin-core.mdc` | Always |
| `backend-clean-arch.mdc` | `backend/**/*.ts` |
| `frontend-nextjs.mdc` | `frontend/**` |
| `mobile-architecture.mdc` | `mobile/lib/**` |
| `payspin-design.mdc` | `mobile/**/*.dart` (UI tokens) |
| `packages-shared.mdc` | `packages/**` |
| `infrastructure-deploy.mdc` | `infrastructure/**` |

## Docs index

See [docs/README.md](docs/README.md) for full documentation map.

## Accounts (production)

- Hetzner / Docker Hub: **payspin.app@gmail.com** only — not work emails.
- GitHub: `git@github.com:MHarooney/Payspin.git`
