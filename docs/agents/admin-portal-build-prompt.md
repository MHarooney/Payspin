# Payspin Ops Admin Portal — full build prompt (backend + frontend)

> **Purpose:** One prompt file to instruct an AI agent to scaffold, implement, wire, and test a **Payspin-branded operations admin portal** — functionally equivalent to the TikiTak Ops Portal HTML mockup, but integrated with the real Payspin stack (Postgres, Yapily, NestJS patterns, dark brand).

---

## ⬇️ COPY THIS — paste entire block into a new Agent chat

```
@docs/agents/admin-portal-build-prompt.md
@AGENTS.md
@docs/agents/architecture.md
@docs/agents/conventions.md
@backend/prisma/schema.prisma
@resources/Payspin Design System/README.md
@CLAUDE.md
@.cursor/skills/payspin/SKILL.md
@/Users/mahmoudalharoon/Downloads/tikitak-admin-portal (1).html

You are building the Payspin Ops Admin Portal — a separate internal ops app (backend + frontend) matching the attached TikiTak HTML mockup in layout and features, but with Payspin branding and real Payspin data.

Do NOT touch legacy Payspin-portal/ (Firebase CMS). Do NOT commit unless I ask.

Run this workflow end-to-end in ONE session — plan, build, test, report. Do not stop after planning. Do not ask permission between steps unless blocked.

── STEP 1 · PLAN ──
Write docs/agents/admin-portal-master-plan.md covering:
- ops-portal/backend + ops-portal/frontend folder layout
- pnpm workspace entries, ports (API :3002, UI :3003)
- Prisma additions (AdminUser, AdminAuditEvent, FeatureFlag, PlatformConfig, etc.)
- Every mockup nav item → route → API endpoint → data source
- Auth (admin JWT, roles), audit trail, kill switch
- Phase 1 (real data) vs Phase 2 (typed stubs + seed)
Show me a short plan summary, then immediately continue to Step 2.

── STEP 2 · SCAFFOLD ──
Create ops-portal/ at repo root:
- ops-portal/backend/ — NestJS 11, clean architecture (controllers → use cases → Prisma/PIS_GATEWAY)
- ops-portal/frontend/ — Next.js 15 App Router, Tailwind, dark Payspin ops theme
Add ops-portal/* to pnpm-workspace.yaml. Reuse @payspin/shared-types and @payspin/validators.
Create .env.example files, README, seed-admin script.

── STEP 3 · IMPLEMENT ──
Match ALL 13 mockup sections with Payspin branding (pink #FC00FF + teal #07D8DD on dark #0B0B12 — NOT TikiTak green):

Overview:     Dashboard, Reports
Operations:   Transactions, Circles/ROSCA, Users/KYC, Compliance, Disputes, Reconciliation, Messages
Platform:     System Health, App Controls, Config & Flags, Audit Log

Global chrome: sidebar, topbar, global search, health pill, kill-switch modal (reason + audit).

Phase 1 (must work with real Postgres data): auth, dashboard KPIs + charts, transactions, users, circles, system health, config/flags, kill switch, audit log.

Phase 2 (UI complete, backend stubbed + seed where needed): reports (all chart sections), compliance, disputes, reconciliation, messages, app controls.

Backend rules: business logic in application/use-cases/, Zod in validators, Yapily only via PIS_GATEWAY, shared backend/prisma/schema.prisma (migrations from backend/).

Frontend rules: reusable OpsShell, OpsSidebar, OpsTopbar, OpsKpiStrip, OpsDataTable, OpsChart, OpsPill, OpsModal components. TanStack Query for data.

── STEP 4 · INTEGRATE ──
Wire ops backend to same Postgres/Redis as main stack. Ensure admin mutations write AdminAuditEvent. Document local run in ops-portal/README.md.

── STEP 5 · TEST ──
Run ALL of these; fix failures before finishing:
A0  pnpm install (root)
A1  prisma generate + migrate (backend/)
A2  ops-portal/backend unit tests + lint
A3  ops-portal/frontend lint + build
A4  seed admin user → login works
A5  curl/smoke dashboard + auth guard (401 without token)
A6  kill switch → audit row created
A7  browser: open :3003, click every sidebar link — no crashes
A8  charts render on Dashboard + Reports without console errors

Start infra if needed: ./scripts/dev/payspin-dev doctor && ./scripts/dev/payspin-dev start

── STEP 6 · REPORT ──
Final summary: what shipped, env vars, how to run (copy-paste commands), login credentials, Phase 2 gaps, screenshot checklist.

Definition of done: ops-portal/ exists, admin can log in and see real payment/user/circle data, audit log works, all tests pass, README is complete.
```

