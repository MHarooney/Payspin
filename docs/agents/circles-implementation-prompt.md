# Payspin Circles (Groepies) — Agent Implementation Prompt

Paste this into a new agent session to implement or extend **Circles / Groepies** in the Payspin monorepo.

**Repo:** `git@github.com:MHarooney/Payspin.git`  
**Backend:** `backend/` · **Mobile:** `mobile/`  
**Do NOT edit:** `.cursor/plans/*.plan.md`

---

## Read first

1. `AGENTS.md`, `docs/agents/architecture.md`, `docs/agents/conventions.md`
2. `docs/agents/circles-contribution-mvp.md` — how round payments work (MULTI payment links)
3. `backend/prisma/schema.prisma` — `Circle`, `CircleMember`
4. Reference: `backend/src/application/use-cases/payment-links/`, `backend/src/application/use-cases/circles/`
5. Mobile reference: `mobile/lib/presentation/circles/`, `mobile/lib/presentation/home/groepies_page.dart`

---

## Product (MVP)

- **UI label:** Groepies · **API/domain:** Circle
- Host creates a circle (DRAFT), shares **invite code**, members join until `memberCount` reached
- Host **activates** → `ACTIVE`, round 0 starts
- Each round: host creates a **contribution payment link** (`POST /circles/:id/contribution-link`); members pay via payer web
- Host **advances round** when ready → next recipient; `COMPLETED` after final round
- Blockchain fields (`smartContractAddress`, `moneriumIban`, `walletAddress`) — store only, no integration in MVP

---

## API (`/v1/circles`, JWT required)

| Method | Route | Purpose |
|--------|-------|---------|
| POST | `/circles` | Create (host auto-joined) |
| GET | `/circles` | List for current user |
| POST | `/circles/join` | Join by `{ inviteCode }` |
| GET | `/circles/:id` | Detail + members |
| PATCH | `/circles/:id/members/:memberId` | Host: reorder/remove (DRAFT only) |
| POST | `/circles/:id/activate` | Host: DRAFT → ACTIVE |
| POST | `/circles/:id/advance-round` | Host: next round / COMPLETED |
| POST | `/circles/:id/contribution-link` | Host: MULTI payment link for current round |

Errors: `{ message, issues? }` — mobile uses `apiErrorMessage()`.

---

## Architecture rules

- **Backend:** Zod in `@payspin/validators` → use case → thin controller. No business logic in controllers.
- **Mobile:** domain repo → `PayspinApiClient` → mappers. No API calls from widgets.
- **Refresh:** `CirclesRefreshNotifier` bumps on create/join/activate/advance (mirrors `LinksRefreshNotifier`).

---

## Mobile screens

| Screen | Route |
|--------|-------|
| Groepies list (home tab) | Home → Groepies tab |
| Create | `/circles/create` |
| Join | `/circles/join` |
| Detail | `/circles/:id` |

Design: `PayspinTheme`, `PayspinTokens`, `CircleRow` (list), gradient CTAs.

---

## Local dev

```bash
pnpm install && ./scripts/dev/payspin-dev start --web
cd mobile && flutter run --dart-define=API_URL=http://localhost:3001/v1
```

---

## Definition of done

- [ ] Backend routes + host guards + Zod validation
- [ ] `pnpm test` green (incl. circle validator tests)
- [ ] Mobile Groepies tab lists circles; create → invite → join → activate → contribution link → advance
- [ ] `flutter analyze` + `flutter test` green
- [ ] Minimal diffs; no secrets committed

---

## Out of scope

Monerium/blockchain, FCM push, payer-web circle UI, member reorder UI (API exists), `payspin/Payspin-mobile` repo migration.

---

## Agent start command

> Load this prompt. Implement missing Circles pieces or harden existing code in `MHarooney/Payspin`. Mirror payment-links patterns. Run `pnpm test` and `cd mobile && flutter test` before finishing.
