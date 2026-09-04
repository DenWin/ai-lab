---
type: Agent Skill Metadata
title: "throwaway"
description: "Rules for code that is run once and discarded - probes that survey a system, one-off fixes, scratch deploy steps. Covers the throwaway-vs-keeper test, ceremony, single emission, parameter/execution split, and the probe handshake that grounds generated code in facts instead of recall. Use when writing, generating, revising, or reviewing a one-off script or snippet in any stack; when about to recite a schema, version, module, cmdlet or path not verified this session; or when the user says \"recon\", \"throwaway\", \"quick script\", \"check my environment first\", or \"help me help you\"."
resource: ./SKILL.md
tags: [session, skill]
---

## Skill Metadata

- Runtime skill: [SKILL.md](SKILL.md)
- Group: `session`
- Origin: local
- Notes: Local original. Successor to `recon` — brought in from the 2026-08
  claude.ai fetch, which renamed `recon` → `throwaway` (SKILL.md frontmatter
  `metadata.version: 2.1.0`, `supersedes: recon 1.2.0`). `recon` remains a
  trigger word. The retired `recon` skill is kept for reference under
  `deprecated/recon/` and is not mirrored to any harness. Bundled resources:
  `PROBES.md`, `RECIPES.md`, `CHANGELOG.md`.
