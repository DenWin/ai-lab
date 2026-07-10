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

$entryScript = Join-Path $PSScriptRoot '../ai-artifacts/skills/shared/setup/setup-repo/scripts/Invoke-SetupRepo.ps1'
$entryScript = (Resolve-Path $entryScript).Path

$entryParams = @{
  Target      = $Target
  MirrorScope = $MirrorScope
}

if ($RepoRoot) {
  $entryParams.RepoRoot = $RepoRoot
}

if ($IfMissing) {
  $entryParams.IfMissing = $true
}

if ($Skill) {
  $entryParams.Skill = $Skill
}

if ($Check) {
  $entryParams.Check = $true
}

if ($SkipHooks) {
  $entryParams.SkipHooks = $true
}

if ($SkipSkillSync) {
  $entryParams.SkipSkillSync = $true
}

& $entryScript @entryParams
exit $LASTEXITCODE
