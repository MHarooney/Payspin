# Payspin — Local Development Runbook

Step-by-step guide to run the full stack on your machine (macOS). Use this when onboarding or when something “keeps loading” in the app.

---

## What you are running

| Service | Stack | Local URL | Purpose |
|---------|-------|-----------|---------|
| **PostgreSQL** | Docker | `localhost:5435` | App database |
| **Redis** | Docker | `localhost:6381` | BullMQ / webhooks queue |
| **API** | NestJS | http://localhost:3001/v1 | Auth, links, IBAN, payments |
| **Payer web** | Next.js | http://localhost:3000 | Payer opens `/{shortCode}` |
| **Mobile** | Flutter | (simulator/device) | Payee app talks to API |

Monorepo root: `/path/to/Payspin`

### One-command CLI (recommended)

```bash
chmod +x scripts/dev/payspin-dev   # once, if needed

./scripts/dev/payspin-dev setup    # first time only
./scripts/dev/payspin-dev start    # Docker + API (background)
./scripts/dev/payspin-dev status   # health + ports
./scripts/dev/payspin-dev stop     # stop API
./scripts/dev/payspin-dev stop --all   # API + web + Docker

# pnpm aliases
pnpm dev:setup
pnpm dev:start
pnpm dev:start:web
pnpm dev:restart -- --force-ports
```

See [`scripts/README.md`](../scripts/README.md) for full command reference (`logs`, `doctor`, `--mobile`, `--target device`).

### Mobile visual QA (design system)

Compare the Flutter app (dark mode) side-by-side with the official prototype:

```bash
open "resources/Payspin Design System/Payspin Prototype.html"
```

Token and screen mapping: [`resources/docs/design-system-flutter-map.md`](design-system-flutter-map.md). Tracker checklist: [`mobile/IMPLEMENTATION_TRACKER.md`](../mobile/IMPLEMENTATION_TRACKER.md) (D1–D10).

---

## Prerequisites

Install once:

| Tool | Version | Check |
|------|---------|--------|
| **Node.js** | ≥ 20 | `node -v` |
| **pnpm** | 9.x | `pnpm -v` |
| **Docker Desktop** | latest | `docker ps` |
| **Flutter** | 3.5+ | `flutter doctor` |
| **Xcode** (iOS sim) | — | For `flutter run` on iPhone simulator |
| **Android Studio** (optional) | — | For Android emulator |

---

## First-time setup (≈ 10 minutes)

Run from the **repo root**:

```bash
cd /path/to/Payspin

# 1. Install JS dependencies (monorepo)
pnpm install

# 2. Start Postgres + Redis
pnpm db:up

# 3. Backend environment
cp backend/.env.example backend/.env
# Edit backend/.env if needed — defaults work for local Docker ports (5435 / 6381)

# 4. Database schema
pnpm --filter @payspin/backend prisma:generate
pnpm --filter @payspin/backend prisma:migrate

# 5. (Optional) Build shared TS packages if API fails on imports
pnpm --filter @payspin/shared-types build
pnpm --filter @payspin/validators build
pnpm --filter @payspin/pisp-provider build
```

Verify Docker:

```bash
docker ps --filter name=payspin
# Expect: payspin-postgres (5435), payspin-redis (6381)
```

---

## Daily development (3 terminals)

### Terminal 1 — Database (leave running)

```bash
cd /path/to/Payspin
pnpm db:up
```

### Terminal 2 — API

```bash
cd /path/to/Payspin
pnpm --filter @payspin/backend dev
```

Wait for: `Nest application successfully started`

Health check:

```bash
curl http://localhost:3001/v1/health
# {"status":"ok","service":"payspin-api",...}
```

### Terminal 3 — Mobile app

```bash
cd /path/to/Payspin/mobile
flutter pub get
flutter run --dart-define=API_URL=http://localhost:3001/v1
```

**Hot reload:** `r` · **Hot restart:** `R` · **Quit:** `q`

### Optional — Payer web (when testing pay links in browser)

```bash
cd /path/to/Payspin
pnpm --filter @payspin/frontend dev
```

Open http://localhost:3000/{shortCode} after creating a link in the app.

---

## Mobile API URL by device

The app must reach the API on your Mac. Use the right base URL:

| Where you run the app | `API_URL` |
|----------------------|-----------|
| **iOS Simulator** | `http://localhost:3001/v1` |
| **Android Emulator** | `http://10.0.2.2:3001/v1` |
| **Physical iPhone/Android** | `http://<YOUR_MAC_LAN_IP>:3001/v1` |

Find Mac LAN IP: **System Settings → Network**, or `ipconfig getifaddr en0`

Example (physical device):

```bash
flutter run --dart-define=API_URL=http://192.168.1.42:3001/v1
```

---

## Test account (no seed user)

Register in the app or via API:

```bash
curl -X POST http://localhost:3001/v1/auth/register \
  -H 'Content-Type: application/json' \
  -d '{"email":"test@payspin.dev","password":"password123","displayName":"Test User"}'
```

Password must be **at least 8 characters**.

Login:

```bash
curl -X POST http://localhost:3001/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"test@payspin.dev","password":"password123"}'
```

Typical flow in the app:

1. Register / login  
2. Display name (if empty)  
3. Add IBAN (S08)  
4. Create link → share → open payer URL on web  

---

## Port reference

