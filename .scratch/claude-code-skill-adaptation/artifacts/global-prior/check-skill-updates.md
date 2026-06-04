---
name: check-skill-updates
description: Check whether installed Claude skills are stale against their upstream source, then safely merge upstream improvements while preserving local customizations. Use when user wants to update skills, check for new skill versions, run "check-skill-updates", or sync with upstream changes.
---

# Check Skill Updates

## Quick start

```powershell
# 1. Pull latest upstream
& "C:\Program Files\Git\cmd\git.exe" -C "C:\GIT\mattpocock\skills" pull

# 2. Run the staleness check
$upstreamRepo = "C:\GIT\mattpocock\skills"
$skillsRoot   = "$env:USERPROFILE\.claude\commands"
$gitExe       = "C:\Program Files\Git\cmd\git.exe"

$results = @()
Get-ChildItem $skillsRoot -Recurse -Filter "*.md" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -notmatch '(?m)^upstream-commit:\s*(\S+)') { return }
    $storedCommit = $Matches[1]
    $upstreamPath = if ($content -match '(?m)^upstream-path:\s*(.+)') { $Matches[1].Trim() } else { return }
    $latestCommit = (& $gitExe -C $upstreamRepo log -1 --format="%H" -- $upstreamPath 2>$null)
    if (-not $latestCommit) {
        $results += [PSCustomObject]@{ Skill=$_.Name; Status="PATH-NOT-FOUND"; Stored=$storedCommit.Substring(0,8); Latest="n/a" }
        return
    }
    $status = if ($storedCommit -eq $latestCommit) { "UP-TO-DATE" } else { "STALE" }
    $results += [PSCustomObject]@{ Skill=$_.Name; Status=$status; Stored=$storedCommit.Substring(0,8); Latest=$latestCommit.Substring(0,8) }
}
$results | Sort-Object Status, Skill | Format-Table -AutoSize
```

## Merging a STALE skill

Skills may have been locally customized (different technology examples, platform adjustments). The merge must preserve those changes while pulling in upstream improvements.

### Step 1 — Identify local customizations

Retrieve the original upstream baseline at the stored commit, then diff it against the installed version. Everything that differs is a local customization.

```powershell
$storedCommit = "<hash from frontmatter>"
$upstreamPath = "<path from frontmatter>"
$upstreamRepo = "C:\GIT\mattpocock\skills"
$gitExe       = "C:\Program Files\Git\cmd\git.exe"

# Original upstream baseline (what was installed before any local changes)
$baseline  = (& $gitExe -C $upstreamRepo show "${storedCommit}:${upstreamPath}" 2>$null)
# Current installed version (may contain local customizations)
$installed = Get-Content "$env:USERPROFILE\.claude\commands\<category>\<skill>.md" -Raw
# New upstream version
$newUpstream = Get-Content "$upstreamRepo\$upstreamPath" -Raw
```

Read all three versions. The diff between `$baseline` and `$installed` shows exactly what was customized locally.

### Step 2 — Review what changed upstream

Read `$newUpstream` alongside `$baseline`. Identify what the upstream author added, fixed, or changed.

### Step 3 — Merge

Apply upstream improvements onto the locally-customized version:

- **Keep** local technology substitutions (PowerShell examples, Windows paths, SQL/AsciiDoc tooling)
- **Keep** local frontmatter fields (`upstream-author`, `upstream-repo`, etc.)
- **Apply** upstream structural improvements, new workflow steps, clarifications
- **Apply** upstream bug fixes to the skill logic
- **Skip** upstream changes that conflict with intentional local customizations — note the conflict

### Step 4 — Update both copies

After merging, update `upstream-commit` in the frontmatter to the new hash, then write the merged file to both:

```powershell
# ~/.claude (live)
Set-Content "$env:USERPROFILE\.claude\commands\<category>\<skill>.md" $merged

# .claude-global (staging copy)
Set-Content "C:\GIT\DenWin\Git-Tooling\handover_from_claudechat\.claude-global\commands\<category>\<skill>.md" $merged
```

## Notes

- Skills with `PATH-NOT-FOUND` may have been moved/renamed upstream — search the upstream repo for the skill by `name:` frontmatter field
- Local-only skills (no `upstream-commit`) are ignored by the check — they have no upstream to compare against
- Always merge manually — never auto-overwrite; the whole point is preserving local customizations
