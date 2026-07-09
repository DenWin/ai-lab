Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = git rev-parse --show-toplevel
if (-not $repoRoot) {
  throw "Unable to determine repository root."
}

$hooksDir = Join-Path $repoRoot ".githooks"
if (Test-Path $hooksDir) {
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  Get-ChildItem -Path $hooksDir -File | ForEach-Object {
    $raw = [System.IO.File]::ReadAllText($_.FullName)
    $normalized = $raw -replace "`r`n", "`n" -replace "`r", "`n"
    if ($normalized -ne $raw) {
      [System.IO.File]::WriteAllText($_.FullName, $normalized, $utf8NoBom)
      Write-Output "Normalized LF line endings: $($_.Name)"
    }
  }
}

git config core.hooksPath .githooks
Write-Output "Configured core.hooksPath to .githooks"
Write-Output "Git hooks are now active for this clone."
