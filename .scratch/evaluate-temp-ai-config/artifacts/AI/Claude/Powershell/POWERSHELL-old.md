# POWERSHELL.md – Best Practices Reference

Target platform: **pwsh (PowerShell 7+)**, cross-platform (Windows, Linux, macOS).

**Language:** All code, comments, variable names, function names, and documentation are written in English – unless explicitly requested otherwise.

---

## 1. File Structure & Encoding

```powershell
# Always at the top of a script
#Requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$InputPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
```

- **Encoding:** UTF-8 without BOM (`utf8NoBOM`)
- **Line endings:** LF preferred (cross-platform), avoid CRLF
- **Shebang for Linux/macOS:**
  ```
  #!/usr/bin/env pwsh
  ```

---

## 2. Naming Conventions

| Element       | Convention             | Example              |
|---------------|------------------------|----------------------|
| Functions     | `Verb-Noun` (approved) | `Get-UserReport`     |
| Parameters    | PascalCase             | `$InputPath`         |
| Local vars    | camelCase              | `$fileCount`         |
| Constants     | UPPER_SNAKE            | `$MAX_RETRIES = 3`   |
| Script files  | `Verb-Noun.ps1`        | `Get-UserReport.ps1` |
| Modules       | PascalCase             | `MyCompany.Utils`    |

**Approved Verbs** (source: `Verbs.cs` in the PowerShell repository):

| Group          | Verbs |
|----------------|-------|
| Common         | Add, Clear, Close, Copy, Enter, Exit, Find, Format, Get, Hide, Join, Lock, Move, New, Open, Optimize, Pop, Push, Redo, Remove, Rename, Reset, Resize, Search, Select, Set, Show, Skip, Split, Step, Switch, Undo, Unlock, Watch |
| Communications | Connect, Disconnect, Read, Receive, Send, Write |
| Data           | Backup, Checkpoint, Compare, Compress, Convert, ConvertFrom, ConvertTo, Dismount, Edit, Expand, Export, Group, Import, Initialize, Limit, Merge, Mount, Out, Publish, Restore, Save, Sync, Unpublish, Update |
| Diagnostic     | Debug, Measure, Ping, Repair, Resolve, Test, Trace |
| Lifecycle      | Approve, Assert, Build, Complete, Confirm, Deny, Deploy, Disable, Enable, Install, Invoke, Register, Request, Restart, Resume, Start, Stop, Submit, Suspend, Uninstall, Unregister, Wait |
| Security       | Block, Grant, Protect, Revoke, Unblock, Unprotect |
| Other          | Use |

**Common synonyms → correct verb:**

| Instead of...                    | Use                  |
|----------------------------------|----------------------|
| Create, Generate, Make, Allocate | `New`                |
| Delete, Erase, Purge, Cut        | `Remove`             |
| Run, Execute                     | `Invoke` / `Start`   |
| Load                             | `Import`             |
| Save (persist)                   | `Export` / `Backup`  |
| Fix, Return                      | `Repair` / `Restore` |
| Modify, Amend, Revise, Change    | `Edit` / `Set`       |
| Display, Print                   | `Show` / `Write`     |
| Verify, Analyze, Diagnose        | `Test`               |
| Refresh, Reload, Renew, Index    | `Update`             |
| Launch, Boot, Initiate           | `Start`              |
| Kill, Terminate, Cancel, End     | `Stop`               |
| Setup                            | `Initialize` / `Install` |

Never invent custom verbs – if nothing fits, check the synonym list first.

---

## 3. Readability & Visual Structure

**Core principle:** Code is read far more often than it is written. A single glance should be enough to understand what is happening.

### Columnization

Related assignments are aligned vertically. The eye instantly recognizes groups as a unit.

