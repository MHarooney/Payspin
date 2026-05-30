#!/usr/bin/env bash
# End-to-end: provision Hetzner (if token set) + deploy API stack.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

if [[ -n "${HCLOUD_TOKEN:-}" ]]; then
  "$ROOT/infrastructure/hetzner/provision.sh"
fi

"$ROOT/infrastructure/hetzner/deploy.sh"
