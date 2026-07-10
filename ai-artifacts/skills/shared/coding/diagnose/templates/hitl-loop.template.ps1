#Requires -Version 7.0
#Requires -PSEdition Core
# RuntimePolicy: core-first

# Human-in-the-loop reproduction loop (PowerShell 7 primary; pwsh on Windows/macOS/Linux).
# Copy this file, edit the steps below, and run it:  pwsh hitl-loop.template.ps1
# The agent runs the script; the user follows prompts in their terminal.
#
# Two helpers:
#   Step "<instruction>"          -> show instruction, wait for Enter
#   Capture <VAR> "<question>"    -> show question, read response into $captured[VAR]
#
# At the end, captured values are printed as KEY=VALUE for the agent to parse.

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$captured = [ordered]@{}

function Step([string]$Instruction) {
    Write-Host "`n>>> $Instruction"
    [void](Read-Host '    [Enter when done]')
}

function Capture([string]$Name, [string]$Question) {
    Write-Host "`n>>> $Question"
    $captured[$Name] = Read-Host '    >'
}

# --- edit below ---------------------------------------------------------

Step 'Open the app at http://localhost:3000 and sign in.'

Capture 'ERRORED'   "Click the 'Export' button. Did it throw an error? (y/n)"

Capture 'ERROR_MSG' 'Paste the error message (or ''none''):'

# --- edit above ---------------------------------------------------------

Write-Host "`n--- Captured ---"
foreach ($k in $captured.Keys) { Write-Host ("{0}={1}" -f $k, $captured[$k]) }
