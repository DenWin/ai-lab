#Requires -Version 7.0
#Requires -PSEdition Core
# RuntimePolicy: core-first

[CmdletBinding()]
param(
  [string]$RepoRoot = "",

  [ValidateSet('All', 'Claude', 'Codex', 'Copilot')]
  [string]$Target = 'All',

  [Alias('Scope')]
  [ValidateSet('Project', 'User')]
  [string]$MirrorScope = 'Project',

  [string]$Skill = '',

  [switch]$IfMissing,
  [switch]$Check,
  [switch]$SkipHooks,
  [switch]$SkipSkillSync
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($Check -and $IfMissing) {
  throw "-Check is read-only; do not combine it with -IfMissing."
}

function Get-UserHomePath {
  if ($env:HOME) { return $env:HOME }
  if ($env:USERPROFILE) { return $env:USERPROFILE }
  throw "Cannot resolve user home path from HOME/USERPROFILE."
}

function Get-RelativePathText {
  param(
    [string]$BasePath,
    [string]$TargetPath
  )

  $rel = [System.IO.Path]::GetRelativePath($BasePath, $TargetPath)
  return $rel.TrimStart('\', '/')
}

function Get-MirrorRootPath {
  param(
    [ValidateSet('Claude', 'Codex', 'Copilot')]
    [string]$TargetName,

    [ValidateSet('Project', 'User')]
    [string]$ScopeName,

    [string]$ResolvedRepoRoot
  )

  switch ("$TargetName|$ScopeName") {
    'Claude|Project' { return (Join-Path $ResolvedRepoRoot '.claude/commands') }
    'Claude|User' { return (Join-Path (Get-UserHomePath) '.claude/commands') }
    'Codex|Project' { return (Join-Path $ResolvedRepoRoot '.agents/skills') }
    'Codex|User' { return (Join-Path (Get-UserHomePath) '.codex/skills') }
    'Copilot|Project' { return (Join-Path $ResolvedRepoRoot '.github/skills') }
    'Copilot|User' { return (Join-Path (Get-UserHomePath) '.copilot/skills') }
    default { throw "Unsupported mirror target/scope combination: $TargetName / $ScopeName" }
  }
}

function Get-SkillDirectories {
  param(
    [string]$SkillsRoot,
    [string]$SkillName
  )

  $dirs = @(Get-ChildItem $SkillsRoot -Recurse -Filter 'SKILL.md' -File | ForEach-Object { $_.Directory })
  if ($SkillName) {
    $dirs = @($dirs | Where-Object { $_.Name -eq $SkillName })
    if ($dirs.Count -eq 0) {
      throw "No SKILL.md found for skill '$SkillName' under $SkillsRoot"
    }
  }
  if ($dirs.Count -eq 0) {
    throw "No SKILL.md files found under $SkillsRoot"
  }
  return $dirs
}

function Get-SyncReportEntry {
  param(
    [string]$Name,
    [string]$Detail
  )

  return [PSCustomObject]@{
    Name   = $Name
    Detail = $Detail
  }
}

function Write-SyncReport {
  param(
    [string]$Flavor,
    [string]$TargetPath,
    [object[]]$Entries,
    [string]$Scope
  )

  $scopeText = if ($Scope) { " (scope=$Scope)" } else { '' }
  Write-Output "Synced $Flavor -> $TargetPath$scopeText"

  if (-not $Entries -or @($Entries).Count -eq 0) {
    return
  }

  $nameWidth = ($Entries | ForEach-Object { $_.Name.Length } | Measure-Object -Maximum).Maximum
  if (-not $nameWidth) { $nameWidth = 0 }

  foreach ($entry in $Entries) {
    Write-Output ("  {0}  {1}" -f $entry.Name.PadRight($nameWidth), $entry.Detail)
  }
}

function Get-SkillResources {
  param([string]$SkillDir)

  return @(Get-ChildItem $SkillDir -Recurse -File |
      Where-Object { $_.Name -notin @('SKILL.md', 'METADATA.md') })
}

function Copy-MirroredResources {
  param(
    [System.IO.FileInfo[]]$Resources,
    [string]$SourceBase,
    [string]$TargetBase
  )

  foreach ($res in $Resources) {
    $rel = Get-RelativePathText -BasePath $SourceBase -TargetPath $res.FullName
    $dest = Join-Path $TargetBase $rel
    New-Item -ItemType Directory -Path (Split-Path $dest -Parent) -Force | Out-Null
    Copy-Item $res.FullName $dest -Force
  }
}

function Test-MirroredResourcesMatch {
  param(
    [System.IO.FileInfo[]]$Resources,
    [string]$SourceBase,
    [string]$TargetBase,
    [switch]$ExcludeTargetSkillFile
  )

  foreach ($res in $Resources) {
    $rel = Get-RelativePathText -BasePath $SourceBase -TargetPath $res.FullName
    $dest = Join-Path $TargetBase $rel
    if (-not (Test-Path $dest) -or
      (Get-FileHash $res.FullName).Hash -ne (Get-FileHash $dest).Hash) {
      return $false
    }
  }

  $resourceCount = @($Resources).Count
  $mirroredCount = if (Test-Path $TargetBase) {
    @(Get-ChildItem $TargetBase -Recurse -File |
        Where-Object { -not $ExcludeTargetSkillFile -or $_.Name -ne 'SKILL.md' }).Count
  }
  else {
    0
  }

  return $mirroredCount -eq $resourceCount
}

function Get-SkillMirrorState {
  param(
    [string]$TargetSkillPath,
    [string]$ExpectedSkill,
    [System.IO.FileInfo[]]$Resources,
    [string]$SourceBase,
    [string]$TargetResourceBase,
    [switch]$ExcludeTargetSkillFile
  )

  if (-not (Test-Path $TargetSkillPath)) { return 'MISSING' }
  if ((Get-Content $TargetSkillPath -Raw) -cne $ExpectedSkill) { return 'STALE' }

  if (-not (Test-MirroredResourcesMatch -Resources $Resources -SourceBase $SourceBase -TargetBase $TargetResourceBase -ExcludeTargetSkillFile:$ExcludeTargetSkillFile)) {
    return 'STALE'
  }

  return 'UP-TO-DATE'
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
    "<!-- GENERATED from $SourceRelPath. Edit ai-artifacts/skills/shared and run scripts/setup-repo.ps1. -->"
    ''
  ) -join "`n"

  return $frontmatter + $body
}

function ConvertTo-CopilotSkill {
  param(
    [string]$SourceDocument,
    [string]$SkillName,
    [string]$SourceRelPath
  )

  $description = Get-FrontmatterValue -Document $SourceDocument -Key 'description'
  if (-not $description) { $description = "Repo skill mirrored from $SourceRelPath." }
  $version = Get-FrontmatterValue -Document $SourceDocument -Key 'version'

  $body = Get-SkillBody -Document $SourceDocument
  $frontmatter = @(
    '---'
    "name: $(ConvertTo-YamlScalar $SkillName)"
    "description: $(ConvertTo-YamlScalar $description)"
    $(if ($version) { "version: $(ConvertTo-YamlScalar $version)" })
    '---'
    ''
    "<!-- GENERATED from $SourceRelPath. Edit ai-artifacts/skills/shared and run scripts/setup-repo.ps1. -->"
    ''
  ) -join "`n"

  return $frontmatter + $body
}

function Invoke-InstallGitHooksInternal {
  param([string]$ResolvedRepoRoot)

  $hooksDir = Join-Path $ResolvedRepoRoot '.githooks'
  if (Test-Path $hooksDir) {
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    Get-ChildItem -Path $hooksDir -File | ForEach-Object {
      $raw = [System.IO.File]::ReadAllText($_.FullName)
      $normalized = $raw -replace "`r`n", "`n" -replace "`r", "`n"
      if ($normalized -ne $raw) {
        [System.IO.File]::WriteAllText($_.FullName, $normalized, $utf8NoBom)
        Write-Output "Normalized LF line endings: $($_.Name)"
      }
    }
  }

  Write-Output '== Git hooks =='
  git config core.hooksPath .githooks
  Write-Output 'Configured core.hooksPath to .githooks'

  if ($IsLinux -or $IsMacOS) {
    $preCommit = Join-Path $hooksDir 'pre-commit'
    if (Test-Path $preCommit) {
      & chmod +x $preCommit
    }
  }

  Write-Output 'Git hooks are now active for this clone.'
}

function Sync-ClaudeSkillsInternal {
  param(
    [System.IO.DirectoryInfo[]]$SkillDirs,
    [string]$ResolvedRepoRoot,
    [string]$ScopeName,
    [switch]$OnlyIfMissing,
    [switch]$ReadOnlyCheck
  )

  $commandsRoot = Get-MirrorRootPath -TargetName 'Claude' -ScopeName $ScopeName -ResolvedRepoRoot $ResolvedRepoRoot
  $entries = [System.Collections.Generic.List[object]]::new()
  $driftCount = 0
  $script:LastSyncExitCode = 0

  Write-Output ''
  Write-Output '== Claude Code skill mirror =='

  foreach ($dir in $SkillDirs) {
    $name = $dir.Name
    $group = $dir.Parent.Name
    $groupDir = Join-Path $commandsRoot $group
    $targetMd = Join-Path $groupDir "$name.md"
    $targetRes = Join-Path $groupDir $name

    if ($OnlyIfMissing -and (Test-Path $targetMd)) {
      $entries.Add((Get-SyncReportEntry -Name ("/{0}:{1}" -f $group, $name) -Detail 'present - skipped (-IfMissing)'))
      continue
    }

    $resources = Get-SkillResources -SkillDir $dir.FullName
    $resRelPaths = $resources | ForEach-Object {
      (Get-RelativePathText -BasePath $dir.FullName -TargetPath $_.FullName).Replace('\\', '/')
    }

    $body = Get-Content (Join-Path $dir.FullName 'SKILL.md') -Raw
    if ($resRelPaths) {
      $body = Convert-ResourceLinks -Body $body -Name $name -ResourceRelPaths $resRelPaths
    }

    if ($ReadOnlyCheck) {
      $state = Get-SkillMirrorState -TargetSkillPath $targetMd -ExpectedSkill $body -Resources $resources -SourceBase $dir.FullName -TargetResourceBase $targetRes
      if ($state -ne 'UP-TO-DATE') { $driftCount++ }
      $entries.Add((Get-SyncReportEntry -Name ("/{0}:{1}" -f $group, $name) -Detail $state))
      continue
    }

    if (Test-Path $targetMd) { Remove-Item $targetMd -Force }
    if (Test-Path $targetRes) { Remove-Item $targetRes -Recurse -Force }
    New-Item -ItemType Directory -Path $groupDir -Force | Out-Null
    Set-Content -Path $targetMd -Value $body -Encoding utf8 -NoNewline
    Copy-MirroredResources -Resources $resources -SourceBase $dir.FullName -TargetBase $targetRes

    $entries.Add((Get-SyncReportEntry -Name ("/{0}:{1}" -f $group, $name) -Detail ("{0,2} resource file(s)" -f @($resources).Count)))
  }

  Write-SyncReport -Flavor 'Claude skills' -TargetPath $commandsRoot -Entries $entries -Scope $ScopeName
  if ($ReadOnlyCheck -and $driftCount) {
    $script:LastSyncExitCode = 1
  }
}

function Sync-CodexSkillsInternal {
  param(
    [System.IO.DirectoryInfo[]]$SkillDirs,
    [string]$ResolvedRepoRoot,
    [string]$ScopeName,
    [switch]$OnlyIfMissing,
    [switch]$ReadOnlyCheck,
    [string]$SelectedSkill
  )

  $agentsRoot = Get-MirrorRootPath -TargetName 'Codex' -ScopeName $ScopeName -ResolvedRepoRoot $ResolvedRepoRoot
  $entries = [System.Collections.Generic.List[object]]::new()
  $expectedSkillNames = [System.Collections.Generic.HashSet[string]]::new()
  $driftCount = 0
  $script:LastSyncExitCode = 0

  if (-not $ReadOnlyCheck -and -not $OnlyIfMissing -and -not $SelectedSkill -and (Test-Path $agentsRoot)) {
    Remove-Item $agentsRoot -Recurse -Force
  }

  Write-Output ''
  Write-Output '== Codex skill mirror =='

  foreach ($dir in $SkillDirs) {
    $sourceName = $dir.Name
    $group = $dir.Parent.Name
    $codexName = "$group`_$sourceName"
    [void]$expectedSkillNames.Add($codexName)
    $targetDir = Join-Path $agentsRoot $codexName
    $targetSkill = Join-Path $targetDir 'SKILL.md'

    if ($OnlyIfMissing -and (Test-Path $targetSkill)) {
      $entries.Add((Get-SyncReportEntry -Name $codexName -Detail 'present - skipped (-IfMissing)'))
      continue
    }

    $sourceRelPath = "ai-artifacts/skills/shared/$group/$sourceName/SKILL.md"
    $sourceDocument = Get-Content (Join-Path $dir.FullName 'SKILL.md') -Raw
    $expectedSkill = ConvertTo-CodexSkill -SourceDocument $sourceDocument -CodexName $codexName -SourceRelPath $sourceRelPath
    $resources = Get-SkillResources -SkillDir $dir.FullName

    if ($ReadOnlyCheck) {
      $state = Get-SkillMirrorState -TargetSkillPath $targetSkill -ExpectedSkill $expectedSkill -Resources $resources -SourceBase $dir.FullName -TargetResourceBase $targetDir -ExcludeTargetSkillFile
      if ($state -ne 'UP-TO-DATE') { $driftCount++ }
      $entries.Add((Get-SyncReportEntry -Name $codexName -Detail $state))
      continue
    }

    if (Test-Path $targetDir) { Remove-Item $targetDir -Recurse -Force }
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    Set-Content -Path $targetSkill -Value $expectedSkill -Encoding utf8 -NoNewline
    Copy-MirroredResources -Resources $resources -SourceBase $dir.FullName -TargetBase $targetDir

    $entries.Add((Get-SyncReportEntry -Name $codexName -Detail ("{0,2} resource file(s)" -f @($resources).Count)))
  }

  if ($ReadOnlyCheck -and -not $SelectedSkill -and (Test-Path $agentsRoot)) {
    foreach ($dir in Get-ChildItem $agentsRoot -Directory) {
      if (-not $expectedSkillNames.Contains($dir.Name)) {
        $driftCount++
        $entries.Add((Get-SyncReportEntry -Name $dir.Name -Detail 'EXTRA'))
      }
    }
  }

  Write-SyncReport -Flavor 'Codex skills' -TargetPath $agentsRoot -Entries $entries -Scope $ScopeName
  if ($ReadOnlyCheck -and $driftCount) {
    $script:LastSyncExitCode = 1
  }
}

function Sync-CopilotSkillsInternal {
  param(
    [System.IO.DirectoryInfo[]]$SkillDirs,
    [string]$ResolvedRepoRoot,
    [string]$ScopeName,
    [switch]$OnlyIfMissing,
    [switch]$ReadOnlyCheck,
    [string]$SelectedSkill
  )

  $skillsMirrorRoot = Get-MirrorRootPath -TargetName 'Copilot' -ScopeName $ScopeName -ResolvedRepoRoot $ResolvedRepoRoot
  $entries = [System.Collections.Generic.List[object]]::new()
  $expectedSkillNames = [System.Collections.Generic.HashSet[string]]::new()
  $driftCount = 0
  $script:LastSyncExitCode = 0

  if (-not $ReadOnlyCheck -and -not $OnlyIfMissing -and -not $SelectedSkill -and (Test-Path $skillsMirrorRoot)) {
    Remove-Item $skillsMirrorRoot -Recurse -Force
  }

  Write-Output ''
  Write-Output '== Copilot skill mirror =='

  foreach ($dir in $SkillDirs) {
    $sourceName = $dir.Name
    $group = $dir.Parent.Name
    $copilotSkillName = "$group`_$sourceName"
    [void]$expectedSkillNames.Add($copilotSkillName)
    $targetDir = Join-Path $skillsMirrorRoot $copilotSkillName
    $targetSkill = Join-Path $targetDir 'SKILL.md'

    if ($OnlyIfMissing -and (Test-Path $targetSkill)) {
      $entries.Add((Get-SyncReportEntry -Name $copilotSkillName -Detail 'present - skipped (-IfMissing)'))
      continue
    }

    $sourceRelPath = "ai-artifacts/skills/shared/$group/$sourceName/SKILL.md"
    $sourceDocument = Get-Content (Join-Path $dir.FullName 'SKILL.md') -Raw
    $expectedSkill = ConvertTo-CopilotSkill -SourceDocument $sourceDocument -SkillName $copilotSkillName -SourceRelPath $sourceRelPath
    $resources = Get-SkillResources -SkillDir $dir.FullName

    if ($ReadOnlyCheck) {
      $state = Get-SkillMirrorState -TargetSkillPath $targetSkill -ExpectedSkill $expectedSkill -Resources $resources -SourceBase $dir.FullName -TargetResourceBase $targetDir -ExcludeTargetSkillFile
      if ($state -ne 'UP-TO-DATE') { $driftCount++ }
      $entries.Add((Get-SyncReportEntry -Name $copilotSkillName -Detail $state))
      continue
    }

    if (Test-Path $targetDir) { Remove-Item $targetDir -Recurse -Force }
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    Set-Content -Path $targetSkill -Value $expectedSkill -Encoding utf8 -NoNewline
    Copy-MirroredResources -Resources $resources -SourceBase $dir.FullName -TargetBase $targetDir

    $entries.Add((Get-SyncReportEntry -Name $copilotSkillName -Detail ("{0,2} resource file(s)" -f @($resources).Count)))
  }

  if ($ReadOnlyCheck -and -not $SelectedSkill -and (Test-Path $skillsMirrorRoot)) {
    foreach ($dir in Get-ChildItem $skillsMirrorRoot -Directory) {
      $skillFile = Join-Path $dir.FullName 'SKILL.md'
      if (-not (Test-Path $skillFile)) { continue }
      if ((Get-Content $skillFile -Raw) -notmatch '<!-- GENERATED from ai-artifacts/skills/shared/') {
        continue
      }
      if (-not $expectedSkillNames.Contains($dir.Name)) {
        $driftCount++
        $entries.Add((Get-SyncReportEntry -Name $dir.Name -Detail 'EXTRA'))
      }
    }
  }

  Write-SyncReport -Flavor 'Copilot skills' -TargetPath $skillsMirrorRoot -Entries $entries -Scope $ScopeName
  if ($ReadOnlyCheck -and $driftCount) {
    $script:LastSyncExitCode = 1
  }
}

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
  $RepoRoot = (& git -C $PSScriptRoot rev-parse --show-toplevel 2>$null)
  if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($RepoRoot)) {
    throw "Unable to determine repo root. Run from inside the repo or pass -RepoRoot."
  }
}

