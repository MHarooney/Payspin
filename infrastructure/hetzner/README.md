# Hetzner Cloud — Payspin backend

Account: **payspin.app@gmail.com** only.

## Stack (verified locally)

| Component | Image |
|-----------|--------|
| API | `payspin/api:latest` (built from `backend/Dockerfile`) |
| Postgres 16 | internal network only |
| Redis 7 | internal network only |
| Caddy | HTTP `:80` → API `:3001` |

Health: `http://<server-ip>/v1/health` → `{"status":"ok","service":"payspin-api"}`

## Cheapest Hetzner MVP (~€3.49–3.99/mo)

- **CX23** (fallback CX22), **fsn1**, Ubuntu 24.04
- Firewall: TCP 22, 80, 443

## One-time: Hetzner Console

**Blocker:** New Payspin accounts may require **ID verification** before any project can be created.

1. [accounts.hetzner.com/account/verification](https://accounts.hetzner.com/account/verification) → **Continue** → iDenfy (physical ID + live selfie)
2. After verification is approved, [console.hetzner.com](https://console.hetzner.com) → **New project** → `payspin`
3. Project → **Security** → **API tokens** → Read & Write → copy token

## SSH key

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_payspin -C payspin.app@gmail.com
```

## Deploy (full pipeline)

```bash
export HCLOUD_TOKEN='your-token'
chmod +x infrastructure/hetzner/*.sh infrastructure/docker/publish.sh
./infrastructure/hetzner/up.sh
```

Or step by step:

```bash
./infrastructure/hetzner/provision.sh   # creates CX23 + firewall + SSH
./infrastructure/hetzner/deploy.sh      # builds image, streams to server, starts compose
```

If the server already exists:

```bash
export PAYSPIN_SERVER_IP='1.2.3.4'
./infrastructure/hetzner/deploy.sh
```

## Docker Hub (optional)

Logged in as **payspin** in Docker Desktop. Push when CLI auth works:

```bash
./infrastructure/docker/publish.sh
```

Deploy works **without** Hub push (image is streamed over SSH).

## Files

| Path | Purpose |
|------|---------|
| `backend/Dockerfile` | Production API image |
| `infrastructure/docker/docker-compose.prod.yml` | Server stack |
| `infrastructure/docker/Caddyfile` | Reverse proxy |
| `backend/.env.production.example` | Env template |
| `infrastructure/hetzner/provision.sh` | Hetzner server + firewall |
| `infrastructure/hetzner/deploy.sh` | Remote deploy |
| `infrastructure/hetzner/up.sh` | Provision + deploy |

## After deploy

- Set Yapily keys in `/opt/payspin/.env.production` on the server
- Point `API_BASE_URL` / `PAYER_WEB_URL` to your real domain when ready
- Mobile: `--dart-define=API_URL=https://api.yourdomain.com/v1`
