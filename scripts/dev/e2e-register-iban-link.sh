#!/usr/bin/env bash
# E2E: register → add IBAN → create payment link
set -euo pipefail

API="${API_URL:-http://localhost:3001/v1}"
EMAIL="e2e-$(date +%s)@payspin.test"
PASSWORD="E2eTestPass123!"
IBAN="DE89370400440532013000"

echo "==> API: $API"
echo "==> Register: $EMAIL"

REGISTER=$(curl -sS -w "\n%{http_code}" -X POST "$API/auth/register" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\",\"displayName\":\"E2E User\"}")

REG_BODY=$(echo "$REGISTER" | sed '$d')
REG_CODE=$(echo "$REGISTER" | tail -1)
echo "    HTTP $REG_CODE"
if [[ "$REG_CODE" != "201" && "$REG_CODE" != "200" ]]; then
  echo "$REG_BODY" | jq . 2>/dev/null || echo "$REG_BODY"
  exit 1
fi

TOKEN=$(echo "$REG_BODY" | jq -r '.accessToken')
USER_ID=$(echo "$REG_BODY" | jq -r '.user.id')
echo "    userId: $USER_ID"

echo "==> Add bank account (manual IBAN)"
BANK=$(curl -sS -w "\n%{http_code}" -X POST "$API/bank-accounts" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{\"iban\":\"$IBAN\",\"accountHolder\":\"E2E Test User\",\"bankName\":\"Modelo Sandbox\"}")

BANK_BODY=$(echo "$BANK" | sed '$d')
BANK_CODE=$(echo "$BANK" | tail -1)
echo "    HTTP $BANK_CODE"
if [[ "$BANK_CODE" != "201" && "$BANK_CODE" != "200" ]]; then
  echo "$BANK_BODY" | jq . 2>/dev/null || echo "$BANK_BODY"
  exit 1
fi

ACCOUNT_ID=$(echo "$BANK_BODY" | jq -r '.id')
IBAN_LAST4=$(echo "$BANK_BODY" | jq -r '.ibanLast4')
echo "    accountId: $ACCOUNT_ID (…$IBAN_LAST4)"

echo "==> Create payment link"
LINK=$(curl -sS -w "\n%{http_code}" -X POST "$API/links" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"amountCents":2500,"currency":"EUR","description":"E2E coffee","linkType":"SINGLE","expiresInDays":7}')

LINK_BODY=$(echo "$LINK" | sed '$d')
LINK_CODE=$(echo "$LINK" | tail -1)
echo "    HTTP $LINK_CODE"
if [[ "$LINK_CODE" != "201" && "$LINK_CODE" != "200" ]]; then
  echo "$LINK_BODY" | jq . 2>/dev/null || echo "$LINK_BODY"
  exit 1
fi

SHORT=$(echo "$LINK_BODY" | jq -r '.shortCode')
LINK_ID=$(echo "$LINK_BODY" | jq -r '.id')
PAYER_WEB="${PAYER_WEB_URL:-http://localhost:3000}"

echo ""
echo "=== E2E SUCCESS ==="
echo "Email:       $EMAIL"
echo "Password:    $PASSWORD"
echo "Bank:        …$IBAN_LAST4 ($ACCOUNT_ID)"
echo "Link ID:     $LINK_ID"
echo "Short code:  $SHORT"
echo "Pay URL:     $PAYER_WEB/$SHORT"
echo ""
echo "$LINK_BODY" | jq '{id, shortCode, amountCents, currency, description, status, payUrl: ("'"$PAYER_WEB"'/" + .shortCode)}'
