#!/usr/bin/env pwsh
# RuntimePolicy: core-first
#Requires -Version 7.0
#Requires -PSEdition Core

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = (& git rev-parse --show-toplevel 2>$null)
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($repoRoot)) {
    throw "Unable to determine repository root for hook execution."
}
$repoRoot = (Resolve-Path $repoRoot).Path

function Assert-ToolAvailable {
    param(
        [string]$Name,
        [string]$Hint
    )

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Missing required tool: $Name. $Hint"
    }
}

function Get-Match {
    param(
        [string[]]$Files,
        [string]$Pattern
    )

    $hits = @($Files | Where-Object { $_ -match $Pattern })
    return ,$hits
}

$staged = @(& git diff --cached --name-only --diff-filter=ACMRTUXB)
if ($LASTEXITCODE -ne 0) {
    throw "Failed to enumerate staged files for pre-commit hook."
}
if (-not $staged -or $staged.Count -eq 0) {
    exit 0
}

# Keep scratch artifacts as-is for linting; safety scans still run in CI.
$filtered = @($staged | Where-Object { $_ -notmatch '^\.scratch/.+/(artefacts|artifacts)/' })
if (-not $filtered -or $filtered.Count -eq 0) {
    exit 0
}

$failed = $false
$nullDevice = if ($IsWindows) { 'NUL' } else { '/dev/null' }

try {
    # Reuse the same policy validators used in CI workflows.
    Assert-ToolAvailable -Name "python" -Hint "Install Python 3 and add it to PATH."
    & python (Join-Path $repoRoot ".github/workflows/scripts/validate-coding-policies.py")
    if ($LASTEXITCODE -ne 0) { $failed = $true }

    & python (Join-Path $repoRoot ".github/workflows/scripts/validate-powershell-runtime.py")
    if ($LASTEXITCODE -ne 0) { $failed = $true }

    $yamlFiles = Get-Match -Files $filtered -Pattern '\.(yml|yaml)$'
    if ($yamlFiles.Count -gt 0) {
        Assert-ToolAvailable -Name "yamllint" -Hint "Install with: pip install yamllint"
        & yamllint -s @yamlFiles
        if ($LASTEXITCODE -ne 0) { $failed = $true }
    }

    $jsonFiles = Get-Match -Files $filtered -Pattern '\.json$'
    if ($jsonFiles.Count -gt 0) {
        Assert-ToolAvailable -Name "python" -Hint "Install Python 3 and add it to PATH."
        foreach ($file in $jsonFiles) {
            & python -m json.tool $file > $null
            if ($LASTEXITCODE -ne 0) {
                $failed = $true
            }
        }
    }

    $mdFiles = Get-Match -Files $filtered -Pattern '\.md$'
    if ($mdFiles.Count -gt 0) {
        Assert-ToolAvailable -Name "markdownlint" -Hint "Install with: npm install -g markdownlint-cli"
        & markdownlint @mdFiles --config .markdownlint.json
        if ($LASTEXITCODE -ne 0) { $failed = $true }
    }

    $adocFiles = Get-Match -Files $filtered -Pattern '\.(adoc|asciidoc)$'
    if ($adocFiles.Count -gt 0) {
        Assert-ToolAvailable -Name "asciidoctor" -Hint "Install with: gem install asciidoctor asciidoctor-lint"
        Assert-ToolAvailable -Name "asciidoctor-lint" -Hint "Install with: gem install asciidoctor asciidoctor-lint"
        foreach ($file in $adocFiles) {
            & asciidoctor -o $nullDevice $file
            if ($LASTEXITCODE -ne 0) { $failed = $true }
            & asciidoctor-lint $file
            if ($LASTEXITCODE -ne 0) { $failed = $true }
        }
    }

    $pyFiles = Get-Match -Files $filtered -Pattern '\.py$'
    if ($pyFiles.Count -gt 0) {
        Assert-ToolAvailable -Name "ruff" -Hint "Install with: pip install ruff"
        & python -m ruff check @pyFiles
        if ($LASTEXITCODE -ne 0) { $failed = $true }
        & python -m ruff format --check @pyFiles
        if ($LASTEXITCODE -ne 0) { $failed = $true }
    }

    $psFiles = Get-Match -Files $filtered -Pattern '\.(ps1|psm1|psd1)$'
    if ($psFiles.Count -gt 0) {
        Assert-ToolAvailable -Name "pwsh" -Hint "Install PowerShell 7 and PSScriptAnalyzer module."
        if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
            Set-PSRepository PSGallery -InstallationPolicy Trusted
            Install-Module PSScriptAnalyzer -Scope CurrentUser -Force
        }

        $results = @(foreach ($psFile in $psFiles) { Invoke-ScriptAnalyzer -Path $psFile -Severity Warning,Error })
        if ($results.Count -gt 0) {
            $results | Format-Table -AutoSize | Out-String | Write-Output
            $failed = $true
        }
    }

    $shFiles = Get-Match -Files $filtered -Pattern '\.sh$'
    if ($shFiles.Count -gt 0) {
        Assert-ToolAvailable -Name "shellcheck" -Hint "Install shellcheck and add it to PATH."
        & shellcheck @shFiles
        if ($LASTEXITCODE -ne 0) { $failed = $true }
    }

    $jsFiles = Get-Match -Files $filtered -Pattern '\.js$'
    if ($jsFiles.Count -gt 0) {
        Assert-ToolAvailable -Name "node" -Hint "Install Node.js and add it to PATH."
        foreach ($file in $jsFiles) {
            & node --check $file
            if ($LASTEXITCODE -ne 0) { $failed = $true }
        }
    }
}
catch {
    Write-Error $_
    exit 1
}

if ($failed) {
    exit 1
}

exit 0
