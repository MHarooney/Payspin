#!/usr/bin/env bash
# MCP filesystem roots for Payspin design context.
# Claude Code sets CLAUDE_PROJECT_DIR when spawning this script.
set -euo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"

exec npx -y @modelcontextprotocol/server-filesystem \
  "${ROOT}/resources/Payspin Design System" \
  "${ROOT}/resources/docs" \
  "${ROOT}/resources/assets" \
  "${ROOT}/mobile/lib/core/design_system" \
  "${ROOT}/.cursor/rules"
