# 03 — Light pass on conversational skills

Status: ready-for-agent

## What to build

Adapt the conversational skills — `caveman`, `grill-me`, `handoff`, `write-a-skill` — for Claude Code:
accept `$ARGUMENTS` where the skill takes an input (e.g. `handoff` already has an `argument-hint`),
set `disable-model-invocation: true` where the skill should only run on explicit request, and tidy any
chat-only phrasing into procedural steps. Keep intent and local customizations intact.

## Acceptance criteria

- [ ] Each skill takes `$ARGUMENTS` where it has an input, or is confirmed not to need one
- [ ] `disable-model-invocation` set where appropriate, with a one-line rationale per decision
- [ ] No remaining "paste this back into chat"-style phrasing where a tool path exists
- [ ] Each verified via `/session:write-a-skill`; `setup-repo.ps1 -SkipHooks` re-run

## Blocked by

- 01 (classification) — recommended first, not strictly required