---

## Which prompt to use

| Goal | What to paste in chat |
|------|------------------------|
| **Build the full admin portal** (plan → scaffold → implement → test → report) | **Master block below** ⬇️ |
| UI reference (layout, sections, interactions) | Attach `@/Users/mahmoudalharoon/Downloads/tikitak-admin-portal (1).html` or copy into `resources/docs/tikitak-admin-portal-reference.html` |
| Repo architecture / ports / conventions | `@AGENTS.md` `@docs/agents/architecture.md` `@docs/agents/conventions.md` |
| Payspin brand tokens & voice | `@resources/Payspin Design System/README.md` `@CLAUDE.md` |
| Existing data model | `@backend/prisma/schema.prisma` |
| End-to-end dev workflows | `@.cursor/skills/payspin/SKILL.md` |

### Master block — copy-paste this entire message

```
@docs/agents/admin-portal-build-prompt.md
@AGENTS.md
@docs/agents/architecture.md
@docs/agents/conventions.md
@backend/prisma/schema.prisma
@resources/Payspin Design System/README.md
@/Users/mahmoudalharoon/Downloads/tikitak-admin-portal (1).html

Execute the Payspin Ops Admin Portal build workflow end-to-end:

1. PLAN — Write docs/agents/admin-portal-master-plan.md: folder layout, API surface,
   Prisma extensions, screen map (mockup → routes), auth model, ports, risks, phased
   delivery (MVP vs Phase 2 stubs). Show me the plan summary, then continue unless blocked.

2. SCAFFOLD — Create ops-portal/ as a separate project:
   - ops-portal/backend/  (NestJS 11, clean architecture, same patterns as backend/)
   - ops-portal/frontend/ (Next.js 15 App Router, dark Payspin ops theme)
   Add ops-portal/* to pnpm-workspace.yaml; reuse packages/shared-types and packages/validators.

3. IMPLEMENT — Match every section in the TikiTak mockup with Payspin branding and real
   data where models exist; stub Phase 2 modules with typed placeholders + seed data.
   Wire admin auth, audit log, kill switch, feature flags, and all CRUD/list endpoints.

4. INTEGRATE — Read the same Postgres as backend/ (shared schema). Do NOT duplicate
   payment business logic in controllers; use use cases. Yapily only via PIS_GATEWAY.

5. TEST — Run the full test matrix (A0–A12). Fix failures before reporting done.
   Start local stack, seed admin user, smoke every nav item in browser.

6. REPORT — Final summary: what shipped, how to run locally, env vars, known gaps,
   screenshot checklist. Do not git commit unless I ask.
```

### Optional attachments

| Attachment | When |
|------------|------|
| `@.cursor/skills/payspin/SKILL.md` | Local dev, Docker, API smoke |
| `@docs/agents/circles-monerium-research.md` | Circles / ROSCA admin actions |
| `@resources/docs/yapily-console-setup.md` | Yapily reconciliation fields |
| `@infrastructure/hetzner/README.md` | System health / deploy notes |

---

## Product definition

**Payspin Ops Portal** — internal web app for operators to monitor payments, circles, users, compliance alerts, reconciliation, support messages, system health, remote app config, and platform kill switch.

**Not in scope for v1:** Replacing Grafana/Prometheus; rebuilding the old Firebase `Payspin-portal/` CMS (posts, offers, blog). The new portal is **ops/fintech**, not content management.

**Brand:** Payspin dark prototype adapted for dense ops UI.

