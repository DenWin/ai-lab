#Requires -Version 7.0
#Requires -PSEdition Core
# RuntimePolicy: core-first

[CmdletBinding()]
param(
  [string]$RepoRoot = "",
  [switch]$InstallTools,
  [switch]$UseChangedFiles
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptPath = Join-Path $PSScriptRoot "../ai-artifacts/skills/shared/workflow/simulate-workflows/scripts/Invoke-LocalWorkflowSimulation.ps1"
$scriptPath = (Resolve-Path $scriptPath).Path

$invokeParams = @{}
if ($RepoRoot) { $invokeParams.RepoRoot = $RepoRoot }
if ($InstallTools) { $invokeParams.InstallTools = $true }
if ($UseChangedFiles) { $invokeParams.UseChangedFiles = $true }

& $scriptPath @invokeParams

exit $LASTEXITCODE
