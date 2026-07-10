#Requires -Version 7.0
#Requires -PSEdition Core
# RuntimePolicy: core-first

[CmdletBinding()]
param(
    [string]$Base = "",
    [string]$Head = "",
    [string]$Before = "",
    [string]$Sha = "",
    [string]$RepoRoot = "",
    [switch]$WriteGithubOutput
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = (& git rev-parse --show-toplevel 2>$null)
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($RepoRoot)) {
        throw "Unable to resolve repo root. Run inside a git repository or pass -RepoRoot."
    }
}

if ([string]::IsNullOrWhiteSpace($Base)) { $Base = $Before }
if ([string]::IsNullOrWhiteSpace($Head)) { $Head = $Sha }

if ([string]::IsNullOrWhiteSpace($Head)) {
    throw "Head SHA is empty. Pass -Head or -Sha."
}

if ([string]::IsNullOrWhiteSpace($Base) -or $Base -eq "0000000000000000000000000000000000000000") {
    $Base = (& git -C $RepoRoot rev-list --max-parents=0 $Head | Select-Object -Last 1)
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($Base)) {
        throw "Failed to resolve fallback base commit from head '$Head'."
    }
}

if ($WriteGithubOutput) {
    if ([string]::IsNullOrWhiteSpace($env:GITHUB_OUTPUT)) {
        throw "GITHUB_OUTPUT is not set; cannot write workflow outputs."
    }
    "base=$Base" >> $env:GITHUB_OUTPUT
    "head=$Head" >> $env:GITHUB_OUTPUT
}

[PSCustomObject]@{
    base = $Base
    head = $Head
}
