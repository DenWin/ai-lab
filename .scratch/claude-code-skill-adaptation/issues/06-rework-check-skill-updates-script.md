# 06 — Extract check-skill-updates into a committed script

Status: ready-for-agent

## What to build

The design is **settled**: `check-skill-updates` compares against the **live GitHub repo** per each
skill's `upstream-repo` (via `gh api`), multi-repo, no clone, and **files a work item** for each stale
skill — it never merges or edits skills itself. That behavior is reflected in the SKILL.md.

Remaining: extract the inline PowerShell from `skills/setup/check-skill-updates/SKILL.md` into
`scripts/check-skill-updates.ps1`:

- Staleness check: parse `upstream-*`, `gh api` for the latest commit touching the skill dir, table output.
- Filer: for each STALE skill, create a tracker work item — `.scratch/skill-updates/<group>-<name>-<latest8>.md`
  when inside this repo, or `gh issue create` when the active repo uses a GitHub tracker. Dedupe against
  open items for the same skill + latest commit.
- The SKILL.md drives the script and keeps the "actioning an update" appendix (three-way merge) as
  guidance for whoever picks up a filed item.
- Optionally accept `$ARGUMENTS` to check a single named skill.

Tracker selection follows the config-distribution decision (`import-upstream-skills` issue 02);
default inside this repo = local-markdown `.scratch/`.

## Acceptance criteria

- [ ] `scripts/check-skill-updates.ps1` prints the staleness table and files one work item per STALE skill
- [ ] Never edits/merges a skill; comparison stays GitHub-remote (no clone), any `upstream-repo`
- [ ] Tracker chosen by context (scratch inside this repo / gh issue otherwise); duplicates avoided
- [ ] Local-only skills skipped; `BAD-REPO-URL` / `PATH-NOT-FOUND` handled
- [ ] Prereq documented (`gh auth status`); pwsh conventions (PS7, `$ErrorActionPreference='Stop'`, no Write-Host)

## Blocked by

- `import-upstream-skills` issue 02 (tracker/config decision) informs the filer's tracker selection — not a hard block for the scratch-default path.
