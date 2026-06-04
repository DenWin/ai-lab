# 02 — Fix write-a-skill's broken resource link

Status: ready-for-agent

## What to build

`skills/session/write-a-skill/SKILL.md` links `REFERENCE.md`, but the bundle ships `EXAMPLES.md` and
`SCRIPTS.md`. Reconcile: either rename the link target to the file that exists, or add the missing
`REFERENCE.md` — whichever matches the skill's intent. Confirm `EXAMPLES.md` is actually referenced
somewhere; if orphaned, wire it in or remove it.

## Acceptance criteria

- [ ] Every resource link in `write-a-skill/SKILL.md` resolves to a file that exists
- [ ] No bundled resource is orphaned (unreferenced)
- [ ] `scripts/sync-skills.ps1` re-run; mirror links resolve

## Blocked by

None — can start immediately.
