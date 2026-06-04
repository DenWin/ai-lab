# 05 — Import/reconcile setup hook skills (git-guardrails, setup-pre-commit)

Status: ready-for-human

## What to build

- **git-guardrails** — import `misc/git-guardrails-claude-code` into `skills/setup/git-guardrails/`
  with provenance. It ships `scripts/block-dangerous-git.sh`; write a pwsh-equivalent guard and wire
  it as a Claude Code hook. Reconcile against the existing global `setup:git-guardrails` (prior
  version) — keep whatever local improvements it already has.
- **setup-pre-commit** — resolve PRD Decision 3 first: Matt's is Husky/lint-staged (JS), my prior
  version is the pre-commit framework (PS/MD/AsciiDoc/SQL). Recommended: treat my toolchain version as
  a **local fork** (SoT = my version, lineage noted, **no** `upstream-commit` so the staleness check
  skips it). Place under `skills/setup/setup-pre-commit/`.

## Acceptance criteria

- [ ] git-guardrails imported; bash guard has a working pwsh equivalent; hook blocks a dangerous git command in test
- [ ] Decision 3 recorded; setup-pre-commit reflects my toolchain (pre-commit framework), lineage noted
- [ ] Provenance correct: git-guardrails tracks upstream; setup-pre-commit marked as fork (skipped by update check)
- [ ] `sync-skills.ps1` run; `/setup:git-guardrails`, `/setup:setup-pre-commit` resolve

## Blocked by

None — can start immediately (Decision 3 is contained here).