| Token | Value | Usage |
|-------|-------|-------|
| `--bg` | `#0B0B12` | Page background |
| `--panel` | `#15141F` | Sidebar, topbar, cards |
| `--panel-2` | `#1E1D2B` | Hover, inputs, nested surfaces |
| `--border` | `#2A2838` | Dividers |
| `--text` | `#F5F5F7` | Primary text |
| `--muted` | `#8B93A7` | Labels, secondary |
| `--accent` | `#07D8DD` | Success, live, primary chart series (teal) |
| `--accent-2` | `#FC00FF` | Brand accent, active nav gradient start |
| `--gradient` | `linear-gradient(135deg, #FC00FF, #07D8DD)` | Logo dot, primary buttons, avatar |
| `--amber` | `#F5A623` | Pending / warning |
| `--red` | `#FF4D4F` | Error, kill switch, high severity |
| `--blue` | `#3B82F6` | Info, authorized state |
| `--purple` | `#6B4EC4` | Escrow / circles |

**Logo lockup:** `Payspin` + small `OPS` label (replace TikiTak). Use gradient dot or emblem — no TikiTak green (`#00d68f`).

**Tagline (footer/about only):** *"Your money, your community, and your peace of mind."*

---

## Reference mockup → Payspin screen map

Use the attached HTML as **layout and interaction reference**, not copy-paste styling. Every nav item becomes a real route.

| Mockup view | Route | MVP data source | Notes |
|-------------|-------|-----------------|-------|
| Dashboard | `/` | Aggregates on `Payment`, `User`, `PaymentLink` | KPI strip, volume chart, open alerts feed, live tx feed (poll or SSE) |
| Reports | `/reports` | Time-bucketed SQL / materialized queries | Hourly/daily/weekly/monthly tabs; Chart.js or Recharts |
| Transactions | `/transactions` | `Payment` + `PaymentLink` + payee user | Filters: status, date, Yapily ref search |
| Circles / ROSCA | `/circles` | `Circle`, `CircleMember` | KPIs, health charts, register table, detail drill-down |
| Users / KYC | `/users` | `User`, `BankAccount` | KYC columns stubbed until Monerium/KYC phase; show phone, bank verified |
| Compliance | `/compliance` | New `ComplianceAlert` model or stub | Alert queue; wire rules in Phase 2 |
| Disputes | `/disputes` | Stub + seed | Phase 2 unless dispute model exists |
| Reconciliation | `/finance` | `Payment` vs Yapily webhook state | Mismatch table, settle KPIs |
| Messages | `/messages` | New `SupportThread` / `SupportMessage` or stub | Split-pane inbox like mockup |
| System Health | `/system` | Health checks: API, Postgres, Redis, BullMQ, Yapily ping | Link out to Grafana |
| App Controls | `/app-controls` | New `RemoteConfig` JSON store | Toggles for mobile modules, banners |
| Config & Flags | `/config` | `PlatformConfig`, `FeatureFlag` tables | Limits, velocity thresholds, maintenance mode |
| Audit Log | `/audit` | Append-only `AdminAuditEvent` | Every mutating admin action |

**Global chrome (all pages):** sticky sidebar, topbar with page title, global search (tx id, user email, short code), health pill, kill-switch button → confirmation modal with reason + audit.

---

## Project layout (mandatory)

Create **`ops-portal/`** at repo root — separate from `frontend/` (payer web) and `backend/` (consumer API), but in the same monorepo.

```
ops-portal/
├── backend/
│   └── src/
│       ├── application/use-cases/     # Admin business logic
│       ├── domain/                    # Admin-specific helpers
│       ├── infrastructure/            # Prisma (shared schema), Redis, Yapily module import
│       └── interfaces/http/           # /admin/v1 controllers, guards
├── frontend/
│   └── app/                           # Next.js 15 App Router
│       ├── (auth)/login/
│       └── (dashboard)/               # Layout with sidebar + topbar
│           ├── page.tsx               # Dashboard
│           ├── reports/
│           ├── transactions/
│           └── …
├── README.md                          # How to run, env, default admin seed
└── docker-compose.override.yml        # Optional: ops API on :3002, UI on :3003
```

### pnpm workspace

Add to root `pnpm-workspace.yaml`:

```yaml
packages:
  - "backend"
  - "frontend"
  - "ops-portal/backend"
  - "ops-portal/frontend"
  - "packages/*"
```

### Ports (do not collide with consumer stack)

