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
Reset-WorkflowFailures -WorkflowName "powershell-tests"

Push-Location $RepoRoot
try {
  if (@(Get-WorkflowFailures).Count -gt 0) {
    Write-Output "Skipping powershell-tests checks due to prerequisite failures."
  }
  else {
  $files = Get-WorkflowFiles -RepoRoot $RepoRoot -Base $range.Base -Head $range.Head -Include @("*.Tests.ps1") -FullScan:$FullScan
  if (@($files).Count -eq 0) {
    Write-Output "== powershell-tests ==`nNo Pester tests found; skipping."
  }
  else {
    Invoke-WorkflowStep -Name "powershell-tests: pester" -Action {
      if (-not (Get-Module -ListAvailable -Name Pester)) {
        throw "Pester is not installed. Run simulate-workflows with -InstallTools first."
      }
      Import-Module Pester -ErrorAction Stop
      Invoke-Pester -Path $files -CI
      if ($LASTEXITCODE -ne 0) { throw "Pester tests failed." }
    }
  }
  }
}
finally {
  Pop-Location
}

$null = Write-WorkflowStatusSummary -RepoRoot $RepoRoot -WorkflowName "powershell-tests"
