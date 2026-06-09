# Payspin — Admin ↔ User support chat (mobile + ops portal)

**Purpose:** Paste this file (or `@docs/agents/support-chat-integration-prompt.md`) when implementing **two-way customer support messaging** between **payees (Flutter mobile)** and **ops admins (ops portal)**. The agent must act as a **senior product engineer + UX designer**: choose a pragmatic realtime strategy, ship polished UI on both surfaces, wire notifications, and **test every edge case locally** before reporting done.

**Product context:** Payspin is non-custodial P2P payment links. Users sometimes need help with stuck payments, KYC, circles, or account issues. Today the ops portal has a **Phase 2 Messages inbox** (admin-only replies on seeded demo threads). The mobile app has a **stub** “Help & support” row on Profile with **no backend**. There is **no consumer API**, **no user ownership** on threads, **no push on admin reply**, and **no polling** on the ops Messages page.

**Explicit constraint for this task:** Implement and test **locally only**. **Do not `git push`**, **do not run `deploy.sh` / `deploy-ops.sh`**, **do not commit** unless the user explicitly asks. Document how to deploy later in the final report — do not execute it.

---

## How to use this prompt

### Option A — Cursor Agent (recommended)

1. Open a **new Agent chat** on your working branch.
2. Paste the **COPY BLOCK** at the bottom of this file.
3. Say: **“Execute end-to-end as a senior expert. Do not stop after planning. Do not push or deploy.”**
4. Review the plan summary, then let the agent run through build + full test matrix.

### Option B — Plan first, implement later

Ask: **“Run STEP 1 only from @docs/agents/support-chat-integration-prompt.md and write docs/agents/support-chat-plan.md”** — then start a fresh chat for implementation.

---

## Non-negotiables (read first)

