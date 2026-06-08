# Payspin Ops Portal — Pre-prod focus (single-shot agent prompt)

> **Purpose:** One copy-paste prompt for a Cursor Agent to **implement, test locally, and verify** the ops portal control room — full **CRUD**, **user lifecycle & presence**, webhooks, payment links, flags enforcement, and edge-case coverage — in one session.
>
> **Local only:** No cloud deploy. No git commit. No git push.
>
> **Out of scope:** Yapily production registration (eIDAS, live institutions). **Circles** entirely. Mobile app UI.

---

## How to use (one prompt, one session)

1. Open a **new Agent chat** on `main` or `dev`.
2. Paste the **COPY BLOCK** below in full (from the first `@` line through `END OF PROMPT`).
3. Add the **execution line** at the end (included in block below).
4. Let the agent run until **STEP 9 · FINAL REPORT**.
5. Review on **http://localhost:3003**.

**You deploy / commit / push yourself later.**

---

## What the agent must deliver

| Deliverable | Required |
|-------------|----------|
| Portal CRUD (create / edit / delete) for users, links, config, compliance, support, admin users | Yes |
| User **createdAt**, **lastLoginAt**, **presence** (online/recent/offline), device count | Yes |
| Consumer flag enforcement + `lastLoginAt` on consumer login | Yes |
| Webhooks, payment-links, transaction refresh, real reports | Yes |
| Edge cases handled (see COPY BLOCK) | Yes |
| `preprod-smoke-test.sh` + extended `cloud-smoke-test.sh` (file only) | Yes |
| Agent suggestions documented in report | Yes |
| Deploy / commit / push | **Forbidden** |

---

## ⬇️ COPY BLOCK — paste entire block into Agent chat

