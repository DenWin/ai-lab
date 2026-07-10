# PRD — Add a drift check to generated mirror sync

Status: done (2026-07-04 — see Progress)
Origin: fable (Claude Fable 5 repo review, 2026-07-04)

## Problem Statement

The SessionStart hook runs `setup-repo.ps1 -IfMissing`, which by design never refreshes a skill
whose target already exists. There is no drift detection between the source of truth
(`ai-artifacts/skills/shared/`) and the generated mirror (`.claude/commands/`). Consequence: after editing a
skill, the stale-mirror failure mode is the **default** path — the hook silently skips, and the
session keeps invoking the old version until someone remembers to re-run the sync manually.

## Solution

*Proposed — refine in triage:*

- Add a `-Check` mode to [scripts/setup-repo.ps1](../../scripts/setup-repo.ps1): compare source
  vs. mirror content (per-skill hash over SKILL.md + resources, with the same link rewriting
  applied), list stale skills, and return a nonzero exit code / warning line.
- Have the SessionStart hook run `-IfMissing` **plus** `-Check`, so a stale mirror produces a
  visible warning at session start instead of silence.
- Open question: should the hook auto-refresh stale skills instead of warning? The mirror is a
  declared build artifact ("never edit"), so auto-refresh is arguably safe — but decide explicitly
  (a user might have an uncommitted source edit mid-flight).

## Progress (2026-07-04 — done)

- ✅ `-Check` mode added to [scripts/setup-repo.ps1](../../scripts/setup-repo.ps1): read-only,
  compares expected mirror output (link rewriting applied) against the actual tree — command-file
  content (`-cne`), per-resource hashes, and extra-files-in-mirror all count as drift. Reports
  UP-TO-DATE / STALE / MISSING per skill; exit 1 on any drift; guarded against combining with
  `-IfMissing`.
- ✅ **Open question decided: warn, don't auto-refresh.** Preserves `-IfMissing`'s non-clobbering
  design; escalate to full-sync-on-start later if warnings prove annoying (one-line hook change).
- ✅ Tested end to end: baseline clean (exit 0); injected drift — edited `caveman.md` → STALE,
  deleted `handoff.md` → MISSING, exit 1; guard throws on `-Check -IfMissing`; full sync repaired;
  re-check clean.
- ✅ SessionStart hook on this machine now runs `-IfMissing` then `-Check`
  (`.claude/settings.local.json` — machine-local, not committed); the recommended two-entry hook
  snippet is documented in the script's `.NOTES` for other machines.

## Further Notes

- Failure mode identified in the Fable repo review (2026-07-04); the `-IfMissing` limitation is
  already documented in the script's own help — this scratch makes it observable.
- *Created by Claude Fable 5 via /planning:scratch.*
