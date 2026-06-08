# Payspin Ops Portal — Data Explorer, Users 360°, and UI polish

> **Purpose:** Agent prompt to add **database schema explorer**, **table/data browser**, a **professional Users 360° experience**, and a **modern UI polish pass** to the existing ops portal (`ops-portal/`). The agent should act as a senior product engineer + designer — propose improvements, then implement.

---

## How to use this prompt

### Option A — Cursor Agent (recommended)

1. Open a **new Agent chat** on branch `main` or `dev`.
2. Paste the **COPY BLOCK** below (from `You are a senior…` through `Definition of done`).
3. Attach context with `@` files listed in the block (or rely on the paths in the block — Cursor will load them).
4. Say: **“Execute end-to-end. Do not stop after planning.”**
5. Review the plan summary, then let the agent run through build + local smoke test.
6. When satisfied: `./ops-portal/scripts/cloud-smoke-test.sh` and manual browser check on `:3003`.

### Option B — Claude Code

```bash
cd /path/to/Payspin
claude
# Paste COPY BLOCK + attach backend/prisma/schema.prisma, ops-portal/frontend/app/globals.css
```

### Option C — Plan first, implement later

Ask the agent: **“Run STEP 1 only from @docs/agents/ops-portal-data-explorer-prompt.md and write the plan to docs/agents/ops-data-explorer-plan.md”** — then start a fresh chat for implementation.

### After implementation

| Check | Command |
|-------|---------|
| Ops API tests | `pnpm --filter @payspin/ops-backend test` |
| Ops UI build | `pnpm --filter @payspin/ops-frontend build` |
| Cloud smoke (prod) | `./ops-portal/scripts/cloud-smoke-test.sh` |
| Deploy ops only | `PAYSPIN_SERVER_IP=… ./infrastructure/hetzner/deploy-ops.sh` |

**Do not commit** unless the user asks.

---

## ⬇️ COPY BLOCK — paste into Agent chat

