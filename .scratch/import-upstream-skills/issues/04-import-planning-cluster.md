# 04 — Import the planning cluster (to-issues, to-prd, triage)

Status: ready-for-agent

## What to build

Import these from Matt's `engineering/` into `skills/planning/` with `upstream-*` provenance,
copying resources (triage's AGENT-BRIEF, OUT-OF-SCOPE) verbatim, then `scripts/sync-skills.ps1`.
Wire them to read tracker + label config from wherever issue 02 lands, defaulting to this repo's
local-markdown `.scratch/` tracker.

## Acceptance criteria

- [ ] `to-issues`, `to-prd`, `triage` under `skills/planning/<name>/` with `upstream-*` frontmatter
- [ ] triage resources present
- [ ] Skills reference the centralized config (issue 02), not a per-skill copy
- [ ] Default tracker = local-markdown `.scratch/`; `sync-skills.ps1` run; `/planning:*` resolve
- [ ] `/setup:check-skill-updates` shows them `UP-TO-DATE`

## Blocked by

- 01 (planning group), 02 (config distribution)
