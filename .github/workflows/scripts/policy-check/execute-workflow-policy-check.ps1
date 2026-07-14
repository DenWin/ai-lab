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
$isFullScan = $FullScan.IsPresent
Reset-WorkflowFailures -WorkflowName "policy-check"

Invoke-WorkflowStep -Name "policy-check: prerequisites" -Action {
  Assert-WorkflowCommandAvailable -Name "python" -InstallHint "Install Python 3.11+ and ensure it is on PATH."
  Assert-WorkflowCommandAvailable -Name "pwsh" -InstallHint "Install PowerShell 7 and ensure it is on PATH."
}

Push-Location $RepoRoot
try {
  Invoke-WorkflowStep -Name "policy-check: enforce repo guardrails" -Action {
    $files = Get-WorkflowFiles -RepoRoot $RepoRoot -Base $range.Base -Head $range.Head -Include @("*") -FullScan:$isFullScan
    foreach ($file in $files) {
      if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { continue }
      $text = Get-Content -LiteralPath $file -Raw -ErrorAction SilentlyContinue
      if ($null -eq $text) { continue }
      if ($text -match '(?im)(api[_-]?key|secret|token|password)\s*[:=]\s*["''][^"'']+["'']') {
        throw "Potential hardcoded secret detected in $file."
      }
    }

    $psFiles = Get-WorkflowFiles -RepoRoot $RepoRoot -Base $range.Base -Head $range.Head -Include @("*.ps1", "*.psm1") -FullScan:$isFullScan
    foreach ($file in $psFiles) {
      if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { continue }
      $head = Get-Content -LiteralPath $file -TotalCount 80
      if (-not ($head -match 'Set-StrictMode')) {
        throw "Missing Set-StrictMode in $file."
      }
    }
  }

  Invoke-WorkflowStep -Name "policy-check: validate coding policies" -Action {
    & python ".github/workflows/scripts/validate-coding-policies.py"
    if ($LASTEXITCODE -ne 0) { throw "validate-coding-policies.py failed." }

    & python ".github/workflows/scripts/validate-powershell-runtime.py"
    if ($LASTEXITCODE -ne 0) { throw "validate-powershell-runtime.py failed." }
  }
}
finally {
  Pop-Location
}

$null = Write-WorkflowStatusSummary -RepoRoot $RepoRoot -WorkflowName "policy-check"
