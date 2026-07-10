#Requires -Version 7.0
#Requires -PSEdition Core
# RuntimePolicy: core-first

param(
  [string]$RepoRoot = "",
  [switch]$InstallTools,
  [switch]$UseChangedFiles
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:WorkflowIndentLevel = 0

function Get-WorkflowIndent {
  return ('  ' * $script:WorkflowIndentLevel)
}

function Write-WorkflowLine {
  param(
    [AllowEmptyString()]
    [string]$Text = ''
  )

  if ([string]::IsNullOrEmpty($Text)) {
    Write-Output ''
    return
  }

  $lines = $Text -split "`r?`n"
  foreach ($line in $lines) {
    Write-Output ((Get-WorkflowIndent) + $line)
  }
}

function Assert-CommandAvailable {
  param(
    [string]$Name,
    [string]$InstallHint
  )

  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "Required command '$Name' is not available. $InstallHint"
  }
}

function Invoke-Step {
  param(
    [string]$Name,
    [scriptblock]$Action
  )

  Write-WorkflowLine "== $Name =="
  $script:WorkflowIndentLevel++
  try {
    & $Action 2>&1 | ForEach-Object {
      if ($_ -is [System.Management.Automation.ErrorRecord]) {
        Write-WorkflowLine ($_.ToString())
      }
      else {
        Write-WorkflowLine ([string]$_)
      }
    }
  }
  finally {
    $script:WorkflowIndentLevel--
  }
}

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
  $RepoRoot = (& git -C $PSScriptRoot rev-parse --show-toplevel 2>$null)
  if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($RepoRoot)) {
    throw "Unable to determine repo root. Run from inside the repo or pass -RepoRoot."
  }
}

$RepoRoot = (Resolve-Path $RepoRoot).Path
if (-not (Test-Path (Join-Path $RepoRoot ".git"))) {
  throw "Repo root is invalid: $RepoRoot"
}

Assert-CommandAvailable -Name "python" -InstallHint "Install Python 3.11+ and ensure it is on PATH."
Assert-CommandAvailable -Name "git" -InstallHint "Install Git and ensure it is on PATH."

if ($InstallTools) {
  Invoke-Step -Name "Install local toolchain" -Action {
    & python -m pip install --upgrade pip
    if ($LASTEXITCODE -ne 0) { throw "pip upgrade failed." }

    & python -m pip install pyyaml pytest ruff yamllint
    if ($LASTEXITCODE -ne 0) { throw "Python tooling install failed." }

    Assert-CommandAvailable -Name "npm" -InstallHint "Install Node.js (npm) to run markdownlint."
    & npm install -g markdownlint-cli
    if ($LASTEXITCODE -ne 0) { throw "markdownlint-cli install failed." }

    Set-PSRepository PSGallery -InstallationPolicy Trusted
    Install-Module PSScriptAnalyzer -Scope CurrentUser -Force
    Install-Module Pester -Scope CurrentUser -Force -SkipPublisherCheck
  }
}

Assert-CommandAvailable -Name "pwsh" -InstallHint "Install PowerShell 7 and ensure it is on PATH."

$runner = Join-Path $RepoRoot ".github/workflows/scripts/execute-all-workflow-scripts.ps1"
if (-not (Test-Path -LiteralPath $runner -PathType Leaf)) {
  throw "Missing workflow runner script: $runner"
}

$runChangedOnly = [bool]$UseChangedFiles

Invoke-Step -Name "Run workflow script executors" -Action {
  if ($runChangedOnly) {
    & pwsh $runner -RepoRoot $RepoRoot
  }
  else {
    & pwsh $runner -RepoRoot $RepoRoot -FullScan
  }

  if ($LASTEXITCODE -ne 0) {
    Write-WorkflowLine "Local workflow script execution reported issues. Review .temp/Reports/*.txt for details."
  }
}

Write-Output "Local workflow simulation finished. Review .temp/Reports/*.txt for per-workflow status and details."
