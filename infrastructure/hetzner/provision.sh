#!/usr/bin/env bash
# Provision minimal Payspin backend infrastructure on Hetzner Cloud.
# Requires: hcloud CLI, HCLOUD_TOKEN (Read & Write), billing enabled on account.
#
# Usage:
#   export HCLOUD_TOKEN='your-token'
#   ./infrastructure/hetzner/provision.sh
#
# See infrastructure/hetzner/README.md for console setup if you have no project yet.

set -euo pipefail

PROJECT_NAME="${HCLOUD_PROJECT_NAME:-payspin}"
SERVER_NAME="${HCLOUD_SERVER_NAME:-payspin-api}"
SSH_KEY_NAME="${HCLOUD_SSH_KEY_NAME:-payspin-deploy}"
FIREWALL_NAME="${HCLOUD_FIREWALL_NAME:-payspin-api}"
# Cheapest EU shared vCPU (Cost-Optimized). Fallback to cx22 if cx23 unavailable.
SERVER_TYPE="${HCLOUD_SERVER_TYPE:-cx23}"
LOCATION="${HCLOUD_LOCATION:-fsn1}"
IMAGE="${HCLOUD_IMAGE:-ubuntu-24.04}"

if ! command -v hcloud >/dev/null 2>&1; then
  echo "Install hcloud: brew install hcloud" >&2
  exit 1
fi

if [[ -z "${HCLOUD_TOKEN:-}" ]]; then
  echo "Set HCLOUD_TOKEN (Security → API tokens → Read & Write in your project)." >&2
  exit 1
fi

export HCLOUD_TOKEN

# Payspin-only deploy key (comment: payspin.app@gmail.com). Do not use work/personal keys.
SSH_PUB="${HCLOUD_SSH_PUBLIC_KEY:-}"
if [[ -z "$SSH_PUB" ]]; then
  for f in "$HOME/.ssh/id_ed25519_payspin.pub"; do
    if [[ -f "$f" ]]; then
      SSH_PUB="$(cat "$f")"
      break
    fi
  done
fi
if [[ -z "$SSH_PUB" ]]; then
  echo "No Payspin SSH key found. Create one:" >&2
  echo "  ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_payspin -C payspin.app@gmail.com" >&2
  echo "Or set HCLOUD_SSH_PUBLIC_KEY to a key whose comment is payspin.app@gmail.com" >&2
  exit 1
fi
if [[ "$SSH_PUB" != *"payspin.app@gmail.com"* && "$SSH_PUB" != *"payspin_app"* ]]; then
  echo "Refusing non-Payspin SSH key. Use payspin.app@gmail.com only." >&2
  exit 1
fi

echo "==> SSH key: $SSH_KEY_NAME"
if ! hcloud ssh-key describe "$SSH_KEY_NAME" >/dev/null 2>&1; then
  hcloud ssh-key create --name "$SSH_KEY_NAME" --public-key "$SSH_PUB"
else
  echo "    (exists)"
fi

echo "==> Firewall: $FIREWALL_NAME (22, 80, 443 inbound)"
if ! hcloud firewall describe "$FIREWALL_NAME" >/dev/null 2>&1; then
  hcloud firewall create --name "$FIREWALL_NAME"
  hcloud firewall add-rule "$FIREWALL_NAME" --direction in --protocol tcp --port 22 --source-ips 0.0.0.0/0 --source-ips ::/0
  hcloud firewall add-rule "$FIREWALL_NAME" --direction in --protocol tcp --port 80 --source-ips 0.0.0.0/0 --source-ips ::/0
  hcloud firewall add-rule "$FIREWALL_NAME" --direction in --protocol tcp --port 443 --source-ips 0.0.0.0/0 --source-ips ::/0
else
  echo "    (exists)"
fi

create_server() {
  local st="$1"
  echo "==> Server: $SERVER_NAME (type=$st, location=$LOCATION, image=$IMAGE)"
  hcloud server create \
    --name "$SERVER_NAME" \
    --type "$st" \
    --location "$LOCATION" \
    --image "$IMAGE" \
    --ssh-key "$SSH_KEY_NAME" \
    --firewall "$FIREWALL_NAME"
}

if hcloud server describe "$SERVER_NAME" >/dev/null 2>&1; then
  echo "==> Server already exists: $SERVER_NAME"
else
  if ! hcloud server-type describe "$SERVER_TYPE" >/dev/null 2>&1; then
    echo "    Server type $SERVER_TYPE not found, trying cx22..." >&2
    SERVER_TYPE=cx22
  fi
  if ! create_server "$SERVER_TYPE" 2>/dev/null; then
    if [[ "$SERVER_TYPE" != "cx22" ]]; then
      echo "    Create failed; retrying with cx22..." >&2
      create_server cx22
    else
      exit 1
    fi
  fi
fi

IP="$(hcloud server ip "$SERVER_NAME")"
echo ""
echo "Done."
echo "  Server:  $SERVER_NAME"
echo "  IPv4:    $IP"
echo "  SSH:     ssh root@$IP"
echo ""
echo "Next: install Docker on the server and deploy Postgres, Redis, and the NestJS API."
