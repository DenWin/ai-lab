#Requires -Version 7.0
<#
.SYNOPSIS
    Mirror the source-of-truth skills under skills/ into a Claude Code commands/ tree.

.DESCRIPTION
    The repo stores skills in folder form (skills/<group>/<name>/SKILL.md + bundled
    resources) as the single source of truth. Claude Code surfaces namespaced slash
    commands (/coding:tdd, /session:recon) from a commands/<group>/<name>.md tree.

    This script generates that tree:
      skills/<group>/<name>/SKILL.md   ->  <target>/commands/<group>/<name>.md
      skills/<group>/<name>/<res...>   ->  <target>/commands/<group>/<name>/<res...>

    Because the SKILL.md moves up one level (into <name>.md) while its resources move
    into a <name>/ subfolder, the script rewrites the SKILL.md body's resource links
    from sibling form  ](res)  /  ](./res)  to subfolder form  ](<name>/res).
    Resource files are copied verbatim (their cross-references stay siblings).

    The generated commands/ tree is a build artifact. Never edit it directly: edit the
    source under skills/ and re-run this script.

.PARAMETER Scope
    Project (default) -> <repo>/.claude/commands  (repo-level; shadows global while in this repo)
    User              -> $env:USERPROFILE/.claude/commands  (global; all projects)

.PARAMETER Skill
    Optional. Mirror only the skill with this name (e.g. "tdd"). Default: all skills.

.PARAMETER IfMissing
    Bootstrap mode: only write a skill whose target command file does not already exist
    ("does not exist -> copy; else leave alone"). Use for a SessionStart hook that materializes
    the gitignored mirror on a fresh clone without clobbering an existing one. Does NOT refresh
    skills you have edited — re-run without this switch after editing a skill.

.PARAMETER RepoRoot
    Repo root. Defaults to the parent of this script's folder.

.EXAMPLE
    ./scripts/sync-skills.ps1
    Mirror every skill into the repo-level .claude/commands tree.

.EXAMPLE
    ./scripts/sync-skills.ps1 -Skill tdd -Scope User
    Push just the tdd skill to the global ~/.claude/commands tree.

.NOTES
    OPTIONAL AUTOMATION — SessionStart hook (opt-in per machine, not committed)

    To auto-materialize the gitignored mirror on session start without clobbering existing files,
    add this snippet to .claude/settings.local.json (machine-local, gitignored — NOT settings.json):

        {
          "hooks": {
            "SessionStart": [
              {
                "hooks": [
                  { "type": "command", "command": "pwsh -NoProfile -File scripts/sync-skills.ps1 -IfMissing" }
                ]
              }
            ]
          }
        }

    This runs silently without a per-execution prompt — hooks are pre-authorized by being in the file.
    Accepting it = adding it to settings.local.json on a given machine. Remove to disable.
    Without it: run `pwsh scripts/sync-skills.ps1` manually after a fresh clone.
#>
[CmdletBinding()]
param(
    [ValidateSet('Project', 'User')]
    [string]$Scope = 'Project',

    [string]$Skill,

    [switch]$IfMissing,

    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'

$skillsRoot = Join-Path $RepoRoot 'skills'
if (-not (Test-Path $skillsRoot)) { throw "skills/ root not found at: $skillsRoot" }

$commandsRoot = switch ($Scope) {
    'Project' { Join-Path $RepoRoot '.claude\commands' }
    'User'    { Join-Path $env:USERPROFILE '.claude\commands' }
}
Write-Verbose "Source : $skillsRoot"
Write-Verbose "Target : $commandsRoot (scope=$Scope)"

# Rewrite a SKILL.md body so resource links point into the <name>/ subfolder.
function Convert-ResourceLinks {
    param(
        [string]$Body,
        [string]$Name,
        [string[]]$ResourceRelPaths   # forward-slash, relative to the skill folder
    )
    foreach ($p in $ResourceRelPaths) {
        # Markdown links: ](p) and ](./p)  ->  ](name/p)
        $Body = $Body.Replace("](./$p)", "]($Name/$p)")
        $Body = $Body.Replace("]($p)",   "]($Name/$p)")
        # @-style file references: @p  ->  @name/p  (only when p is a real resource path)
        $Body = $Body -replace ("(?<=@)" + [regex]::Escape($p) + "\b"), "$Name/$p"
    }
    return $Body
}

# Discover skills: skills/<group>/<name>/SKILL.md
$skillDirs = Get-ChildItem $skillsRoot -Recurse -Filter 'SKILL.md' -File |
    ForEach-Object { $_.Directory } |
    Where-Object { -not $Skill -or $_.Name -eq $Skill }

if (-not $skillDirs) {
    if ($Skill) { throw "No skill named '$Skill' found under $skillsRoot" }
    throw "No SKILL.md files found under $skillsRoot"
}

$report = [System.Text.StringBuilder]::new()
foreach ($dir in $skillDirs) {
    $name  = $dir.Name
    $group = $dir.Parent.Name
    $groupDir = Join-Path $commandsRoot $group

    $targetMd  = Join-Path $groupDir "$name.md"
    $targetRes = Join-Path $groupDir $name

    if ($IfMissing -and (Test-Path $targetMd)) {
        [void]$report.AppendLine(("  /{0}:{1,-18} present — skipped (-IfMissing)" -f $group, $name))
        continue
    }

    # Clean only this skill's own targets (leaves unmanaged siblings, e.g. bootstrap.md, intact)
    if (Test-Path $targetMd)  { Remove-Item $targetMd -Force }
    if (Test-Path $targetRes) { Remove-Item $targetRes -Recurse -Force }
    New-Item -ItemType Directory -Path $groupDir -Force | Out-Null

    # Enumerate bundled resources (everything except SKILL.md)
    $resources = Get-ChildItem $dir.FullName -Recurse -File | Where-Object { $_.Name -ne 'SKILL.md' }
    $resRelPaths = $resources | ForEach-Object {
        $_.FullName.Substring($dir.FullName.Length).TrimStart('\').Replace('\', '/')
    }

    # Write the command file with rewritten resource links
    $body = Get-Content (Join-Path $dir.FullName 'SKILL.md') -Raw
    if ($resRelPaths) { $body = Convert-ResourceLinks -Body $body -Name $name -ResourceRelPaths $resRelPaths }
    Set-Content -Path $targetMd -Value $body -Encoding utf8 -NoNewline

    # Copy resources verbatim into <name>/
    foreach ($res in $resources) {
        $rel    = $res.FullName.Substring($dir.FullName.Length).TrimStart('\')
        $dest   = Join-Path $targetRes $rel
        New-Item -ItemType Directory -Path (Split-Path $dest -Parent) -Force | Out-Null
        Copy-Item $res.FullName $dest -Force
    }

    [void]$report.AppendLine(("  /{0}:{1,-18} {2} resource file(s)" -f $group, $name, $resources.Count))
}

Write-Output "Synced skills -> $commandsRoot (scope=$Scope)"
Write-Output $report.ToString().TrimEnd()
