# PRD — Verify check-skill-updates detection scope (SKILL.md vs scripts/hooks)

Status: needs-triage

Quick capture — iron out in scratch-planning, don't action yet.

## Problem Statement

Confirm what `setup/check-skill-updates` actually treats as a "change" when deciding a skill is STALE:
only `SKILL.md`, or also bundled scripts, hooks, and other resources?

**First-pass read of the current SKILL.md (to verify, not assume):**
The skill *claims* directory-level detection. Step 1 says it asks GitHub for "the latest commit that
touched the skill's **directory** (so resource changes count, not just `SKILL.md`)", and the script
derives `$dir = $upstreamPath -replace '/SKILL\.md$',''` then queries `commits?path=$dir`. So in
principle **any** change inside the upstream skill directory — scripts included — flips it to STALE.

**The gap worth investigating (the real reason for this scratch):**

- Detection is scoped to the tracked `upstream-path` **directory**. Components that live *outside*
  that directory upstream would be **missed** — e.g. repo-level hooks, shared/root-level scripts, or
  a `.codex-plugin/plugin.json` sibling. The `watch` skill ([[add-watch-skill]]) is a concrete test
  case: does everything it needs sit under the skill dir, or are there out-of-dir pieces?
- `upstream-commit` is a single SHA per skill. Does directory-scoped commit comparison behave
  correctly when the dir was renamed/moved (PATH-NOT-FOUND path), and does it false-negative on
  changes to files the skill depends on but doesn't physically contain?
- Hooks specifically: are hooks ever part of a skill's tracked directory in this repo's model, or do
  they live under a separate `ai-artifacts/hooks/`/settings path that detection never looks at?

## Acceptance (what "checked in detail" means)

- A written verdict: which file classes are/aren't covered by staleness detection, with the line(s)
  of evidence.
- Explicit call-out of any out-of-directory components that escape detection, and whether that's a
  real risk for current skills.

*Solution: Fill in.*