```
@docs/agents/ops-portal-data-explorer-prompt.md
@AGENTS.md
@docs/agents/architecture.md
@docs/agents/conventions.md
@docs/agents/admin-portal-master-plan.md
@backend/prisma/schema.prisma
@ops-portal/README.md
@ops-portal/frontend/app/globals.css
@ops-portal/frontend/lib/nav.ts
@ops-portal/frontend/components/ops/primitives.tsx
@ops-portal/frontend/app/(dashboard)/users/page.tsx
@packages/shared-types/src/admin.ts
@packages/validators/src/admin.ts
@resources/Payspin Design System/README.md
@CLAUDE.md
@.cursor/skills/payspin/SKILL.md

You are a senior staff engineer + product designer implementing the next phase of the Payspin Ops Admin Portal (ops-portal/). The portal already ships 13 routes, JWT auth, real Postgres data, and production deploy at https://ops.payspin.io.

Your mission: help operators **understand the database**, **inspect real table data safely**, **manage users professionally**, and **elevate the entire UI** to feel modern, beautiful, and effortless — without breaking existing features.

Act with autonomy: propose sensible UX improvements beyond this spec where they clearly help ops users. Document your suggestions in the final report.

Do NOT touch Payspin-portal/ (local gitignored legacy). Do NOT modify consumer backend/ business logic unless required for shared Prisma types. Do NOT commit unless I ask.

── STEP 1 · PLAN (then continue immediately — do not wait) ──
Write docs/agents/ops-data-explorer-plan.md with:
- New routes + nav placement (suggest a "Data" or "Developer" section in sidebar)
- API endpoints (read-only data explorer + enhanced users)
- DTOs in @payspin/shared-types, Zod in @payspin/validators
- Security: role gates, field redaction list, rate limits
- UI wireframe notes (ASCII or bullet layout per page)
- Design polish scope (tokens, components to refactor)
- Phase 1 (must ship) vs nice-to-have
Show a 10-line summary, then proceed to Step 2.

── STEP 2 · BACKEND (ops-portal/backend) ──
Add a new feature module `data/` (or `explorer/`) following existing patterns:
controllers → use cases → PrismaService.

Required endpoints (prefix /admin/v1):

1) GET /data/schema
   - Return structured metadata for ALL Prisma models in backend/prisma/schema.prisma
   - Per model: name, db table name (@map), fields (name, type, optional, relation target)
   - Per relation: from → to, cardinality (1:1, 1:n, n:1)
   - Include a `mermaidErDiagram` string the frontend can render (or nodes/edges JSON for a custom graph)
   - READ ONLY. Roles: SUPER_ADMIN, OPS, READ_ONLY

2) GET /data/tables
   - List explorable tables with row counts (cached 60s ok)
   - Group: "Consumer" (User, Payment, …) vs "Ops" (AdminUser, FeatureFlag, …)
   - Never expose internal Prisma migration tables

3) GET /data/tables/:tableKey/rows?page=&pageSize=&search=
   - Paginated row preview for whitelisted tables only (allowlist — do not accept arbitrary table names)
   - Redact/mask sensitive columns ALWAYS:
     passwordHash, ibanEncrypted, ibanIv, yapilyConsentToken, paymentRequestSnapshot, webhookRaw, JWT secrets
   - Show `***REDACTED***` + optional last4 where applicable (ibanLast4 ok)
   - Max pageSize 50. Roles: SUPER_ADMIN, OPS only (not READ_ONLY for raw rows)

4) GET /users/:id  (enhance users module)
   - User 360° detail: profile, UserAdminState, stats (payment count, link count, lifetime volume)
   - Related lists (paginated, capped): recent payments, payment links, bank accounts (masked), circles, notifications count
   - Link to existing POST /users/:id/state for KYC/freeze actions

Implement allowlist in code (single source of truth), e.g.:
users, payments, payment_links, bank_accounts, circles, circle_members, admin_users, admin_audit_events, feature_flags, platform_config, user_admin_states, compliance_alerts, disputes, support_threads

Log every /data/tables/:key/rows access to AdminAuditEvent (action: DATA_TABLE_VIEW).

── STEP 3 · FRONTEND (ops-portal/frontend) ──
Add pages under app/(dashboard)/:

A) /data/schema — "Schema & Relations"
   - Split layout: left = searchable model list, right = detail panel
   - Show fields table (name, type, nullable, relation)
   - Interactive ER diagram (Mermaid via dynamic import OR SVG graph — your choice; must work in dark + light theme)
   - Click a model → highlight its relations
   - Empty/loading states with PayspinEmblemLoader

B) /data/tables — "Table Explorer"
   - Grid of table cards: name, row count, consumer/ops badge
   - Click → /data/tables/[tableKey] or slide-over panel
   - Row viewer: sticky header, monospace IDs, column type hints, pagination, optional column search
   - Banner: "Sensitive fields are redacted. Read-only preview."
   - Copy cell value (id, shortCode) on click

C) /users/[id] — "User 360°" (upgrade list page too)
   - List page (/users): add row click → detail; avatar/initials; better filters; summary chips (verified KYC, frozen count)
   - Detail page: hero header (name, email, status pills, risk, member since)
   - Tabs: Overview | Payments | Links | Bank | Circles | Admin notes | Audit
   - Inline actions (Approve KYC, Freeze) with modal + reason (replace window.prompt)
   - Timeline of recent activity (payments + admin events)

D) Global UI polish (apply across existing pages — minimal diffs per file, consistent system)
   - Typography: clear hierarchy (page title, section, label, hint)
   - Spacing rhythm: 8px grid; more breathing room in cards
   - Inputs/selects: focus rings using --accent; consistent height 36px
   - Tables: zebra optional, row hover, sticky thead
   - Sidebar: active state with gradient left border; section labels softer
   - Topbar: refine search dropdown; health pill tooltip with service breakdown
   - Motion: 150–200ms transitions; respect prefers-reduced-motion
   - Keep Payspin tokens: #FC00FF + #07D8DD on dark #0B0B12 (see globals.css + design system)
   - Do NOT switch to white wireframe or Tikkie green

Reuse/extend: OpsCard, OpsDataTable, OpsPill, OpsSectionHead, OpsSegment, emblem loader.
Add only components that earn their keep (e.g. OpsTabs, OpsDrawer, OpsFieldGrid, OpsErDiagram).

── STEP 4 · SHARED PACKAGES ──
Add types + Zod schemas to packages/shared-types and packages/validators:
- SchemaMetadata, TableSummary, TableRowsPreview, UserDetailAdmin, etc.
Export from package index files.

── STEP 5 · NAV & AUTH ──
Update ops-portal/frontend/lib/nav.ts:
- New section e.g. "Data" with Schema + Tables (icons: ◫ and ⊞)
Update titleForPath for /data/* and /users/[id].

── STEP 6 · TEST ──
Run and fix:
B1  pnpm --filter @payspin/ops-backend test && lint
B2  pnpm --filter @payspin/ops-frontend lint && build
B3  Local: login → /data/schema loads ER diagram
B4  Local: /data/tables → users rows, confirm password_hash never in JSON
B5  Local: /users → click user → detail tabs load
B6  curl: GET /admin/v1/data/schema with JWT returns models
B7  curl: GET /admin/v1/data/tables/payments/rows?pageSize=5 redacts sensitive fields
B8  READ_ONLY role cannot access row preview (403)
B9  Extend ops-portal/scripts/cloud-smoke-test.sh with data explorer smoke checks (optional but preferred)

Start infra if needed:
./scripts/dev/payspin-dev doctor && ./scripts/dev/payspin-dev start
pnpm --filter @payspin/ops-backend dev   # :3002
pnpm --filter @payspin/ops-frontend dev    # :3003

── STEP 7 · REPORT ──
Final summary:
- Routes + screenshots checklist
- Security redaction list
- Your extra UX suggestions implemented vs deferred
- How to use the new pages
- Any follow-up for production (deploy-ops.sh)

Definition of done:
- Operators can see schema/relations and browse allowlisted tables with redacted data
- Users list + detail feel professional (no window.prompt)
- UI polish is visibly improved on dashboard + at least 2 other pages
- All tests/build pass; no secrets in responses
```

