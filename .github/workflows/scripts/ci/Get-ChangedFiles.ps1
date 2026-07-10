#Requires -Version 7.0
#Requires -PSEdition Core
# RuntimePolicy: core-first

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Base,
    [Parameter(Mandatory = $true)]
    [string]$Head,
    [string]$RepoRoot = "",
    [string[]]$Include = @("*"),
    [string[]]$Exclude = @(),
    [switch]$DisableDefaultExcludes,
    [switch]$FullScan,
    [switch]$OutputCount
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = (& git rev-parse --show-toplevel 2>$null)
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($RepoRoot)) {
        throw "Unable to resolve repo root. Run inside a git repository or pass -RepoRoot."
    }
}

$resolvedExclude = [System.Collections.Generic.List[string]]::new()
foreach ($pattern in $Exclude) {
    if (-not [string]::IsNullOrWhiteSpace($pattern)) { $resolvedExclude.Add($pattern) }
}

if (-not $DisableDefaultExcludes) {
    foreach ($pattern in @('.scratch/*/artefacts/**', '.scratch/*/artifacts/**')) {
        if (-not $resolvedExclude.Contains($pattern)) {
            $resolvedExclude.Add($pattern)
        }
    }
}

$autoFullScan = $env:GITHUB_EVENT_NAME -eq 'push' -and $env:GITHUB_REF -eq 'refs/heads/main'
$useFullScan = $FullScan -or $autoFullScan

$pathspecs = [System.Collections.Generic.List[string]]::new()
foreach ($pattern in $Include) {
    if (-not [string]::IsNullOrWhiteSpace($pattern)) { $pathspecs.Add($pattern) }
}
foreach ($pattern in $resolvedExclude) {
    if (-not [string]::IsNullOrWhiteSpace($pattern)) { $pathspecs.Add(":(exclude)$pattern") }
}

$files = @()
if ($useFullScan) {
    $files = & git -C $RepoRoot ls-files -- @pathspecs
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to enumerate tracked files via git ls-files."
    }
}
else {
    $files = & git -C $RepoRoot diff --name-only --diff-filter=ACMRTUXB $Base $Head -- @pathspecs
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to enumerate changed files for range $Base..$Head."
    }
}

$clean = @($files | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

if ($OutputCount) {
    $clean.Count
    return
}

$clean
