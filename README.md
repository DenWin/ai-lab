---
type: Reference
title: AI Lab Repository Entry Point
description: Start-here guide for external contributors and AI agents working in DenWin/ai-lab.
tags: [ai-lab, onboarding, repository, agents]
---

# ai-lab

This repository is the source of truth for AI and software-development artifacts: skills,
instruction surfaces, MCP config, prompts, hooks, policies, and sync tooling.

## Start here

1. Read [`AGENTS.md`](https://raw.githubusercontent.com/DenWin/ai-lab/refs/heads/main/AGENTS.md) for repo-wide operational rules.
2. Read [`docs/repo-layout.adoc`](https://raw.githubusercontent.com/DenWin/ai-lab/refs/heads/main/docs/repo-layout.adoc) for the canonical structure.
3. Run `pwsh scripts/setup-repo.ps1` on fresh clones to enable hooks and rebuild generated mirrors.

## What exists in this repo

- [`ai-artifacts/skills/`](https://github.com/DenWin/ai-lab/tree/main/ai-artifacts/skills) — portable source skills and scoped variants
- [`ai-artifacts/instructions/`](https://github.com/DenWin/ai-lab/tree/main/ai-artifacts/instructions) — editable repo copies of harness instruction surfaces
- [`ai-artifacts/`](https://github.com/DenWin/ai-lab/tree/main/ai-artifacts) (`hooks`, `mcp-config`, `output-styles`, `agents`, `prompts`, `plugins`) — artifact families, scoped by `shared/`, `<vendor>/`, or `<vendor>/<harness>/`
- [`docs/harnesses/`](https://github.com/DenWin/ai-lab/tree/main/docs/harnesses) — harness behavior and loading model docs
- [`.scratch/`](https://github.com/DenWin/ai-lab/tree/main/.scratch) — tracked planning work (PRDs, issues, backlog)
- [`scripts/`](https://github.com/DenWin/ai-lab/tree/main/scripts) — setup/sync orchestration

## How changes are supposed to be implemented

- Edit source artifacts only; never edit generated mirrors (`.claude/commands/`, `.agents/skills/`, `.github/skills/`).
- Keep deliverables in their final artifact-type homes; `.scratch/` stores planning/supporting material.
- Follow `coding-policies/` (`polyglot-policy.yaml` first, then language policy via `usage-policy.yaml`).
- Keep changes scoped and run relevant validation before opening a PR.
- This is a public repo: do not commit secrets.

## Canonical references

- Operational rules: [`AGENTS.md`](https://raw.githubusercontent.com/DenWin/ai-lab/refs/heads/main/AGENTS.md)
- Layout source of truth: [`docs/repo-layout.adoc`](https://raw.githubusercontent.com/DenWin/ai-lab/refs/heads/main/docs/repo-layout.adoc)
- Terminology/context: [`CONTEXT.md`](https://raw.githubusercontent.com/DenWin/ai-lab/refs/heads/main/CONTEXT.md)
- Instructions surface model: [`ai-artifacts/instructions/README.md`](https://raw.githubusercontent.com/DenWin/ai-lab/refs/heads/main/ai-artifacts/instructions/README.md)
