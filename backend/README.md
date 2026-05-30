# Payspin API

NestJS backend with clean architecture (domain / application / infrastructure / interfaces).

## Quick start

```bash
# From repo root
pnpm install
pnpm db:up
cp backend/.env.example backend/.env
pnpm --filter @payspin/backend prisma:generate
pnpm --filter @payspin/backend prisma:migrate
pnpm --filter @payspin/pisp-provider build
pnpm --filter @payspin/backend dev
```

API: `http://localhost:3001/v1/health`

## Layout

```
src/
  domain/           # pure helpers (short codes, IBAN extract)
  application/      # use cases (auth, links, payments, open banking)
  infrastructure/   # Prisma, encryption, Yapily gateways, BullMQ
  interfaces/       # HTTP controllers, webhooks, JWT
```

## HTTP surface

| Area | Routes |
|------|--------|
| Auth | `POST /auth/register`, `POST /auth/login` |
| Users | `GET/PATCH /users/me` |
| Bank accounts | `GET/POST /bank-accounts`, `POST /bank-accounts/connect`, `POST /bank-accounts/connect/complete` |
| Links | `GET/POST /links`, `GET /links/:id`, `DELETE /links/:id` |
| Payer (public) | `GET/POST /pay/:code/initiate`, `POST /pay/:code/complete`, `GET /pay/:code/status/:id` |
| Open banking | `GET /open-banking/institutions` |
| Webhooks | `POST /webhooks/yapily` |

## Yapily

- **PIS**: `payment-auth-requests` → user consent → `POST /payments` with `Consent` header
- **AIS**: `account-auth-requests` → `GET /accounts` with consent
- Sandbox when `YAPILY_APP_KEY` is empty (see `.env.example`)

## Environment

See [`backend/.env.example`](.env.example).

## Tests

```bash
pnpm --filter @payspin/backend test
```
