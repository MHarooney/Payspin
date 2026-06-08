#!/usr/bin/env bash
# Full ops portal smoke test against production (or any BASE URL).
set -euo pipefail

BASE="${OPS_API_URL:-https://ops.payspin.io/admin/v1}"
WEB="${OPS_WEB_URL:-https://ops.payspin.io}"
EMAIL="${ADMIN_EMAIL:-admin@payspin.app}"
PASSWORD="${ADMIN_PASSWORD:-PayspinOps!2026}"

pass=0
fail=0
warn=0

ok() { echo "  ✓ $1"; pass=$((pass + 1)); }
bad() { echo "  ✗ $1"; fail=$((fail + 1)); }
note() { echo "  ~ $1"; warn=$((warn + 1)); }

assert_code() {
  local label="$1" expected="$2" actual="$3"
  if [[ "$actual" == "$expected" ]]; then ok "$label ($actual)"; else bad "$label expected $expected got $actual"; fi
}

assert_json_field() {
  local label="$1" json="$2" jq_expr="$3"
  if echo "$json" | jq -e "$jq_expr" >/dev/null 2>&1; then ok "$label"; else bad "$label — jq: $jq_expr"; fi
}

echo "==> Ops cloud smoke test"
echo "    API: $BASE"
echo "    WEB: $WEB"
echo ""

echo "==> 1. Public UI routes (SSR)"
for path in /login / /transactions /users /circles /config /audit /system /compliance /reports /data/schema /data/tables; do
  code=$(curl -s -o /dev/null -w '%{http_code}' "$WEB$path")
  assert_code "GET $path" "200" "$code"
done

echo ""
echo "==> 2. Auth edge cases"
assert_code "GET /auth/me without token" "401" "$(curl -s -o /dev/null -w '%{http_code}' "$BASE/auth/me")"
assert_code "POST /auth/login wrong password" "401" "$(curl -s -o /dev/null -w '%{http_code}' -X POST "$BASE/auth/login" -H 'Content-Type: application/json' -d '{"email":"admin@payspin.app","password":"wrong"}')"

empty_code=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$BASE/auth/login" -H 'Content-Type: application/json' -d '{}')
if [[ "$empty_code" == "400" || "$empty_code" == "422" ]]; then ok "POST /auth/login empty body ($empty_code)"; else bad "POST /auth/login empty body expected 400/422 got $empty_code"; fi

