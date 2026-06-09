#!/usr/bin/env bash
# Support-chat integration matrix (API-level rows).
# Local only. Hits consumer API :3001 and ops API :3002.
set -uo pipefail

API=http://localhost:3001/v1
OPS=http://localhost:3002/admin/v1
PG="postgresql://payspin:payspin_dev@localhost:5435/payspin"

PASS=0
FAIL=0
note() { printf '\n\033[1m%s\033[0m\n' "$1"; }
ok()   { PASS=$((PASS+1)); printf '  \033[32mPASS\033[0m %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  \033[31mFAIL\033[0m %s\n' "$1"; }
expect() { # expect <desc> <actual> <expected>
  if [ "$2" = "$3" ]; then ok "$1 ($2)"; else bad "$1 (got $2 want $3)"; fi
}

ts=$(date +%s)
jqf() { node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{const o=JSON.parse(s);const p=process.argv[1].split(".");let v=o;for(const k of p){v=v?.[k]}console.log(typeof v==="object"?JSON.stringify(v):v)}catch(e){console.log("")}})' "$1"; }

note "Auth: register user A + user B, login admin"
A_TOKEN=$(curl -s -X POST "$API/auth/register" -H 'content-type: application/json' \
  -d "{\"email\":\"a_${ts}@test.io\",\"password\":\"password123\",\"displayName\":\"User A\"}" | jqf accessToken)
B_TOKEN=$(curl -s -X POST "$API/auth/register" -H 'content-type: application/json' \
  -d "{\"email\":\"b_${ts}@test.io\",\"password\":\"password123\",\"displayName\":\"User B\"}" | jqf accessToken)
ADMIN_TOKEN=$(curl -s -X POST "$OPS/auth/login" -H 'content-type: application/json' \
  -d '{"email":"admin@payspin.app","password":"PayspinOps!2026"}' | jqf accessToken)
[ -n "$A_TOKEN" ] && ok "user A token" || bad "user A token"
[ -n "$B_TOKEN" ] && ok "user B token" || bad "user B token"
[ -n "$ADMIN_TOKEN" ] && ok "admin token" || bad "admin token"

AH=(-H "authorization: Bearer $A_TOKEN")
BH=(-H "authorization: Bearer $B_TOKEN")
MH=(-H "authorization: Bearer $ADMIN_TOKEN")
JSON=(-H 'content-type: application/json')

note "Row 17 — Unauthenticated -> 401"
code=$(curl -s -o /dev/null -w '%{http_code}' "$API/support/threads")
expect "GET /support/threads no JWT" "$code" "401"

note "Row 1 — Happy path: new thread (category PAYMENT, contextRef)"
THREAD=$(curl -s -X POST "$API/support/threads" "${AH[@]}" "${JSON[@]}" \
  -d '{"category":"PAYMENT","body":"My payment did not arrive","contextRef":"pay_abc123"}')
TID=$(echo "$THREAD" | jqf id)
[ -n "$TID" ] && ok "thread created id=$TID" || bad "thread created ($THREAD)"
cat=$(echo "$THREAD" | jqf category); expect "category stored" "$cat" "PAYMENT"
ctx=$(echo "$THREAD" | jqf contextRef); expect "contextRef stored (Row 13)" "$ctx" "pay_abc123"

note "Row 1 (ops) — thread visible to ops with unread"
OPS_LIST=$(curl -s "$OPS/messages" "${MH[@]}")
echo "$OPS_LIST" | grep -q "$TID" && ok "thread appears in ops list" || bad "thread in ops list"
 unread=$(curl -s "$OPS/messages/$TID" "${MH[@]}" | jqf unread)
expect "ops unread=true on new thread" "$unread" "true"

note "Row 6 — Empty body rejected -> 400"
code=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$API/support/threads/$TID/messages" "${AH[@]}" "${JSON[@]}" -d '{"body":""}')
expect "POST empty body" "$code" "400"

note "Row 7 — Max length (4001 chars) -> 400"
BIG=$(printf 'x%.0s' $(seq 1 4001))
code=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$API/support/threads/$TID/messages" "${AH[@]}" "${JSON[@]}" -d "{\"body\":\"$BIG\"}")
expect "POST 4001 chars" "$code" "400"

note "Row 5 — Ownership isolation: user B reads A's thread -> 404"
code=$(curl -s -o /dev/null -w '%{http_code}' "$API/support/threads/$TID" "${BH[@]}")
expect "user B GET A thread" "$code" "404"

