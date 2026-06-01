#!/usr/bin/env bash
# Serve Payspin Prototype.html for browser MCP / local visual QA.
# Same content as https://claude.ai/design/p/0e804e64-9500-4d7e-9fb9-598d971d0b82?file=Payspin+Prototype.html
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PORT="${PORT:-8765}"
DIR="$ROOT/resources/Payspin Design System"
echo "Payspin prototype: http://localhost:${PORT}/Payspin%20Prototype.html"
echo "Press Ctrl+C to stop."
cd "$DIR"
exec python3 -m http.server "$PORT"
