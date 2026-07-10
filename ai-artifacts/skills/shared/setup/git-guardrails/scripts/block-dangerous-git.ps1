#Requires -Version 5.1
# RuntimePolicy: dual-runtime
# PreToolUse hook: block dangerous git commands before Claude Code runs them (PowerShell).
# Reads the tool-call JSON on stdin; on a dangerous match, writes a message to stderr and exits 2
# (which Claude Code treats as "blocked"); otherwise exits 0.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$raw = [Console]::In.ReadToEnd()
try {
    $command = ($raw | ConvertFrom-Json).tool_input.command
} catch {
    exit 0   # not a parseable tool call — nothing to guard
}
if ([string]::IsNullOrWhiteSpace($command)) { exit 0 }

# Patterns are regular expressions (mirrors the bash `grep -E` guard). `\.` = a literal dot.
$dangerousPatterns = @(
    'git push'
    'git reset --hard'
    'git clean -fd'
    'git clean -f'
    'git branch -D'
    'git checkout \.'
    'git restore \.'
    'push --force'
    'reset --hard'
)

foreach ($pattern in $dangerousPatterns) {
    if ($command -match $pattern) {
        [Console]::Error.WriteLine(
            "BLOCKED: '$command' matches dangerous pattern '$pattern'. The user has prevented you from doing this.")
        exit 2
    }
}
exit 0