| Service | URL |
|---------|-----|
| Consumer API | http://localhost:3001/v1 |
| Payer web | http://localhost:3000 |
| **Ops API** | http://localhost:3002/admin/v1 |
| **Ops portal UI** | http://localhost:3003 |
| Postgres | localhost:5435 (shared) |
| Redis | localhost:6381 (shared) |

### Shared packages

- **`@payspin/shared-types`** — admin DTOs (`AdminPaymentListItem`, `DashboardKpis`, etc.)
- **`@payspin/validators`** — Zod for admin inputs (config updates, kill switch reason, user actions)
- **`@payspin/pisp-provider`** — inject `PIS_GATEWAY` for reconciliation / Yapily status checks

### Prisma strategy

**Preferred:** Ops backend uses the **same** `backend/prisma/schema.prisma` via workspace path or symlink — single migration source. Add admin-only models there:

```prisma
model AdminUser { … }
model AdminAuditEvent { … }
model FeatureFlag { … }
model PlatformConfig { … }
model ComplianceAlert { … }  // optional Phase 2
model SupportThread { … }    // optional Phase 2
```

Run migrations from `backend/` as today. Ops backend imports `PrismaClient` from generated client.

**Forbidden:** A second divergent schema; business logic in controllers; direct Yapily HTTP from use cases.

---

## Backend architecture (non-negotiable)

Mirror `docs/agents/architecture.md`:

```
HTTP Controller → Use Case → PrismaService / PIS_GATEWAY
                      ↓
                 Zod (validators) + mappers → shared-types DTOs
```

### Auth

- **Admin JWT** (separate from consumer Firebase phone auth): email + password or magic link for `AdminUser` rows only.
- Roles: `SUPER_ADMIN`, `OPS`, `SUPPORT`, `READ_ONLY`.
- Guards on all `/admin/v1/*` except `POST /admin/v1/auth/login`.
- Session: short-lived access token + httpOnly refresh cookie.
- **2FA hook** for kill switch (stub TOTP verification if full 2FA not implemented — document gap).

### Key use cases (minimum)

| Use case | Description |
|----------|-------------|
| `AdminLoginUseCase` | Authenticate admin, issue tokens |
| `GetDashboardKpisUseCase` | Period-scoped aggregates |
| `ListPaymentsAdminUseCase` | Paginated, filterable payment list |
| `GetPaymentDetailAdminUseCase` | Full payment + link + webhook snapshot |
| `RetryPaymentAdminUseCase` | Re-queue stuck payment (audit logged) |
| `ListUsersAdminUseCase` | Search users, bank verification status |
| `SuspendUserAdminUseCase` | Flag user (extend User model or side table) |
| `ListCirclesAdminUseCase` | Circle register with status filters |
| `GetCircleDetailAdminUseCase` | Members, payout order, contract address |
| `ListReconciliationExceptionsUseCase` | Ledger vs Yapily mismatches |
| `GetSystemHealthUseCase` | Ping DB, Redis, queue depth, Yapily |
| `GetFeatureFlagsUseCase` / `UpdateFeatureFlagsUseCase` | CRUD + audit |
| `GetPlatformConfigUseCase` / `UpdatePlatformConfigUseCase` | Limits, thresholds |
| `ActivateKillSwitchUseCase` | Set flag, reason required, audit, optional 2FA |
| `ListAuditEventsUseCase` | Immutable admin action log |
| `GlobalSearchUseCase` | tx id, user email, payment link short code |

### Audit trail

Every mutating admin action writes `AdminAuditEvent`:

```
{ id, adminUserId, action, targetType, targetId, before, after, ip, userAgent, createdAt }
```

Actions enum examples: `KYC_APPROVE`, `USER_FREEZE`, `TX_RETRY`, `CONFIG_UPDATE`, `FLAG_TOGGLE`, `KILL_SWITCH_ON`.

---

## Frontend architecture

### Stack

- **Next.js 15** App Router, TypeScript strict
- **Tailwind CSS** with CSS variables matching brand tokens above
- **Recharts** or **Chart.js** (match mockup chart types: bar, line, doughnut, stacked bar)
- **TanStack Query** for server state
- **Zod** + react-hook-form for modals (kill switch, config edits)

### Layout components (reusable)

