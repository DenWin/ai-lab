# Stack Rules: PowerShell 7 (pwsh)

- Use Pester 5+ syntax. Do not mix older Pester patterns.
- Set `Set-StrictMode -Version Latest` and `$ErrorActionPreference = 'Stop'`
  in test setup. Without StrictMode, typos in property names silently return
  `$null` and tests pass when they should fail.
- Assert on **exact output shape** (type and value), not just truthiness —
  PowerShell's success stream merges return values with `Write-Output`, so a
  function can return a one-element array where the test expected a scalar.
- Distinguish **modules with logic** (TDD applies normally) from **diagnostic
  scripts** (TDD does not apply — the script is the verification). For
  diagnostics, basic engineering hygiene applies instead: fail fast on
  infrastructure problems, separate result output from progress logging, buffer
  results and flush once at the end, no silent continuation. For automation
  scripts, decide by whether they will grow: if yes, treat as a module from
  day one; if no, treat as a diagnostic.
- Mock named wrapper functions, never cmdlets like `Invoke-RestMethod` or
  `Get-AzKeyVaultSecret` directly. If code calls `Get-AzKeyVaultSecret`, wrap
  it in `Get-SecretFromVault` and mock that — otherwise the test couples to Az.
- Tests must not depend on `Write-Host` output (it bypasses the success stream
  and Pester cannot capture it cleanly — use `Write-Output` for results,
  `Write-Verbose`/`Write-Information` for progress), nor on current directory,
  environment variables, or `PSModulePath` without explicit isolation in
  `BeforeEach`/`AfterEach`.