1. Read [AGENTS.md](../../AGENTS.md), [architecture.md](architecture.md), [conventions.md](conventions.md).
2. Business logic in `application/use-cases/` — not controllers.
3. Validation via Zod in `@payspin/validators` — not Nest DTO classes for domain rules.
4. **Minimal diffs** — no drive-by refactors; reuse existing patterns.
5. Mobile UI: Payspin **dark design system** (`mobile/lib/core/design_system/`, skill `.cursor/skills/payspin-design/SKILL.md`).
6. Ops UI: existing `.msg-*` styles in `ops-portal/frontend/app/globals.css` — extend, don’t reinvent.
7. **Do not commit** `.env`, Firebase keys, or secrets.
8. **Do not push to git or deploy to cloud** for this task unless the user explicitly asks afterward.
9. **Test everything** in the [Test matrix](#test-matrix-edge-cases--scenarios) before marking done.

---

## Local environment

| Service | URL |
|---------|-----|
| Main API | `http://localhost:3001/v1` |
| Ops API | `http://localhost:3002/admin/v1` |
| Ops UI | `http://localhost:3003` |
| Postgres | `localhost:5435` |
| Redis | `localhost:6381` |

```bash
pnpm install
./scripts/dev/payspin-dev doctor
./scripts/dev/payspin-dev start --web   # if not already running
cd ops-portal && pnpm dev               # ops backend + frontend (see ops-portal/README.md)
cd mobile && flutter run --dart-define=API_URL=http://localhost:3001/v1
```

Seed admin + demo support threads:

```bash
cd backend && pnpm exec tsx prisma/seed-admin.ts
```

Default ops login (from seed): see terminal output after seed (typically `admin@payspin.dev`).

---

## Current architecture (what already exists)

### Database (`backend/prisma/schema.prisma`)

```prisma
model SupportThread {
  id            String
  userRef       String    // display string e.g. "User #5012" — NOT a FK today
  subjectName   String
  meta          String?
  status        String    @default("OPEN")   // OPEN | RESOLVED (convention)
  unread        Boolean   @default(true)     // admin-side unread flag
  lastMessageAt DateTime
  messages      SupportMessage[]
}

model SupportMessage {
  id         String
  threadId   String
  direction  String    @default("IN")     // IN = user→admin, OUT = admin→user
  body       String
  authorName String
  createdAt  DateTime
}
```

**Gaps:** no `userId` FK on `SupportThread`; no `readAt` / per-side unread; no link to payment/link/circle context; seed data is ops-only demo.

### Ops portal (admin side — partial)

| Layer | Path |
|-------|------|
| List threads | `ops-portal/backend/.../messages/list-support-threads.use-case.ts` |
| Get thread | `ops-portal/backend/.../messages/get-support-thread.use-case.ts` |
| HTTP | `ops-portal/backend/.../phase2/phase2.controller.ts` — `GET /messages`, `GET /messages/:id`, `POST /messages/threads/:id/reply`, `PATCH /messages/threads/:id` |
| UI | `ops-portal/frontend/app/(dashboard)/messages/page.tsx` — split-pane inbox, bubbles, reply, mark resolved |
| CSS | `ops-portal/frontend/app/globals.css` — `.msg-layout`, `.bubble.in/out` |
| Types | `packages/shared-types/src/admin.ts` — `SupportThreadDto`, `SupportMessageDto` |
| Validators | `packages/validators/src/admin.ts` — `createSupportMessageSchema`, `patchSupportThreadSchema` |
| Sidebar badge | `ops-portal/frontend/components/ops/sidebar.tsx` — polls thread list for unread count |

**Gaps:** reply logic is **inline in controller** (should move to use case); **no polling** on messages page (dashboard polls every 8s); **no FCM** when user sends IN message; **no user 360° link** from Users page.

### Main backend (consumer — missing)

No `/v1/support/*` routes. No use cases under `backend/src/application/use-cases/support/`.

### Mobile (consumer — missing)

| Stub | Path |
|------|------|
| Profile row | `mobile/lib/presentation/profile/profile_page.dart` — `helpSupport` → `onTap: () {}` |
| L10n key | `mobile/lib/core/l10n/payspin_localizations.dart` — `helpSupport` |

**Reference patterns to mirror:**

| Feature | Pattern file |
|---------|--------------|
| In-app list + refresh | `mobile/lib/presentation/notifications/notifications_page.dart` |
| FCM + in-app notification | `backend/.../notify-payment-received.use-case.ts` |
| Push data → deep link | `NotificationType`, `notifications_refresh_notifier.dart` |
| API client | `mobile/lib/data/datasources/payspin_api_client.dart` |

### Notifications infrastructure (reuse)

- `NotificationType` enum in `packages/shared-types/src/index.ts` — add `SUPPORT_REPLY = 'support.reply'`.
- `CreateNotificationUseCase`, BullMQ `NOTIFICATIONS_QUEUE`, FCM via `SendPushNotificationUseCase`.
- Mobile handles push → refresh notifier → reload screens.

---

## Recommended approach — realtime without WebSockets (v1)

**Decision:** Use **REST + short polling + FCM push** — same dual-channel pattern as payment notifications. **Do not add WebSockets/SSE in v1** unless you hit a blocker; the stack already has FCM, TanStack Query, and Flutter refresh notifiers.

| Event | Mechanism |
|-------|-----------|
| User sends message | `POST /v1/support/threads/:id/messages` → ops thread `unread=true`, optional ops-side poll picks it up |
| Admin replies | `POST /admin/v1/messages/threads/:id/reply` → `NotifySupportReplyUseCase` → in-app notification + FCM with `{ type: 'support.reply', threadId }` |
| User on chat screen | Poll thread every **5s** (match `link_detail_page.dart`) |
| User elsewhere | FCM → `SupportRefreshNotifier` → badge on Profile / tab |
| Admin on Messages page | `refetchInterval: 5000` on thread list + active thread (match dashboard) |
| Admin elsewhere | Sidebar badge already refetches thread list |

**Why not WebSockets v1:** Two apps (main API + ops API), no existing WS infra, FCM already wired for mobile; polling at 5s is acceptable for support UX and matches existing Payspin patterns.

**Future v2 (document only, do not implement unless time):** SSE endpoint on main API for open chat screens; shared Redis pub/sub between ops and main API.

---

## Schema changes (required)

Add a Prisma migration from `backend/`:

```prisma
model SupportThread {
  // ... existing fields ...
  userId        String?   @map("user_id")      // FK → users.id; null for legacy seed rows
  category      String?                        // e.g. PAYMENT, ACCOUNT, CIRCLE, OTHER
  contextRef    String?   @map("context_ref")  // optional paymentId / linkId / circleId
  userUnread    Boolean   @default(false) @map("user_unread")  // user-side unread (admin replies)
  user          User?     @relation(fields: [userId], references: [id], onDelete: SetNull)

  @@index([userId, lastMessageAt])
}

model User {
  supportThreads SupportThread[]
}
```

**Semantics:**

| Field | Meaning |
|-------|---------|
| `unread` | Admin has not read latest **IN** message |
| `userUnread` | User has not read latest **OUT** message |
| `userRef` | Keep for display (`User #5012` or email) — populate from user on create |
| `subjectName` | User display name at thread creation |
| `meta` | Auto-generated context line, e.g. `Payment · €50 · link abc123` |

**Status values:** `OPEN`, `RESOLVED`, `ARCHIVED` (optional — at minimum OPEN + RESOLVED).

---

## API specification

### Consumer API — `backend/src/interfaces/http/support/`

Base path: `/v1/support` — all routes require **user JWT** (same guard as notifications).

| Method | Path | Use case | Description |
|--------|------|----------|-------------|
| `GET` | `/threads` | `ListUserSupportThreadsUseCase` | Current user’s threads, newest first |
| `POST` | `/threads` | `CreateSupportThreadUseCase` | New thread + first IN message |
| `GET` | `/threads/:id` | `GetUserSupportThreadUseCase` | Thread + messages; **403 if not owner** |
| `POST` | `/threads/:id/messages` | `SendUserSupportMessageUseCase` | Append IN message; reopen if RESOLVED |
| `PATCH` | `/threads/:id/read` | `MarkSupportThreadReadUseCase` | Clear `userUnread` |
| `GET` | `/unread-count` | `GetSupportUnreadCountUseCase` | For Profile badge |

**Create thread body (Zod in `@payspin/validators`):**

```typescript
{
  subject?: string;           // default "Support request"
  category?: 'PAYMENT' | 'ACCOUNT' | 'CIRCLE' | 'OTHER';
  body: string;                 // first message, min 1 max 4000
  contextRef?: string;          // optional link/payment id from deep link
}
```

**Ownership:** Every query filters `where: { userId: currentUser.id }`. Return 404 (not 403) for wrong id to avoid leaking existence.

**When user sends IN message:** set `unread=true` on thread, update `lastMessageAt`. Optionally enqueue lightweight job or inline update — ops poll will see it.

### Ops API — extend existing routes

Refactor inline Prisma in `phase2.controller.ts` into use cases:

| Use case | Behavior |
|----------|----------|
| `ReplyToSupportThreadUseCase` | Create OUT message; `userUnread=true`; `unread=false`; call `NotifySupportReplyUseCase` |
| `PatchSupportThreadUseCase` | Status change + audit (existing) |
| `ListSupportThreadsUseCase` | Add filter `?status=OPEN`, `?userId=`, sort unchanged |
| `GetSupportThreadUseCase` | On GET, optionally mark admin `unread=false` (or separate PATCH — prefer explicit `PATCH .../read` for admin) |

Add:

| Method | Path | Description |
|--------|------|-------------|
| `PATCH` | `/messages/threads/:id/read` | Admin marks thread read (`unread=false`) |
| `GET` | `/users/:userId/support-threads` | User 360° — threads for a user |

### Shared types

Extend `packages/shared-types`:

- Consumer DTOs in `packages/shared-types/src/support.ts` (or extend `index.ts` if small).
- Add `SupportCategory`, consumer `CreateSupportThreadInput`, `SupportUnreadCount`.
- Extend `NotificationType.SUPPORT_REPLY`.
- Keep admin DTOs in `admin.ts` — add `userId`, `category`, `contextRef`, `userUnread` where needed.

### Notification on admin reply

New `NotifySupportReplyUseCase` (mirror `notify-payment-received.use-case.ts`):

```typescript
// title: "Support replied"
// body: truncate admin message to ~120 chars
// data: { type: 'support.reply', threadId, messageId }
```

Mobile: handle `support.reply` in push handler → navigate to `/support/:threadId` or refresh list.

---

## UI/UX specification

### Design principles

1. **Calm, trustworthy support** — not a generic chat app; Payspin dark tokens, glass surfaces, gradient accent on primary actions only.
2. **Context-first** — show payment/link context when `contextRef` present; offer “Report issue with this payment” from link detail.
3. **Low friction** — quick topic chips before free text; pre-filled subject from category.
4. **Clear state** — OPEN vs RESOLVED badges; “We typically reply within a few hours” expectation copy.
5. **Accessibility** — min 44pt tap targets, readable timestamps, pull-to-refresh on mobile.

### Mobile screens (Flutter)

**Route:** `/support` (inbox), `/support/new`, `/support/:threadId` — register in `mobile/lib/app/router.dart`.

| Screen | UX |
|--------|-----|
| **Support inbox** | List threads: subject, preview, relative time, unread dot; empty state with CTA “Contact support”; pull-to-refresh + poll every 5s while visible |
| **New request** | Category chips (Payment issue, Account, Circle, Other); optional context banner if opened from link detail; multiline composer; `PayspinPrimaryButton` Send |
| **Thread detail** | Chat bubbles: IN right-aligned (user, teal accent), OUT left-aligned (Support, muted panel); sticky composer at bottom; RESOLVED banner + “Send another message” reopens thread |
| **Profile entry** | Wire `helpSupport` row → `/support`; show unread badge count from `/support/unread-count` |
| **Link detail entry** | Optional: “Need help?” text button → `/support/new?contextRef={linkId}` |

**Widgets:** Reuse `PayspinGlassSurface`, `PayspinFlowHeader`, `PayspinPrimaryButton`, `PayspinEmblemLoader`, semantic colors from `payspin_semantic_colors.dart`.

**L10n:** Add EN + NL strings for all new copy (match `payspin_localizations.dart` pattern).

**Architecture:** `SupportRepository` (abstract) → `SupportRepositoryImpl` → `PayspinApiClient` methods; register in `injection.dart`; optional `SupportRefreshNotifier` (copy notifications pattern).

### Ops portal enhancements

**Messages page** (`messages/page.tsx`):

1. Add `refetchInterval: 5000` to threads + active thread queries.
2. Show `category`, `contextRef`, link to User 360° when `userId` present.
3. **Quick replies** dropdown (local constants, not AI): e.g. “We’re looking into your payment…”, “Please try again in 30 minutes”, “Your KYC is pending review”.
4. Filter tabs: All | Open | Resolved.
5. Keyboard: Enter sends (Shift+Enter newline) — optional polish.
6. Auto-scroll on new messages (already partially there).
7. Empty state: link to seed command.

**Users 360°** (`users/[id]` or existing user detail):

- Section “Support threads” — list + link to `/messages?thread={id}` or open thread in messages.

**Sidebar badge:** Already counts admin `unread` — verify it updates after user sends IN message.

### Customer-support product suggestions (implement the practical subset)

| Feature | Priority | Notes |
|---------|----------|-------|
| Category + context on create | **P0** | Helps ops triage without asking “which payment?” |
| Push + in-app on admin reply | **P0** | Core realtime feel |
| Quick reply templates (ops) | **P1** | Speed; store as frontend constants v1 |
| “Report payment issue” from link detail | **P1** | Pre-fills category + contextRef |
| Office hours / SLA hint on mobile | **P1** | Static copy in Remote Config or l10n |
| FAQ accordion before new ticket | **P2** | 3–5 items: stuck payment, refund policy, KYC timing |
| Attach screenshot | **P3** | Defer — needs upload infra |
| CSAT thumbs after RESOLVED | **P3** | Defer — needs new table |
| Bot / AI triage | **Out of scope** | Human support only v1 |

---

## Implementation phases (agent workflow)

### STEP 1 · Plan (mandatory, then continue)

Write `docs/agents/support-chat-plan.md` (local doc OK to create) with:

- Migration fields + rollback note
- File list (every new/changed path)
- Sequence diagram (user message → ops inbox → admin reply → FCM → mobile)
- Explicit “no deploy” reminder

Show a **short plan summary** in chat, then **immediately continue** — do not stop for approval unless blocked.

### STEP 2 · Schema + shared packages

1. Prisma migration (`userId`, `category`, `contextRef`, `userUnread`, indexes).
2. `pnpm --filter backend exec prisma migrate dev` (local).
3. Update `@payspin/shared-types` + `@payspin/validators`.
4. Update seed: attach demo threads to a real seeded user if one exists; keep backward-compatible rows with `userId: null`.

### STEP 3 · Main backend (consumer API)

1. Use cases under `backend/src/application/use-cases/support/`.
2. `SupportModule` + controller under `backend/src/interfaces/http/support/`.
3. `NotifySupportReplyUseCase` under notifications.
4. Wire ops `ReplyToSupportThreadUseCase` to call notifier (shared code: either duplicate thin wrapper in ops-backend importing pattern, or extract shared service — **prefer ops use case calling same notification logic via duplicated queue add mirroring main backend**; ops and main share Postgres + Redis).

**Important:** Ops backend and main backend are separate Nest apps but share **same Postgres**. Consumer writes go through main API; admin writes through ops API. Both read/write `support_threads` / `support_messages`.

### STEP 4 · Ops portal

1. Extract reply/patch into use cases.
2. Polling + filters + quick replies on Messages page.
3. User 360° support section.
4. `NotifySupportReplyUseCase` in ops-backend (or inject queue to main — simplest: **ops-backend enqueues to same Redis `notifications` queue** with userId from thread).

### STEP 5 · Mobile

1. Repository + API client methods.
2. Three screens + routes.
3. Profile + optional link detail entry.
4. FCM handler for `support.reply`.
5. `SupportRefreshNotifier` for badge.

### STEP 6 · Tests

**Backend unit tests** (`backend/test/support-*.test.ts`):

- Create thread sets userId, first IN message, unread for admin.
- User cannot read another user’s thread.
- Send message on RESOLVED reopens to OPEN.
- Admin reply sets userUnread, clears admin unread, enqueues notification job.
- Mark read endpoints idempotent.

**Ops backend tests** (if pattern exists): reply + audit row.

**Manual / integration:**

- Full flow with curl + ops UI + Flutter simulator.

### STEP 7 · Report

Final summary: what shipped, how to run, test results table, known gaps, **“not deployed / not pushed”** confirmation.

---

## Test matrix (edge cases & scenarios)

Agent must run **all** rows; fix failures before done.

| # | Scenario | Steps | Expected |
|---|----------|-------|----------|
| 1 | Happy path — new thread | Mobile: new request, category Payment, send | Thread in mobile inbox; appears in ops Messages with `unread` badge |
| 2 | Happy path — admin reply | Ops: reply to thread | Message in thread; mobile receives push (simulator) or in-app notification; `userUnread` on mobile |
| 3 | Happy path — user reads reply | Mobile: open thread | Bubbles correct; mark read clears badge |
| 4 | Multi-message thread | User sends 3 messages, admin 2 replies | Order by `createdAt`; scroll sticks to bottom |
| 5 | Ownership isolation | User A token → GET User B thread id | 404 |
| 6 | Empty body rejected | POST message `body: ""` | 400 Zod error |
| 7 | Max length | 4001 char body | 400 |
| 8 | Resolved thread | Admin marks RESOLVED | Mobile shows resolved state; user can send again → OPEN |
| 9 | Reopen on user message | RESOLVED → user sends IN | status OPEN, admin `unread=true` |
| 10 | Ops READ_ONLY role | Login read-only admin | Can view threads, **cannot** reply (403 or disabled UI) |
| 11 | Polling — ops | Keep Messages open; user sends from mobile | Ops UI shows new message within ~5s without refresh |
| 12 | Polling — mobile | Keep thread open; admin replies | Mobile shows reply within ~5s |
| 13 | Context from link | Open support from link detail | `contextRef` stored; ops sees meta |
| 14 | Seed legacy rows | Threads with `userId: null` | Ops still lists them; consumer API does not expose to users |
| 15 | Concurrent sends | Two rapid sends user + admin | Both persisted; no lost messages |
| 16 | Network error mobile | Airplane mode send | Error toast; composer retains text |
| 17 | Unauthenticated | curl without JWT | 401 |
| 18 | Notification payload | Admin reply | DB notification row + FCM job with `threadId` |
| 19 | Mark all read | Mobile mark thread read | `/unread-count` returns 0 |
| 20 | Sidebar badge ops | User sends IN | Ops sidebar Messages badge increments |
| 21 | Quick reply ops | Select template | Inserts into compose; send works |
| 22 | i18n | Switch mobile to NL | Support strings translated |
| 23 | Backend tests | `pnpm --filter backend test` | All pass including new support tests |
| 24 | Ops build | `pnpm --filter @payspin/ops-frontend build` | No errors |
| 25 | Flutter analyze | `cd mobile && dart analyze lib/presentation/support` | No errors |

---

## Key files reference

| Area | Path |
|------|------|
| Schema | `backend/prisma/schema.prisma` |
| Seed | `backend/prisma/seed-admin.ts` |
| Ops messages UI | `ops-portal/frontend/app/(dashboard)/messages/page.tsx` |
| Ops controller | `ops-portal/backend/src/interfaces/http/phase2/phase2.controller.ts` |
| Admin types | `packages/shared-types/src/admin.ts` |
| Payment notify pattern | `backend/src/application/use-cases/notifications/notify-payment-received.use-case.ts` |
| Mobile notifications pattern | `mobile/lib/presentation/notifications/notifications_page.dart` |
| Profile stub | `mobile/lib/presentation/profile/profile_page.dart` |
| Design skill | `.cursor/skills/payspin-design/SKILL.md` |

---

## Definition of done

- [ ] User can create threads and send messages from **mobile** with Payspin-branded UI.
- [ ] Admin can view, reply, resolve from **ops Messages** with **5s polling** and unread badges.
- [ ] **FCM + in-app notification** fires on admin reply (`NotificationType.SUPPORT_REPLY`).
- [ ] **Ownership enforced** on all consumer endpoints.
- [ ] **Prisma migration** applied locally; seed still works.
- [ ] **Unit tests** for support use cases pass; manual matrix rows 1–25 verified.
- [ ] Final report includes run commands and explicitly states **no git push / no cloud deploy** performed.
- [ ] Optional plan doc at `docs/agents/support-chat-plan.md`.

---

## ⬇️ COPY BLOCK — paste into Agent chat

```
@docs/agents/support-chat-integration-prompt.md
@AGENTS.md
@docs/agents/architecture.md
@docs/agents/conventions.md
@backend/prisma/schema.prisma
@packages/shared-types/src/admin.ts
@packages/shared-types/src/index.ts
@packages/validators/src/admin.ts
@ops-portal/backend/src/interfaces/http/phase2/phase2.controller.ts
@ops-portal/frontend/app/(dashboard)/messages/page.tsx
@ops-portal/frontend/app/globals.css
@backend/src/application/use-cases/notifications/notify-payment-received.use-case.ts
@mobile/lib/presentation/profile/profile_page.dart
@mobile/lib/presentation/notifications/notifications_page.dart
@mobile/lib/app/router.dart
@resources/Payspin Design System/README.md
@CLAUDE.md
@.cursor/skills/payspin/SKILL.md
@.cursor/skills/payspin-design/SKILL.md

You are a senior Payspin engineer and product designer. Implement full two-way support chat: payee (Flutter mobile) ↔ ops admin (ops portal Messages).

Read the prompt file completely. Follow its architecture decision: REST + 5s polling + FCM (no WebSockets v1). Extend Prisma with userId ownership, category, contextRef, userUnread. Build consumer /v1/support/* on main backend; refactor ops reply into use cases; wire NotifySupportReplyUseCase.

Mobile: beautiful dark Payspin UI — inbox, new request (category chips), thread chat bubbles, Profile “Help & support” wired, optional entry from link detail. Ops: polling, filters, quick reply templates, user 360° threads section.

Act as senior expert: propose sensible support UX improvements from the prompt’s suggestion table (implement P0–P1 items).

Execute STEP 1–7 end-to-end in ONE session. Write docs/agents/support-chat-plan.md after STEP 1, then implement immediately.

TESTING IS MANDATORY: run the full 25-row test matrix in the prompt. Fix all failures. Run backend unit tests and ops-frontend build + dart analyze on support screens.

CRITICAL CONSTRAINTS:
- Do NOT git push
- Do NOT deploy to cloud (no deploy.sh, no deploy-ops.sh)
- Do NOT commit unless I explicitly ask
- Work locally only (:3001, :3002, :3003, Flutter simulator)

Start infra if needed: ./scripts/dev/payspin-dev doctor && ./scripts/dev/payspin-dev start

Definition of done: per checklist at bottom of support-chat-integration-prompt.md. End with a structured report: shipped features, test results table, how to run, known gaps, confirmation nothing was pushed/deployed.
```
