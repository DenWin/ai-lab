# PRD — Incorporate the global Claude Code setup into the repo

Status: ready-for-human

The claude.ai profile is now repo-managed (`ai-artifacts/instructions/anthropic/claude-ai/profile.md`). The **Claude Code**
global setup (`~/.claude/`) is the other half and is not yet in the repo. Bring the relevant parts
in as harness-scoped source-of-truth copies, the same way skills are managed.

A snapshot of the current global config is in `artifacts/` (`global-CLAUDE.md`, `global-settings.json`)
— fetched read-only; **no** credentials/history/sessions were copied.

## Problem Statement

`~/.claude/CLAUDE.md` (global instructions) and `~/.claude/settings.json` (permissions/hooks) are
machine-local and unversioned. They overlap heavily with the claude.ai profile (same behavioral
preferences) but are a different harness, authored and loaded separately. Right now they live only on
this machine — no version control, no portability, no single place that reconciles them with the
profile.

## Solution (proposed — refine when building)

Mirror the relevant global config into the repo under harness-scoped paths, establish a sync
direction (repo = source of truth, like skills), and identify the content that overlaps with the
claude.ai profile so it can be hoisted into a root `AGENTS.md` (the cross-harness shared layer)
instead of being maintained twice.

## What to bring in

| Source (`~/.claude/`)                   | Proposed repo location                                             | Notes                                                                |
| --------------------------------------- | ------------------------------------------------------------------ | -------------------------------------------------------------------- |
| `CLAUDE.md` (global instructions)       | `ai-artifacts/instructions/claude-code/CLAUDE.md`                  | Harness-scoped; overlaps with the profile                            |
| `settings.json` (permissions/hooks/MCP) | `ai-artifacts/mcp-config/claude-code/settings.json` *(or similar)* | Decide: global settings vs project settings; secrets stay out        |
| Global skills (`commands/`)             | already handled by the skills work                                 | Prior-version globals captured in `import-upstream-skills` artifacts |

## Pending content to fold in when hoisting `CLAUDE.md`

The repo copy of `CLAUDE.md` should not be a verbatim snapshot — there is already drafted guidance
waiting to be merged into it when it lands:

- [ ] **Quick-helper-mode guidance** (from [`quick-script-over-engineering`](../quick-script-over-engineering/PRD.md)).
      That scratch root-caused why "quick" script requests still get full production scaffolding and
      drafted a concrete patch at
      [`quick-script-over-engineering/artifacts/proposed-CLAUDE-guidance.md`](../quick-script-over-engineering/artifacts/proposed-CLAUDE-guidance.md):
      a new §9a "quick helper mode" trigger + suppression list, `#Requires` made a justified claim not
      a badge (§8), an explicit *form ≠ depth* rule, and a value/verdict/legend separation in §9's
      output convention. Apply it to the live `~/.claude/CLAUDE.md` when hoisting, rather than pasting
      the current unpatched version — then run that scratch's verification recipe (the two originating
      prompts) to confirm it fires.

## Open decisions

1. **Sync direction** — repo SoT → `~/.claude/` via the repo setup sync path, or
   fetch-once-and-hand-maintain? Recommend repo-SoT + sync for consistency with skills.
2. **Overlap → `AGENTS.md`** — what is identical between `profile.md` and `CLAUDE.md` and should live
   once in a root `AGENTS.md` (read by Claude Code + Codex + Copilot), leaving only harness-specific
   deltas in each file? This is the high-value cleanup. Needs a careful diff.
3. **Settings scope** — global `~/.claude/settings.json` vs the repo's `.claude/settings.json`; which
   belong in the repo and which stay machine-local. Permissions are fine to version; never secrets.
4. **Profile ↔ CLAUDE.md reconciliation** — keep them in deliberate sync, or let `AGENTS.md` be the
   shared core and each carry only its harness-specific remainder.

## Out of Scope

- Credentials, chat history, sessions — never copied or versioned.
- The claude.ai profile itself (already in `ai-artifacts/instructions/anthropic/claude-ai/`).
- The full instructions/settings taxonomy (vendor tag, other harnesses) — repo-scaffold handoff.

## Further Notes

- Ties to the harness taxonomy (`docs/harnesses/`) and the `AGENTS.md` root layer.
- Relates to `profile-improvement` (the profile's own refinement) — the `AGENTS.md` hoist in
  decision 2 should happen after both the profile and CLAUDE.md are settled, to diff stable versions.
- Review `artifacts/global-CLAUDE.md` for anything personal/sensitive before committing the real copy
  to `instructions/claude-code/`.
