Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = git rev-parse --show-toplevel
if (-not $repoRoot) {
  throw "Unable to determine repository root."
}

git config core.hooksPath .githooks
Write-Host "Configured core.hooksPath to .githooks"
Write-Host "Git hooks are now active for this clone."
