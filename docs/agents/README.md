# Agent documentation

Quick index for AI agents working on Payspin.

## Start here

1. [../../AGENTS.md](../../AGENTS.md) — repo overview and non-negotiable principles
2. [architecture.md](architecture.md) — clean architecture per app
3. [conventions.md](conventions.md) — naming, anti-patterns
4. [workflows.md](workflows.md) — step-by-step task checklists
5. [mobile-implementation-prompt.md](mobile-implementation-prompt.md) — full agent prompt for **Payspin-mobile** repo (payment links + Circles/Groepies)
6. [circles-implementation-prompt.md](circles-implementation-prompt.md) — Circles/Groepies backend + mobile (Phase 2–3)
7. [circles-contribution-mvp.md](circles-contribution-mvp.md) — round contribution via MULTI payment links
8. [circles-phase3-blockchain-prompt.md](circles-phase3-blockchain-prompt.md) — **Monerium + blockchain + all missing Circles features**
9. [circles-monerium-research.md](circles-monerium-research.md) — Monerium API research seed (agent re-verifies live)

## Cursor integration

| Asset | Path |
|-------|------|
| Project skill | [../../.cursor/skills/payspin/SKILL.md](../../.cursor/skills/payspin/SKILL.md) |
| Core rule (always on) | [../../.cursor/rules/payspin-core.mdc](../../.cursor/rules/payspin-core.mdc) |
| Backend rule | [../../.cursor/rules/backend-clean-arch.mdc](../../.cursor/rules/backend-clean-arch.mdc) |
| Frontend rule | [../../.cursor/rules/frontend-nextjs.mdc](../../.cursor/rules/frontend-nextjs.mdc) |
| Mobile rule | [../../.cursor/rules/mobile-architecture.mdc](../../.cursor/rules/mobile-architecture.mdc) |
| Mobile UI rule | [../../.cursor/rules/payspin-design.mdc](../../.cursor/rules/payspin-design.mdc) |
| Packages rule | [../../.cursor/rules/packages-shared.mdc](../../.cursor/rules/packages-shared.mdc) |
| Infra rule | [../../.cursor/rules/infrastructure-deploy.mdc](../../.cursor/rules/infrastructure-deploy.mdc) |

## How rules and docs relate

- **Rules** (`.cursor/rules/*.mdc`) — short, enforceable context loaded automatically by Cursor when relevant files are open.
- **Docs** (`docs/agents/`) — deeper reference: folder trees, checklists, deployment notes.
- **Skill** — workflow glue: when to read which doc, common commands, do-not list.

When adding a new pattern, update the relevant rule *and* the matching section in `architecture.md` or `conventions.md`.
