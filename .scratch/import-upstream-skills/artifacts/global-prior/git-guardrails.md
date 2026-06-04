---
name: git-guardrails-claude-code
description: Set up Claude Code hooks to block dangerous git commands (push, reset --hard, clean, branch -D, etc.) before they execute. Use when user wants to prevent destructive git operations, add git safety hooks, or block git push/reset in Claude Code.
upstream-author: mattpocock
upstream-repo: https://github.com/mattpocock/skills
upstream-path: skills/misc/git-guardrails-claude-code/SKILL.md
upstream-commit: 62f43a18177be6ec82da242e59ffbc490a4c22ea
---

# Setup Git Guardrails

Sets up a PreToolUse hook that intercepts and blocks dangerous git commands before Claude executes them.

## What Gets Blocked

- `git push` (all variants including `--force`)
- `git reset --hard`
- `git clean -f` / `git clean -fd`
- `git branch -D`
- `git checkout .` / `git restore .`

When blocked, Claude sees a message telling it that it does not have authority to access these commands.

## Steps

### 1. Ask scope

Ask the user: install for **this project only** (`.claude/settings.json`) or **all projects** (`~/.claude/settings.json`)?

### 2. Copy the hook script

Two hook scripts are bundled — use the one matching the target system:

| Script                          | When to use                      |
| ------------------------------- | -------------------------------- |
| `hooks/block-dangerous-git.ps1` | Windows (PowerShell — primary)   |
| `hooks/block-dangerous-git.sh`  | Linux/macOS or Git Bash fallback |

Copy the chosen script to the target location:

- **Project**: `.claude/hooks/block-dangerous-git.ps1` (or `.sh`)
- **Global**: `%USERPROFILE%\.claude\hooks\block-dangerous-git.ps1` (or `.sh`)

On Windows, no `chmod` is needed for `.ps1`. For `.sh` via Git Bash, run once:

```bash
chmod +x ~/.claude/hooks/block-dangerous-git.sh
```

### 3. Add hook to settings

Add to the appropriate settings file.

**Windows — PowerShell hook:**

**Project** (`.claude/settings.json`):

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

**Global** (`%USERPROFILE%\.claude\settings.json`):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "pwsh -NoProfile -NonInteractive -File \"%USERPROFILE%\\.claude\\hooks\\block-dangerous-git.ps1\""
          }
        ]
      }
    ]
  }
}
```

**Linux/macOS — Bash hook:**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/block-dangerous-git.sh"
          }
        ]
      }
    ]
  }
}
```

If the settings file already exists, merge the hook into existing `hooks.PreToolUse` array — don't overwrite other settings.

### 4. Ask about customization

Ask if user wants to add or remove any patterns from the blocked list. Edit the copied script accordingly.

### 5. Verify

Run a quick test:

```bash
echo '{"tool_input":{"command":"git push origin main"}}' | <path-to-script>
```

Should exit with code 2 and print a BLOCKED message to stderr.
