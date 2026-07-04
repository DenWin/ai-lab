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

- ~~[repo-scaffold](../../repo-scaffold/PRD.md) `git init`~~ — **unblocked 2026-07-04**: git init
  done 2026-06-04, repo published at `github.com/DenWin/ai-lab`. A repo-relative reference is now
  authorable.
- Remaining gate: PRD **Open Decision 3** (doc home — this repo vs its own repo). Settle before
  authoring the link so it isn't rewritten (see Note below).

## Note

If the doc moves to its own repo (open decision 3 in the PRD), the reference must point at that repo
instead — settle that decision before authoring the link to avoid rewriting it twice.
