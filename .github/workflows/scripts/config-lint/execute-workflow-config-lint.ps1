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
$scanArgs = @()
if ($isFullScan) {
  $scanArgs += "--full-scan"
}
Reset-WorkflowFailures -WorkflowName "config-lint"

Invoke-WorkflowStep -Name "config-lint: prerequisites" -Action {
  Assert-WorkflowCommandAvailable -Name "python" -InstallHint "Install Python 3.11+ and ensure it is on PATH."
  Assert-WorkflowCommandAvailable -Name "bash" -InstallHint "Install bash to run config-lint scripts locally."
}

$runnerDir = Join-Path $RepoRoot ".github/workflows/scripts/config-lint"
foreach ($script in @(
  "install-linters.sh",
  "lint-yaml.sh",
  "validate-json.sh",
  "lint-markdown.sh",
  "lint-asciidoc.sh",
  "lint-shell.sh",
  "validate-js-syntax.sh"
)) {
  $path = Join-Path $runnerDir $script
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    Add-WorkflowFailure -Message ("Missing config-lint helper script: {0}" -f $path)
    Write-WorkflowLine ("[LOCAL FAILURE] Missing config-lint helper script: {0}" -f $path)
  }
}

Push-Location $RepoRoot
try {
  if (@(Get-WorkflowFailures).Count -gt 0) {
    Write-Output "Skipping config-lint checks due to prerequisite failures."
  }
  else {
    Invoke-WorkflowStep -Name "config-lint: install linters" -Action {
      & bash ".github/workflows/scripts/config-lint/install-linters.sh"
      if ($LASTEXITCODE -ne 0) { throw "install-linters.sh failed." }
    }

    Invoke-WorkflowStep -Name "config-lint: yaml" -Action {
      & bash ".github/workflows/scripts/config-lint/lint-yaml.sh" $range.Base $range.Head @scanArgs
      if ($LASTEXITCODE -ne 0) { throw "lint-yaml.sh failed." }
    }

    Invoke-WorkflowStep -Name "config-lint: json syntax" -Action {
      & bash ".github/workflows/scripts/config-lint/validate-json.sh" $range.Base $range.Head @scanArgs
      if ($LASTEXITCODE -ne 0) { throw "validate-json.sh failed." }
    }

    Invoke-WorkflowStep -Name "config-lint: markdown" -Action {
      & bash ".github/workflows/scripts/config-lint/lint-markdown.sh" $range.Base $range.Head @scanArgs
      if ($LASTEXITCODE -ne 0) { throw "lint-markdown.sh failed." }
    }

    Invoke-WorkflowStep -Name "config-lint: asciidoc parse" -Action {
      & bash ".github/workflows/scripts/config-lint/lint-asciidoc.sh" $range.Base $range.Head @scanArgs
      if ($LASTEXITCODE -ne 0) { throw "lint-asciidoc.sh failed." }
    }

    Invoke-WorkflowStep -Name "config-lint: shellcheck" -Action {
      & bash ".github/workflows/scripts/config-lint/lint-shell.sh" $range.Base $range.Head @scanArgs
      if ($LASTEXITCODE -ne 0) { throw "lint-shell.sh failed." }
    }

    Invoke-WorkflowStep -Name "config-lint: javascript syntax" -Action {
      & bash ".github/workflows/scripts/config-lint/validate-js-syntax.sh" $range.Base $range.Head @scanArgs
      if ($LASTEXITCODE -ne 0) { throw "validate-js-syntax.sh failed." }
    }
  }
}
finally {
  Pop-Location
}

$null = Write-WorkflowStatusSummary -RepoRoot $RepoRoot -WorkflowName "config-lint"
