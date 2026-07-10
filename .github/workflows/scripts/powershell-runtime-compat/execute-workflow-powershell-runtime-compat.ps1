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
Reset-WorkflowFailures -WorkflowName "powershell-runtime-compat"

Push-Location $RepoRoot
try {
  $files = Get-WorkflowFiles -RepoRoot $RepoRoot -Base $range.Base -Head $range.Head -Include @("*.ps1") -FullScan:$FullScan

  Invoke-WorkflowStep -Name "powershell-runtime-compat: pwsh syntax (core-first + dual-runtime)" -Action {
    $targets = foreach ($file in $files) {
      if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { continue }
      $lines = Get-Content -LiteralPath $file -TotalCount 40
      $policyLine = $lines | Where-Object { $_ -match '^\s*#\s*RuntimePolicy:\s*' } | Select-Object -First 1
      if (-not $policyLine) { continue }
      $policy = ($policyLine -replace '^\s*#\s*RuntimePolicy:\s*', '').Trim().ToLowerInvariant()
      if ($policy -in @('core-first', 'dual-runtime')) { $file }
    }

    if (-not $targets) {
      Write-Output "No pwsh-target files found."
      return
    }

    $errors = [System.Collections.Generic.List[string]]::new()
    foreach ($file in $targets) {
      $tokens = $null
      $parseErrors = $null
      [System.Management.Automation.Language.Parser]::ParseFile($file, [ref]$tokens, [ref]$parseErrors) | Out-Null
      if ($parseErrors) {
        foreach ($err in $parseErrors) {
          $errors.Add(("{0}:{1}:{2}: {3}" -f $file, $err.Extent.StartLineNumber, $err.Extent.StartColumnNumber, $err.Message))
        }
      }
    }

    if ($errors.Count -gt 0) {
      $errors | Write-Output
      throw "pwsh syntax validation failed."
    }
  }

  Invoke-WorkflowStep -Name "powershell-runtime-compat: windows powershell syntax (dual-runtime + desktop-only)" -Action {
    $winPs = Get-Command powershell -ErrorAction SilentlyContinue
    if (-not $winPs) {
      Write-Output "Windows PowerShell executable not found; skipping desktop runtime parse step."
      return
    }

    $targets = foreach ($file in $files) {
      if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { continue }
      $lines = Get-Content -LiteralPath $file -TotalCount 40
      $policyLine = $lines | Where-Object { $_ -match '^\s*#\s*RuntimePolicy:\s*' } | Select-Object -First 1
      if (-not $policyLine) { continue }
      $policy = ($policyLine -replace '^\s*#\s*RuntimePolicy:\s*', '').Trim().ToLowerInvariant()
      if ($policy -in @('dual-runtime', 'desktop-only')) { $file }
    }

    if (-not $targets) {
      Write-Output "No Windows PowerShell target files found."
      return
    }

    foreach ($file in $targets) {
      & powershell -NoProfile -Command "`$tokens = `$null; `$errors = `$null; [System.Management.Automation.Language.Parser]::ParseFile('$file', [ref]`$tokens, [ref]`$errors) | Out-Null; if (`$errors.Count -gt 0) { `$errors | ForEach-Object { throw (`$_.Extent.File + ':' + `$_.Extent.StartLineNumber + ':' + `$_.Extent.StartColumnNumber + ': ' + `$_.Message) } }"
      if ($LASTEXITCODE -ne 0) { throw "Windows PowerShell syntax validation failed for $file." }
    }
  }
}
finally {
  Pop-Location
}

$null = Write-WorkflowStatusSummary -RepoRoot $RepoRoot -WorkflowName "powershell-runtime-compat"
