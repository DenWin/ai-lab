---
name: setup-repo
version: 1.0.0
description: Bootstrap this repository after clone by enabling git hooks and syncing generated skill mirrors. Use when user asks to set up the repo, bootstrap local tooling, or initialize mirrors/hooks for this clone.
---

# Setup Repo

Bootstraps this clone in one pass:

1. Activates repo git hooks
2. Syncs generated skill mirrors for Claude, Codex, and Copilot

Implementation layout:

- Canonical entrypoint: `ai-artifacts/skills/shared/setup/setup-repo/scripts/Invoke-SetupRepo.ps1`
- Repo convenience wrapper: `scripts/setup-repo.ps1`

## Applicability (capability contract)

This skill needs shell + filesystem access in a local git checkout. In chat-only environments,
provide the exact commands and explain what each command configures.

## Default command

```powershell
pwsh scripts/setup-repo.ps1
```

## Common variants

Project-local mirrors for one harness:

```powershell
pwsh scripts/setup-repo.ps1 -Target Copilot -Scope Project
```

User-scope mirrors for all harnesses:

```powershell
pwsh scripts/setup-repo.ps1 -Scope User
```

Bootstrap only missing generated mirrors (keeps existing generated files untouched):

```powershell
pwsh scripts/setup-repo.ps1 -IfMissing
```

Refresh generated mirrors without touching git hooks:

```powershell
pwsh scripts/setup-repo.ps1 -SkipHooks
```

Check generated mirrors for drift:

```powershell
pwsh scripts/setup-repo.ps1 -SkipHooks -Check
pwsh scripts/setup-repo.ps1 -SkipHooks -Target Codex -Skill tdd -Check
```

Run only one phase:

```powershell
pwsh scripts/setup-repo.ps1 -SkipHooks
pwsh scripts/setup-repo.ps1 -SkipSkillSync
```

## Verify

```powershell
git config --get core.hooksPath
Test-Path .claude/commands
Test-Path .agents/skills
Test-Path .github/skills
pwsh scripts/setup-repo.ps1 -SkipHooks -Check
```

Expected:

- `core.hooksPath` prints `.githooks`
- mirror folders exist for selected targets
