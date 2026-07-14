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

. (Join-Path (Join-Path $PSScriptRoot "ci") "WorkflowScript.Common.ps1")

$RepoRoot = Resolve-WorkflowRepoRoot -RepoRoot $RepoRoot -CallerRoot $PSScriptRoot
$range = Resolve-WorkflowDiffRange -RepoRoot $RepoRoot -Base $Base -Head $Head
$isFullScan = $FullScan.IsPresent
Reset-WorkflowFailures -WorkflowName "execute-all-workflow-scripts"

$reportDir = Join-Path $RepoRoot ".temp/Reports"
New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
$env:REPORTS_DIR = $reportDir

$workflowScripts = @(
  "policy-check/execute-workflow-policy-check.ps1",
  "python-quality/execute-workflow-python-quality.ps1",
  "python-tests/execute-workflow-python-tests.ps1",
  "powershell-quality/execute-workflow-powershell-quality.ps1",
  "powershell-tests/execute-workflow-powershell-tests.ps1",
  "powershell-runtime-compat/execute-workflow-powershell-runtime-compat.ps1",
  "shell-quality/execute-workflow-shell-quality.ps1",
  "shell-tests/execute-workflow-shell-tests.ps1",
  "config-lint/execute-workflow-config-lint.ps1"
)

foreach ($scriptName in $workflowScripts) {
  $scriptPath = Join-Path $PSScriptRoot $scriptName
  if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
    Add-WorkflowFailure -Message ("Missing workflow execution script: {0}" -f $scriptPath)
    Write-WorkflowLine ("[LOCAL FAILURE] Missing workflow execution script: {0}" -f $scriptPath)
    continue
  }

  Write-WorkflowLine ''
  Invoke-WorkflowStep -Name "Run $scriptName" -Action {
    if ($isFullScan) {
      & pwsh $scriptPath -RepoRoot $RepoRoot -Base $range.Base -Head $range.Head -FullScan
    }
    else {
      & pwsh $scriptPath -RepoRoot $RepoRoot -Base $range.Base -Head $range.Head
    }
    if ($LASTEXITCODE -ne 0) {
      throw "$scriptName failed."
    }
  }
}

Write-WorkflowLine ''
$summary = @(Write-WorkflowStatusSummary -RepoRoot $RepoRoot -WorkflowName "execute-all-workflow-scripts") | Select-Object -Last 1
if ($summary.HasFailures) {
  Write-WorkflowLine "Local workflow script runners completed with reported issues."
}
else {
  Write-WorkflowLine "All local workflow script runners completed successfully."
}
