# Payspin Ops Admin Portal — Master Plan

> Step 1 output for `docs/agents/admin-portal-build-prompt.md`. Living plan for the
> internal operations portal that mirrors the TikiTak Ops mockup with Payspin
> branding and real Payspin data.

## 1. Executive summary

- **What:** A separate internal web app (`ops-portal/backend` + `ops-portal/frontend`) for
  operators to monitor payments, circles, users, compliance, reconciliation, support,
  system health, app config and a platform kill switch.
- **Scope:** 13 mockup sections. Phase 1 ships on **real Postgres data**; Phase 2 ships
  **complete UI on real (seedable) models** marked with a `Preview` badge.
- **Ports:** Ops API `:3002` (`/admin/v1`), Ops UI `:3003`. Shares Postgres `:5435` and
  Redis `:6381` with the consumer stack.
- **Brand:** Payspin dark — pink `#FC00FF` + teal `#07D8DD` on `#0B0B12` / `#15141F`
  (never TikiTak green).
- **Non-custodial truth:** "Funds in flight" = in-progress bank settlements, never a
  custodial balance.

### Key engineering decisions

| Decision | Rationale |
|---|---|
| **Shared Prisma schema** (`backend/prisma/schema.prisma`) | Single migration source. Admin models added additively; existing models untouched. |
| **Admin overlay table** `UserAdminState` instead of editing `User` | Keeps consumer schema diff-free while storing KYC/risk/freeze status. |
| **Plain CSS + design tokens** (not Tailwind) | Matches existing payer web (`frontend/`), removes Tailwind build fragility, faster, theme parity with mockup. |
| **Chart.js + react-chartjs-2** (React 18.3) | Mirrors the mockup's chart types; avoids React 19 charting peer-dep issues. |
| **Self-contained ops backend** | No import of consumer `backend/` internals. Yapily health is best-effort/config-based (documented gap). |

## 2. Screen inventory

| # | Mockup view | Route | Phase | Data source | Key components |
|---|---|---|---|---|---|
| 1 | Dashboard | `/` | 1 | `Payment`, `PaymentLink`, `User` aggregates | OpsKpiStrip, OpsChart (volume), alerts feed, live tx feed |
| 2 | Reports | `/reports` | 2 | Time-bucketed SQL (seed fallback) | OpsSegment tabs, 7 OpsChart sections |
| 3 | Transactions | `/transactions` | 1 | `Payment` + `PaymentLink` + payee `User` | OpsDataTable, filters, detail drawer |
| 4 | Circles / ROSCA | `/circles` | 1 | `Circle`, `CircleMember` | KPIs, OpsChart, register table, detail drill-down |
| 5 | Users / KYC | `/users` | 1 | `User`, `BankAccount`, `UserAdminState` | OpsDataTable, KYC/freeze actions |
| 6 | Compliance | `/compliance` | 2 | `ComplianceAlert` (seed) | KPIs, alert queue table |
| 7 | Disputes | `/disputes` | 2 | `Dispute` (seed) | Case table |
| 8 | Reconciliation | `/finance` | 2 | `Payment` vs settlement state (+ seed mismatches) | KPIs, exceptions table |
| 9 | Messages | `/messages` | 2 | `SupportThread`, `SupportMessage` (seed) | OpsMessageLayout split pane |
| 10 | System Health | `/system` | 1 | Live: Postgres, Redis, queue depth; Yapily best-effort | svc tiles |
| 11 | App Controls | `/app-controls` | 2 | `FeatureFlag` (category `app`) + `PlatformConfig` (group `app`) | toggles, banner editor |
| 12 | Config & Flags | `/config` | 1 | `PlatformConfig`, `FeatureFlag` | config rows, flag toggles |
| 13 | Audit Log | `/audit` | 1 | `AdminAuditEvent` | OpsDataTable |

Global chrome on every page: sticky `OpsSidebar`, `OpsTopbar` (title, global search,
health pill, kill-switch button → `KillSwitchModal` with reason + audit).

## 3. Prisma delta (additive only — `backend/prisma/schema.prisma`)

New enums: `AdminRole`.

New models:

