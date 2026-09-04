---
type: Agent Skill Metadata
title: "recon"
description: "Before generating code (SQL, PowerShell, Bash, Python, or any stack) whose correctness depends on environment facts you cannot see, generate a small read-only probe script the user runs to report ground truth — schema and column names/types, server version and edition, installed modules or importable packages, available cmdlets, file paths, config values, existing object definitions. The user pastes the probe's output back, and you generate the real code against what actually exists instead of against assumptions. Use when a request targets an existing system and correctness hinges on identifiers, versions, or availability you'd otherwise guess at; when the user says \"recon\", \"check my environment first\", \"confirm what you know\", or \"help me help you\"; or any time you're about to recite a column name, version, module, or path from memory."
resource: ./SKILL.md
tags: [session, skill]
---

## Skill Metadata

- Runtime skill: [SKILL.md](SKILL.md)
- Group: `deprecated` (was `session`)
- Origin: local
- Status: **Deprecated 2026-09.** Superseded by `session/throwaway/`, which the
  2026-08 claude.ai fetch produced by renaming `recon` → `throwaway`. Kept here
  for reference only; `sync-skills.ps1` skips everything under `deprecated/`, so
  this skill is no longer mirrored to any harness. `recon` survives as a trigger
  word in the `throwaway` skill.
- Notes: Local original.
