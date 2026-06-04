# 03 — Import the coding skills (diagnose, improve-codebase-architecture, zoom-out)

Status: ready-for-agent

## What to build

Import these three from Matt's repo into `skills/coding/` with `upstream-*` provenance (commit
`aaf2453…`), copying bundled resources verbatim, then `scripts/sync-skills.ps1`:

- `diagnose` (+ `scripts/hitl-loop.template.sh` — keep the file; pwsh equivalent is an adaptation task)
- `improve-codebase-architecture` (+ DEEPENING, INTERFACE-DESIGN, LANGUAGE, HTML-REPORT)
- `zoom-out` (preserve `disable-model-invocation: true`)

Body adaptation (capability contract, pwsh) is tracked separately in issue 06 — this issue is the
faithful import + grouping + provenance only.

## Acceptance criteria

- [ ] Three skills under `skills/coding/<name>/` with correct `upstream-*` frontmatter
- [ ] Bundled resources present; `zoom-out` retains `disable-model-invocation`
- [ ] `sync-skills.ps1` run; `/coding:diagnose` etc. resolve; resource links rewritten correctly
- [ ] `/setup:check-skill-updates` shows them `UP-TO-DATE`

## Blocked by

- 01 (grouping confirmed)