| Model | Purpose | Phase |
|---|---|---|
| `AdminUser` | Admin identity (email/password, role, active) | 1 |
| `AdminAuditEvent` | Append-only admin action log | 1 |
| `FeatureFlag` | Boolean flags (incl. kill switch + app modules) | 1 |
| `PlatformConfig` | Typed limits/thresholds (+ app-side defaults) | 1 |
| `UserAdminState` | Admin overlay on consumer users (KYC/risk/freeze) | 1 |
| `ComplianceAlert` | AML/risk alert queue | 2 |
| `Dispute` | Disputes & escrow cases | 2 |
| `SupportThread` / `SupportMessage` | Support inbox | 2 |

No existing model is modified → migration is purely additive.

## 4. API catalog (`/admin/v1`)

| Method | Path | Use case | Phase | Min role |
|---|---|---|---|---|
| POST | `/auth/login` | `AdminLoginUseCase` | 1 | public |
| GET | `/auth/me` | (guard) | 1 | READ_ONLY |
| GET | `/dashboard/kpis` | `GetDashboardKpisUseCase` | 1 | READ_ONLY |
| GET | `/dashboard/volume` | `GetVolumeSeriesUseCase` | 1 | READ_ONLY |
| GET | `/dashboard/alerts` | `ListOpenAlertsUseCase` | 1 | READ_ONLY |
| GET | `/transactions` | `ListPaymentsAdminUseCase` | 1 | READ_ONLY |
| GET | `/transactions/:id` | `GetPaymentDetailAdminUseCase` | 1 | READ_ONLY |
| POST | `/transactions/:id/retry` | `RetryPaymentAdminUseCase` | 1 | OPS |
| GET | `/users` | `ListUsersAdminUseCase` | 1 | READ_ONLY |
| POST | `/users/:id/state` | `SetUserAdminStateUseCase` | 1 | OPS |
| GET | `/circles` | `ListCirclesAdminUseCase` | 1 | READ_ONLY |
| GET | `/circles/:id` | `GetCircleDetailAdminUseCase` | 1 | READ_ONLY |
| GET | `/system/health` | `GetSystemHealthUseCase` | 1 | READ_ONLY |
| GET | `/config/flags` | `GetFeatureFlagsUseCase` | 1 | READ_ONLY |
| PATCH | `/config/flags/:key` | `UpdateFeatureFlagUseCase` | 1 | OPS |
| GET | `/config/platform` | `GetPlatformConfigUseCase` | 1 | READ_ONLY |
| PATCH | `/config/platform/:key` | `UpdatePlatformConfigUseCase` | 1 | OPS |
| GET | `/kill-switch` | `GetKillSwitchStateUseCase` | 1 | READ_ONLY |
| POST | `/kill-switch` | `ActivateKillSwitchUseCase` | 1 | SUPER_ADMIN |
| GET | `/audit` | `ListAuditEventsUseCase` | 1 | READ_ONLY |
| GET | `/search` | `GlobalSearchUseCase` | 1 | READ_ONLY |
| GET | `/reports` | `GetReportSeriesUseCase` | 2 | READ_ONLY |
| GET | `/compliance` | `ListComplianceAlertsUseCase` | 2 | READ_ONLY |
| GET | `/disputes` | `ListDisputesUseCase` | 2 | READ_ONLY |
| GET | `/finance/exceptions` | `ListReconciliationExceptionsUseCase` | 2 | READ_ONLY |
| GET | `/messages` | `ListSupportThreadsUseCase` | 2 | SUPPORT |
| GET | `/messages/:id` | `GetSupportThreadUseCase` | 2 | SUPPORT |
| GET | `/app-controls` | `GetAppControlsUseCase` | 2 | READ_ONLY |

## 5. Auth & roles matrix

Admin JWT (separate from consumer Firebase phone auth). Email + password against
`AdminUser` rows only. Short-lived access token (`ADMIN_JWT_EXPIRES_IN`, default 15m).
`RolesGuard` enforces minimums.

| Capability | SUPER_ADMIN | OPS | SUPPORT | READ_ONLY |
|---|:---:|:---:|:---:|:---:|
| View all dashboards/lists | ✓ | ✓ | ✓ | ✓ |
| Retry tx / user state / config / flags | ✓ | ✓ | — | — |
| Support inbox | ✓ | ✓ | ✓ | — |
| Kill switch | ✓ | — | — | — |

**2FA hook:** kill switch accepts an optional TOTP code; verification is stubbed and
documented as a gap until full 2FA is implemented.

## 6. Component library (frontend)

