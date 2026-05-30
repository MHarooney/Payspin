# Architecture reference (agents)

## Monorepo

```
Payspin/
├── backend/src/
│   ├── domain/              # Pure helpers (minimal)
│   ├── application/use-cases/   # Business logic — one class per operation
│   ├── infrastructure/    # Prisma, encryption, Yapily, BullMQ
│   └── interfaces/          # HTTP controllers, webhooks, guards
├── frontend/app/            # Next.js App Router
├── mobile/lib/
│   ├── app/                 # router, DI
│   ├── core/                # theme, network, storage
│   ├── domain/              # entities, repo interfaces, use cases
│   ├── data/                # API client, repo impls, mappers
│   └── presentation/        # pages, widgets, cubits
├── packages/
│   ├── shared-types/        # DTOs shared with frontend
│   ├── validators/          # Zod schemas
│   └── pisp-provider/       # PIS_GATEWAY, AIS_GATEWAY tokens + interfaces
└── infrastructure/docker/   # compose, Caddy, prod stack
```

## Backend — clean architecture (pragmatic)

### Flow

```
HTTP Controller → Use Case → PrismaService / Gateway
                      ↓
                 Zod (validators) + mappers → shared-types DTOs
```

### Rules

- **Controllers:** parse route params, call `useCase.execute()`, return DTO. No Prisma, no Yapily.
- **Use cases:** `@Injectable()`, file `*.use-case.ts`, class `FooBarUseCase`, method `execute()`.
- **Persistence:** inject `PrismaService` directly (no repository interfaces yet).
- **External banking:** inject `@Inject(PIS_GATEWAY)` or `@Inject(AIS_GATEWAY)` only.
- **Modules:** feature module in `interfaces/http/<feature>/` registers controller + use cases. Import `YapilyModule` when gateways needed.

### Adding a feature (backend)

1. Zod schema in `packages/validators/` if new input shape.
2. DTO in `packages/shared-types/` if new response shape.
3. Use case in `backend/src/application/use-cases/<feature>/`.
4. Controller + module in `backend/src/interfaces/http/<feature>/`.
5. Register module in `http-api.module.ts`.
6. Prisma migration if schema changed: `cd backend && pnpm prisma migrate dev`.

### Key files

| File | Role |
|------|------|
| `backend/src/app.module.ts` | Root Nest module |
| `backend/src/interfaces/http/http-api.module.ts` | HTTP feature aggregator |
| `backend/src/infrastructure/yapily/yapily.module.ts` | Gateway providers |
| `packages/pisp-provider/src/index.ts` | DI tokens |
| `backend/prisma/schema.prisma` | Database schema |

## Frontend — Next.js payer web

- **Public only** — no JWT; pay by short code in URL.
- Dynamic route: `frontend/app/[code]/page.tsx`.
- API client: `frontend/lib/api.ts` → `NEXT_PUBLIC_API_URL` (default `http://localhost:3001/v1`).
- Yapily callback: `frontend/app/[code]/callback/page.tsx` → POST complete to API.

## Mobile — Flutter

### Layers

```
Presentation (pages) → Domain use cases / repos → Data (ApiClient) → Backend /v1
```

- **Routing:** `mobile/lib/app/router.dart` — `go_router`, session/onboarding redirects.
- **DI:** `mobile/lib/app/di/injection.dart` — GetIt `sl`.
- **State:** `Cubit` only for onboarding; other screens use repos directly.
- **API:** `--dart-define=API_URL=...` → `mobile/lib/core/network/api_config.dart`.

### UI

Dark prototype design system — see `.cursor/rules/payspin-design.mdc` and `resources/Payspin Design System/`.

## Payment flow (cross-app)

```
Mobile: POST /links → shortCode
Payer:  GET /pay/:code → POST /pay/:code/initiate → Yapily redirect
        → callback → POST /pay/:code/complete → success page
Webhook: POST /webhooks/yapily (async status)
```

## Infrastructure

| Env | Compose | Notes |
|-----|---------|-------|
| Local | `infrastructure/docker/docker-compose.yml` | Postgres + Redis only |
| Prod | `infrastructure/docker/docker-compose.prod.yml` | API + DB + Redis + Caddy |

Deploy scripts: `infrastructure/hetzner/{provision,deploy,up}.sh`.