login_res=$(curl -s -X POST "$BASE/auth/login" -H 'Content-Type: application/json' -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")
TOKEN=$(echo "$login_res" | jq -r '.accessToken // empty')
if [[ -n "$TOKEN" && "$TOKEN" != "null" ]]; then ok "POST /auth/login success"; else bad "POST /auth/login — $login_res"; exit 1; fi

auth() { curl -s -H "Authorization: Bearer $TOKEN" "$@"; }

me=$(auth "$BASE/auth/me")
assert_json_field "GET /auth/me email" "$me" '.email == "admin@payspin.app"'
assert_json_field "GET /auth/me role SUPER_ADMIN" "$me" '.role == "SUPER_ADMIN"'

echo ""
echo "==> 3. Dashboard (Postgres-backed KPIs)"
for period in today week month; do
  kpis=$(auth "$BASE/dashboard/kpis?period=$period")
  assert_json_field "dashboard/kpis period=$period" "$kpis" ".period == \"$period\" and (.kpis | length) == 5"
done

vol=$(auth "$BASE/dashboard/volume?period=week")
assert_json_field "dashboard/volume week" "$vol" '.points | length >= 1'

alerts=$(auth "$BASE/dashboard/alerts")
assert_json_field "dashboard/alerts array" "$alerts" '. | type == "array"'

in_flight=$(echo "$(auth "$BASE/dashboard/kpis?period=today")" | jq -r '.kpis[] | select(.label=="Funds in Flight") | .value')
if [[ "$in_flight" =~ ^€ ]]; then ok "Funds in Flight formatted ($in_flight)"; else bad "Funds in Flight missing euro format: $in_flight"; fi

echo ""
echo "==> 4. Transactions"
tx_list=$(auth "$BASE/transactions?pageSize=10")
assert_json_field "transactions paginated" "$tx_list" '(.items | type == "array") and (.total >= 0)'
tx_id=$(echo "$tx_list" | jq -r '.items[0].id // empty')
if [[ -n "$tx_id" ]]; then
  assert_json_field "transaction detail" "$(auth "$BASE/transactions/$tx_id")" ".id == \"$tx_id\""
else note "no transactions in DB"
fi

echo ""
echo "==> 5. Users & circles"
users_list=$(auth "$BASE/users?limit=5")
assert_json_field "users list" "$users_list" '.items | type == "array"'
user_id=$(echo "$users_list" | jq -r '.items[0].id // empty')
if [[ -n "$user_id" ]]; then
  assert_json_field "user detail" "$(auth "$BASE/users/$user_id")" ".id == \"$user_id\" and (.paymentCount >= 0)"
else note "no users in DB"
fi
circle_id=$(auth "$BASE/circles?limit=1" | jq -r '.items[0].id // empty')
if [[ -n "$circle_id" ]]; then
  assert_json_field "circle detail" "$(auth "$BASE/circles/$circle_id")" ".id == \"$circle_id\""
else note "no circles in DB"
fi

echo ""
echo "==> 6. System health"
health=$(auth "$BASE/system/health")
assert_json_field "system health overall" "$health" '.overall != null and (.services | length) >= 4'
pg=$(echo "$health" | jq -r '.services[] | select(.name=="PostgreSQL") | .status')
[[ "$pg" == "ok" ]] && ok "PostgreSQL ok" || bad "PostgreSQL status=$pg"

echo ""
echo "==> 7. Config, kill switch, audit, search"
assert_json_field "feature flags" "$(auth "$BASE/config/flags")" '. | type == "array"'
assert_json_field "platform config" "$(auth "$BASE/config/platform")" '. | type == "array"'
assert_json_field "kill-switch" "$(auth "$BASE/kill-switch")" 'has("active")'
assert_json_field "audit log" "$(auth "$BASE/audit?limit=3")" '.items | type == "array"'
assert_json_field "global search" "$(auth "$BASE/search?q=pay")" '. | type == "array"'

echo ""
echo "==> 8. Validation (expect 400)"
assert_code "invalid dashboard period" "400" "$(auth -o /dev/null -w '%{http_code}' "$BASE/dashboard/kpis?period=7d")"
assert_code "kill switch short reason" "400" "$(auth -o /dev/null -w '%{http_code}' -X POST "$BASE/kill-switch" -H 'Content-Type: application/json' -d '{"active":true,"reason":"short"}')"

echo ""
echo "==> 9. Phase 2 routes"
for ep in compliance disputes finance/exceptions messages reports app-controls; do
  assert_code "GET /$ep" "200" "$(auth -o /dev/null -w '%{http_code}' "$BASE/$ep")"
done

echo ""
echo "==> 10. Data explorer"
schema=$(auth "$BASE/data/schema")
assert_json_field "data/schema models" "$schema" '(.models | length) >= 10'
tables=$(auth "$BASE/data/tables")
assert_json_field "data/tables list" "$tables" '(.tables | type == "array") and (.tables | length) >= 1'
rows=$(auth "$BASE/data/tables/users/rows?pageSize=3")
assert_json_field "data/tables/users/rows paginated" "$rows" '(.rows | type == "array") and (.total >= 0)'
if echo "$rows" | jq -e '.rows[] | select(.passwordHash != "***REDACTED***")' >/dev/null 2>&1; then
  bad "passwordHash not redacted in users row preview"
else
  ok "passwordHash redacted in users row preview"
fi
assert_code "data/tables invalid key" "400" "$(auth -o /dev/null -w '%{http_code}' "$BASE/data/tables/not_a_table/rows")"

echo ""
echo "==> 11. Security"
assert_code "invalid JWT" "401" "$(curl -s -o /dev/null -w '%{http_code}' -H 'Authorization: Bearer bad.token' "$BASE/dashboard/kpis")"

echo ""
echo "========================================"
echo "PASS: $pass  FAIL: $fail  WARN: $warn"
if [[ "$fail" -gt 0 ]]; then exit 1; fi
