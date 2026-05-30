#!/usr/bin/env bash
# Live verification of the P0 payment-link state machine against a running API.
set -uo pipefail
API="${API_URL:-http://localhost:3001/v1}"
PASS=0; FAIL=0
ok()   { echo "  PASS: $1"; PASS=$((PASS+1)); }
bad()  { echo "  FAIL: $1 (got: $2)"; FAIL=$((FAIL+1)); }

EMAIL="p0-$(date +%s)@payspin.test"
TOKEN=$(curl -sS -X POST "$API/auth/register" -H 'Content-Type: application/json' \
  -d "{\"email\":\"$EMAIL\",\"password\":\"E2eTestPass123!\",\"displayName\":\"P0\"}" | jq -r .accessToken)
curl -sS -X POST "$API/bank-accounts" -H 'Content-Type: application/json' -H "Authorization: Bearer $TOKEN" \
  -d '{"iban":"DE89370400440532013000","accountHolder":"P0 User","bankName":"Sandbox"}' >/dev/null

mklink() { # args: json -> echoes shortCode
  curl -sS -X POST "$API/links" -H 'Content-Type: application/json' -H "Authorization: Bearer $TOKEN" -d "$1" | jq -r .shortCode
}
code()  { curl -sS -o /dev/null -w '%{http_code}' "$@"; }
field() { curl -sS "$@" | jq -r "$1"; shift; }

echo "== Scenario 1: SINGLE blocks a parallel in-flight payment (409)"
SP=$(mklink '{"amountCents":2500,"linkType":"SINGLE"}')
curl -sS -X POST "$API/pay/$SP/initiate" -H 'Content-Type: application/json' -d '{}' >/dev/null
INFLIGHT=$(code -X POST "$API/pay/$SP/initiate" -H 'Content-Type: application/json' -d '{}')
[[ "$INFLIGHT" == "409" ]] && ok "second in-flight initiate on SINGLE -> 409" || bad "in-flight 409" "$INFLIGHT"

echo "== Scenario 1b: SINGLE completes once, settles, status polls, then not-active"
S1=$(mklink '{"amountCents":2500,"linkType":"SINGLE"}')
PID=$(curl -sS -X POST "$API/pay/$S1/initiate" -H 'Content-Type: application/json' -d '{}' | jq -r .paymentId)
ST=$(curl -sS -X POST "$API/pay/$S1/complete" -H 'Content-Type: application/json' -d "{\"paymentId\":\"$PID\"}" | jq -r .status)
[[ "$ST" == "COMPLETED" ]] && ok "single payment completes" || bad "single completes" "$ST"
C2=$(code -X POST "$API/pay/$S1/initiate" -H 'Content-Type: application/json' -d '{}')
[[ "$C2" == "400" ]] && ok "initiate on SETTLED SINGLE -> 400 (not active)" || bad "settled initiate 400" "$C2"
PST=$(curl -sS "$API/pay/$S1/status/$PID" | jq -r .status)
[[ "$PST" == "COMPLETED" ]] && ok "status poll after settle works" || bad "status poll" "$PST"
VST=$(curl -sS "$API/pay/$S1" | jq -r .status)
[[ "$VST" == "SETTLED" ]] && ok "public view shows SETTLED" || bad "public view settled" "$VST"

echo "== Scenario 2: double-complete is a no-op (no double count)"
DC=$(code -X POST "$API/pay/$S1/complete" -H 'Content-Type: application/json' -d "{\"paymentId\":\"$PID\"}")
[[ "$DC" == "400" || "$DC" == "404" ]] && ok "re-complete settled link rejected ($DC)" || bad "re-complete rejected" "$DC"

echo "== Scenario 3: MULTI accepts up to maxUses then settles"
M1=$(mklink '{"amountCents":1000,"linkType":"MULTI","maxUses":2}')
for i in 1 2; do
  P=$(curl -sS -X POST "$API/pay/$M1/initiate" -H 'Content-Type: application/json' -d '{}' | jq -r .paymentId)
  R=$(curl -sS -X POST "$API/pay/$M1/complete" -H 'Content-Type: application/json' -d "{\"paymentId\":\"$P\"}" | jq -r .status)
  [[ "$R" == "COMPLETED" ]] && ok "multi payment $i completes" || bad "multi $i" "$R"
done
M3=$(code -X POST "$API/pay/$M1/initiate" -H 'Content-Type: application/json' -d '{}')
[[ "$M3" == "400" ]] && ok "MULTI initiate after maxUses -> 400" || bad "maxUses block" "$M3"
MV=$(curl -sS "$API/pay/$M1" | jq -r .status)
[[ "$MV" == "SETTLED" ]] && ok "MULTI settles at maxUses" || bad "multi settled" "$MV"

echo "== Scenario 4: open-amount + validation"
OA=$(mklink '{"linkType":"SINGLE"}')
OAE=$(code -X POST "$API/pay/$OA/initiate" -H 'Content-Type: application/json' -d '{}')
[[ "$OAE" == "400" ]] && ok "open-amount requires amount -> 400" || bad "open-amount" "$OAE"
NEG=$(code -X POST "$API/pay/$OA/initiate" -H 'Content-Type: application/json' -d '{"amountCents":-5}')
[[ "$NEG" == "400" ]] && ok "negative amount rejected -> 400" || bad "neg amount" "$NEG"
OAP=$(curl -sS -X POST "$API/pay/$OA/initiate" -H 'Content-Type: application/json' -d '{"amountCents":500}' | jq -r .paymentId)
[[ -n "$OAP" && "$OAP" != "null" ]] && ok "open-amount with amount initiates" || bad "open-amount initiate" "$OAP"

echo "== Scenario 5: webhook valid + duplicate dedup"
EVID="evt-$(date +%s)"
W1=$(code -X POST "$API/webhooks/yapily" -H 'Content-Type: application/json' \
  -d "{\"id\":\"$EVID\",\"type\":\"payment.status\",\"paymentId\":\"$OAP\",\"status\":\"COMPLETED\"}")
[[ "$W1" == "201" || "$W1" == "200" ]] && ok "webhook accepted ($W1)" || bad "webhook accept" "$W1"
DUP=$(curl -sS -X POST "$API/webhooks/yapily" -H 'Content-Type: application/json' \
  -d "{\"id\":\"$EVID\",\"type\":\"payment.status\",\"paymentId\":\"$OAP\",\"status\":\"COMPLETED\"}" | jq -r '.duplicate // false')
[[ "$DUP" == "true" ]] && ok "duplicate webhook deduped" || bad "webhook dedup" "$DUP"

echo "== Scenario 6: unknown short code -> 404"
NF=$(code "$API/pay/doesnotexist1")
[[ "$NF" == "404" ]] && ok "unknown link -> 404" || bad "unknown 404" "$NF"

echo ""
echo "RESULT: $PASS passed, $FAIL failed"
[[ "$FAIL" == "0" ]]
