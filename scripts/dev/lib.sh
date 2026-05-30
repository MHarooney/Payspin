#!/usr/bin/env bash
# Payspin dev scripts — shared library
# shellcheck disable=SC2034

set -euo pipefail

# ── Paths ─────────────────────────────────────────────────────────────────────
if [[ -z "${PAYSPIN_ROOT:-}" ]]; then
  PAYSPIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi
export PAYSPIN_ROOT

PAYSPIN_STATE_DIR="${PAYSPIN_ROOT}/.payspin"
PAYSPIN_PID_DIR="${PAYSPIN_STATE_DIR}/pids"
PAYSPIN_LOG_DIR="${PAYSPIN_STATE_DIR}/logs"
DOCKER_COMPOSE_FILE="${PAYSPIN_ROOT}/infrastructure/docker/docker-compose.yml"
BACKEND_ENV="${PAYSPIN_ROOT}/backend/.env"
BACKEND_ENV_EXAMPLE="${PAYSPIN_ROOT}/backend/.env.example"

API_PORT="${PAYSPIN_API_PORT:-3001}"
WEB_PORT="${PAYSPIN_WEB_PORT:-3000}"
PG_PORT="${PAYSPIN_PG_PORT:-5435}"
REDIS_PORT="${PAYSPIN_REDIS_PORT:-6381}"
API_HEALTH_URL="http://localhost:${API_PORT}/v1/health"

# ── Colors (respect NO_COLOR) ─────────────────────────────────────────────────
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  C_RESET='\033[0m'
  C_BOLD='\033[1m'
  C_DIM='\033[2m'
  C_RED='\033[31m'
  C_GREEN='\033[32m'
  C_YELLOW='\033[33m'
  C_BLUE='\033[34m'
  C_CYAN='\033[36m'
else
  C_RESET='' C_BOLD='' C_DIM='' C_RED='' C_GREEN='' C_YELLOW='' C_BLUE='' C_CYAN=''
fi

log_info()    { printf '%b[INFO]%b %s\n'    "$C_BLUE"  "$C_RESET" "$*"; }
log_ok()      { printf '%b[OK]%b %s\n'      "$C_GREEN" "$C_RESET" "$*"; }
log_warn()    { printf '%b[WARN]%b %s\n'  "$C_YELLOW" "$C_RESET" "$*"; }
log_error()   { printf '%b[ERROR]%b %s\n' "$C_RED"   "$C_RESET" "$*" >&2; }
log_step()    { printf '\n%b▸ %s%b\n' "$C_BOLD" "$*" "$C_RESET"; }

die() { log_error "$*"; exit 1; }

ensure_state_dirs() {
  mkdir -p "$PAYSPIN_PID_DIR" "$PAYSPIN_LOG_DIR"
}

pid_file() { echo "${PAYSPIN_PID_DIR}/$1.pid"; }
log_file() { echo "${PAYSPIN_LOG_DIR}/$1.log"; }

is_running() {
  local name="$1"
  local pf
  pf="$(pid_file "$name")"
  if [[ ! -f "$pf" ]]; then
    return 1
  fi
  local pid
  pid="$(<"$pf")"
  if kill -0 "$pid" 2>/dev/null; then
    return 0
  fi
  rm -f "$pf"
  return 1
}

save_pid() {
  local name="$1"
  local pid="$2"
  ensure_state_dirs
  echo "$pid" > "$(pid_file "$name")"
}

stop_process() {
  local name="$1"
  local pf
  pf="$(pid_file "$name")"
  if [[ ! -f "$pf" ]]; then
    return 0
  fi
  local pid
  pid="$(<"$pf")"
  if kill -0 "$pid" 2>/dev/null; then
    log_info "Stopping ${name} (pid ${pid})…"
    kill "$pid" 2>/dev/null || true
    local i=0
    while kill -0 "$pid" 2>/dev/null && [[ $i -lt 15 ]]; do
      sleep 0.5
      i=$((i + 1))
    done
    if kill -0 "$pid" 2>/dev/null; then
      kill -9 "$pid" 2>/dev/null || true
    fi
  fi
  rm -f "$pf"
}

free_port() {
  local port="$1"
  local pids
  pids="$(lsof -ti ":${port}" 2>/dev/null || true)"
  if [[ -n "$pids" ]]; then
    log_warn "Freeing port ${port} (pids: ${pids//$'\n'/ })"
    # shellcheck disable=SC2086
    kill -9 $pids 2>/dev/null || true
    sleep 0.5
  fi
}

require_cmd() {
  local cmd="$1"
  local hint="${2:-}"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    die "Required command not found: ${cmd}${hint:+ — $hint}"
  fi
}

require_docker() {
  require_cmd docker "Install Docker Desktop"
  docker info >/dev/null 2>&1 || die "Docker is not running. Start Docker Desktop."
}

api_url_for_target() {
  local target="${1:-ios}"
  case "$target" in
    ios|simulator|sim)     echo "http://localhost:${API_PORT}/v1" ;;
    android|emu|emulator)  echo "http://10.0.2.2:${API_PORT}/v1" ;;
    device|physical|lan)
      local ip
      ip="$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || true)"
      if [[ -z "$ip" ]]; then
        die "Could not detect LAN IP. Set PAYSPIN_API_URL manually."
      fi
      echo "http://${ip}:${API_PORT}/v1"
      ;;
    *)
      die "Unknown mobile target: ${target}. Use: ios | android | device"
      ;;
  esac
}

wait_for_health() {
  local url="${1:-$API_HEALTH_URL}"
  local max="${2:-60}"
  local i=0
  while [[ $i -lt $max ]]; do
    if curl -sf "$url" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
    i=$((i + 1))
  done
  return 1
}

docker_services_up() {
  docker compose -f "$DOCKER_COMPOSE_FILE" ps --status running -q 2>/dev/null | grep -q .
}
