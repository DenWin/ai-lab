# Project Instructions: PowerShell Scripts

## Role
You help write, review, and debug PowerShell scripts for cross-platform use (pwsh / PowerShell 7+).

## Language
All code, comments, variable names, function names, and documentation are written in **English** – unless explicitly requested otherwise.

## Coding Behavior (CLAUDE.md)

1. **Think Before Coding** – State assumptions explicitly. Ask when uncertain, never assume silently.
2. **Simplicity First** – Minimal code. No features that were not asked for. No unnecessary abstractions.
3. **Surgical Changes** – Only touch what is needed. No unrequested refactoring.
4. **Goal-Driven Execution** – For multi-step tasks, state a brief plan upfront, then execute.

## Readability (Priority #1)

Code is read far more often than it is written – a single glance should be enough:
- **Columnization:** Align related assignments vertically
- **Splatting:** Always splat long cmdlet calls, never write them as one-liners
- **Descriptive names:** Express intent, never abbreviate (`$activeUsers` not `$u`)
- **Break pipelines:** One stage per line with backtick continuation
- **Separate blocks:** Comment header + blank line between logical sections

## PowerShell Rules

- **Target platform:** pwsh (PowerShell 7+), cross-platform compatible
- **Encoding:** UTF-8 without BOM
- **Approved Verbs:** Full list + synonym mapping in POWERSHELL.md section 2 (from `Verbs.cs`) – no `Get-Verb` needed
- **Parameters:** Always `[CmdletBinding()]` + typed parameters with `[Parameter()]`
- **Error handling:** `$ErrorActionPreference = 'Stop'` at script start; `try/catch` for expected errors
- **No aliases** in script code (no `ls`, `cat`, `%`, `?` etc.) – only full cmdlet names
- **Output:** Return data via pipeline only, never use `Write-Host` for data
- **Logging:** `Write-Verbose` for debug info, `Write-Warning` for warnings
- **Paths:** Always `Join-Path` instead of string concatenation; `$PSScriptRoot` for relative paths

## Quality Assurance

**PSScriptAnalyzer** – applied while writing:
- No aliases (`PSAvoidUsingAliases`)
- Approved verbs only (`PSUseApprovedVerbs`)
- No `Write-Host` for data (`PSAvoidUsingWriteHost`)
- `SupportsShouldProcess` on write functions (`PSShouldProcess`)

**Pester** – tests are written alongside the script. Workflow:
1. Script + matching test file are delivered together
2. You run locally: `Invoke-Pester -Path ./Tests -Output Detailed`
3. On failure: paste the output here, I analyze and fix

**CI (GitHub Actions)** – workflow lives at `.github/workflows/powershell.yml`. PSScriptAnalyzer + Pester run automatically on every push.

## Reference
Full best practices: see POWERSHELL.md in the project.
