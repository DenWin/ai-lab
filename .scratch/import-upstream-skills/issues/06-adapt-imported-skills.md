# 06 — Claude Code adaptation pass for the imported skills

Status: ready-for-agent

## What to build

Run the same capability-contract adaptation on the newly-imported skills as pass 1 used on the
originals (see `.scratch/claude-code-skill-adaptation/`): shell/tool path where available,
conversational fallback otherwise; `$ARGUMENTS` where a skill takes input; convert Matt's bash
helpers to pwsh; ensure agentic skills (diagnose, triage, improve-codebase-architecture) actually use
repo/file/shell access.

## Acceptance criteria

- [ ] Each imported skill classified (conversational / agentic) and adapted accordingly
- [ ] `diagnose` HITL loop and `git-guardrails` guard exist as pwsh, not bash-only
- [ ] Agentic skills exercise real tool access on a throwaway target; fallbacks preserved
- [ ] Each verified via `/session:write-a-skill`; `setup-repo.ps1 -SkipHooks` run after edits

## Blocked by

- 03, 04, 05 (skills must be imported first)
