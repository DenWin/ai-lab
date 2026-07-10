#Requires -Version 7.0
#Requires -PSEdition Core
# RuntimePolicy: core-first

[CmdletBinding()]
param(
  [string]$RepoRoot = "",
  [string]$Base = "",
  [string]$Head = "",
  [switch]$FullScan
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path (Join-Path $PSScriptRoot "..") "ci/WorkflowScript.Common.ps1")

$RepoRoot = Resolve-WorkflowRepoRoot -RepoRoot $RepoRoot -CallerRoot $PSScriptRoot
$range = Resolve-WorkflowDiffRange -RepoRoot $RepoRoot -Base $Base -Head $Head
Reset-WorkflowFailures -WorkflowName "python-tests"

Invoke-WorkflowStep -Name "python-tests: prerequisites" -Action {
  Assert-WorkflowCommandAvailable -Name "python" -InstallHint "Install Python 3.11+ and ensure it is on PATH."
}

Push-Location $RepoRoot
try {
  if (@(Get-WorkflowFailures).Count -gt 0) {
    Write-Output "Skipping python-tests checks due to prerequisite failures."
  }
  else {
  $files = Get-WorkflowFiles -RepoRoot $RepoRoot -Base $range.Base -Head $range.Head -Include @("ai-artifacts/**/tests/test_*.py") -FullScan:$FullScan
  if (@($files).Count -eq 0) {
    Write-Output "== python-tests ==`nNo Python tests found; skipping."
  }
  else {
    Invoke-WorkflowStep -Name "python-tests: pytest" -Action {
      & python -m pytest @files -q
      if ($LASTEXITCODE -ne 0) { throw "pytest failed." }
    }
  }
  }
}
finally {
  Pop-Location
}

$null = Write-WorkflowStatusSummary -RepoRoot $RepoRoot -WorkflowName "python-tests"