```
OpsShell          — sidebar + main column
OpsSidebar        — nav sections, badges, admin foot
OpsTopbar         — title, search, health pill, kill switch
OpsKpiStrip       — 4–5 KPI cards
OpsDataTable      — sortable table with filters, row actions
OpsCard           — panel wrapper
OpsPill           — status badges (ok/pend/fail/blue/purple)
OpsSegment        — period toggles (today/week/month)
OpsModal          — kill switch, confirm destructive actions
OpsChart          — themed chart wrapper (dark grid lines)
OpsMessageLayout  — split-pane support inbox
```

### UX rules

- Dark theme only for v1 (ops density > consumer polish)
- Sidebar nav mirrors mockup sections exactly
- Lazy-load charts when view becomes active (performance)
- Loading skeletons on tables and KPIs
- Empty states with actionable copy
- Responsive: collapse sidebar on `<1024px`; tables horizontal scroll
- No emoji in UI copy (Payspin voice)
- Primary CTA buttons use pink→teal gradient; destructive = red

### API client

`ops-portal/frontend/lib/admin-api.ts` → `NEXT_PUBLIC_OPS_API_URL` default `http://localhost:3002/admin/v1`

Attach `Authorization: Bearer` from auth context. Handle 401 → redirect `/login`.

---

## Phase delivery

### Phase 1 — MVP (must ship in first agent session)

- [ ] Scaffold ops-portal backend + frontend + workspace entries
- [ ] Admin auth + seed script (`pnpm ops:seed-admin` or documented curl)
- [ ] Dashboard with real KPIs and volume chart
- [ ] Transactions list + detail drawer
- [ ] Users list (real User/BankAccount data)
- [ ] Circles list + detail (real Circle data)
- [ ] System health page (live checks)
- [ ] Config & feature flags (persisted + audit)
- [ ] Kill switch modal (functional flag + audit)
- [ ] Audit log (records all Phase 1 mutations)
- [ ] README with run instructions

### Phase 2 — stubs with seed data (UI complete, backend typed placeholders)

- [ ] Reports (all 7 chart sections — can use seeded aggregates initially)
- [ ] Compliance alert queue
- [ ] Disputes
- [ ] Reconciliation exceptions (real logic when Yapily sync exists)
- [ ] Messages / support inbox
- [ ] App controls (remote config for mobile)

Mark Phase 2 pages with a subtle `Preview` badge until backend is live.

---

## Environment variables

### ops-portal/backend/.env.example

```env
DATABASE_URL=postgresql://payspin:payspin@localhost:5435/payspin
REDIS_URL=redis://localhost:6381
ADMIN_JWT_SECRET=change-me-in-production
ADMIN_JWT_EXPIRES_IN=15m
ADMIN_REFRESH_SECRET=change-me-in-production
OPS_CORS_ORIGIN=http://localhost:3003
# Reuse from main backend:
YAPILY_APPLICATION_ID=
YAPILY_APPLICATION_SECRET=
YAPILY_WEBHOOK_SECRET=
PIS_GATEWAY=yapily
```

### ops-portal/frontend/.env.example

```env
NEXT_PUBLIC_OPS_API_URL=http://localhost:3002/admin/v1
```

---

## Test matrix (mandatory — agent must run all)

| ID | Test | Command / action | Pass criteria |
|----|------|------------------|---------------|
| A0 | Monorepo install | `pnpm install` from root | No dependency errors |
| A1 | Prisma generate | `cd backend && pnpm prisma generate` | Client builds with new admin models |
| A2 | Migrations | `cd backend && pnpm prisma migrate dev` | Admin tables created |
| A3 | Ops backend unit tests | `cd ops-portal/backend && pnpm test` | All pass |
| A4 | Ops backend lint | `cd ops-portal/backend && pnpm lint` | No errors |
| A5 | Ops frontend lint | `cd ops-portal/frontend && pnpm lint` | No errors |
| A6 | Ops frontend build | `cd ops-portal/frontend && pnpm build` | Production build succeeds |
| A7 | Seed admin | Run seed script | Can login with documented credentials |
| A8 | API smoke | curl login + dashboard KPIs | 200 + valid JSON |
| A9 | Auth guard | curl protected route without token | 401 |
| A10 | Kill switch | POST with reason → audit row created | Flag on + audit entry |
| A11 | Browser nav | Open :3003, click every sidebar item | Each route renders without crash |
| A12 | Chart render | Reports + Dashboard | Charts mount, no console errors |