| Port | Service | If busy |
|------|---------|---------|
| **3001** | Nest API | See [Troubleshooting — port 3001](#port-3001-in-use) |
| **3000** | Next.js payer web | Change in `frontend/package.json` or stop other app |
| **5435** | Postgres (host) | `lsof -i :5435` — often old Postgres on 5432/5433 |
| **6381** | Redis (host) | `lsof -i :6381` |

`backend/.env` must match Docker:

```env
DATABASE_URL="postgresql://payspin:payspin_dev@localhost:5435/payspin?schema=public"
REDIS_URL="redis://localhost:6381"
PORT=3001
PAYER_WEB_URL="http://localhost:3000"
```

---

## Useful commands

```bash
# Stop database containers
pnpm db:down

# Prisma Studio (browse DB in browser)
pnpm --filter @payspin/backend prisma:studio

# Flutter tests
cd mobile && flutter test

# Flutter analyze
cd mobile && flutter analyze

# Backend typecheck
pnpm --filter @payspin/backend typecheck

# Run all workspace builds
pnpm build
```

---

## Troubleshooting

### App stuck on “Saving…” or “Loading your account…”

**Cause:** API not reachable (backend down, wrong `API_URL`, or request hanging).

**Fix:**

1. Confirm health: `curl http://localhost:3001/v1/health`
2. Start backend: `pnpm --filter @payspin/backend dev`
3. Hot restart Flutter: `R`
4. On device, use Mac LAN IP, not `localhost`

The mobile client times out after **15 seconds** and should show a clear error if the API is down.

### Port 3001 in use

```bash
lsof -i :3001
kill -9 <PID>
pnpm --filter @payspin/backend dev
```

Error in logs: `EADDRINUSE: address already in use :::3001` — only **one** backend instance should run.

### Prisma `P1000` (authentication failed)

**Cause:** `DATABASE_URL` points at wrong host/port/credentials (e.g. system Postgres on 5432 instead of Docker on **5435**).

**Fix:**

1. `pnpm db:up`
2. Ensure `backend/.env` uses port **5435** as in `.env.example`
3. `pnpm --filter @payspin/backend prisma:migrate`

### Docker Postgres won’t start

```bash
pnpm db:down
docker volume rm payspin_pg_data   # ⚠️ wipes local DB data
pnpm db:up
pnpm --filter @payspin/backend prisma:migrate
```

### `pnpm install` / workspace package errors

From repo root:

```bash
pnpm install
pnpm --filter @payspin/shared-types build
pnpm --filter @payspin/validators build
pnpm --filter @payspin/pisp-provider build
```

### iOS build / CocoaPods

```bash
cd mobile/ios && pod install && cd ..
flutter clean && flutter pub get && flutter run --dart-define=API_URL=http://localhost:3001/v1
```

### Yapily / open banking (PIS + AIS)

**Without credentials** (`YAPILY_APP_KEY` / `YAPILY_APP_SECRET` empty), the API uses in-process **sandbox gateways**: payer flow redirects to `/{shortCode}/callback?paymentId=…` and auto-completes on `POST /pay/:code/complete`. Register, manual IBAN, links, and mobile app work unchanged.

**With credentials** (from [Yapily Console](https://console.yapily.com/)):

1. Copy Application ID and Secret into `backend/.env`
2. Set `YAPILY_DEFAULT_INSTITUTION` (sandbox: `yapily-mock` or UK `modelo-sandbox`)
3. Set `YAPILY_DEFAULT_COUNTRY` (e.g. `NL`)
4. Optional: `YAPILY_WEBHOOK_SECRET` + expose `POST /v1/webhooks/yapily` via ngrok for payment status events

Payer flow (two-step, per [Yapily docs](https://docs.yapily.com/payments/tutorial-single-payment)):

1. `POST /v1/pay/:code/initiate` → `redirectUrl` (bank authorisation)
2. User returns to payer web callback with `consent` query param
3. Payer web calls `POST /v1/pay/:code/complete` with `{ paymentId, consentToken }`
4. Poll `GET /v1/pay/:code/status/:paymentId`

AIS (verify bank account, optional for mobile Phase 2):

- `GET /v1/open-banking/institutions?country=NL`
- `POST /v1/bank-accounts/connect` → `authorisationUrl`
- `POST /v1/bank-accounts/connect/complete` with `{ connectionId, consentToken }`

Modelo sandbox login (UK testing): username/password `mits` / `mits`.

```bash
pnpm --filter @payspin/backend test
pnpm --filter @payspin/pisp-provider build
```

---

## Stopping everything

```bash
# Ctrl+C in backend / frontend / flutter terminals

pnpm db:down          # stop Postgres + Redis containers
```

---

## Related docs

| Doc | Topic |
|-----|--------|
| [backend-architecture.md](./backend-architecture.md) | API modules, auth, webhooks |
| [payspin-solution-architecture.md](./payspin-solution-architecture.md) | End-to-end system |
| [wireframe-spec.md](./wireframe-spec.md) | Mobile screens & design tokens |
| [../wireframes/index.html](../wireframes/index.html) | Interactive wireframe gallery |
| [../../mobile/IMPLEMENTATION_TRACKER.md](../../mobile/IMPLEMENTATION_TRACKER.md) | Mobile feature status |
| [../../backend/README.md](../../backend/README.md) | API module list |
| [../../mobile/README.md](../../mobile/README.md) | Flutter setup summary |

---

## Quick checklist before demo

- [ ] `docker ps` shows `payspin-postgres` and `payspin-redis`
- [ ] `curl http://localhost:3001/v1/health` returns `"status":"ok"`
- [ ] Flutter launched with correct `API_URL` for your device
- [ ] Registered user + IBAN saved
- [ ] (Optional) `pnpm --filter @payspin/frontend dev` for payer web

*Last updated: May 2026*
