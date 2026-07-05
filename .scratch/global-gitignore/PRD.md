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
- `__pycache__/`, `*.pyc` — **reclassified to repo-level** (see decision 2026-07-05 below)

## Decisions / actionable (2026-07-05)

Surfaced while running the `mail-to-doc` tool's pytest suite in a cloud session: the generated
`__pycache__/` dirs showed as untracked and tripped the session stop-hook.

1. **`__pycache__/` + `*.pyc` belong in the repo `.gitignore`, not only a global one.** A global
   `~/.gitignore_global` (`core.excludesFile`) is **machine-local and never cloned** — fresh cloud
   sessions, CI, and other contributors don't have it. Any tool cache that appears *while working in
   this repo* (Python bytecode from the mail-to-doc tool, `.gradle/` from docToolchain runs) must be
   ignored **in-repo** to actually stop the untracked-file noise. So the global-vs-repo split isn't
   "OS/tool ⇒ global"; it's: **caches produced by this repo's own workflows ⇒ repo-level**; purely
   host/editor noise unrelated to repo work (`.DS_Store`, `Thumbs.db`, `.idea/`, `.vs/`) ⇒ global.
2. **`__pycache__/` + `*.pyc` were added to the repo `.gitignore`** on the `mail-to-doc` branch
   (this PR). ⚠️ **Actionable:** that rule only lives on that branch until it merges — until then
   other branches/sessions still hit the noise. **Land the pycache/`.gitignore` rule on `main`**
   (merge #6, or cherry-pick just the `.gitignore` change) so every branch and cloud session inherits it.
3. When this scratch is built: audit `.gitignore` with the split in (1); create the canonical
   `config/gitignore.global` for the genuinely host/editor-only entries and document the
   `core.excludesFile` wiring — but do **not** move repo-workflow caches out of the repo `.gitignore`.

## Further Notes

_Created by /planning:scratch._
