# 05 — Import/reconcile setup hook skills (git-guardrails, setup-pre-commit)

Status: done (git-guardrails + setup-pre-commit imported 2026-07-05; setup cluster complete)

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
- [ ] `setup-repo.ps1 -SkipHooks` run; `/setup:git-guardrails`, `/setup:setup-pre-commit` resolve

## Progress (2026-07-05)

- ✅ **git-guardrails** → `ai-artifacts/skills/shared/setup/git-guardrails/`. Imported from the **global-prior**
  (already localized: pwsh + bash, Windows-primary hook wiring) rather than the raw bash-only artifact.
  Wrote the **pwsh guard** `scripts/block-dangerous-git.ps1` (uses `ConvertFrom-Json`, no `jq`
  dependency; same regex pattern list as the bash guard) alongside the bash one. Added an
  **Applicability** note — it configures a Claude Code PreToolUse hook, so it's N/A in chat-only envs.
  Provenance tracks `misc/git-guardrails-claude-code` in the skill's `METADATA.md`; README no longer
  duplicates exact upstream checkpoints. Bash guard smoke-tested: `git push` → exit 2, `git status`
  → exit 0; pwsh mirrors the same patterns.
- ✅ **setup-pre-commit** → `ai-artifacts/skills/shared/setup/setup-pre-commit/`. **Decision 3 resolved:** imported
  the global-prior (pre-commit framework for PS/MD/AsciiDoc/SQL) as a **local fork** — SoT = mine,
  lineage recorded in an HTML comment, **no `upstream-*` frontmatter** so `/setup:check-skill-updates`
  skips it (it shares only a name with Matt's Husky/lint-staged version). Added an Applicability note
  (repo-setup skill → N/A in chat-only; degrade to handing over the config files). README fork row +
  provenance note added.

**Setup cluster (issue 05) complete.** Remaining import cluster: 04 (planning: to-issues/to-prd/triage).

## Blocked by

None — can start immediately (Decision 3 is contained here).
