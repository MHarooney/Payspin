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

Production (`pay.payspin.io`, app `53b0d904-21b3-41a7-ba2b-e440ab460bf9`):

```
https://pay.payspin.io/v1/bank-accounts/connect/callback
https://pay.payspin.io/*/callback
```

Payer web uses `PAYER_WEB_URL` + `/{shortCode}/callback?paymentId=…` (see `backend/.env`).

## 3. API credentials

From the application **Credentials** tab copy:

- **Application ID** → `YAPILY_APP_KEY` in `backend/.env`
- **Application Secret** → `YAPILY_APP_SECRET`

## 4. Webhooks (required on production for PENDING → COMPLETED)

When the payer closes the browser before the bank settles, the only way the
payee's payment flips to `COMPLETED` is the Yapily webhook.

1. Console → Webhooks → add endpoint:
   - Local (via tunnel): `https://<ngrok-host>/v1/webhooks/yapily`
   - **Production:** `https://pay.payspin.io/v1/webhooks/yapily`
2. Subscribe to payment status events.
3. Copy the signing secret → server env `YAPILY_WEBHOOK_SECRET`
   (`/opt/payspin/.env.production`), then restart the API.

The endpoint verifies the `webhook-signature` HMAC (`YAPILY_WEBHOOK_SECRET`),
de-dupes via the `webhook_events` unique constraint, and enqueues to the
`yapily-webhooks` BullMQ queue. On a completing transition it also fires the
payee's in-app notification + FCM push (`notifications` queue).

Local dev works without webhooks (sandbox completes via `POST /pay/:code/complete`).

## 5. Register a sandbox bank (required for Direct apps)

On **Applications → Payspin → Connected Institutions**:

1. **Add Institutions** → search `modelo-sandbox` → **Add selected**
2. Click **Register** → **Yes, Preconfigured Credentials**

(`yapily-mock` needs manual OB certificates; **Modelo Sandbox** is the recommended preconfigured sandbox per [Yapily Get Started](https://docs.yapily.com/getting-started/get-started).)

Set default institution and optional per-country routing (Phase D — the backend
derives the country from the payee IBAN and picks the matching institution):

```env
YAPILY_DEFAULT_INSTITUTION="modelo-sandbox"
# Optional country → institution overrides (fall back to default when unset)
YAPILY_INSTITUTION_NL="modelo-sandbox"
YAPILY_INSTITUTION_DE="modelo-sandbox"
YAPILY_INSTITUTION_GB="modelo-sandbox"
```

> NL/DE live institutions (ING, ABN, Rabobank, Deutsche Bank, …) and
> `deutschebank-sandbox` require eIDAS certificates — register later; the
> defaults keep the sandbox journey working today.

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

## 8. Going live with real NL/DE banks (N26, ING, ABN AMRO, …)

**Current state (verified via API 2026-06-04):** app `53b0d904-21b3-41a7-ba2b-e440ab460bf9`
is **Type: `Direct`**. `GET /institutions` returns **only** `modelo-sandbox`.
Real banks fail to start a consent:

```
POST /account-auth-requests {"institutionId":"n26"}
→ 404 "Institution credentials not found for application '53b0d904…' and institution 'n26'"
```

`n26` exists in the catalog (LIVE, covers DE/NL/AT/FR/ES/IT, `credentialsType: OPEN_BANKING_NO_KEY`)
but a **Direct** app must register every live bank with its **own eIDAS QWAC/QSEAL
certificates** (Console → Certificates). That requires an AISP licence/agency.

### Recommended: convert to **Yapily Connect**

Yapily Connect uses Yapily's regulatory licence + certificates, so we don't need
our own certs — they add the institutions on our behalf and they become available
immediately. This **cannot** be self-served from a Direct app; raise it with Yapily.

> Channel: [Yapily support](https://support.yapily.com/hc/en-gb/requests/new)
> (Console → *Contact support*) or your account manager.

**Request template (copy/paste):**

```
Subject: Convert Direct app to Yapily Connect + enable NL/DE institutions

Hi Yapily team,

We'd like to move our application to Yapily Connect so we can connect live
accounts without holding our own eIDAS certificates.

  • Application name: Payspin
  • Application UUID: 53b0d904-21b3-41a7-ba2b-e440ab460bf9
  • Current type: Direct
  • Use case: AIS only (account verification / ownership for a P2P payment-link
    app — we are non-custodial, no funds held). PIS may follow later.

Please convert this app to Yapily Connect (or advise the correct app to use) and
enable the following live institutions for AIS:

  Netherlands: ING, ABN AMRO, Rabobank, bunq, SNS, ASN, Knab, Revolut, N26
  Germany:     N26, Deutsche Bank, Commerzbank, Sparkasse, DKB, ING-DiBa,
               Revolut, Postbank

Also confirm our OB redirect host. We currently use the default
https://auth.yapily.com/ and our AIS callback is
https://pay.payspin.io/v1/bank-accounts/connect/callback
(production). Let us know if a custom redirect or any allow-listing is required.

Thanks!
```

### Verify once enabled

Re-run the smoke check — DE/NL banks (incl. `n26`) should now appear:

```bash
AUTH=$(printf "$YAPILY_APP_KEY:$YAPILY_APP_SECRET" | base64)
curl -s -H "Authorization: Basic $AUTH" "https://api.yapily.com/institutions?country=NL" \
  | python3 -c "import sys,json;d=json.load(sys.stdin)['data'];print(len(d),'NL banks');[print(' ',i['id'],i['name']) for i in d]"
curl -s -H "Authorization: Basic $AUTH" "https://api.yapily.com/institutions?country=DE" \
  | python3 -c "import sys,json;d=json.load(sys.stdin)['data'];print(len(d),'DE banks')"
```

The mobile **Connect bank** screen already has a NL/DE/GB country selector and passes
the chosen `institutionId`, so users can pick N26 etc. the moment the list is non-empty.

## Browser automation

- **Browser MCP extension**: click the extension → **Connect** on the tab you use for Console.
- **Cursor built-in browser**: already opens Console; sign in with **email + password** (avoid Google passkey if it fails).

After login, ask the agent to continue on `/applications` to copy keys into `.env`.
