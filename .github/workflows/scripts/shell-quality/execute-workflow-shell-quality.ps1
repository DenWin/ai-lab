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
Reset-WorkflowFailures -WorkflowName "shell-quality"

$shellcheckAvailable = $null -ne (Get-Command shellcheck -ErrorAction SilentlyContinue)
if (-not $shellcheckAvailable) {
  Write-WorkflowLine "shellcheck is not available locally; skipping shell-quality checks."
}

Push-Location $RepoRoot
try {
  if (-not $shellcheckAvailable) {
    Write-Output "Skipping shell-quality checks because shellcheck is unavailable."
  }
  else {
    $files = Get-WorkflowFiles -RepoRoot $RepoRoot -Base $range.Base -Head $range.Head -Include @("*.sh") -FullScan:$FullScan
    if (@($files).Count -eq 0) {
      Write-Output "== shell-quality ==`nNo shell files found."
    }
    else {
      Invoke-WorkflowStep -Name "shell-quality: shellcheck" -Action {
        & shellcheck @files
        if ($LASTEXITCODE -ne 0) { throw "shellcheck failed." }
      }
    }
  }
}
finally {
  Pop-Location
}

$null = Write-WorkflowStatusSummary -RepoRoot $RepoRoot -WorkflowName "shell-quality"
