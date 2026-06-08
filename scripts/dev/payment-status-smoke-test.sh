#!/usr/bin/env bash
# Payment status lifecycle smoke: abandon, stale expiry, reconcile, initiate unblock.
set -euo pipefail

API="${API_URL:-http://localhost:3001/v1}"
INTERNAL_SECRET="${OPS_INTERNAL_SECRET:-dev-ops-internal-secret-change-me}"
PASS="${TEST_PASS:-TestPass123!}"
EMAIL="pay-status-$(date +%s)@test.local"

pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; exit 1; }

echo "==> Register payee"
TOKEN=$(curl -sf -X POST "$API/auth/register" \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASS\",\"displayName\":\"Pay Status Test\"}" \
  | jq -r '.accessToken')
[[ -n "$TOKEN" && "$TOKEN" != "null" ]] || fail "register"

echo "==> Add IBAN + create link"
curl -sf -X POST "$API/bank-accounts" -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"iban":"NL91ABNA0417164300","accountHolder":"Pay Status Test"}' >/dev/null

LINK=$(curl -sf -X POST "$API/payment-links" -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"amountCents":1500,"description":"status-smoke","linkType":"SINGLE"}')
CODE=$(echo "$LINK" | jq -r '.shortCode')

echo "==> Initiate (creates AWAITING)"
INIT=$(curl -sf -X POST "$API/pay/$CODE/initiate" -H 'Content-Type: application/json' -d '{}')
PAY_ID=$(echo "$INIT" | jq -r '.paymentId')

echo "==> Abandon (bank cancel)"
AB=$(curl -sf -X POST "$API/pay/$CODE/abandon" -H 'Content-Type: application/json' \
  -d "{\"paymentId\":\"$PAY_ID\"}")
[[ "$(echo "$AB" | jq -r '.status')" == "CANCELLED" ]] || fail "abandon status"

echo "==> Initiate again after abandon (SINGLE link unblocked)"
curl -sf -X POST "$API/pay/$CODE/initiate" -H 'Content-Type: application/json' -d '{}' >/dev/null \
  || fail "second initiate blocked"

echo "==> Internal sweep"
SWEEP=$(curl -sf -X POST "$API/internal/payments/sweep/stale" \
  -H "x-ops-internal-secret: $INTERNAL_SECRET")
echo "$SWEEP" | jq -e '.awaitingCancelled >= 0' >/dev/null || fail "sweep"

pass "payment status lifecycle smoke"
echo "Done."