$RepoRoot = (Resolve-Path $RepoRoot).Path
$skillsRoot = Join-Path $RepoRoot 'ai-artifacts/skills/shared'
$skillDirs = Get-SkillDirectories -SkillsRoot $skillsRoot -SkillName $Skill

if (-not $SkipHooks) {
  Invoke-InstallGitHooksInternal -ResolvedRepoRoot $RepoRoot
}

if (-not $SkipSkillSync) {
  $exitCode = 0
  switch ($Target) {
    'All' {
      Sync-ClaudeSkillsInternal -SkillDirs $skillDirs -ResolvedRepoRoot $RepoRoot -ScopeName $MirrorScope -OnlyIfMissing:$IfMissing -ReadOnlyCheck:$Check
      $exitCode = [Math]::Max($exitCode, $script:LastSyncExitCode)
      Sync-CodexSkillsInternal -SkillDirs $skillDirs -ResolvedRepoRoot $RepoRoot -ScopeName $MirrorScope -OnlyIfMissing:$IfMissing -ReadOnlyCheck:$Check -SelectedSkill $Skill
      $exitCode = [Math]::Max($exitCode, $script:LastSyncExitCode)
      Sync-CopilotSkillsInternal -SkillDirs $skillDirs -ResolvedRepoRoot $RepoRoot -ScopeName $MirrorScope -OnlyIfMissing:$IfMissing -ReadOnlyCheck:$Check -SelectedSkill $Skill
      $exitCode = [Math]::Max($exitCode, $script:LastSyncExitCode)
    }
    'Claude' {
      Sync-ClaudeSkillsInternal -SkillDirs $skillDirs -ResolvedRepoRoot $RepoRoot -ScopeName $MirrorScope -OnlyIfMissing:$IfMissing -ReadOnlyCheck:$Check
      $exitCode = $script:LastSyncExitCode
    }
    'Codex' {
      Sync-CodexSkillsInternal -SkillDirs $skillDirs -ResolvedRepoRoot $RepoRoot -ScopeName $MirrorScope -OnlyIfMissing:$IfMissing -ReadOnlyCheck:$Check -SelectedSkill $Skill
      $exitCode = $script:LastSyncExitCode
    }
    'Copilot' {
      Sync-CopilotSkillsInternal -SkillDirs $skillDirs -ResolvedRepoRoot $RepoRoot -ScopeName $MirrorScope -OnlyIfMissing:$IfMissing -ReadOnlyCheck:$Check -SelectedSkill $Skill
      $exitCode = $script:LastSyncExitCode
    }
  }

  if ($Check) {
    if ($exitCode) {
      Write-Output 'Generated mirrors are stale or missing. Rebuild with: pwsh scripts/setup-repo.ps1 -SkipHooks'
      exit 1
    }

    Write-Output 'Generated mirrors are up to date.'
  }
}

Write-Output "Repository setup completed."
