# Agent workflows

Copy-checklist workflows for common Payspin tasks.

## 1. Local dev stack

```
- [ ] pnpm install
- [ ] ./scripts/dev/payspin-dev setup      # .env, docker DB, migrate
- [ ] ./scripts/dev/payspin-dev start --web
- [ ] curl http://localhost:3001/v1/health
- [ ] Optional: cd mobile && flutter run --dart-define=API_URL=http://localhost:3001/v1
```

Troubleshoot: `./scripts/dev/payspin-dev doctor`

## 2. New authenticated API endpoint

```
- [ ] Add/update Zod schema in packages/validators/
- [ ] Add DTO in packages/shared-types/ if needed
- [ ] Create use case in backend/src/application/use-cases/<feature>/
- [ ] Wire in controller under backend/src/interfaces/http/<feature>/
- [ ] Register providers in feature module; add module to http-api.module.ts
- [ ] If gateways needed: imports: [YapilyModule]
- [ ] Prisma migrate if schema changed
- [ ] Manual test via curl or e2e script
```

## 3. New payment / Yapily change

```
- [ ] Read resources/docs/yapily-console-setup.md
- [ ] Update gateway in backend/src/infrastructure/yapily/
- [ ] Ensure sandbox fallback when keys empty (local dev)
- [ ] Update payer callback in frontend/app/[code]/callback/
- [ ] Test: scripts/dev/e2e-register-iban-link.sh (API path)
- [ ] Production: public HTTPS URLs in Yapily Console
```

## 4. New mobile screen

```
- [ ] Add route in mobile/lib/app/router.dart
- [ ] Page under mobile/lib/presentation/<feature>/
- [ ] Use PayspinTheme / existing widgets
- [ ] Repository method if new API call needed
- [ ] Wire in injection.dart if new deps
- [ ] Widget test or integration_test route if critical path
```

## 5. Deploy backend (Hetzner)

```
- [ ] Hetzner account verified (accounts.hetzner.com)
- [ ] Project created → API token (Read & Write)
- [ ] export HCLOUD_TOKEN='...'
- [ ] ./infrastructure/hetzner/up.sh
- [ ] curl http://<server-ip>/v1/health
- [ ] Set Yapily keys in /opt/payspin/.env.production on server
- [ ] Point mobile: --dart-define=API_URL=http://<ip>/v1
```

See `infrastructure/hetzner/README.md`.

## 6. E2E smoke (API)

```bash
./scripts/dev/e2e-register-iban-link.sh
```

Creates test user, manual IBAN, payment link. Does not complete live iDEAL redirect.

## 7. Automated tests

```bash
pnpm test                              # turbo: builds packages, runs all suites
pnpm --filter @payspin/backend test    # backend only (node:test + tsx)
pnpm --filter @payspin/validators test # shared validators
cd mobile && flutter test              # mobile unit
```

CI runs install -> prisma generate -> build -> typecheck -> lint -> test on every
PR (`.github/workflows/ci.yml`).

Use `backend/test/helpers/fake-prisma.ts` (in-memory Prisma double) for use-case
unit tests instead of a live database.

### Covered edge cases (backend)

| Area | Cases |
|------|-------|
| Payment-link state | SINGLE settles once + blocks parallel; MULTI up to `maxUses` then settles; expired/cancelled blocked; status poll after settle |
| Idempotency | Double completion no-ops; webhook vs callback race never double-counts `useCount` |
| Webhooks | Missing/garbled status never marks paid; failed != completed; missing paymentId still acks |
| Payments | Open-amount requires amount; snapshot never stores a plaintext IBAN |
| Auth | Duplicate email (pre-check + P2002 race) -> 409; wrong password / unknown user -> generic message |
| Encryption | AES-256-GCM round-trip; fresh IV per call; tampered ciphertext rejected; bad key length rejected |
| Validators | IBAN checksum/country/length; amount bounds; payer + open-banking schemas; country code |

## 8. Before opening a PR

```
- [ ] pnpm typecheck (or turbo typecheck)
- [ ] pnpm test (all suites green)
- [ ] No .env or secrets in diff
- [ ] AGENTS.md / docs updated if architecture or workflows changed
```