```powershell
# ✅ Columnized – pattern immediately visible
$firstName   = 'Max'
$lastName    = 'Mustermann'
$email       = 'max@example.com'
$role        = 'Admin'
$isActive    = $true

# ❌ Unaligned – no visual pattern
$firstName = 'Max'
$lastName = 'Mustermann'
$email = 'max@example.com'
$role = 'Admin'
$isActive = $true
```

Applies to hashtables and splatting as well:

```powershell
# ✅ Hashtable columnized
$config = @{
    ServerName   = 'srv-prod-01'
    DatabaseName = 'AppDb'
    Port         = 5432
    Timeout      = 30
    UseSsl       = $true
}

# ✅ Splatting columnized
$params = @{
    Path        = $outputPath
    Encoding    = 'utf8NoBOM'
    Force       = $true
    ErrorAction = 'Stop'
}
Set-Content @params
```

### Splatting instead of long one-liners

```powershell
# ❌ Bad – too long, hard to scan
Copy-Item -Path $sourcePath -Destination $destPath -Recurse -Force -ErrorAction Stop

# ✅ Good – every parameter immediately visible
$params = @{
    Path        = $sourcePath
    Destination = $destPath
    Recurse     = $true
    Force       = $true
    ErrorAction = 'Stop'
}
Copy-Item @params
```

### Descriptive names – no guessing

Names should express intent, not type or abbreviation.

```powershell
# ❌ Unclear
$d   = Get-Date
$u   = Get-ADUser -Filter *
$res = Invoke-RestMethod $url
$tmp = $users | Where-Object { $_.Enabled }

# ✅ Self-explanatory
$today       = Get-Date
$allUsers    = Get-ADUser -Filter *
$apiResponse = Invoke-RestMethod $url
$activeUsers = $allUsers | Where-Object { $_.Enabled }
```

### Break pipeline chains across lines

```powershell
# ❌ Everything on one line
$result = Get-ChildItem -Path $logDir -Filter '*.log' | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } | Sort-Object LastWriteTime | Select-Object -Last 10

# ✅ One step per line – reads like a recipe
$result = Get-ChildItem -Path $logDir -Filter '*.log'                           `
              | Where-Object  { $_.LastWriteTime -lt (Get-Date).AddDays(-30) }  `
              | Sort-Object     LastWriteTime                                   `
              | Select-Object  -Last 10
```

Note: backtick line continuation is sensitive to trailing whitespace – even one space after the backtick breaks it.

### Separate logical blocks with blank lines and comment headers

```powershell
function Invoke-DataExport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $SourcePath,
        [Parameter(Mandatory)] [string] $OutputPath
    )

    # --- Validate input ---
    if (-not (Test-Path -Path $SourcePath)) {
        throw "Source not found: $SourcePath"
    }

    # --- Load data ---
    $rawData     = Import-Csv -Path $SourcePath
    $activeRows  = $rawData | Where-Object { $_.Status -eq 'Active' }

    # --- Process ---
    $exportData = $activeRows | Select-Object Name, Email, CreatedAt

    # --- Output ---
    $exportData | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding utf8NoBOM
    Write-Verbose "Exported $($exportData.Count) rows to $OutputPath"
}
```

**Rules summary:**
- Related assignments → align `=` columnized
- Related cmdlet calls → align parameter names and values columnized
- Long cmdlet calls → splat them
- Names → express intent, never abbreviate
- Pipeline chains → one stage per line with backtick continuation
- Logical sections → comment header + blank line

---

## 4. Parameters & CmdletBinding

```powershell
function Get-ProcessInfo {
    [CmdletBinding(SupportsShouldProcess)]  # SupportsShouldProcess for write operations
    param(
        [Parameter(Mandatory, ValueFromPipeline, HelpMessage = 'Process name or ID')]
        [string]$Name,

        [Parameter()]
        [ValidateRange(1, 65535)]
        [int]$Port = 8080,

        [Parameter()]
        [ValidateSet('json', 'csv', 'text')]
        [string]$Format = 'text',

        [Parameter()]
        [switch]$Force
    )

    begin   { }
    process { }
    end     { }
}
```

**Rules:**
- Always use `[CmdletBinding()]` – enables `-Verbose`, `-Debug`, `-WhatIf`, `-ErrorAction` etc.
- Add `SupportsShouldProcess` for functions that modify or delete data
- Add `ValueFromPipeline` where it makes sense
- Validate directly in the parameter: `[ValidateNotNullOrEmpty()]`, `[ValidateRange()]`, `[ValidateSet()]`, `[ValidatePattern()]`
- Never use positional parameters without explicitly setting `Position = 0`

---

## 5. Error Handling

```powershell
$ErrorActionPreference = 'Stop'  # Force terminating errors

