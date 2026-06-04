---
name: check-skill-updates
description: Check whether the skills in this repo are stale against their upstream source on GitHub, and file a work item (GitHub issue or .scratch entry) for each stale one. It never edits or merges skills itself. Use when user wants to check for new skill versions, run "check-skill-updates", or sync with upstream changes.
---

# Check Skill Updates

Skills carry their origin in frontmatter (`upstream-author`, `upstream-repo`, `upstream-path`,
`upstream-commit`). This skill reads those fields, compares each skill against its upstream **directly
on GitHub**, and for every stale skill **files a work item** in the active tracker. It does **not**
merge or edit any skill — the actual update is triaged and done later (by a human or an agent picking
up the filed item), preserving local customizations under review rather than auto-overwriting.

- No local clone of any upstream is needed, and it works for **any** `upstream-repo`.
- Source of truth is `skills/<group>/<name>/SKILL.md`; the `.claude/commands/` copies are a generated
  mirror (`scripts/sync-skills.ps1`).
- Skills with no `upstream-commit` (local originals like `session/recon`, `setup/check-skill-updates`)
  are skipped.

## Prerequisite — GitHub CLI, authenticated

```powershell
gh auth status   # must be logged in; run `gh auth login` if not
```

## Step 1 — Detect stale skills

For each skill, ask GitHub for the latest commit that touched the skill's **directory** (so resource
changes count, not just `SKILL.md`) and compare to `upstream-commit`.

```powershell
$ErrorActionPreference = 'Stop'

$repoRoot   = Resolve-Path (Join-Path $PSScriptRoot '..\..\..')
$skillsRoot = Join-Path $repoRoot 'skills'

$results = foreach ($skill in Get-ChildItem $skillsRoot -Recurse -Filter 'SKILL.md') {
    $content = Get-Content $skill.FullName -Raw
    if ($content -notmatch '(?m)^upstream-commit:\s*(\S+)') { continue }
    $storedCommit = $Matches[1]
    if ($content -notmatch '(?m)^upstream-repo:\s*(\S+)') { continue }
    $upstreamRepo = $Matches[1]
    if ($content -notmatch '(?m)^upstream-path:\s*(.+)') { continue }
    $upstreamPath = $Matches[1].Trim()

    if ($upstreamRepo -notmatch 'github\.com[:/]+([^/]+)/([^/.\s]+)') {
        [PSCustomObject]@{ Skill=$skill.Directory.Name; Status='BAD-REPO-URL'; Stored=$storedCommit.Substring(0,8); Latest='n/a'; Repo=$upstreamRepo; Path=$upstreamPath }
        continue
    }
    $owner = $Matches[1]; $repo = $Matches[2]
    $dir = $upstreamPath -replace '/SKILL\.md$', ''

    $latestCommit = (& gh api "repos/$owner/$repo/commits?path=$dir&per_page=1" --jq '.[0].sha' 2>$null)
    $rel = $skill.Directory.FullName.Substring($skillsRoot.Length).TrimStart('\').Replace('\','/')
    if (-not $latestCommit) {
        [PSCustomObject]@{ Skill=$rel; Status='PATH-NOT-FOUND'; Stored=$storedCommit.Substring(0,8); Latest='n/a'; Repo=$upstreamRepo; Path=$upstreamPath }
        continue
    }
    $status = if ($storedCommit -eq $latestCommit) { 'UP-TO-DATE' } else { 'STALE' }
    [PSCustomObject]@{ Skill=$rel; Status=$status; Stored=$storedCommit.Substring(0,8); Latest=$latestCommit.Substring(0,8); Repo=$upstreamRepo; Path=$upstreamPath }
}
$results | Sort-Object Status, Skill | Format-Table Skill, Status, Stored, Latest -AutoSize
```

## Step 2 — File a work item for each STALE skill

This skill **reports**; it does not merge. For every `STALE` row, create one work item in the
**active tracker**. Pick the tracker by context (this mirrors the repo's tracker config — see
`.scratch/import-upstream-skills/issues/02-resolve-config-distribution.md`):

- **Running inside this repo** (local-markdown tracker): write a file under
  `.scratch/skill-updates/<group>-<name>-<latest8>.md` with `Status: needs-triage` and the body below.
- **Running in a repo with a GitHub tracker**: `gh issue create` with the same body and an
  appropriate label.

Do not open a duplicate if an open item for the same skill + `Latest` commit already exists.

Work-item body:

```markdown
## Stale skill: <group>/<name>

Upstream has moved past the commit this skill was last reconciled to.

- Upstream repo: <upstream-repo>
- Upstream path: <upstream-path>
- Reconciled at: <stored-commit>
- Latest upstream: <latest-commit>
- Compare: <upstream-repo>/compare/<stored-commit>...<latest-commit>

## Action

Review the upstream changes and merge the worthwhile ones into
`skills/<group>/<name>/SKILL.md` (and resources), preserving local customizations, then bump
`upstream-commit` and re-run `scripts/sync-skills.ps1`. See "Appendix: actioning an update" in the
check-skill-updates skill for the three-way procedure.
```

## Step 3 — Report

Print the table and a one-line summary of how many items were filed and where. Make no edits to any
skill.

## Appendix: actioning an update (for whoever picks up a filed item — NOT run by this skill)

A skill may carry local customizations (technology substitutions, platform tweaks, intentional merges
like `grill-me` ← `grill-with-docs`). Merge manually; never auto-overwrite. Fetch all versions from
GitHub (still no clone):

```powershell
$owner = '<owner>'; $repo = '<repo>'
$upstreamPath = '<upstream-path>'; $storedCommit = '<stored-commit>'

$baseline    = (& gh api -H 'Accept: application/vnd.github.raw' "repos/$owner/$repo/contents/$upstreamPath`?ref=$storedCommit")
$installed   = Get-Content '<repo>\skills\<group>\<name>\SKILL.md' -Raw
$newUpstream = (& gh api -H 'Accept: application/vnd.github.raw' "repos/$owner/$repo/contents/$upstreamPath")
```

`$baseline` vs `$installed` = local customizations to keep. `$baseline` vs `$newUpstream` = upstream
changes to consider. Apply upstream fixes/improvements; keep local substitutions and intentional
merges; skip conflicting upstream changes and note them. Then bump `upstream-commit`, write to the
source of truth, and re-run `scripts/sync-skills.ps1`.

## Notes

- `PATH-NOT-FOUND` ⇒ the skill moved/renamed upstream — find it by `name:` and update `upstream-path`.
- `BAD-REPO-URL` ⇒ `upstream-repo` isn't a parseable `github.com/<owner>/<repo>` URL — fix it.
- Local-only skills (no `upstream-commit`) are skipped.