### Local run (document in ops-portal/README.md)

```bash
# Terminal 1 — infra
./scripts/dev/payspin-dev start

# Terminal 2 — consumer API (optional, for shared DB writes)
cd backend && pnpm start:dev

# Terminal 3 — ops API
cd ops-portal/backend && pnpm start:dev

# Terminal 4 — ops UI
cd ops-portal/frontend && pnpm dev
```

---

## Master plan template (required PLAN output)

Agent must write `docs/agents/admin-portal-master-plan.md` with:

1. **Executive summary** — scope, ports, timeline
2. **Screen inventory** — mockup section → route → components → API endpoints
3. **Prisma delta** — new models + fields on existing models
4. **API catalog** — `METHOD /admin/v1/...` table
5. **Auth & roles matrix** — which roles can kill switch, edit config, etc.
6. **Component library list** — shared frontend components
7. **Phase 1 vs Phase 2** — checkbox delivery list
8. **Risk register** — shared DB migrations, Yapily sandbox, CORS
9. **File checklist** — every new file path
10. **Test plan** — mapping to A0–A12

---

## Constraints (agent must obey)

1. **Minimal diffs** on existing consumer `backend/` and `frontend/` — only Prisma additions and shared package types unless explicitly required.
2. **Do not expand** legacy `Payspin-portal/` (Firebase CMS).
3. **No secrets** in git — `.env.example` only.
4. **No commit** unless user asks.
5. **Clean code:** small focused use cases, typed DTOs, no `any`, no god components.
6. **Reusable architecture** — ops portal patterns should be easy to extend (new nav item = route + use case + controller + table component).
7. **Non-custodial truth** — copy and KPIs must reflect Payspin never holds funds; "Funds in flight" = in-progress bank settlements, not custodial balance.

---

## How to use this prompt (for you)

### Option A — Cursor Agent (recommended)

1. Open a **new Agent chat** in the Payspin repo (Agent mode, not Ask).
2. Copy the **Master block** from the top of this file into chat.
3. Attach the reference HTML:
   - Either drag `tikitak-admin-portal (1).html` from Downloads into chat, or
   - Copy it to `resources/docs/tikitak-admin-portal-reference.html` in the repo and `@` mention that path.
4. Send. Let the agent run through PLAN → SCAFFOLD → IMPLEMENT → TEST → REPORT without stopping.
5. Review `docs/agents/admin-portal-master-plan.md` when the plan step completes.
6. When done, open http://localhost:3003 and walk every sidebar link.

### Option B — Claude Code

```bash
cd /Users/mahmoudalharoon/Desktop/Payspin
claude
```

Paste the Master block. Ensure MCP `payspin-design` is enabled if you want token parity checks.

### Option C — Phased sessions (if context limits hit)

Run three separate chats in order:

1. **Session 1:** Master block but add: *"Stop after PLAN + SCAFFOLD + auth + Dashboard only."*
2. **Session 2:** *"Continue admin portal Phase 1 per admin-portal-master-plan.md — Transactions, Users, Circles, System, Config, Audit, Kill switch."*
3. **Session 3:** *"Complete Phase 2 stubs + full test matrix A0–A12 + README."*

Always `@docs/agents/admin-portal-master-plan.md` in follow-up sessions.

### Tips for best results

- **One session is better** — the mockup has 13 views; splitting causes inconsistent tokens and API shapes.
- **Start infra first:** `./scripts/dev/payspin-dev doctor` before asking the agent to test.
- **Pin the HTML** in the repo so `@` references work on every machine.
- **Review Prisma migrations** before applying — admin models should be additive only.
- **Ask for screenshots** in the REPORT step if you want visual confirmation.

---

## Success criteria (definition of done)

You are done when:

- [ ] `ops-portal/` exists with separate backend and frontend
- [ ] UI matches mockup **structure** with Payspin **brand** (pink/teal on dark)
- [ ] Admin can log in, see real payment/user/circle data from Postgres
- [ ] Kill switch, config edits, and user actions write to audit log
- [ ] All tests A0–A12 pass
- [ ] `ops-portal/README.md` documents setup in under 5 minutes for a new developer