```
@docs/agents/ops-portal-preprod-focus-prompt.md
@AGENTS.md
@docs/agents/architecture.md
@docs/agents/conventions.md
@docs/agents/admin-portal-master-plan.md
@ops-portal/README.md
@ops-portal/scripts/cloud-smoke-test.sh
@backend/prisma/schema.prisma
@backend/prisma/seed-admin.ts
@backend/src/application/use-cases/auth/login-user.use-case.ts
@backend/src/application/use-cases/auth/phone-sign-in.use-case.ts
@backend/src/application/use-cases/payments/initiate-payer-payment.use-case.ts
@backend/src/application/use-cases/payments/complete-payer-payment.use-case.ts
@backend/src/application/use-cases/payments/get-payment-status.use-case.ts
@backend/src/application/use-cases/payment-links/create-payment-link.use-case.ts
@backend/src/application/use-cases/payment-links/cancel-payment-link.use-case.ts
@backend/src/infrastructure/queue/yapily-webhook.processor.ts
@backend/src/infrastructure/yapily/yapily.module.ts
@ops-portal/backend/src/domain/constants.ts
@ops-portal/backend/src/interfaces/http/data/data.allowlist.ts
@ops-portal/backend/src/application/use-cases/users/list-users-admin.use-case.ts
@ops-portal/backend/src/application/use-cases/users/set-user-admin-state.use-case.ts
@ops-portal/backend/src/application/use-cases/users/get-user-detail-admin.use-case.ts
@ops-portal/backend/src/application/use-cases/transactions/retry-payment-admin.use-case.ts
@ops-portal/backend/src/application/use-cases/transactions/get-payment-detail-admin.use-case.ts
@ops-portal/backend/src/application/use-cases/finance/list-reconciliation-exceptions.use-case.ts
@ops-portal/backend/src/application/use-cases/reports/get-report-series.use-case.ts
@ops-portal/backend/src/application/use-cases/search/global-search.use-case.ts
@ops-portal/backend/src/interfaces/http/users/users.controller.ts
@ops-portal/backend/src/interfaces/http/ops-http.module.ts
@ops-portal/frontend/app/(dashboard)/users/page.tsx
@ops-portal/frontend/app/(dashboard)/users/[id]/page.tsx
@ops-portal/frontend/app/(dashboard)/transactions/page.tsx
@ops-portal/frontend/app/(dashboard)/finance/page.tsx
@ops-portal/frontend/app/(dashboard)/reports/page.tsx
@ops-portal/frontend/app/(dashboard)/config/page.tsx
@ops-portal/frontend/app/(dashboard)/compliance/page.tsx
@ops-portal/frontend/app/(dashboard)/messages/page.tsx
@ops-portal/frontend/lib/nav.ts
@ops-portal/frontend/lib/admin-api.ts
@ops-portal/frontend/components/ops/topbar.tsx
@ops-portal/frontend/components/ops/primitives.tsx
@packages/shared-types/src/admin.ts
@packages/validators/src/admin.ts
@packages/pisp-provider/src/index.ts
@.cursor/skills/payspin/SKILL.md

You are a senior staff engineer + product designer executing a **single end-to-end delivery** for Payspin. The ops portal is the operator control room. Data explorer + partial Users 360° already ship.

Act with autonomy: propose and implement sensible UX improvements beyond this spec (document in final report). Cover **happy paths, error paths, permissions, and edge cases** — think like a fintech ops lead shipping internal tooling.

## YOUR CONTRACT (non-negotiable)

1. **Implement everything below** — portal (~65%) + consumer hooks (~35%). No circles. No Yapily prod registration.
2. **Full CRUD where specified** — create, edit, delete (or soft-delete) with confirmation modals, audit logs, role gates.
3. **User lifecycle & presence** — created date, last login, online/recent/offline heuristic, device count; visible on list + detail.
4. **You run all tests yourself** — fix every failure; loop until green.
5. **Local verification only** — :3001 consumer, :3002 ops API, :3003 ops UI.
6. **Do NOT deploy, commit, push, or create PRs.**
7. **Do NOT stop after planning** — write plan file, 10-line summary, continue immediately.

HARD EXCLUSIONS: Yapily eIDAS/live institutions. Circles/ROSCA. Payspin-portal/. Mobile UI. Cloud deploy. Git.

── STEP 1 · PLAN ──
Write docs/agents/ops-preprod-focus-plan.md:
- CRUD matrix (entity × create/read/update/delete × roles)
- User presence model (fields + heuristics)
- Prisma migration if adding lastLoginAt / lastSeenAt / deletedAt
- Routes, endpoints, edge-case checklist
- Test matrix
10-line summary → STEP 2.

── STEP 2 · SCHEMA + SHARED PACKAGES ──

A) Prisma migration (backend/prisma/) — if fields missing on User:
   - lastLoginAt DateTime? @map("last_login_at")
   - lastSeenAt DateTime? @map("last_seen_at")  // updated on login + optional auth middleware
   - deletedAt DateTime? @map("deleted_at")     // soft delete
   Run migrate locally. Regenerate client.

B) @payspin/shared-types + @payspin/validators:
   - AdminUserPresence: 'online' | 'recent' | 'offline' | 'never'
   - Extend AdminUserListItem + AdminUserDetail: lastLoginAt, lastSeenAt, createdAt, presence, registeredDeviceCount, isDeleted
   - AdminWebhook*, AdminPaymentLink*, AdminReportSeries (preview: false)
   - AdminPaymentDetail: relatedWebhooks[], webhookRawSummary
   - createUserAdminSchema, updateUserAdminSchema, deleteUserAdminSchema
   - updatePaymentLinkAdminSchema, updateComplianceAlertSchema, createSupportMessageSchema, createAdminUserSchema, etc.
   - Zod for all new query/body shapes

── STEP 3 · CONSUMER BACKEND (hooks + presence) ──

A) PlatformControlsService (backend/src/infrastructure/platform/)
   - isEnabled, getConfig, assertPlatformAllowsPaymentWrites (503 PLATFORM_DISABLED)
   - assertUserCanTransact(userId) — FROZEN or deletedAt set → Forbidden
   - Honor: platform_kill_switch, maintenance_mode, payment_links, new_signups

B) Wire into: create-payment-link, initiate/complete payment, register

C) Record activity on consumer auth:
   - login-user.use-case.ts → set lastLoginAt + lastSeenAt
   - phone-sign-in.use-case.ts → same
   - Optional lightweight middleware on JWT routes → bump lastSeenAt (throttle 1/min)

D) Block deleted/frozen users at login with clear error

E) payerBankName on complete / status / webhook processor

F) Tests: platform-controls.test.ts, login sets lastLoginAt, deleted user cannot login

── STEP 4 · OPS BACKEND — READ + CRUD ──

Follow controller → use case → Prisma. Audit every write. Roles per matrix below.

### Role matrix (default — adjust in plan if needed)
| Action | SUPER_ADMIN | OPS | SUPPORT | READ_ONLY |
|--------|-------------|-----|---------|-----------|
| Read lists/detail | ✓ | ✓ | ✓ | ✓ |
| User create/edit/delete | ✓ | ✓ create+edit; delete soft SUPER_ADMIN only | edit note/KYC | ✗ |
| Payment link cancel/extend | ✓ | ✓ | ✗ | ✗ |
| Transaction refresh | ✓ | ✓ | ✗ | ✗ |
| Config/flags write | ✓ | ✓ | ✗ | ✗ |
| Compliance/dispute update | ✓ | ✓ | ✓ status | ✗ |
| Support reply | ✓ | ✓ | ✓ | ✗ |
| Admin user CRUD | ✓ only | ✗ | ✗ | ✗ |

### A) Users — full lifecycle
GET /users — add columns: presence, lastLoginAt, createdAt, deviceCount (list already has createdAt — add rest)
GET /users/:id — paymentLinks, audit, presence, devices summary (platform, last token update — no raw FCM tokens in UI)
POST /users — create consumer user (email, displayName?, phoneE164?, tempPassword?) — hash password, audit USER_CREATE
PATCH /users/:id — edit displayName, phoneE164; email change SUPER_ADMIN only + uniqueness check
DELETE /users/:id — soft delete (deletedAt); reject if in-flight payments; audit USER_DELETE; optional hard delete SUPER_ADMIN + empty payments
POST /users/:id/reset-password — SUPER_ADMIN/OPS; set new temp password; audit
GET /users/:id/audit — AdminAuditEvent for user
POST /users/:id/state — extend: note, KYC, freeze (existing)

Presence heuristic (document in code):
- online: lastSeenAt within 5 minutes
- recent: lastSeenAt within 7 days
- offline: lastSeenAt older
- never: lastLoginAt null
Label in API as `presence` — not "logged in JWT session" (we have no session table).

### B) Webhooks (read-only + optional mark reviewed)
GET /webhooks, GET /webhooks/:id — redacted payload, linkedPaymentId, audit WEBHOOK_VIEW

### C) Payment links — read + write
GET /payment-links, GET /payment-links/:id
PATCH /payment-links/:id — cancel (status CANCELLED), extend expiresAt; reject invalid transitions; audit
POST /payment-links/:id — optional: ops create link on behalf of user (payeeUserId, amount, description) — OPS+

### D) Transactions
GET /transactions/:id — relatedWebhooks, webhookRawSummary
POST /transactions/:id/refresh — PIS_GATEWAY poll, audit PAYMENT_REFRESH, OPS+

### E) Finance, Reports, Search — as before (real SQL reports, enhanced exceptions)

### F) Compliance & disputes — edit
PATCH /compliance/:id — status OPEN/INVESTIGATING/CLEARED; assignee note; audit
PATCH /disputes/:id — status, resolution note; audit

### G) Support messages — create
POST /messages/threads/:id/reply — body text; persist SupportMessage; audit
PATCH /messages/threads/:id — status open/resolved

### H) Config — already PATCH flags/platform; ensure validation + audit on all writes

### I) Admin users (ops staff) — CRUD page API
GET /admin-users, GET /admin-users/:id
POST /admin-users — email, role, temp password (SUPER_ADMIN)
PATCH /admin-users/:id — role, isActive, displayName
DELETE /admin-users/:id — deactivate (isActive false), never delete last SUPER_ADMIN

── STEP 5 · OPS FRONTEND — CRUD + presence UX ──

Every destructive action: OpsConfirmModal with reason field where appropriate.
Every form: inline validation, loading state, error toast from API message.
READ_ONLY: hide/disable all write buttons.

### Users (priority)
- /users list: columns Created, Last login, Presence pill (green/teal/gray), Status, Actions
- "Create user" button → modal (email, name, phone, temp password)
- Row click → /users/[id]
- /users/[id] hero: Created · Last login · Presence · Devices (N registered)
- Tabs: Overview | Payments | Links | Bank | Notes | Audit | Devices
- Edit profile modal (PATCH)
- Freeze / Approve KYC modals with reason
- Soft delete with confirm ("type email to confirm") — SUPER_ADMIN
- Reset password button → modal

### Webhooks, Payment links, Transactions, Finance, Reports — as before +:
- Payment link detail: Cancel / Extend expiry buttons
- Transaction: Refresh from Yapily

### Compliance, Disputes, Messages — enable edit/reply (remove disabled placeholders)

### Config — existing toggles; show last updated by

### Admin users (new page /settings/admins or /admin-users) — SUPER_ADMIN only in nav
- List, create, deactivate, role change

### Nav, search, polish
- Operations: Webhooks, Payment Links
- Settings: Admin users (SUPER_ADMIN)
- Search → detail routes
- Remove Preview badges on real-data pages
- Cross-link chips user ↔ link ↔ transaction

── STEP 6 · EDGE CASES & SCENARIOS (must handle — add tests where practical) ──

Users:
- Duplicate email on create → 409
- Delete user with AWAITING_AUTHORIZATION payment → 409 + message
- Soft-deleted user: login blocked consumer-side; ops list filter "include deleted"
- Frozen user: initiate blocked; ops can unfreeze
- Edit phone invalid E.164 → 400
- READ_ONLY attempts POST → 403
- Empty search / pagination boundaries
- User never logged in → presence 'never', lastLoginAt null

Payment links:
- Cancel already CANCELLED/SETTLED → 400
- Extend expiry on EXPIRED → re-activate or 400 (document choice)
- MULTI link at maxUses → show clearly on detail

Transactions:
- Refresh without yapilyPaymentId → 400
- Refresh on COMPLETED → idempotent return, no error
- Yapily poll failure → 502 with message, no corrupt DB state

Flags:
- Disable payment_links → consumer initiate 503; re-enable restores
- Kill switch blocks complete mid-flight

Webhooks:
- Orphan event (no matching payment) → still listable, linkedPaymentId null

Support:
- Reply to resolved thread → 400 or reopen (document)

Admin users:
- Cannot deactivate self
- Cannot remove last SUPER_ADMIN

── STEP 7 · SMOKE SCRIPTS ──

A) ops-portal/scripts/preprod-smoke-test.sh — must cover:
   1. Ops login
   2. GET /webhooks, /payment-links, /reports (preview false)
   3. GET /users — item has presence + lastLoginAt fields (nullable ok)
   4. POST /users create test user → GET detail → PATCH → soft DELETE (or cleanup)
   5. Consumer login test user → GET /users/:id shows lastLoginAt updated + presence recent/online
   6. Flag toggle payment_links → initiate 503 → restore
   7. GET /transactions/:id relatedWebhooks key
   8. PATCH /payment-links/:id cancel (if test link exists) OR skip with note
   9. READ_ONLY role smoke optional if seed second admin
   FAIL: 0 required

B) Extend cloud-smoke-test.sh (file only — do NOT run against prod)

── STEP 8 · LOCAL TEST PIPELINE ──

T1–T4: build packages, backend test+lint, ops-backend test+lint, ops-frontend lint+build
T5: payspin-dev start + ops-backend dev :3002
T6: preprod-smoke-test.sh — FAIL: 0
T7: Manual UI checklist http://localhost:3003:
   - Create user flow
   - User shows Created + Last login + Presence after consumer login
   - Edit user, freeze, notes
   - Payment links cancel
   - Webhooks page
   - Transaction refresh button
   - Compliance/dispute edit OR support reply
FORBIDDEN: deploy-ops.sh, git commit/push, cloud-smoke against prod

── STEP 9 · FINAL REPORT ──

| Check | Result |
|-------|--------|
| Prisma migration applied | yes/no |
| Consumer tests | pass/fail |
| Ops tests | pass/fail |
| Ops frontend build | pass/fail |
| Local preprod-smoke | N / 0 fail |
| User CRUD + presence verified | yes/no |
| Edge cases covered | checklist |
| Agent suggestions implemented vs deferred | list |
| Deploy/commit/push | skipped |

Sections: Shipped, CRUD matrix (what's live), Operator guide, Presence semantics, Flag keys, Edge cases handled, Suggestions, Deploy-later commands, Deferred.

Definition of done (ALL true):
✓ User create/edit/soft-delete + reset password from ops
✓ createdAt, lastLoginAt, presence, device count on list + detail
✓ Consumer records lastLoginAt on login; deleted/frozen blocked
✓ Payment links ops CRUD (at least cancel + detail)
✓ Webhooks + transaction refresh + real reports
✓ Compliance/dispute/support write paths work
✓ Admin users CRUD (SUPER_ADMIN)
✓ Edge cases in STEP 6 handled or documented with 400/403/409
✓ preprod-smoke 0 failures
✓ No deploy/commit/push

END OF PROMPT

Execute end-to-end in one session: implement → test locally → fix all failures → verify every edge case you can. Do not deploy. Do not commit or push. Do not stop after planning. Do not ask me to run tests — you run them. Add your own suggestions where they clearly help ops.
```

---

## Context for the human (you)

### New in this version

| Feature | What you get |
|---------|----------------|
| **User CRUD** | Create, edit, soft-delete, reset password from ops |
| **Presence** | Created, last login, online/recent/offline pill, device count |
| **Payment links** | Cancel, extend expiry, ops detail page |
| **Compliance / disputes / support** | Status updates, reply to threads |
| **Admin users** | Manage ops staff (SUPER_ADMIN) |
| **Edge cases** | Duplicate email, delete with active payment, role 403s, etc. |

### Presence note

Consumer app uses **JWT** (no server session table). “Online” = **lastSeenAt within 5 minutes** (set on login + throttled API activity). UI label: **“Active recently”** not “Live session guaranteed.”

### When you are ready to ship

```bash
git status && git diff
./infrastructure/hetzner/deploy-ops.sh   # you run
./ops-portal/scripts/cloud-smoke-test.sh
git commit && git push
```

### Related docs

| Doc | Purpose |
|-----|---------|
| [ops-portal-data-explorer-prompt.md](ops-portal-data-explorer-prompt.md) | Data explorer (shipped) |
| [admin-portal-master-plan.md](admin-portal-master-plan.md) | Original scope |
