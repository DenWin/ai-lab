#Requires -Version 7.0
<#
.SYNOPSIS
    Sync generated skill mirrors for supported local harnesses.

.DESCRIPTION
    shared/skills/ is the source of truth. This script refreshes generated harness mirrors:

      Claude Code -> .claude/commands/
      Codex       -> .agents/skills/

    By default it updates both. Use -Target to limit the sync to one harness.

.PARAMETER Target
    All (default), Claude, or Codex.

.PARAMETER Scope
    Claude target only. Project (default) writes <repo>/.claude/commands; User writes
    $env:USERPROFILE/.claude/commands. Codex is always repo-local.

.PARAMETER Skill
    Optional. Mirror only the source skill with this name (e.g. "tdd"). Default: all skills.

.PARAMETER IfMissing
    Bootstrap mode: only write a missing generated skill. Does not refresh existing generated files.

.PARAMETER Check
    Read-only drift check. Reports UP-TO-DATE / STALE / MISSING and exits 1 if any target differs.

.PARAMETER RepoRoot
    Repo root. Defaults to the parent of this script's folder.

.EXAMPLE
    pwsh scripts/sync-skills.ps1
    Rebuild Claude Code and Codex skill mirrors from shared/skills.

.EXAMPLE
    pwsh scripts/sync-skills.ps1 -Check
    Check every generated mirror for drift.

.EXAMPLE
    pwsh scripts/sync-skills.ps1 -Target Claude -Skill tdd -Scope User
    Push only the tdd skill to the user-global Claude command mirror.