function Remove-TempFiles {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -Path $Path)) {
        throw "Path not found: $Path"
    }

    try {
        if ($PSCmdlet.ShouldProcess($Path, 'Delete files')) {
            Remove-Item -Path $Path -Recurse -Force
        }
    }
    catch [System.UnauthorizedAccessException] {
        Write-Error "Access denied: $Path"
    }
    catch {
        Write-Error "Unexpected error: $_"
        throw  # Re-throw if unrecoverable
    }
}
```

**Rules:**
- `$ErrorActionPreference = 'Stop'` at the top of every script
- Catch specific exception types (`[System.IO.FileNotFoundException]` etc.)
- Use `throw` for your own errors, never `Write-Error` as a substitute for aborting
- `$_` in the catch block holds the current exception object

---

## 6. WhatIf & Verbose

### WhatIf (`SupportsShouldProcess`)

Add `SupportsShouldProcess` to any function that modifies, deletes, or creates resources. This gives callers `-WhatIf` (dry run) and `-Confirm` (prompt before each action) for free.

```powershell
function Remove-OldLogs {
    [CmdletBinding(SupportsShouldProcess)]  # enables -WhatIf and -Confirm
    param(
        [Parameter(Mandatory)]
        [string]$LogPath,

        [Parameter()]
        [int]$RetentionDays = 30
    )

    $cutoffDate = (Get-Date).AddDays(-$RetentionDays)
    $oldLogs    = Get-ChildItem -Path $LogPath -Filter '*.log' `
                      | Where-Object { $_.LastWriteTime -lt $cutoffDate }

    foreach ($log in $oldLogs) {
        # ShouldProcess returns $false when -WhatIf is passed – nothing gets deleted
        if ($PSCmdlet.ShouldProcess($log.FullName, 'Remove log file')) {
            Remove-Item -Path $log.FullName -Force
            Write-Verbose "Removed: $($log.FullName)"
        }
    }
}
```

**Calling the function:**
```powershell
# Normal run – deletes files
Remove-OldLogs -LogPath 'C:/logs'

# Dry run – prints what WOULD happen, deletes nothing
Remove-OldLogs -LogPath 'C:/logs' -WhatIf

# Prompts before each deletion
Remove-OldLogs -LogPath 'C:/logs' -Confirm
```

**`ShouldProcess` message format:**
```powershell
# $PSCmdlet.ShouldProcess(target, action)
#   target → the resource being affected (file path, server name, etc.)
#   action → what will be done to it
$PSCmdlet.ShouldProcess($log.FullName,  'Remove log file')
$PSCmdlet.ShouldProcess($serverName,    'Restart service')
$PSCmdlet.ShouldProcess($databaseName,  'Drop table')
```

**`ConfirmImpact` – control when `-Confirm` prompts automatically:**
```powershell
# Default is Medium – only prompts when user passes -Confirm explicitly
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]

# ConfirmImpact levels:
#   None   – never prompts automatically
#   Low    – prompts when $ConfirmPreference is Low or lower
#   Medium – prompts when $ConfirmPreference is Medium or lower (default)
#   High   – always prompts automatically (use for destructive operations)
```

**Rules:**
- Every function that writes, deletes, or modifies → add `SupportsShouldProcess`
- Always gate the destructive call behind `if ($PSCmdlet.ShouldProcess(...))`
- Use `ConfirmImpact = 'High'` for irreversible operations (drop DB, format disk etc.)
- Never call `$PSCmdlet.ShouldProcess` more than once per operation

---

### Verbose & Debug output

`-Verbose` and `-Debug` are enabled automatically by `[CmdletBinding()]` – no extra plumbing needed.

```powershell
function Invoke-DataSync {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)] [string] $SourcePath,
        [Parameter(Mandatory)] [string] $DestPath
    )

    Write-Verbose "Starting sync: $SourcePath → $DestPath"

    $files = Get-ChildItem -Path $SourcePath -Recurse
    Write-Verbose "Found $($files.Count) files to sync"

    foreach ($file in $files) {
        Write-Debug "Processing: $($file.FullName)"  # only shown with -Debug

        if ($PSCmdlet.ShouldProcess($file.Name, 'Copy file')) {
            Copy-Item -Path $file.FullName -Destination $DestPath -Force
        }
    }

    Write-Verbose "Sync complete"
}
```

**Calling with output levels:**
```powershell
# Silent – only errors shown
Invoke-DataSync -SourcePath './src' -DestPath './dst'

# Progress messages shown
Invoke-DataSync -SourcePath './src' -DestPath './dst' -Verbose

# Full detail including per-file debug output
Invoke-DataSync -SourcePath './src' -DestPath './dst' -Debug

# Dry run with progress messages
Invoke-DataSync -SourcePath './src' -DestPath './dst' -WhatIf -Verbose
```

**Write-* stream guide:**

| Cmdlet            | Stream  | When to use                                      | Visible by default |
|-------------------|---------|--------------------------------------------------|--------------------|
| `Write-Output`    | Success | Return data via pipeline                         | ✅ Yes             |
| `Write-Verbose`   | Verbose | Progress / what the function is doing            | ❌ Only with `-Verbose` |
| `Write-Debug`     | Debug   | Fine-grained detail for troubleshooting          | ❌ Only with `-Debug` |
| `Write-Warning`   | Warning | Something unexpected but recoverable             | ✅ Yes             |
| `Write-Error`     | Error   | Non-terminating error (continues execution)      | ✅ Yes             |
| `Write-Host`      | Info    | Interactive UI only – never for data             | ✅ Yes (not capturable) |
| `Write-Progress`  | Progress | Long-running operation progress bar             | ✅ Yes             |

**Rules:**
- `Write-Verbose` for every meaningful step – makes `-Verbose` actually useful
- `Write-Debug` for per-item or per-iteration detail
- Never use `Write-Host` for anything that should be captured or redirected
- `-Verbose` and `-WhatIf` combine naturally – always test both together

---

## 7. Output & Pipeline

```powershell
# ✅ Correct – output via pipeline
function Get-ActiveUsers {
    Get-ADUser -Filter { Enabled -eq $true } |
        Select-Object Name, SamAccountName, LastLogonDate
}

# ❌ Wrong – Write-Host swallows data
function Get-ActiveUsers {
    $users = Get-ADUser -Filter *
    Write-Host $users  # Data never reaches the pipeline!
}
```

**Rules:**
- Always return data via the pipeline (implicit `return` / `Write-Output`)
- `Write-Host` only for purely interactive UI output, never for data
- `Write-Verbose` for debug information (only visible with `-Verbose`)
- `Write-Warning` for warnings the user should see
- `Write-Progress` for long-running operations
- No explicit `return` needed at the end – the last expression is output automatically

---

## 8. No Aliases in Script Code

```powershell
# ❌ Aliases – never use in scripts
ls, dir    # → Get-ChildItem
cat, type  # → Get-Content
%          # → ForEach-Object
?          # → Where-Object
echo       # → Write-Output
cd         # → Set-Location
del, rm    # → Remove-Item
cp         # → Copy-Item
mv         # → Move-Item
ps         # → Get-Process
kill       # → Stop-Process
curl, wget # → Invoke-WebRequest
```

Aliases are fine interactively, but must not appear in scripts – they may be absent depending on platform or configuration.

---

## 9. Paths & Filesystem

```powershell
# ✅ Correct
$configPath = Join-Path -Path $PSScriptRoot -ChildPath 'config'    -AdditionalChildPath 'settings.json'
$logFile    = Join-Path -Path $env:TEMP     -ChildPath 'myapp.log'

# ❌ Wrong – platform-specific separators
$configPath = "$PSScriptRoot\config\settings.json"   # Breaks on Linux
$configPath = $PSScriptRoot + "\config\settings.json"

# Existence checks
if (Test-Path -Path $configPath -PathType Leaf)      { }  # File
if (Test-Path -Path $dirPath    -PathType Container) { }  # Directory
```

**Key variables:**
- `$PSScriptRoot`         – directory of the current script
- `$PSCommandPath`        – full path of the current script
- `$env:TEMP` / `$env:TMP` – temp directory (cross-platform)
- `$env:HOME`             – home directory (cross-platform; Windows: `$env:USERPROFILE`)

---

## 10. Strings & Interpolation

```powershell
# Single quotes – no interpolation
$literal  = 'No $expand here'

# Double quotes – interpolation
$name     = 'World'
$greeting = "Hello, $name!"
$complex  = "Path: $($env:HOME)/data"  # Expressions inside $()

# Here-string for multi-line text
$json = @"
{
    "name": "$name",
    "version": "1.0"
}
"@

# String formatting
$msg = 'Found: {0} files in {1}' -f $count, $path
```

---

## 11. Cross-Platform Compatibility

```powershell
# Detect platform
if ($IsWindows) { }
if ($IsLinux)   { }
if ($IsMacOS)   { }

# Path separator
[System.IO.Path]::DirectorySeparatorChar  # \ on Windows, / on Unix

# Line ending
[System.Environment]::NewLine

# Temp directory (cross-platform)
[System.IO.Path]::GetTempPath()

# Executables
$exe = $IsWindows ? 'tool.exe' : 'tool'
```

**Avoid:**
- Hardcoded Windows paths (`C:\`, `D:\`)
- `cmd.exe` calls
- Registry access without a platform check
- COM objects (Windows-only)

---

## 12. Modules

```powershell
# Project structure – tests live outside the module (not bundled when publishing)
MyProject/
├── MyModule/
│   ├── MyModule.psd1       # Manifest
│   ├── MyModule.psm1       # Root module
│   ├── Public/             # Exported functions
│   │   └── Get-Something.ps1
│   └── Private/            # Internal functions
│       └── Invoke-Helper.ps1
└── Tests/
    ├── Public/             # Mirrors MyModule/Public/
    │   └── Get-Something.Tests.ps1
    └── Private/            # Mirrors MyModule/Private/
        └── Invoke-Helper.Tests.ps1
```

The mirrored folder structure is its own coverage report – a missing test file is immediately visible.

Tests are kept outside the module so they are never bundled when publishing to the PowerShell Gallery via `Publish-Module`.

```powershell
# In MyModule.psm1
$public  = Get-ChildItem -Path "$PSScriptRoot/Public/*.ps1"
$private = Get-ChildItem -Path "$PSScriptRoot/Private/*.ps1"

foreach ($file in ($public + $private)) {
    . $file.FullName  # dot-sourcing
}

Export-ModuleMember -Function $public.BaseName
```

**Manifest (psd1) minimum fields:**
```powershell
@{
    ModuleVersion     = '1.0.0'
    GUID              = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
    Author            = 'Name'
    RootModule        = 'MyModule.psm1'
    FunctionsToExport = @('Get-Something')
    RequiredModules   = @()
    PowerShellVersion = '7.0'
}
```

---

## 13. Pester Tests

**Install (once, locally):**
```powershell
Install-Module -Name Pester -Force -SkipPublisherCheck
```

**File structure – standalone scripts:**
```
MyProject/
├── Public/
│   └── Get-Something.ps1
└── Tests/
    └── Get-Something.Tests.ps1
```

**File structure – module:**
```
MyProject/
├── MyModule/
│   ├── Public/
│   │   └── Get-Something.ps1
│   └── Private/
│       └── Invoke-Helper.ps1
└── Tests/
    ├── Public/
    │   └── Get-Something.Tests.ps1
    └── Private/
        └── Invoke-Helper.Tests.ps1
```

**Test file template – standalone script:**
```powershell
# Tests/Get-Something.Tests.ps1
BeforeAll {
    . "$PSScriptRoot/../Public/Get-Something.ps1"
}
```

**Test file template – module (public function):**
```powershell
# Tests/Public/Get-Something.Tests.ps1
BeforeAll {
    . "$PSScriptRoot/../../MyModule/Public/Get-Something.ps1"
}
```

**Test file template – module (private function):**
```powershell
# Tests/Private/Invoke-Helper.Tests.ps1
BeforeAll {
    # Dot-source directly to bypass module boundary
    . "$PSScriptRoot/../../MyModule/Private/Invoke-Helper.ps1"
}
```

**Full test example:**
```powershell
BeforeAll {
    . "$PSScriptRoot/../../MyModule/Public/Get-Something.ps1"
}

Describe 'Get-Something' {
    Context 'Valid input' {
        It 'Returns correct result' {
            $result      = Get-Something -Name 'Test'
            $result      | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be 'Test'
        }

        It 'Accepts pipeline input' {
            $result = 'Test' | Get-Something
            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Invalid input' {
        It 'Throws on empty name' {
            { Get-Something -Name '' }    | Should -Throw
        }

        It 'Throws on null' {
            { Get-Something -Name $null } | Should -Throw
        }
    }
}
```

**Run tests locally:**
```powershell
# All tests
Invoke-Pester -Path ./Tests -Output Detailed

# With code coverage (adjust path for module vs scripts)
Invoke-Pester -Path ./Tests -Output Detailed -CodeCoverage ./MyModule/Public/*.ps1

# Single file
Invoke-Pester -Path ./Tests/Public/Get-Something.Tests.ps1
```

**Key Should assertions:**
```powershell
$result | Should -Be 'expected'           # Equality
$result | Should -Not -BeNullOrEmpty      # Not empty
$result | Should -BeOfType [string]       # Type check
$result | Should -BeGreaterThan 0         # Comparison
$result | Should -Contain 'item'          # Array contains element
{ Invoke-Something } | Should -Throw      # Error expected
{ Invoke-Something } | Should -Not -Throw # No error expected
```

---

## 14. PSScriptAnalyzer

**Install (once, locally):**
```powershell
Install-Module -Name PSScriptAnalyzer -Force
```

**Run locally:**
```powershell
# Single file
Invoke-ScriptAnalyzer -Path ./MyScript.ps1

# Warnings and errors only
Invoke-ScriptAnalyzer -Path ./MyScript.ps1 -Severity Warning, Error

# Entire directory recursively
Invoke-ScriptAnalyzer -Path . -Recurse -Severity Warning, Error
```

**Key rules (checked automatically):**

| Rule                                   | What is checked                                |
|----------------------------------------|------------------------------------------------|
| `PSAvoidUsingAliases`                  | No aliases (`ls`, `%`, `?` etc.)               |
| `PSUseApprovedVerbs`                   | Only official verbs in function names          |
| `PSAvoidUsingWriteHost`                | No `Write-Host` for data                       |
| `PSUseDeclaredVarsMoreThanAssignments` | No unused variables                            |
| `PSAvoidUsingPlainTextForPassword`     | No passwords as plain strings                  |
| `PSShouldProcess`                      | `SupportsShouldProcess` on write functions     |
| `PSUseOutputTypeAttribute`             | `[OutputType()]` on functions that return data |

**Custom config file (`PSScriptAnalyzerSettings.psd1`):**
```powershell
@{
    Severity     = @('Warning', 'Error')
    ExcludeRules = @(
        # Example: disable a rule when intentionally needed
        # 'PSAvoidUsingWriteHost'
    )
    Rules        = @{
        PSUseCompatibleSyntax = @{
            Enable         = $true
            TargetVersions = @('7.0', '7.2', '7.4')
        }
    }
}
```

Run with custom config:
```powershell
Invoke-ScriptAnalyzer -Path . -Recurse -Settings ./PSScriptAnalyzerSettings.psd1
```

---

## 15. GitHub Actions CI Workflow

Create `.github/workflows/powershell.yml`:

```yaml
name: PowerShell CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  analyze-and-test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Install PSScriptAnalyzer
        shell: pwsh
        run: Install-Module PSScriptAnalyzer -Force -ErrorAction Stop

      - name: Run PSScriptAnalyzer
        shell: pwsh
        run: |
          $results = Invoke-ScriptAnalyzer -Path . -Recurse -Severity Warning, Error
          if ($results) {
              $results | Format-Table -AutoSize
              throw "PSScriptAnalyzer found $($results.Count) issue(s)"
          }
          Write-Output "PSScriptAnalyzer: no issues found"

      - name: Install Pester
        shell: pwsh
        run: Install-Module Pester -Force -SkipPublisherCheck -ErrorAction Stop

      - name: Run Pester Tests
        shell: pwsh
        run: |
          $config                       = New-PesterConfiguration
          $config.Run.Path              = './Tests'
          $config.Output.Verbosity      = 'Detailed'
          $config.TestResult.Enabled    = $true
          $config.TestResult.OutputPath = 'TestResults.xml'
          $config.CodeCoverage.Enabled  = $true
          $config.CodeCoverage.Path     = './Public/*.ps1'
          Invoke-Pester -Configuration $config

      - name: Publish Test Results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: test-results
          path: TestResults.xml
```

**Prerequisites in the repo:**
- Scripts live under `Public/` (adjust path in workflow if needed)
- Tests live under `Tests/*.Tests.ps1`
- Optional: `PSScriptAnalyzerSettings.psd1` in the root for custom rule config

---

## 16. Common Pitfalls

| Problem              | Wrong                   | Right                               |
|----------------------|-------------------------|-------------------------------------|
| Null comparison      | `$x -eq $null`          | `$null -eq $x` (null on the left!)  |
| Boolean comparison   | `$x -eq $true`          | `$x` or `[bool]$x`                  |
| Single-element array | `$result = @()` + check | `@($result)` forces array           |
| String comparison    | `$a == $b`              | `$a -eq $b`                         |
| Regex match          | `$s -match "pattern"`   | Check result in `$Matches`          |
| Pipeline variable    | `$_` everywhere         | Only in `process {}` or scriptblock |
| Type casting         | `[int]"abc"` throws     | Use `[int]::TryParse()`             |

---

## Quick Reference: Useful Cmdlets

```powershell
# Filter / transform objects
Where-Object   { $_.Name -like '*test*' }
ForEach-Object { $_.Name }
Select-Object  -First 10 -Property Name, Age
Sort-Object    -Property Name -Descending
Group-Object   -Property Department

# Measure
Measure-Object -Property Size -Sum -Average -Maximum

# JSON
$obj  | ConvertTo-Json   -Depth 5
$json | ConvertFrom-Json

# Date / time
Get-Date -Format 'yyyy-MM-dd'
[datetime]::UtcNow

# Processes & services (cross-platform)
Get-Process   -Name pwsh
Start-Process -FilePath 'pwsh' -ArgumentList '-File', 'script.ps1' -Wait
```