#!/usr/bin/env bash
# Start go-ios tunnel + port forward for mobile-mcp on a physical iPhone.
# WebDriverAgent must be running on the device (one-time Xcode setup — see below).
#
# Prerequisites:
#   npm install -g go-ios
#   git clone --depth 1 https://github.com/appium/WebDriverAgent.git ~/WebDriverAgent
#   Xcode → open ~/WebDriverAgent/WebDriverAgent.xcodeproj
#     → WebDriverAgentRunner target → unique Bundle ID + your Team → select iPhone → Test
#   curl http://localhost:8100/status   # should return JSON once WDA is up
#
# Usage (from repo root):
#   ./scripts/dev/ios-mobile-mcp-setup.sh start    # tunnel + forward (two background jobs)
#   ./scripts/dev/ios-mobile-mcp-setup.sh status   # ios list + WDA health
#   ./scripts/dev/ios-mobile-mcp-setup.sh stop     # kill tunnel/forward PIDs
set -euo pipefail

UDID="${IOS_DEVICE_UDID:-00008110-00060C6C3A83401E}"
PID_DIR="${TMPDIR:-/tmp}/payspin-mobile-mcp"
TUNNEL_PID="$PID_DIR/tunnel.pid"
FORWARD_PID="$PID_DIR/forward.pid"

mkdir -p "$PID_DIR"

cmd="${1:-status}"

stop_jobs() {
  for f in "$TUNNEL_PID" "$FORWARD_PID"; do
    if [[ -f "$f" ]] && kill -0 "$(cat "$f")" 2>/dev/null; then
      kill "$(cat "$f")" 2>/dev/null || true
      echo "Stopped $(basename "$f" .pid) (pid $(cat "$f"))"
    fi
    rm -f "$f"
  done
}

case "$cmd" in
  start)
    stop_jobs
    if ! command -v ios >/dev/null; then
      echo "Install go-ios: npm install -g go-ios" >&2
      exit 1
    fi
    echo "Starting ios tunnel (userspace) for ${UDID}..."
    ios tunnel start --userspace &
    echo $! >"$TUNNEL_PID"
    sleep 2
    echo "Starting ios forward 8100 → device:8100…"
    ios forward 8100 8100 &
    echo $! >"$FORWARD_PID"
    sleep 1
    echo "PIDs: tunnel=$(cat "$TUNNEL_PID") forward=$(cat "$FORWARD_PID")"
    echo "Verify: curl -s http://localhost:8100/status"
    ;;
  stop)
    stop_jobs
    ;;
  status)
    command -v ios >/dev/null && ios list || echo "go-ios not installed"
    if curl -sf --connect-timeout 2 http://localhost:8100/status >/dev/null; then
      echo "WebDriverAgent: OK (localhost:8100)"
    else
      echo "WebDriverAgent: not reachable — run WDA from Xcode (Test on WebDriverAgentRunner)"
    fi
    ;;
  *)
    echo "Usage: $0 {start|stop|status}" >&2
    exit 1
    ;;
esac
