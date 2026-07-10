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
Reset-WorkflowFailures -WorkflowName "powershell-quality"

Push-Location $RepoRoot
try {
  $reportDir = Get-WorkflowReportDirectory -RepoRoot $RepoRoot
  New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
  $scriptAnalyzerReport = Join-Path $reportDir "psscriptanalyzer-local.txt"
  $syntaxReport = Join-Path $reportDir "powershell-syntax-local.txt"

  if (@(Get-WorkflowFailures).Count -gt 0) {
    Write-Output "Skipping powershell-quality checks due to prerequisite failures."
  }
  else {
    $files = Get-WorkflowFiles -RepoRoot $RepoRoot -Base $range.Base -Head $range.Head -Include @("*.ps1", "*.psm1", "*.psd1") -FullScan:$FullScan
    if (@($files).Count -eq 0) {
      Write-Output "== powershell-quality ==`nNo PowerShell files found."
    }
    else {
      Invoke-WorkflowStep -Name "powershell-quality: script analyzer" -Action {
        if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
          throw "PSScriptAnalyzer is not installed. Run simulate-workflows with -InstallTools first."
        }
        Import-Module PSScriptAnalyzer -ErrorAction Stop
        $results = foreach ($file in $files) {
          Invoke-ScriptAnalyzer -Path $file -Severity Warning, Error -ExcludeRule PSUseSingularNouns, PSAvoidUsingWriteHost, PSUseBOMForUnicodeEncodedFile
        }
        if ($results) {
          $results | Format-Table Path, Line, RuleName, Severity, Message -AutoSize | Out-String | Set-Content -Path $scriptAnalyzerReport -Encoding utf8
          Write-Output ("PSScriptAnalyzer found {0} issue(s). Report: {1}" -f @($results).Count, $scriptAnalyzerReport)
          Get-Content -Path $scriptAnalyzerReport | Write-Output
          throw "PSScriptAnalyzer found issues."
        }

        "No PSScriptAnalyzer issues found." | Set-Content -Path $scriptAnalyzerReport -Encoding utf8
        Write-Output ("No PSScriptAnalyzer issues found. Report: {0}" -f $scriptAnalyzerReport)
      }

      Invoke-WorkflowStep -Name "powershell-quality: pwsh syntax parse" -Action {
        $errors = [System.Collections.Generic.List[string]]::new()
        foreach ($file in $files) {
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
          $errors | Set-Content -Path $syntaxReport -Encoding utf8
          Write-Output ("PowerShell syntax validation found {0} issue(s). Report: {1}" -f $errors.Count, $syntaxReport)
          Get-Content -Path $syntaxReport | Write-Output
          throw "PowerShell syntax validation failed."
        }

        "No PowerShell syntax issues found." | Set-Content -Path $syntaxReport -Encoding utf8
        Write-Output ("No PowerShell syntax issues found. Report: {0}" -f $syntaxReport)
      }
    }
  }
}
finally {
  Pop-Location
}

$null = Write-WorkflowStatusSummary -RepoRoot $RepoRoot -WorkflowName "powershell-quality"
