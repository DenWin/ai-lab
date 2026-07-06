# 05 — Import/reconcile setup hook skills (git-guardrails, setup-pre-commit)

Status: in-progress (git-guardrails imported + pwsh guard done 2026-07-05; setup-pre-commit pending)

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

## Progress (2026-07-05)

- ✅ **git-guardrails** → `shared/skills/setup/git-guardrails/`. Imported from the **global-prior**
  (already localized: pwsh + bash, Windows-primary hook wiring) rather than the raw bash-only artifact.
  Wrote the **pwsh guard** `scripts/block-dangerous-git.ps1` (uses `ConvertFrom-Json`, no `jq`
  dependency; same regex pattern list as the bash guard) alongside the bash one. Added an
  **Applicability** note — it configures a Claude Code PreToolUse hook, so it's N/A in chat-only envs.
  Provenance tracks `misc/git-guardrails-claude-code` at **`62f43a18`** (the global-prior's commit,
  not `aaf2453`); README blanket-commit note corrected. Bash guard smoke-tested: `git push` → exit 2,
  `git status` → exit 0; pwsh mirrors the same patterns.
- ⏳ **setup-pre-commit** — next: treat my toolchain version (pre-commit framework, PS/MD/AsciiDoc/SQL)
  as a **local fork** (SoT = mine, lineage noted, no `upstream-commit` so the staleness check skips it).

## Blocked by

None — can start immediately (Decision 3 is contained here).
