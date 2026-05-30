# Yapily Console setup (Payspin)

Use [Yapily Console → Applications](https://console.yapily.com/applications).

## 1. Create application

| Field | Value |
|-------|--------|
| Name | `Payspin` (or `Payspin Dev`) |
| Environment | **Sandbox** for local dev |

## 2. Redirect URIs (required for PIS + AIS)

Add these callback URLs on the application:

```
http://localhost:3000/*/callback
http://localhost:3001/v1/bank-accounts/connect/callback
```

Payer web uses `PAYER_WEB_URL` + `/{shortCode}/callback?paymentId=…` (see `backend/.env`).

## 3. API credentials

From the application **Credentials** tab copy:

- **Application ID** → `YAPILY_APP_KEY` in `backend/.env`
- **Application Secret** → `YAPILY_APP_SECRET`

## 4. Webhooks (optional for local)

For payment status without polling:

1. Console → Webhooks → add endpoint: `https://<ngrok-host>/v1/webhooks/yapily`
2. Copy signing secret → `YAPILY_WEBHOOK_SECRET`

Local dev works without webhooks (sandbox completes via `POST /pay/:code/complete`).

## 5. Register a sandbox bank (required for Direct apps)

On **Applications → Payspin → Connected Institutions**:

1. **Add Institutions** → search `modelo-sandbox` → **Add selected**
2. Click **Register** → **Yes, Preconfigured Credentials**

(`yapily-mock` needs manual OB certificates; **Modelo Sandbox** is the recommended preconfigured sandbox per [Yapily Get Started](https://docs.yapily.com/getting-started/get-started).)

Set default institution:

```env
YAPILY_DEFAULT_INSTITUTION="modelo-sandbox"
```

UK test login after authorisation: `mits` / `mits`.

## 6. `backend/.env`

```env
YAPILY_APP_KEY="<Application UUID>"
YAPILY_APP_SECRET="<Application Secret>"
YAPILY_WEBHOOK_SECRET="<optional>"
YAPILY_DEFAULT_INSTITUTION="modelo-sandbox"
YAPILY_DEFAULT_COUNTRY="GB"
PAYER_WEB_URL="http://localhost:3000"
API_BASE_URL="http://localhost:3001"
```

Restart API after updating env:

```bash
pnpm --filter @payspin/backend dev
```

## 7. Smoke test

```bash
curl -u "$YAPILY_APP_KEY:$YAPILY_APP_SECRET" https://api.yapily.com/institutions?country=NL
```

UK sandbox bank (Modelo): institution `modelo-sandbox`, login `mits` / `mits`.

## Browser automation

- **Browser MCP extension**: click the extension → **Connect** on the tab you use for Console.
- **Cursor built-in browser**: already opens Console; sign in with **email + password** (avoid Google passkey if it fails).

After login, ask the agent to continue on `/applications` to copy keys into `.env`.