---

## Context for the human (you)

### Why these pages?

| Need | Page | Value |
|------|------|-------|
| “What tables exist? How do they connect?” | **Schema & Relations** | Onboard new ops/dev staff without opening Prisma Studio |
| “What’s actually in the DB?” | **Table Explorer** | Debug production issues, verify seed/migration data |
| “Who is this user? What did they do?” | **Users 360°** | KYC, support, fraud — one place instead of scattered list |

### Models in Postgres today (19)

**Consumer:** User, DeviceToken, Notification, BankAccount, BankConnection, PaymentLink, Payment, WebhookEvent, Circle, CircleMember

**Ops:** AdminUser, AdminAuditEvent, FeatureFlag, PlatformConfig, UserAdminState, ComplianceAlert, Dispute, SupportThread, SupportMessage

Source of truth: `backend/prisma/schema.prisma`

### Security non-negotiables

- Table explorer is **read-only** — no UPDATE/DELETE from UI
- **Allowlist** tables — never dynamic SQL from user input
- **Redact** secrets and PII blobs (see list in COPY BLOCK)
- **Audit** table row views
- **READ_ONLY** admin role: schema yes, raw rows no

### Design direction

Reference: `resources/Payspin Design System/README.md`, `ops-portal/frontend/app/globals.css`, hosted prototype in `CLAUDE.md`.

Aim for: **Stripe Dashboard meets Linear** — dense but calm, dark-first, pink/teal accents used sparingly for emphasis (CTAs, active nav, charts).

### Suggested agent extras (optional — agent may implement)

- Command palette (`⌘K`) jumping to tables/users
- “Copy SQL” read-only hint per table (SELECT with LIMIT — no write)
- Schema diff badge when migration pending (compare migration folder mtime)
- User detail: “Open in Table Explorer” deep link
- Export current table page to CSV (redacted columns only)

---

## Related docs

| Doc | Purpose |
|-----|---------|
| [admin-portal-master-plan.md](admin-portal-master-plan.md) | Original ops portal scope |
| [admin-portal-build-prompt.md](admin-portal-build-prompt.md) | Initial build prompt (already shipped) |
| [ui-ux-brand-enhancement-prompt.md](ui-ux-brand-enhancement-prompt.md) | Brand tokens (mobile/web — reuse principles) |
| [../ops-portal/README.md](../../ops-portal/README.md) | Run locally + deploy ops |
