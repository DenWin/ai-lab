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
Reset-WorkflowFailures -WorkflowName "python-quality"

Invoke-WorkflowStep -Name "python-quality: prerequisites" -Action {
  Assert-WorkflowCommandAvailable -Name "python" -InstallHint "Install Python 3.11+ and ensure it is on PATH."
}

Push-Location $RepoRoot
try {
  if (@(Get-WorkflowFailures).Count -gt 0) {
    Write-Output "Skipping python-quality checks due to prerequisite failures."
  }
  else {
    $files = Get-WorkflowFiles -RepoRoot $RepoRoot -Base $range.Base -Head $range.Head -Include @("*.py") -FullScan:$FullScan
    if (@($files).Count -eq 0) {
      Write-Output "== python-quality ==`nNo Python files found."
    }
    else {
      Invoke-WorkflowStep -Name "python-quality: ruff check" -Action {
        & python -m ruff check @files
        if ($LASTEXITCODE -ne 0) { throw "ruff check failed." }
      }

      Invoke-WorkflowStep -Name "python-quality: ruff format check" -Action {
        & python -m ruff format --check @files
        if ($LASTEXITCODE -ne 0) { throw "ruff format --check failed." }
      }
    }
  }
}
finally {
  Pop-Location
}

$null = Write-WorkflowStatusSummary -RepoRoot $RepoRoot -WorkflowName "python-quality"
