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
Reset-WorkflowFailures -WorkflowName "shell-tests"

$batsAvailable = $null -ne (Get-Command bats -ErrorAction SilentlyContinue)
$bashAvailable = $null -ne (Get-Command bash -ErrorAction SilentlyContinue)
if (-not $batsAvailable) {
  Write-WorkflowLine "bats is not available locally; skipping shell-tests checks."
}
if (-not $bashAvailable) {
  Write-WorkflowLine "bash is not available locally; skipping shell-tests checks."
}

Push-Location $RepoRoot
try {
  if (-not ($batsAvailable -and $bashAvailable)) {
    Write-Output "Skipping shell-tests checks because bats or bash is unavailable."
  }
  else {
  $files = Get-WorkflowFiles -RepoRoot $RepoRoot -Base $range.Base -Head $range.Head -Include @("*.bats") -FullScan:$FullScan
  if (@($files).Count -eq 0) {
    Write-Output "== shell-tests ==`nNo bats tests found; skipping."
  }
  else {
    Invoke-WorkflowStep -Name "shell-tests: bats" -Action {
      $joined = $files -join [Environment]::NewLine
      $env:BATS_FILES = $joined
      & bash ".github/workflows/scripts/shell/run-shell-tests.sh"
      if ($LASTEXITCODE -ne 0) { throw "bats tests failed." }
    }
  }
  }
}
finally {
  Pop-Location
}

$null = Write-WorkflowStatusSummary -RepoRoot $RepoRoot -WorkflowName "shell-tests"
