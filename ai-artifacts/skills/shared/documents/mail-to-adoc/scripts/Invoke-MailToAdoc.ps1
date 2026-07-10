#Requires -Version 7
#Requires -PSEdition Core
# RuntimePolicy: core-first
<#
.SYNOPSIS
    Batch-converts .eml/.msg files in a source folder to AsciiDoc via mail_to_adoc.py.

.DESCRIPTION
    For every .eml / .msg found in -SourceDir (default: <TargetDir-parent>\.new):
      1. Runs mail_to_adoc.py --json, captures the JSON result line.
      2. Verifies the output .adoc exists on disk.
      3. Verifies the archived copy is byte-for-byte identical to the original.
      4. Removes the original from -SourceDir if both checks pass (-WhatIf respected).
    Returns one [PSCustomObject] per processed file — pipeline-friendly.

.PARAMETER SourceDir
    Folder to scan for .eml / .msg files.
    Default: <TargetDir-parent>\.new

.PARAMETER TargetDir
    The 01_Korrespondenz output directory. Its parent becomes --root for mail_to_adoc.py.
    Default: <current working directory>\01_Korrespondenz

.PARAMETER Recurse
    Also scan subfolders of -SourceDir for .eml / .msg files.

.PARAMETER Overwrite
    Pass --overwrite to mail_to_adoc.py — overwrites an existing identical adoc.

.PARAMETER PythonExe
    Python interpreter to use.  Default: 'python' (relies on PATH).

.PARAMETER ScriptPath
    Explicit path to mail_to_adoc.py.
    Default: <this script's directory>\mail_to_adoc.py

.PARAMETER WhatIf
    Standard PS -WhatIf: skips deletion of source originals; all other steps run normally.

.EXAMPLE
    # Dry-run — see what would be deleted
    .\Invoke-MailToAdoc.ps1 -WhatIf

.EXAMPLE
    # Include subfolders of .new
    .\Invoke-MailToAdoc.ps1 -Recurse -Verbose

.EXAMPLE
    # Explicit target, pipe results and filter failures
    .\Invoke-MailToAdoc.ps1 -TargetDir 'D:\Projekt\01_Korrespondenz' |
        Where-Object { -not $_.Verified } | Select-Object Source, Error
