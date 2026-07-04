# PRD — Add a drift check to sync-skills.ps1

Status: needs-triage
Origin: fable (Claude Fable 5 repo review, 2026-07-04)

Quick capture — iron out in scratch-planning, don't action yet.

## Problem Statement

The SessionStart hook runs `sync-skills.ps1 -IfMissing`, which by design never refreshes a skill
whose target already exists. There is no drift detection between the source of truth
(`shared/skills/`) and the generated mirror (`.claude/commands/`). Consequence: after editing a
skill, the stale-mirror failure mode is the **default** path — the hook silently skips, and the
session keeps invoking the old version until someone remembers to re-run the sync manually.

## Solution

_Proposed — refine in triage:_

- Add a `-Check` mode to [scripts/sync-skills.ps1](../../scripts/sync-skills.ps1): compare source
  vs. mirror content (per-skill hash over SKILL.md + resources, with the same link rewriting
  applied), list stale skills, and return a nonzero exit code / warning line.
- Have the SessionStart hook run `-IfMissing` **plus** `-Check`, so a stale mirror produces a
  visible warning at session start instead of silence.
- Open question: should the hook auto-refresh stale skills instead of warning? The mirror is a
  declared build artifact ("never edit"), so auto-refresh is arguably safe — but decide explicitly
  (a user might have an uncommitted source edit mid-flight).

## Further Notes

- Failure mode identified in the Fable repo review (2026-07-04); the `-IfMissing` limitation is
  already documented in the script's own help — this scratch makes it observable.
- _Created by Claude Fable 5 via /planning:scratch._
