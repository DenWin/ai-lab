# 01 — Reference the foundation doc from the tdd skill

Status: ready-for-human

## What to build

Add a reference from the `tdd` skill to the foundation document, establishing the doc as the skill's
source-of-truth. The reference must be a **git-repo reference** — a repo-relative path or git URL that
resolves once the repo is published — not a machine-local absolute path.

Target file: `skills/coding/tdd/SKILL.md` (likely a line in the "Reference Files" / "Core Frame"
section pointing at `docs/testing-methodologies-foundation.adoc` as the canonical §11 source).

## Acceptance criteria

- `SKILL.md` names the foundation doc as its source-of-truth and links it via a git-tracked path.
- The link resolves in the published repo (not just on this machine).
- After the edit: re-run `scripts/sync-skills.ps1` so the synced command copy carries the reference.

## Blocked by

- [repo-scaffold](../../repo-scaffold/PRD.md) — specifically its `git init` step (Phase 2, scope
  item 1). ai-lab is not yet a git repository, so a git-repo reference (repo-relative path / git URL)
  cannot be authored. Until then the doc lives at `docs/testing-methodologies-foundation.adoc` but the
  skill is not wired to it.

## Note

If the doc moves to its own repo (open decision 3 in the PRD), the reference must point at that repo
instead — settle that decision before authoring the link to avoid rewriting it twice.
