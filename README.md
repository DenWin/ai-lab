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

1. Read `/home/runner/work/ai-lab/ai-lab/AGENTS.md` for repo-wide operational rules.
2. Read `/home/runner/work/ai-lab/ai-lab/docs/repo-layout.adoc` for the canonical structure.
3. Run `pwsh /home/runner/work/ai-lab/ai-lab/scripts/setup-repo.ps1` on fresh clones to enable hooks and rebuild generated mirrors.

## What exists in this repo

- `/home/runner/work/ai-lab/ai-lab/ai-artifacts/skills/` — portable source skills and scoped variants
- `/home/runner/work/ai-lab/ai-lab/ai-artifacts/instructions/` — editable repo copies of harness instruction surfaces
- `/home/runner/work/ai-lab/ai-lab/ai-artifacts/{hooks,mcp-config,output-styles,agents,prompts,plugins}/` — artifact families, scoped by `shared/`, `<vendor>/`, or `<vendor>/<harness>/`
- `/home/runner/work/ai-lab/ai-lab/docs/harnesses/` — harness behavior and loading model docs
- `/home/runner/work/ai-lab/ai-lab/.scratch/` — tracked planning work (PRDs, issues, backlog)
- `/home/runner/work/ai-lab/ai-lab/scripts/` — setup/sync orchestration

## How changes are supposed to be implemented

- Edit source artifacts only; never edit generated mirrors (`.claude/commands/`, `.agents/skills/`, `.github/skills/`).
- Keep deliverables in their final artifact-type homes; `.scratch/` stores planning/supporting material.
- Follow `coding-policies/` (`polyglot-policy.yaml` first, then language policy via `usage-policy.yaml`).
- Keep changes scoped and run relevant validation before opening a PR.
- This is a public repo: do not commit secrets.

## Canonical references

- Operational rules: `/home/runner/work/ai-lab/ai-lab/AGENTS.md`
- Layout source of truth: `/home/runner/work/ai-lab/ai-lab/docs/repo-layout.adoc`
- Terminology/context: `/home/runner/work/ai-lab/ai-lab/CONTEXT.md`
- Instructions surface model: `/home/runner/work/ai-lab/ai-lab/ai-artifacts/instructions/README.md`