#>
[CmdletBinding(SupportsShouldProcess)]
param (
    [string] $SourceDir  = '',
    [string] $TargetDir  = '',
    [switch] $Recurse,
    [switch] $Overwrite,
    [string] $PythonExe  = 'python',
    [string] $ScriptPath = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Resolve defaults ──────────────────────────────────────────────────────────
if (-not $ScriptPath) {
    $ScriptPath = Join-Path $PSScriptRoot 'mail_to_adoc.py'
}
if (-not (Test-Path $ScriptPath)) {
    throw "mail_to_adoc.py not found at: $ScriptPath"
}

# TargetDir default: <cwd>\01_Korrespondenz
if (-not $TargetDir) {
    $TargetDir = Join-Path (Get-Location).Path '01_Korrespondenz'
}
# Python --root is TargetDir's parent (the project root)
$EffectiveRoot = Split-Path $TargetDir -Parent

if (-not $SourceDir) {
    $SourceDir = Join-Path $EffectiveRoot '.new'
}
if (-not (Test-Path $SourceDir)) {
    throw "Source directory not found: $SourceDir"
}

# ── Build constant Python args ─────────────────────────────────────────────
$PyArgs = @('--root', $EffectiveRoot, '--json')
if ($Overwrite) { $PyArgs += '--overwrite' }

# ── Collect input files ───────────────────────────────────────────────────────
$GciParams = @{ LiteralPath = $SourceDir; File = $true }
if ($Recurse) { $GciParams['Recurse'] = $true }
$Files = Get-ChildItem @GciParams | Where-Object { $_.Extension -in '.eml', '.msg' }

if (-not $Files) {
    Write-Host "No .eml / .msg files found in: $SourceDir$(if ($Recurse) { ' (recursive)' })"
    return
}

Write-Verbose "TargetDir: $TargetDir"
Write-Verbose "Root     : $EffectiveRoot"
Write-Verbose "SourceDir: $SourceDir$(if ($Recurse) { ' (recursive)' })"
Write-Verbose "Files    : $($Files.Count)"

# ── Process loop ──────────────────────────────────────────────────────────────
foreach ($File in $Files) {
    $Result = [PSCustomObject]@{
        Source         = $File.FullName
        SourceName     = $File.Name
        AdocPath       = $null
        AdocStatus     = $null
        ArchivePath    = $null
        ArchiveStatus  = $null
        AdocExists     = $false
        ArchiveMatch   = $false
        OrigRemoved    = $false
        Verified       = $false
        Error          = $null
        RawJson        = $null
    }

    try {
        # ── 1. Run Python ─────────────────────────────────────────────────────
        $AllArgs = $PyArgs + @($File.FullName)
        Write-Verbose "Running: $PythonExe $ScriptPath $($AllArgs -join ' ')"

        # stdout → JSON; stderr → Verbose stream
        $stdout = & $PythonExe $ScriptPath @AllArgs 2>&1 |
                  ForEach-Object {
                      if ($_ -is [System.Management.Automation.ErrorRecord]) {
                          Write-Verbose "  [py] $($_.Exception.Message)"
                      } else {
                          Write-Verbose "  [py] $_"
                          $_   # pass non-error lines through
                      }
                  }

        # Last non-empty line that starts with '{' is the JSON
        $JsonLine = ($stdout | Where-Object { $_ -match '^\s*\{' } | Select-Object -Last 1)

        if (-not $JsonLine) {
            $Result.Error = "No JSON output from Python"
            Write-Warning "[$($File.Name)] No JSON output — Python may have failed"
            continue
        }

        $Result.RawJson      = $JsonLine
        $jr                  = $JsonLine | ConvertFrom-Json
        $Result.AdocPath     = $jr.adoc
        $Result.AdocStatus   = $jr.adoc_status
        $Result.ArchivePath  = $jr.archive
        $Result.ArchiveStatus= $jr.archive_status

        # ── 2. Verify adoc exists ─────────────────────────────────────────────
        if ($Result.AdocPath -and (Test-Path -LiteralPath $Result.AdocPath)) {
            $Result.AdocExists = $true
        } else {
            $Result.Error = "Adoc not found: $($Result.AdocPath)"
            Write-Warning "[$($File.Name)] Adoc missing: $($Result.AdocPath)"
            continue
        }

        # ── 3. Verify archive is byte-identical to original ───────────────────
        if ($Result.ArchivePath -and (Test-Path -LiteralPath $Result.ArchivePath)) {
            if (Test-Path -LiteralPath $File.FullName) {
                # Original still on disk — compare hashes
                $HashOrig    = (Get-FileHash -LiteralPath $File.FullName    -Algorithm SHA256).Hash
                $HashArchive = (Get-FileHash -LiteralPath $Result.ArchivePath -Algorithm SHA256).Hash
                $Result.ArchiveMatch = $HashOrig -eq $HashArchive
                if (-not $Result.ArchiveMatch) {
                    $Result.Error = "Archive hash mismatch — NOT deleting original"
                    Write-Warning "[$($File.Name)] SHA256 mismatch — skipping removal"
                    continue
                }
            } else {
                # Python already deleted the original (succeeded on Windows)
                $Result.ArchiveMatch = $true
                $Result.OrigRemoved  = $true
                $Result.Verified     = $true
                Write-Verbose "[$($File.Name)] Original already removed by Python"
                continue
            }
        } elseif ($Result.ArchiveStatus -in 'skipped','skipped_rename') {
            # Archive already existed and was identical — treat as verified
            $Result.ArchiveMatch = $true
        } else {
            $Result.Error = "Archive path missing or not set"
            Write-Warning "[$($File.Name)] Archive not found: $($Result.ArchivePath)"
            continue
        }

        # ── 4. Remove original from SourceDir ────────────────────────────────
        $Result.Verified = $true

        if (Test-Path -LiteralPath $File.FullName) {
            if ($PSCmdlet.ShouldProcess($File.FullName, 'Remove original from .new')) {
                Remove-Item -LiteralPath $File.FullName -Force
                $Result.OrigRemoved = $true
                Write-Verbose "[$($File.Name)] Original removed"
            }
        }
    }
    catch {
        $Result.Error = $_.Exception.Message
        Write-Warning "[$($File.Name)] Exception: $($_.Exception.Message)"
    }
    finally {
        $Result   # emit to pipeline
    }
}
