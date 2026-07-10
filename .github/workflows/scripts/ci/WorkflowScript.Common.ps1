#Requires -Version 7.0
#Requires -PSEdition Core
# RuntimePolicy: core-first

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:WorkflowIndentLevel = 0
$script:WorkflowCurrentFailures = [System.Collections.Generic.List[string]]::new()
$script:WorkflowCurrentName = "workflow"

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

function Assert-WorkflowCommandAvailable {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Name,
    [Parameter(Mandatory = $true)]
    [string]$InstallHint
  )

  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "Required command '$Name' is not available. $InstallHint"
  }
}

function Reset-WorkflowFailures {
  param(
    [string]$WorkflowName = "workflow"
  )

  $script:WorkflowCurrentName = $WorkflowName
  $script:WorkflowCurrentFailures = [System.Collections.Generic.List[string]]::new()
}

function Get-WorkflowFailures {
  return @($script:WorkflowCurrentFailures)
}

function Add-WorkflowFailure {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Message
  )

  $script:WorkflowCurrentFailures.Add($Message) | Out-Null
}

function Get-WorkflowReportDirectory {
  param(
    [Parameter(Mandatory = $true)]
    [string]$RepoRoot
  )

  $envReportDir = $env:REPORTS_DIR
  if (-not [string]::IsNullOrWhiteSpace($envReportDir)) {
    if ([System.IO.Path]::IsPathRooted($envReportDir)) {
      return $envReportDir
    }
    return (Join-Path $RepoRoot $envReportDir)
  }

  return (Join-Path $RepoRoot ".temp/Reports")
}

function Write-WorkflowStatusSummary {
  param(
    [Parameter(Mandatory = $true)]
    [string]$RepoRoot,
    [string]$WorkflowName = ""
  )

  if ([string]::IsNullOrWhiteSpace($WorkflowName)) {
    $WorkflowName = $script:WorkflowCurrentName
  }

  $reportDir = Get-WorkflowReportDirectory -RepoRoot $RepoRoot
  New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
  $summaryPath = Join-Path $reportDir ("{0}-local-summary.txt" -f $WorkflowName)

  $failures = @($script:WorkflowCurrentFailures)
  if ($failures.Count -eq 0) {
    @(
      "Workflow: $WorkflowName",
      "Status: SUCCESS",
      "Timestamp: $(Get-Date -Format o)",
      "No step failures recorded."
    ) | Set-Content -Path $summaryPath -Encoding utf8

    Write-WorkflowLine ("LOCAL WORKFLOW STATUS: SUCCESS ({0})" -f $WorkflowName)
    Write-WorkflowLine ("Report: {0}" -f $summaryPath)
    return [PSCustomObject]@{
      WorkflowName = $WorkflowName
      HasFailures  = $false
      FailureCount = 0
      ReportPath   = $summaryPath
    }
  }

  $content = [System.Collections.Generic.List[string]]::new()
  $content.Add("Workflow: $WorkflowName") | Out-Null
  $content.Add("Status: FAILED") | Out-Null
  $content.Add("Timestamp: $(Get-Date -Format o)") | Out-Null
  $content.Add("Failure count: $($failures.Count)") | Out-Null
  $content.Add("") | Out-Null
  foreach ($failure in $failures) {
    $content.Add("- $failure") | Out-Null
  }
  $content | Set-Content -Path $summaryPath -Encoding utf8

  Write-WorkflowLine ("LOCAL WORKFLOW STATUS: FAILED ({0})" -f $WorkflowName)
  Write-WorkflowLine ("Failure count: {0}" -f $failures.Count)
  foreach ($failure in $failures) {
    Write-WorkflowLine ("[FAIL] {0}" -f $failure)
  }
  Write-WorkflowLine ("Report: {0}" -f $summaryPath)

  return [PSCustomObject]@{
    WorkflowName = $WorkflowName
    HasFailures  = $true
    FailureCount = $failures.Count
    ReportPath   = $summaryPath
  }
}

function Invoke-WorkflowStep {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Name,
    [Parameter(Mandatory = $true)]
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
  catch {
    $message = "{0}: {1}" -f $Name, $_.Exception.Message
    Add-WorkflowFailure -Message $message
    Write-WorkflowLine ("[LOCAL FAILURE] {0}" -f $message)
  }
  finally {
    $script:WorkflowIndentLevel--
  }
}

function Resolve-WorkflowRepoRoot {
  param(
    [string]$RepoRoot,
    [string]$CallerRoot
  )

  if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = (& git -C $CallerRoot rev-parse --show-toplevel 2>$null)
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($RepoRoot)) {
      throw "Unable to determine repo root. Run from inside the repo or pass -RepoRoot."
    }
  }

  $resolved = (Resolve-Path $RepoRoot).Path
  if (-not (Test-Path (Join-Path $resolved ".git"))) {
    throw "Repo root is invalid: $resolved"
  }
  return $resolved
}

function Resolve-WorkflowDiffRange {
  param(
    [Parameter(Mandatory = $true)]
    [string]$RepoRoot,
    [string]$Base,
    [string]$Head
  )

  if ([string]::IsNullOrWhiteSpace($Head)) {
    $Head = (& git -C $RepoRoot rev-parse HEAD)
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($Head)) {
      throw "Unable to resolve HEAD commit."
    }
  }

  if ([string]::IsNullOrWhiteSpace($Base)) {
    $Base = (& git -C $RepoRoot rev-parse "$Head~1" 2>$null)
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($Base)) {
      $Base = (& git -C $RepoRoot rev-list --max-parents=0 $Head | Select-Object -Last 1)
      if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($Base)) {
        throw "Unable to resolve base commit."
      }
    }
  }

  return [PSCustomObject]@{
    Base = $Base
    Head = $Head
  }
}

function Get-WorkflowFiles {
  param(
    [Parameter(Mandatory = $true)]
    [string]$RepoRoot,
    [Parameter(Mandatory = $true)]
    [string]$Base,
    [Parameter(Mandatory = $true)]
    [string]$Head,
    [Parameter(Mandatory = $true)]
    [string[]]$Include,
    [switch]$FullScan
  )

  $resolvedExclude = @('.scratch/*/artefacts/**', '.scratch/*/artifacts/**')
  $pathspecs = [System.Collections.Generic.List[string]]::new()
  foreach ($pattern in $Include) {
    if (-not [string]::IsNullOrWhiteSpace($pattern)) {
      $pathspecs.Add($pattern)
    }
  }
  foreach ($pattern in $resolvedExclude) {
    $pathspecs.Add(":(exclude)$pattern")
  }

  $autoFullScan = $env:GITHUB_EVENT_NAME -eq 'push' -and $env:GITHUB_REF -eq 'refs/heads/main'
  $useFullScan = $FullScan -or $autoFullScan

  $files = if ($useFullScan) {
    & git -C $RepoRoot ls-files -- @pathspecs
  }
  else {
    & git -C $RepoRoot diff --name-only --diff-filter=ACMRTUXB $Base $Head -- @pathspecs
  }
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to enumerate files for includes: $($Include -join ', ')."
  }

  return @(
    $files |
      Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
      Where-Object { Test-Path -LiteralPath (Join-Path $RepoRoot $_) -PathType Leaf }
  )
}
