# Support chat — implementation plan

Two-way support messaging: payee (Flutter mobile) ↔ ops admin (ops portal Messages).
Architecture: **REST + 5s polling + FCM** (no WebSockets v1) — mirrors the existing
payment-notification dual-channel pattern.

> **Local only.** No `git push`, no `deploy.sh` / `deploy-ops.sh`, no commit unless asked.

## 1. Migration

`backend/prisma/schema.prisma` — extend `SupportThread`, add reverse relation on `User`:

| Field | Type | Meaning |
|-------|------|---------|
| `userId` | `String?` (`user_id`) | FK → `users.id`; `null` for legacy seed rows |
| `category` | `String?` | `PAYMENT` \| `ACCOUNT` \| `CIRCLE` \| `OTHER` |
| `contextRef` | `String?` (`context_ref`) | optional linkId / paymentId / circleId |
| `userUnread` | `Boolean` `@default(false)` (`user_unread`) | user has unread admin (OUT) reply |
| relation | `user User? @relation(... onDelete: SetNull)` | |
| index | `@@index([userId, lastMessageAt])` | |

`unread` (existing) keeps its meaning: admin has unread user (IN) message.

**Rollback:** `prisma migrate resolve` / drop the new columns + index; all new columns are
nullable or defaulted, so existing rows and the ops demo seed stay valid.

## 2. Shared packages

- `packages/shared-types/src/support.ts` (new): `SupportCategory`, `SupportMessageView`,
  `SupportThreadView`, `SupportThreadWithMessages`, `CreateSupportThreadInput`,
  `SendSupportMessageInput`, `SupportUnreadCount`. Re-export from `index.ts`.
- `index.ts`: add `NotificationType.SUPPORT_REPLY = 'support.reply'`.
- `admin.ts`: add `userId`, `category`, `contextRef`, `userUnread` to `SupportThreadDto`.
- `packages/validators/src/support.ts` (new): `createSupportThreadSchema` (subject?,
  category?, body 1–4000, contextRef?), `sendSupportMessageSchema` (body 1–4000). Re-export.

## 3. Main backend — consumer API (`/v1/support`, user JWT)

Use cases in `backend/src/application/use-cases/support/`:

| Use case | Route | Behaviour |
|----------|-------|-----------|
| `ListUserSupportThreadsUseCase` | `GET /threads` | own threads, newest first |
| `CreateSupportThreadUseCase` | `POST /threads` | thread + first IN msg; `unread=true` |
| `GetUserSupportThreadUseCase` | `GET /threads/:id` | **404 if not owner** |
| `SendUserSupportMessageUseCase` | `POST /threads/:id/messages` | append IN; reopen if RESOLVED; `unread=true` |
| `MarkSupportThreadReadUseCase` | `PATCH /threads/:id/read` | clear `userUnread` |
| `GetSupportUnreadCountUseCase` | `GET /unread-count` | profile badge |

Thread fields on create: `subjectName` = chosen subject / category label; `userRef` = email
/ phone / `User <id8>`; `meta` = `displayName · category · ref <contextRef>`. Controller +
`SupportModule` in `interfaces/http/support/`, registered in `http-api.module.ts`.

## 4. Ops portal

**Backend** (`ops-portal/backend`): add `bullmq` + `@nestjs/bullmq`, `BullModule.forRootAsync`
in `app.module.ts`, register `notifications` queue in `Phase2Module`. New use cases under
`application/use-cases/`:

- `messages/reply-to-support-thread.use-case.ts` — OUT msg, `userUnread=true`, `unread=false`,
  audit, then `NotifySupportReplyUseCase`.
- `messages/patch-support-thread.use-case.ts` — status + audit (extracted from controller).
- `messages/mark-support-thread-read.use-case.ts` — admin `unread=false`.
- `notifications/notify-support-reply.use-case.ts` — create `Notification` row
  (`type='support.reply'`) **and** enqueue `push` job to the shared `notifications` queue
  (main backend worker delivers FCM). DB row is the inbox source of truth.
- Extend `ListSupportThreadsUseCase` (filter `status` / `userId`, map new fields) and
  `GetSupportThreadUseCase` (map new fields).

New ops routes: `PATCH /messages/threads/:id/read`, `GET /users/:userId/support-threads`.

**Frontend** (`ops-portal/frontend`):
- `messages/page.tsx`: `refetchInterval: 5000` on threads + active thread; filter tabs
  All/Open/Resolved; quick-reply templates (constants); mark-read on open; category /
  contextRef / User 360° link; preselect via `?thread=`.
- `users/[id]/page.tsx`: new **Support** tab → `/users/:id/support-threads`, links to messages.

## 5. Mobile (Flutter, dark Payspin DS)

- Domain: `entities/support_thread.dart`, `repositories/support_repository.dart`.
- Data: API client methods, `repositories/support_repository_impl.dart`,
  `core/state/support_refresh_notifier.dart`.
- Presentation `presentation/support/`: `support_inbox_page.dart`,
  `new_support_request_page.dart` (category chips + context banner),
  `support_thread_page.dart` (chat bubbles, 5s poll, RESOLVED reopen).
- Routes `/support`, `/support/new`, `/support/:threadId` in `router.dart` (+ redirect
  allowlist). Profile `helpSupport` → `/support`. Link detail "Need help?" →
  `/support/new?contextRef=<id>&category=PAYMENT`.
- FCM: `PushService` handles `support.reply` → bump `SupportRefreshNotifier` +
  `openSupportThreadRequests`; `main_shell` navigates. EN/NL/DE/AR l10n.

## 6. Tests

- `backend/test/support-use-cases.test.ts` — in-memory Prisma fake: create sets userId +
  IN msg + admin unread; ownership 404; send reopens RESOLVED; mark-read idempotent;
  unread-count.
- `ops-portal/backend/test/support-reply.test.ts` — reply sets userUnread, clears admin
  unread, enqueues push + notification row.
- Ops frontend `build`; `dart analyze lib/presentation/support`.
- Manual 25-row matrix via curl + ops UI.

## 7. Sequence

```
Mobile POST /v1/support/threads ─▶ support_threads (unread=true, userUnread=false)
   │                                     ▲
   │  (ops polls /messages every 5s) ────┘
Ops POST /admin/v1/messages/threads/:id/reply
   ├─▶ support_messages (OUT) ; thread userUnread=true, unread=false
   ├─▶ notifications row (type=support.reply)
   └─▶ enqueue push → [main backend NotificationProcessor] → FCM
Mobile: poll thread (5s) on screen  |  FCM → SupportRefreshNotifier → badge/refresh elsewhere
Mobile PATCH /v1/support/threads/:id/read ─▶ userUnread=false
```

**No deploy / no push for this task.**