#>
[CmdletBinding()]
param(
    [ValidateSet('All', 'Claude', 'Codex')]
    [string]$Target = 'All',

    [ValidateSet('Project', 'User')]
    [string]$Scope = 'Project',

    [string]$Skill,

    [switch]$IfMissing,

    [switch]$Check,

    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'
if ($Check -and $IfMissing) { throw "-Check is read-only; do not combine it with -IfMissing." }
if ($Scope -eq 'User' -and $Target -ne 'Claude') {
    throw "-Scope User applies only to Claude. Use -Target Claude -Scope User."
}

$skillsRoot = Join-Path $RepoRoot 'shared\skills'
if (-not (Test-Path $skillsRoot)) { throw "shared/skills root not found at: $skillsRoot" }
$script:LastSyncExitCode = 0

function Get-SkillDirectories {
    param(
        [string]$Root,
        [string]$Name
    )

    $dirs = Get-ChildItem $Root -Recurse -Filter 'SKILL.md' -File |
        ForEach-Object { $_.Directory } |
        Where-Object { -not $Name -or $_.Name -eq $Name }

    if (-not $dirs) {
        if ($Name) { throw "No skill named '$Name' found under $Root" }
        throw "No SKILL.md files found under $Root"
    }

    return @($dirs)
}

function Convert-ResourceLinks {
    param(
        [string]$Body,
        [string]$Name,
        [string[]]$ResourceRelPaths
    )

    foreach ($path in $ResourceRelPaths) {
        $Body = $Body.Replace("](./$path)", "]($Name/$path)")
        $Body = $Body.Replace("]($path)", "]($Name/$path)")
        $Body = $Body -replace ("(?<=@)" + [regex]::Escape($path) + "\b"), "$Name/$path"
    }
    return $Body
}

function ConvertTo-YamlScalar {
    param([string]$Value)

    if ($null -eq $Value) { return '""' }
    return '"' + ($Value -replace '\\', '\\' -replace '"', '\"') + '"'
}

function Get-FrontmatterValue {
    param(
        [string]$Document,
        [string]$Key
    )

    if ($Document -notmatch "(?s)\A---\r?\n(.*?)\r?\n---\r?\n") { return $null }
    $frontmatter = $Matches[1]
    $match = [regex]::Match($frontmatter, "(?m)^$([regex]::Escape($Key)):\s*(.*)$")
    if (-not $match.Success) { return $null }

    $value = $match.Groups[1].Value.Trim()
    if ($value -in @('>', '|', '>-', '|-', '>+', '|+')) {
        $lines = $frontmatter -split "\r?\n"
        $startIndex = [Array]::IndexOf($lines, $match.Value)
        if ($startIndex -lt 0) { return $null }

        $blockLines = [System.Collections.Generic.List[string]]::new()
        for ($i = $startIndex + 1; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            if ($line -match '^\S[^:]*:\s*') { break }
            if ($line -match '^\s*$') {
                $blockLines.Add('')
                continue
            }
            $blockLines.Add(($line -replace '^\s{1,}', ''))
        }

        if ($value.StartsWith('|')) {
            return ($blockLines -join "`n").Trim()
        }
        return (($blockLines | Where-Object { $_ -ne '' }) -join ' ').Trim()
    }
    if (($value.StartsWith('"') -and $value.EndsWith('"')) -or
        ($value.StartsWith("'") -and $value.EndsWith("'"))) {
        $value = $value.Substring(1, $value.Length - 2)
    }
    return $value
}

function Get-SkillBody {
    param([string]$Document)

    if ($Document -match "(?s)\A---\r?\n.*?\r?\n---\r?\n(.*)\z") {
        return $Matches[1].TrimStart()
    }
    return $Document.TrimStart()
}

function ConvertTo-CodexSkill {
    param(
        [string]$SourceDocument,
        [string]$CodexName,
        [string]$SourceRelPath
    )

    $description = Get-FrontmatterValue -Document $SourceDocument -Key 'description'
    if (-not $description) { $description = "Repo skill mirrored from $SourceRelPath." }
    $version = Get-FrontmatterValue -Document $SourceDocument -Key 'version'

    $body = Get-SkillBody -Document $SourceDocument
    $frontmatter = @(
        '---'
        "name: $(ConvertTo-YamlScalar $CodexName)"
        "description: $(ConvertTo-YamlScalar $description)"
        $(if ($version) { "version: $(ConvertTo-YamlScalar $version)" })
        '---'
        ''
        "<!-- GENERATED from $SourceRelPath. Edit shared/skills and run scripts/sync-skills.ps1. -->"
        ''
    ) -join "`n"

    return $frontmatter + $body
}

function Get-CodexCompatibilityWarnings {
    param(
        [string]$Document,
        [string]$SkillName
    )

    $patterns = [ordered]@{
        'claude-path'     = '\.claude|CLAUDE_PROJECT_DIR'
        'claude-command'  = '(^|\s)/[A-Za-z0-9_-]+:[A-Za-z0-9_-]+|\$ARGUMENTS|!command'
        'codex-case'      = '\.Codex'
        'old-skills-root' = 'skills/<group>/<name>|(?<!shared/)skills/'
    }

    foreach ($entry in $patterns.GetEnumerator()) {
        if ($Document -match $entry.Value) { "$SkillName $($entry.Key)" }
    }
}

function Sync-ClaudeSkills {
    param(
        [System.IO.DirectoryInfo[]]$SkillDirs,
        [string]$Root,
        [string]$ClaudeScope,
        [switch]$OnlyIfMissing,
        [switch]$ReadOnlyCheck
    )

    $commandsRoot = switch ($ClaudeScope) {
        'Project' { Join-Path $RepoRoot '.claude\commands' }
        'User'    { Join-Path $env:USERPROFILE '.claude\commands' }
    }

    $report = [System.Text.StringBuilder]::new()
    $driftCount = 0
    $script:LastSyncExitCode = 0

    foreach ($dir in $SkillDirs) {
        $name = $dir.Name
        $group = $dir.Parent.Name
        $groupDir = Join-Path $commandsRoot $group
        $targetMd = Join-Path $groupDir "$name.md"
        $targetRes = Join-Path $groupDir $name

        if ($OnlyIfMissing -and (Test-Path $targetMd)) {
            [void]$report.AppendLine(("  /{0}:{1,-18} present - skipped (-IfMissing)" -f $group, $name))
            continue
        }

        $resources = @(Get-ChildItem $dir.FullName -Recurse -File |
            Where-Object { $_.Name -notin @('SKILL.md', 'METADATA.md') })
        $resRelPaths = $resources | ForEach-Object {
            $_.FullName.Substring($dir.FullName.Length).TrimStart('\').Replace('\', '/')
        }

        $body = Get-Content (Join-Path $dir.FullName 'SKILL.md') -Raw
        if ($resRelPaths) {
            $body = Convert-ResourceLinks -Body $body -Name $name -ResourceRelPaths $resRelPaths
        }

        if ($ReadOnlyCheck) {
            $state = 'UP-TO-DATE'
            if (-not (Test-Path $targetMd)) { $state = 'MISSING' }
            elseif ((Get-Content $targetMd -Raw) -cne $body) { $state = 'STALE' }
            else {
                foreach ($res in $resources) {
                    $rel = $res.FullName.Substring($dir.FullName.Length).TrimStart('\')
                    $dest = Join-Path $targetRes $rel
                    if (-not (Test-Path $dest) -or
                        (Get-FileHash $res.FullName).Hash -ne (Get-FileHash $dest).Hash) {
                        $state = 'STALE'
                        break
                    }
                }
                if ($state -eq 'UP-TO-DATE') {
                    $mirrored = if (Test-Path $targetRes) { @(Get-ChildItem $targetRes -Recurse -File).Count } else { 0 }
                    if ($mirrored -ne $resources.Count) { $state = 'STALE' }
                }
            }

            if ($state -ne 'UP-TO-DATE') { $driftCount++ }
            [void]$report.AppendLine(("  /{0}:{1,-18} {2}" -f $group, $name, $state))
            continue
        }

        if (Test-Path $targetMd) { Remove-Item $targetMd -Force }
        if (Test-Path $targetRes) { Remove-Item $targetRes -Recurse -Force }
        New-Item -ItemType Directory -Path $groupDir -Force | Out-Null
        Set-Content -Path $targetMd -Value $body -Encoding utf8 -NoNewline

        foreach ($res in $resources) {
            $rel = $res.FullName.Substring($dir.FullName.Length).TrimStart('\')
            $dest = Join-Path $targetRes $rel
            New-Item -ItemType Directory -Path (Split-Path $dest -Parent) -Force | Out-Null
            Copy-Item $res.FullName $dest -Force
        }

        [void]$report.AppendLine(("  /{0}:{1,-18} {2} resource file(s)" -f $group, $name, $resources.Count))
    }

    if ($ReadOnlyCheck) {
        Write-Output "Drift check: $Root -> $commandsRoot (target=Claude, scope=$ClaudeScope)"
        Write-Output $report.ToString().TrimEnd()
        if ($driftCount) {
            Write-Output "STALE MIRROR: $driftCount Claude skill(s) stale or missing - rebuild with: pwsh scripts/sync-skills.ps1 -Target Claude"
            $script:LastSyncExitCode = 1
            return
        }
        Write-Output "Claude skills up to date."
        return
    }

    Write-Output "Synced Claude skills -> $commandsRoot (scope=$ClaudeScope)"
    Write-Output $report.ToString().TrimEnd()
    return
}

function Sync-CodexSkills {
    param(
        [System.IO.DirectoryInfo[]]$SkillDirs,
        [string]$Root,
        [string]$SelectedSkill,
        [switch]$OnlyIfMissing,
        [switch]$ReadOnlyCheck
    )

    $agentsRoot = Join-Path $RepoRoot '.agents\skills'
    $report = [System.Text.StringBuilder]::new()
    $warnings = [System.Collections.Generic.List[string]]::new()
    $expectedSkillNames = [System.Collections.Generic.HashSet[string]]::new()
    $driftCount = 0
    $script:LastSyncExitCode = 0

    if (-not $ReadOnlyCheck -and -not $OnlyIfMissing -and -not $SelectedSkill -and (Test-Path $agentsRoot)) {
        Remove-Item $agentsRoot -Recurse -Force
    }

    foreach ($dir in $SkillDirs) {
        $sourceName = $dir.Name
        $group = $dir.Parent.Name
        $codexName = "$group-$sourceName"
        [void]$expectedSkillNames.Add($codexName)
        $targetDir = Join-Path $agentsRoot $codexName
        $targetSkill = Join-Path $targetDir 'SKILL.md'

        if ($OnlyIfMissing -and (Test-Path $targetSkill)) {
            [void]$report.AppendLine(("  {0,-36} present - skipped (-IfMissing)" -f $codexName))
            continue
        }

        $sourceSkill = Join-Path $dir.FullName 'SKILL.md'
        $sourceRelPath = "shared/skills/$group/$sourceName/SKILL.md"
        $sourceDocument = Get-Content $sourceSkill -Raw
        $expectedSkill = ConvertTo-CodexSkill -SourceDocument $sourceDocument -CodexName $codexName -SourceRelPath $sourceRelPath
        foreach ($warning in Get-CodexCompatibilityWarnings -Document $sourceDocument -SkillName $codexName) {
            $warnings.Add($warning)
        }

        $resources = @(Get-ChildItem $dir.FullName -Recurse -File |
            Where-Object { $_.Name -notin @('SKILL.md', 'METADATA.md') })

        if ($ReadOnlyCheck) {
            $state = 'UP-TO-DATE'
            if (-not (Test-Path $targetSkill)) { $state = 'MISSING' }
            elseif ((Get-Content $targetSkill -Raw) -cne $expectedSkill) { $state = 'STALE' }
            else {
                foreach ($res in $resources) {
                    $rel = $res.FullName.Substring($dir.FullName.Length).TrimStart('\')
                    $dest = Join-Path $targetDir $rel
                    if (-not (Test-Path $dest) -or
                        (Get-FileHash $res.FullName).Hash -ne (Get-FileHash $dest).Hash) {
                        $state = 'STALE'
                        break
                    }
                }
                if ($state -eq 'UP-TO-DATE') {
                    $mirrored = @(Get-ChildItem $targetDir -Recurse -File | Where-Object { $_.Name -ne 'SKILL.md' }).Count
                    if ($mirrored -ne $resources.Count) { $state = 'STALE' }
                }
            }

            if ($state -ne 'UP-TO-DATE') { $driftCount++ }
            [void]$report.AppendLine(("  {0,-36} {1}" -f $codexName, $state))
            continue
        }

        if (Test-Path $targetDir) { Remove-Item $targetDir -Recurse -Force }
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        Set-Content -Path $targetSkill -Value $expectedSkill -Encoding utf8 -NoNewline

        foreach ($res in $resources) {
            $rel = $res.FullName.Substring($dir.FullName.Length).TrimStart('\')
            $dest = Join-Path $targetDir $rel
            New-Item -ItemType Directory -Path (Split-Path $dest -Parent) -Force | Out-Null
            Copy-Item $res.FullName $dest -Force
        }

        [void]$report.AppendLine(("  {0,-36} {1} resource file(s)" -f $codexName, $resources.Count))
    }

    if ($ReadOnlyCheck -and -not $SelectedSkill -and (Test-Path $agentsRoot)) {
        foreach ($dir in Get-ChildItem $agentsRoot -Directory) {
            if (-not $expectedSkillNames.Contains($dir.Name)) {
                $driftCount++
                [void]$report.AppendLine(("  {0,-36} EXTRA" -f $dir.Name))
            }
        }
    }

    if ($ReadOnlyCheck) {
        Write-Output "Drift check: $Root -> $agentsRoot (target=Codex)"
        Write-Output $report.ToString().TrimEnd()
        if ($warnings.Count) {
            Write-Output "Compatibility warnings:"
            $warnings | Sort-Object -Unique | ForEach-Object { Write-Output "  $_" }
        }
        if ($driftCount) {
            Write-Output "STALE MIRROR: $driftCount Codex skill(s) stale or missing - rebuild with: pwsh scripts/sync-skills.ps1 -Target Codex"
            $script:LastSyncExitCode = 1
            return
        }
        Write-Output "Codex skills up to date."
        return
    }

    Write-Output "Synced Codex skills -> $agentsRoot"
    Write-Output $report.ToString().TrimEnd()
    if ($warnings.Count) {
        Write-Output "Compatibility warnings:"
        $warnings | Sort-Object -Unique | ForEach-Object { Write-Output "  $_" }
    }
    return
}

$skillDirs = Get-SkillDirectories -Root $skillsRoot -Name $Skill
$exitCodes = [System.Collections.Generic.List[int]]::new()

if ($Target -in @('All', 'Claude')) {
    Write-Output "== Claude Code skill mirror =="
    Sync-ClaudeSkills -SkillDirs $skillDirs -Root $skillsRoot -ClaudeScope $Scope -OnlyIfMissing:$IfMissing -ReadOnlyCheck:$Check
    $exitCodes.Add($script:LastSyncExitCode)
}

if ($Target -in @('All', 'Codex')) {
    Write-Output "== Codex skill mirror =="
    Sync-CodexSkills -SkillDirs $skillDirs -Root $skillsRoot -SelectedSkill $Skill -OnlyIfMissing:$IfMissing -ReadOnlyCheck:$Check
    $exitCodes.Add($script:LastSyncExitCode)
}

if ($exitCodes | Where-Object { $_ -ne 0 }) { exit 1 }
