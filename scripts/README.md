# Payspin scripts

## Development CLI (`payspin-dev`)

Orchestrates local Postgres, Redis, API, payer web, and optional Flutter.

```bash
# From repo root (first time)
./scripts/dev/payspin-dev setup

# Daily: database + API in background
./scripts/dev/payspin-dev start

# With payer web
./scripts/dev/payspin-dev start --web

# Flutter in this terminal (iOS simulator)
./scripts/dev/payspin-dev start --mobile

# Physical device (uses Mac LAN IP for API_URL)
./scripts/dev/payspin-dev start --mobile --target device

# Status & health
./scripts/dev/payspin-dev status

# Tail API logs
./scripts/dev/payspin-dev logs api

# Stop API only
./scripts/dev/payspin-dev stop

# Stop everything including Docker
./scripts/dev/payspin-dev stop --all

# Restart API (+ web if it was running with --web)
./scripts/dev/payspin-dev restart --web --force-ports

# Prerequisites check
./scripts/dev/payspin-dev doctor
```

### pnpm shortcuts

```bash
pnpm dev:setup
pnpm dev:start
pnpm dev:start:web
pnpm dev:stop
pnpm dev:restart
pnpm dev:status
pnpm dev:logs
pnpm dev:doctor
```

### State files

| Path | Purpose |
|------|---------|
| `.payspin/pids/` | PID files for background API / web |
| `.payspin/logs/` | `api.log`, `web.log` |

These directories are gitignored.

See also: [Local development runbook](../resources/docs/local-development-runbook.md).
