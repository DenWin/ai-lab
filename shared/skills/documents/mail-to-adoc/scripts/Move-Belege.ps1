#Requires -Version 7
<#
.SYNOPSIS
    Moves files from a staging folder to their target folder, removing duplicates.

.DESCRIPTION
    For each file in -SourceDir:
      - Identical copy already in -DestDir  → remove source (already staged)
      - Different file with same name in -DestDir → skip + warn (needs manual review)
      - Not in -DestDir → move source to dest
    Returns one [PSCustomObject] per file. -WhatIf respected throughout.

.PARAMETER SourceDir
    Staging folder to move files from.
    Default: <cwd>\.new\Abrechnungen

.PARAMETER DestDir
    Target folder to move files into.
    Default: <cwd>\02_Auskunft-Einkommen\Gehaltsabrechnungen

.PARAMETER Recurse
    Also process subfolders of -SourceDir. Folder structure is NOT recreated in -DestDir.

.PARAMETER WhatIf
    Show what would happen without making any changes.

.EXAMPLE
    # Default: .new\Abrechnungen → 02_Auskunft-Einkommen\Gehaltsabrechnungen
    .\Move-Belege.ps1 -WhatIf

.EXAMPLE
    # ESt-Bescheid
    .\Move-Belege.ps1 -SourceDir '.new\Steuern' -DestDir '04_Steuern'

.EXAMPLE
    # GbR
    .\Move-Belege.ps1 -SourceDir '.new\GbR' -DestDir '02_Auskunft-Einkommen\GbR-Beispiel-Immobilien'

.EXAMPLE
    # Pipe and inspect skipped files
    .\Move-Belege.ps1 | Where-Object Action -eq 'Skipped' | Format-List
#>
[CmdletBinding(SupportsShouldProcess)]
param (
    [string] $SourceDir = '',
    [string] $DestDir   = '',
    [switch] $Recurse
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Root = (Get-Location).Path

if (-not $SourceDir) { $SourceDir = Join-Path $Root '.new\Abrechnungen' }
if (-not $DestDir)   { $DestDir   = Join-Path $Root '02_Auskunft-Einkommen\Gehaltsabrechnungen' }

if (-not (Test-Path $SourceDir)) { throw "SourceDir not found: $SourceDir" }

# Create dest if it doesn't exist yet
if (-not (Test-Path $DestDir)) {
    if ($PSCmdlet.ShouldProcess($DestDir, 'Create directory')) {
        New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
    }
}

$GciParams = @{ LiteralPath = $SourceDir; File = $true }
if ($Recurse) { $GciParams['Recurse'] = $true }
$Files = Get-ChildItem @GciParams

if (-not $Files) {
    Write-Host "No files found in: $SourceDir"
    return
}

Write-Verbose "Source : $SourceDir$(if ($Recurse) { ' (recursive)' })"
Write-Verbose "Dest   : $DestDir"
Write-Verbose "Files  : $($Files.Count)"

foreach ($File in $Files) {
    $Result = [PSCustomObject]@{
        Name   = $File.Name
        Action = $null   # Moved | Removed | Skipped | Error
        Source = $File.FullName
        Dest   = Join-Path $DestDir $File.Name
        Note   = $null
    }

    try {
        if (Test-Path -LiteralPath $Result.Dest) {
            $HashSrc  = (Get-FileHash -LiteralPath $File.FullName  -Algorithm SHA256).Hash
            $HashDest = (Get-FileHash -LiteralPath $Result.Dest    -Algorithm SHA256).Hash

            if ($HashSrc -eq $HashDest) {
                # Identical — safe to remove source
                if ($PSCmdlet.ShouldProcess($File.FullName, 'Remove duplicate source')) {
                    Remove-Item -LiteralPath $File.FullName -Force
                }
                $Result.Action = 'Removed'
                $Result.Note   = 'Identical copy already at dest'
            } else {
                # Different content — do not overwrite, needs manual review
                $Result.Action = 'Skipped'
                $Result.Note   = 'Name collision with different content — review manually'
                Write-Warning "[$($File.Name)] Name exists at dest with different content — skipped"
            }
        } else {
            if ($PSCmdlet.ShouldProcess($File.FullName, "Move to $($Result.Dest)")) {
                Move-Item -LiteralPath $File.FullName -Destination $Result.Dest -Force
            }
            $Result.Action = 'Moved'
        }
    }
    catch {
        $Result.Action = 'Error'
        $Result.Note   = $_.Exception.Message
        Write-Warning "[$($File.Name)] $($_.Exception.Message)"
    }

    $Result
}
