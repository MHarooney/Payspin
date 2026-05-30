# Payspin Backend Architecture

Phase 1 API for Payspin P2P payment links.

## Stack

| Layer | Technology |
|-------|------------|
| API | NestJS 11, TypeScript |
| Database | PostgreSQL 16 + Prisma |
| Auth | JWT + bcrypt (users in PostgreSQL) |
| Queue | BullMQ + Redis 7 |
| Payer web | Next.js (no auth — public pay links) |

## Monorepo layout

```
backend/     NestJS API
frontend/    Next.js payer web (pay.payspin.io)
mobile/      Flutter app (iOS + Android)
packages/    shared-types, validators, pisp-provider
Payspin-portal/  Admin (deferred, separate stack)
```

## API routes (`/v1`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/health` | Public | Health check |
| POST | `/auth/register` | Public | Create account (email + password) |
| POST | `/auth/login` | Public | Sign in → JWT |
| GET | `/users/me` | JWT | Get profile |
| PATCH | `/users/me` | JWT | Update display name |
| POST | `/bank-accounts` | JWT | Add IBAN (encrypted) |
| GET | `/bank-accounts` | JWT | List accounts (last4 only) |
| POST | `/links` | JWT | Create payment link |
| GET | `/links` | JWT | List links |
| GET | `/links/:id` | JWT | Get link |
| DELETE | `/links/:id` | JWT | Cancel link |
| GET | `/pay/:code` | Public | Payer view (no IBAN) |
| POST | `/pay/:code/initiate` | Public | Start Yapily payment |
| GET | `/pay/:code/status/:paymentId` | Public | Payment status |
| POST | `/webhooks/yapily` | HMAC | Yapily webhook |

## Mobile (Flutter)

The payee app lives in [`mobile/`](../../mobile/) — outside the pnpm workspace.

- Auth: `POST /auth/login` → store JWT → `Authorization: Bearer`
- API base: `--dart-define=API_URL=http://localhost:3001/v1`

See [`mobile/README.md`](../../mobile/README.md).

## Figma / wireframes

See [`wireframe-spec.md`](wireframe-spec.md).
