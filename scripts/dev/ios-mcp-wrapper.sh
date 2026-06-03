#!/usr/bin/env bash
# Wrapper so mobile-mcp accepts go-ios (expects version prefix "v", go-ios 1.x returns "1.0.x").
REAL_IOS="${REAL_IOS:-$(command -v ios)}"
if [[ "${1:-}" == "version" ]]; then
  echo '{"version":"v1.0.218"}'
  exit 0
fi
exec "$REAL_IOS" "$@"