note "Row 4 — Multi-message: user sends 2 more, admin replies 2"
curl -s -o /dev/null -X POST "$API/support/threads/$TID/messages" "${AH[@]}" "${JSON[@]}" -d '{"body":"Second user message"}'
curl -s -o /dev/null -X POST "$API/support/threads/$TID/messages" "${AH[@]}" "${JSON[@]}" -d '{"body":"Third user message"}'
curl -s -o /dev/null -X POST "$OPS/messages/threads/$TID/reply" "${MH[@]}" "${JSON[@]}" -d '{"body":"Admin reply one"}'
curl -s -o /dev/null -X POST "$OPS/messages/threads/$TID/reply" "${MH[@]}" "${JSON[@]}" -d '{"body":"Admin reply two"}'
DETAIL=$(curl -s "$API/support/threads/$TID" "${AH[@]}")
mcount=$(echo "$DETAIL" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{const o=JSON.parse(s);console.log((o.messages||[]).length)})')
expect "message count (1 create + 2 user + 2 admin = 5)" "$mcount" "5"
ordered=$(echo "$DETAIL" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{const o=JSON.parse(s);const m=o.messages||[];let asc=true;for(let i=1;i<m.length;i++){if(new Date(m[i].createdAt)<new Date(m[i-1].createdAt))asc=false}console.log(asc)})')
expect "messages ordered by createdAt asc" "$ordered" "true"

note "Row 2 — Admin reply sets userUnread; Row 19 — unread-count"
uc=$(curl -s "$API/support/unread-count" "${AH[@]}" | jqf count)
[ "$uc" -ge 1 ] 2>/dev/null && ok "unread-count >=1 after admin reply ($uc)" || bad "unread-count after reply ($uc)"

note "Row 18 — Notification row + FCM job on admin reply"
NOTIF=$(psql "$PG" -tAc \
  "select count(*) from notifications where type='support.reply';" 2>/dev/null | tr -d '[:space:]')
[ "${NOTIF:-0}" -ge 1 ] 2>/dev/null && ok "DB notification rows ($NOTIF)" || bad "DB notification rows ($NOTIF)"

note "Row 3 / 19 — user reads thread clears badge"
curl -s -o /dev/null -X PATCH "$API/support/threads/$TID/read" "${AH[@]}"
uc=$(curl -s "$API/support/unread-count" "${AH[@]}" | jqf count)
expect "unread-count after mark read" "$uc" "0"

note "Row 8 — Admin marks RESOLVED"
curl -s -o /dev/null -X PATCH "$OPS/messages/threads/$TID" "${MH[@]}" "${JSON[@]}" -d '{"status":"RESOLVED"}'
st=$(curl -s "$API/support/threads/$TID" "${AH[@]}" | jqf status)
expect "status RESOLVED" "$st" "RESOLVED"

note "Row 9 — Reopen on user message"
curl -s -o /dev/null -X POST "$API/support/threads/$TID/messages" "${AH[@]}" "${JSON[@]}" -d '{"body":"Actually still broken"}'
st=$(curl -s "$API/support/threads/$TID" "${AH[@]}" | jqf status)
expect "status reopened to OPEN" "$st" "OPEN"
unread=$(curl -s "$OPS/messages/$TID" "${MH[@]}" | jqf unread)
expect "admin unread=true after reopen" "$unread" "true"

note "Row 14 — Legacy seed rows (userId null) visible to ops, not to user"
LEGACY=$(psql "$PG" -tAc \
  "select id from support_threads where user_id is null limit 1;" 2>/dev/null | tr -d '[:space:]')
if [ -n "$LEGACY" ]; then
  curl -s "$OPS/messages" "${MH[@]}" | grep -q "$LEGACY" && ok "ops lists legacy thread" || bad "ops lists legacy thread"
  code=$(curl -s -o /dev/null -w '%{http_code}' "$API/support/threads/$LEGACY" "${AH[@]}")
  expect "consumer cannot access legacy thread" "$code" "404"
else
  bad "no legacy seed thread found"
fi

note "Row 5b — non-owner cannot send to A's thread -> 404"
code=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$API/support/threads/$TID/messages" "${BH[@]}" "${JSON[@]}" -d '{"body":"intruder"}')
expect "user B POST to A thread" "$code" "404"

printf '\n\033[1mRESULT: %d passed, %d failed\033[0m\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
