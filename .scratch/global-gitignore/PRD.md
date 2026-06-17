# PRD — Global Gitignore

Status: needs-triage

## Problem Statement

Entries like `.gradle/`, `.history/`, OS noise (`.DS_Store`, `Thumbs.db`), and editor artifacts belong in a global gitignore (`~/.gitignore_global`) rather than per-repo `.gitignore` files. Currently these are scattered across repo-level files or missing entirely.

## Solution

1. Audit the existing `.gitignore` in this repo and identify entries that are machine/tool artifacts rather than project-specific.
2. Create a canonical `gitignore.global` file in this repo (`config/gitignore.global`) as the source of truth.
3. Document how to wire it: `git config --global core.excludesFile ~/.gitignore_global` (or point directly at the repo file).
4. Decide which entries stay per-repo (project-specific generated output) vs. move global (OS, editor, tool caches).

## Candidates for Global

- `.gradle/` — Gradle cache, always transient
- `.history/` — VS Code Local History extension
- `Thumbs.db`, `Desktop.ini` — Windows OS artifacts
- `.DS_Store` — macOS OS artifacts
- `*.suo`, `.vs/` — Visual Studio artifacts
- `__pycache__/`, `*.pyc` — Python cache
- `.idea/` — JetBrains IDE artifacts

## Candidates to Stay Per-Repo

- `/.temp/*` + `!/.temp/.gitkeep` — project-specific landing zone convention
- `/.claude/commands/*` — project-specific generated skill mirror

## Further Notes

_Created by /planning:scratch._