`OpsShell`, `OpsSidebar`, `OpsTopbar`, `OpsKpiStrip`, `OpsKpiCard`, `OpsCard`,
`OpsDataTable`, `OpsPill`, `OpsSegment`, `OpsModal`, `KillSwitchModal`, `OpsChart`
(BarChart/LineChart/DoughnutChart wrappers), `OpsMessageLayout`, `OpsToggle`,
`OpsEmptyState`, `OpsSkeleton`, `OpsPreviewBadge`.

State: `@tanstack/react-query`. Forms: `react-hook-form` + `zod`. Auth: React context +
`localStorage` token, 401 → `/login`.

## 7. Phase 1 vs Phase 2

**Phase 1 (real data):** auth + seed, dashboard KPIs + volume chart, transactions
list/detail/retry, users list + state actions, circles list/detail, system health,
config + feature flags (persisted + audit), kill switch (flag + audit), audit log,
global search, README.

**Phase 2 (complete UI, real seedable models, `Preview` badge):** reports (7 charts),
compliance queue, disputes, reconciliation exceptions, support inbox, app controls.

## 8. Risk register

| Risk | Mitigation |
|---|---|
| Shared DB migration breaks consumer app | Additive-only models/enums; no edits to existing tables. Review migration before deploy. |
| Yapily sandbox creds absent in ops | System health reports Yapily as config-based best-effort; reconciliation is Phase 2 + seed. |
| CORS between :3003 and :3002 | `OPS_CORS_ORIGIN` env, credentials enabled. |
| Chart lib SSR | Charts are client components, dynamically rendered. |
| Lint/build flakiness | Self-contained eslint flat configs; plain CSS (no Tailwind). |
| Secret leakage | `.env.example` only; real `.env` git-ignored. |

## 9. File checklist

```
backend/prisma/schema.prisma                      (+admin models)
backend/prisma/seed-admin.ts                       (admin + Phase 2 seed)
packages/shared-types/src/admin.ts                 (admin DTOs) + index re-export
packages/validators/src/admin.ts                   (admin Zod) + index re-export
pnpm-workspace.yaml                                 (+ ops-portal/*)

ops-portal/backend/                                 (NestJS 11)
  package.json tsconfig.json nest-cli.json eslint.config.mjs .env.example
  src/main.ts app.module.ts
  src/infrastructure/persistence/prisma.module.ts
  src/infrastructure/redis/redis.module.ts
  src/infrastructure/audit/{audit.service.ts,audit.module.ts}
  src/interfaces/http/guards/{admin-jwt.strategy.ts,jwt-auth.guard.ts,roles.guard.ts,roles.decorator.ts}
  src/interfaces/http/decorators/current-admin.decorator.ts
  src/interfaces/http/filters/all-exceptions.filter.ts
  src/application/use-cases/<feature>/*.use-case.ts (+ mappers)
  src/interfaces/http/<feature>/{*.controller.ts,*.module.ts}
  src/interfaces/http/ops-http.module.ts

ops-portal/frontend/                                (Next.js 15, plain CSS)
  package.json tsconfig.json next.config.js .eslintrc.json .env.example
  app/{layout.tsx,globals.css,providers.tsx}
  app/(auth)/login/page.tsx
  app/(dashboard)/layout.tsx + all 13 route folders
  components/ops/* (component library)
  lib/{admin-api.ts,auth.tsx,format.ts,theme.ts}

ops-portal/README.md
docs/agents/admin-portal-master-plan.md             (this file)
```

## 10. Test plan (A0–A12)

| ID | Test | Command |
|---|---|---|
| A0 | Monorepo install | `pnpm install` |
| A1 | Prisma generate | `cd backend && pnpm prisma generate` |
| A2 | Migrations | `cd backend && pnpm prisma migrate dev` |
| A3 | Ops backend tests | `pnpm --filter @payspin/ops-backend test` |
| A4 | Ops backend lint/typecheck | `pnpm --filter @payspin/ops-backend typecheck` |
| A5 | Ops frontend lint | `pnpm --filter @payspin/ops-frontend lint` |
| A6 | Ops frontend build | `pnpm --filter @payspin/ops-frontend build` |
| A7 | Seed admin | `cd backend && pnpm ops:seed-admin` |
| A8 | API smoke | curl login + dashboard KPIs |
| A9 | Auth guard | curl protected route → 401 |
| A10 | Kill switch | POST with reason → audit row |
| A11 | Browser nav | open :3003, click every nav item |
| A12 | Chart render | dashboard + reports charts mount |
