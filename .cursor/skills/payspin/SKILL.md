---
name: payspin
description: >-
  Work on the Payspin monorepo (NestJS backend, Next.js payer web, Flutter mobile).
  Use when implementing features, fixing bugs, running local dev, deploying to Hetzner,
  Yapily payments, or when the user mentions Payspin, payment links, or this repo.
---

# Payspin project skill

## Read first

1. [AGENTS.md](../../AGENTS.md) — repo map and principles
2. [docs/agents/architecture.md](../../docs/agents/architecture.md) — layer rules
3. [docs/agents/workflows.md](../../docs/agents/workflows.md) — task checklists

## Quick orientation

| App | Path | Start command |
|-----|------|---------------|
| API | `backend/` | `./scripts/dev/payspin-dev start` |
| Payer web | `frontend/` | `./scripts/dev/payspin-dev start --web` |
| Mobile | `mobile/` | `flutter run --dart-define=API_URL=http://localhost:3001/v1` |
| DB | `infrastructure/docker/` | `pnpm db:up` |

Health: `curl http://localhost:3001/v1/health`

## When implementing a backend feature

```
validators → shared-types → use case → controller/module → http-api.module.ts
```

- Gateways: `@Inject(PIS_GATEWAY)` / `@Inject(AIS_GATEWAY)` + `YapilyModule` import
- No business logic in controllers
- Prisma changes: migrate in `backend/prisma/`

## When implementing mobile UI

- Follow `.cursor/rules/payspin-design.mdc` (dark theme, gradient CTAs)
- Route in `mobile/lib/app/router.dart`
- Repo pattern: abstract in `domain/`, impl in `data/`

## When deploying

1. Confirm Hetzner verification complete
2. `export HCLOUD_TOKEN=... && ./infrastructure/hetzner/up.sh`
3. Verify `http://<ip>/v1/health`
4. Update server `.env.production` for Yapily + public URLs

Details: [infrastructure/hetzner/README.md](../../infrastructure/hetzner/README.md)

## E2E API smoke

```bash
./scripts/dev/e2e-register-iban-link.sh
```

## Additional resources

- [docs/agents/conventions.md](../../docs/agents/conventions.md) — naming, anti-patterns
- [resources/docs/yapily-console-setup.md](../../resources/docs/yapily-console-setup.md)
- [resources/docs/local-development-runbook.md](../../resources/docs/local-development-runbook.md)

## Do not

- Expand `Payspin-portal/` unless explicitly requested
- Use non-Payspin emails for Hetzner/Docker (`payspin.app@gmail.com` only)
- Commit secrets or `.env` files
- Add repository abstraction layer to backend without user request (Prisma-in-use-case is intentional)
