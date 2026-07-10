---
name: git-guardrails
version: 1.0.0
description: Set up Claude Code hooks to block dangerous git commands (push, reset --hard, clean, branch -D, etc.) before they execute. Use when user wants to prevent destructive git operations, add git safety hooks, or block git push/reset in Claude Code.
---

# Setup Git Guardrails

Sets up a PreToolUse hook that intercepts and blocks dangerous git commands before Claude executes them.

## Applicability (capability contract)

This skill configures a **Claude Code hook** — it needs a shell, a filesystem, and Claude Code's
`settings.json`. In a chat-only environment (e.g. claude.ai) there is no Bash tool to intercept and
no hook mechanism, so there is nothing to install — the skill is **not applicable** there; say so
rather than pretending to configure anything. The guard scripts ship in **pwsh (primary, Windows)**
and **bash (Linux/macOS/Git Bash)** so the hook runs natively on the target OS.

## What Gets Blocked

- `git push` (all variants including `--force`)
- `git reset --hard`
- `git clean -f` / `git clean -fd`
- `git branch -D`
- `git checkout .` / `git restore .`

When blocked, Claude sees a message telling it that it does not have authority to access these commands.

## Steps

### 1. Ask scope

Ask the user: install for **this project only** (`.claude/settings.json`) or **all projects**
(`~/.claude/settings.json` / `%USERPROFILE%\.claude\settings.json`)?

### 2. Copy the hook script

Two guard scripts are bundled — use the one matching the target system:

| Script                            | When to use                      |
| --------------------------------- | -------------------------------- |
| `scripts/block-dangerous-git.ps1` | Windows (PowerShell — primary)   |
| `scripts/block-dangerous-git.sh`  | Linux/macOS or Git Bash fallback |

Copy the chosen script to the target location:

- **Project**: `.claude/hooks/block-dangerous-git.ps1` (or `.sh`)
- **Global**: `%USERPROFILE%\.claude\hooks\block-dangerous-git.ps1` (or `~/.claude/hooks/block-dangerous-git.sh`)

On Windows, no `chmod` is needed for `.ps1`. For `.sh` via Git Bash, run once: `chmod +x <path>/block-dangerous-git.sh`.

### 3. Add hook to settings

Merge into the appropriate settings file's `hooks.PreToolUse` array — don't overwrite other settings.

**Windows — PowerShell hook** (`.claude/settings.json` or `%USERPROFILE%\.claude\settings.json`):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "pwsh -NoProfile -NonInteractive -File \"%CLAUDE_PROJECT_DIR%\\.claude\\hooks\\block-dangerous-git.ps1\""
          }
        ]
      }
    ]
  }
}
```

(Global: swap `%CLAUDE_PROJECT_DIR%\.claude` for `%USERPROFILE%\.claude`.)

**Linux/macOS — Bash hook** (`.claude/settings.json` or `~/.claude/settings.json`):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/block-dangerous-git.sh"
          }
        ]
      }
    ]
  }
}
```

### 4. Ask about customization

Ask if the user wants to add or remove any patterns from the blocked list. Edit the copied script's
pattern array accordingly (both scripts keep the same list).

### 5. Verify

Feed a fake tool call to the copied script and confirm it exits 2 with a `BLOCKED` message on stderr:

```powershell
'{"tool_input":{"command":"git push origin main"}}' | pwsh -NoProfile -File <path>\block-dangerous-git.ps1
```

```bash
echo '{"tool_input":{"command":"git push origin main"}}' | <path>/block-dangerous-git.sh
```

A safe command (e.g. `git status`) must exit 0 and print nothing.
