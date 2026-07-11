---
type: Reference
title: Repository Index
description: Generated register of repository artifacts, workflows, and frontmatter metadata.
tags: [index, generated, repository, ai-lab]
generated_at: 2026-07-11T16:15:22Z
generator: scripts/generate-repo-index.ps1
---

# Repository Index (Generated)

This file is auto-generated. Do not edit manually; run `pwsh scripts/generate-repo-index.ps1`.

## Scope Note

The `ai-artifacts/skills/shared` source + generated mirror pattern (`.claude/commands`, `.agents/skills`, `.github/skills`) is specific to this repository because it is both source-of-truth and consumer.
External repositories can consume copied skills directly and do not need this mirror workflow.

<!-- markdownlint-disable MD060 -->

## Artifact Roots

| Artifact | Path | File count |
| --- | --- | ---: |
| skills | ai-artifacts/skills | 77 |
| instructions | ai-artifacts/instructions | 2 |
| hooks | ai-artifacts/hooks | 1 |
| mcp-config | ai-artifacts/mcp-config | 1 |
| output-styles | ai-artifacts/output-styles | 1 |
| agents | ai-artifacts/agents | 1 |
| prompts | ai-artifacts/prompts | 1 |
| plugins | ai-artifacts/plugins | 1 |
| harness-docs | docs/harnesses | 6 |
| scratch | .scratch | 156 |
| scripts | scripts | 3 |

## Skills (`SKILL.md`)

| Skill | Version | Path | Description |
| --- | --- | --- | --- |
| diagnose | 1.0.0 | ai-artifacts/skills/shared/coding/diagnose/SKILL.md | Disciplined diagnosis loop for hard bugs and performance regressions. Reproduce → minimise → hypothesise → instrument → fix → regression-test. Use when user says "diagnose this" / "debug this", reports a bug, says something is broken/throwing/failing, or describes a performance regression. |
| improve-codebase-architecture | 1.0.0 | ai-artifacts/skills/shared/coding/improve-codebase-architecture/SKILL.md | Find deepening opportunities in a codebase, informed by the domain language in CONTEXT.md and the decisions in docs/adr/. Use when the user wants to improve architecture, find refactoring opportunities, consolidate tightly-coupled modules, or make a codebase more testable and AI-navigable. |
| prototype | 1.0.0 | ai-artifacts/skills/shared/coding/prototype/SKILL.md | Build a throwaway prototype to flesh out a design before committing to it. Build a tiny interactive terminal app that drives a state model, data shape, command surface, or output format by hand — pushing it through cases that are hard to reason about on paper. Use when the user wants to prototype, sanity-check a data model or state machine, feel out an API/cmdlet surface or SQL schema, explore an idea, or says "prototype this", "let me play with it", "does this shape feel right". |
| tdd | 1.0.0 | ai-artifacts/skills/shared/coding/tdd/SKILL.md | Test-driven development applied as a workflow across unit, integration, and acceptance levels, with on-demand stack-specific rules for PowerShell, SQL, Python, and C#. Use when building features or fixing bugs test-first, when writing or reviewing tests, when choosing test doubles, when picking a companion technique (property-based, mutation, contract, approval, snapshot testing), or when the user mentions TDD, red-green-refactor, BDD, acceptance tests, or mocking. |
| zoom-out | 1.0.0 | ai-artifacts/skills/shared/coding/zoom-out/SKILL.md | Tell the agent to zoom out and give broader context or a higher-level perspective. Use when you're unfamiliar with a section of code or need to understand how it fits into the bigger picture. |
| mail-to-adoc | 0.1.0 | ai-artifacts/skills/shared/documents/mail-to-adoc/SKILL.md | "Convert .msg or .eml email files to AsciiDoc (.adoc) format. Use when: converting msg to asciidoc, converting eml to asciidoc, turning an outlook email into adoc, converting email file to documentation, saving mail as AsciiDoc. Runs mail_to_adoc.py from the project root." |
| scratch-plan | 1.0.0 | ai-artifacts/skills/shared/planning/scratch-plan/SKILL.md | > |
| scratch | 1.0.0 | ai-artifacts/skills/shared/planning/scratch/SKILL.md | > |
| caveman | 1.0.0 | ai-artifacts/skills/shared/session/caveman/SKILL.md | > |
| grill-me | 1.0.0 | ai-artifacts/skills/shared/session/grill-me/SKILL.md | Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree. Optionally challenges the plan against the project's existing language and drafts/revises documentation (CONTEXT.md, ADRs). Use when the user wants to stress-test a plan, get grilled on a design, says "grill me", or wants a plan checked against documented decisions and terminology. |
| handoff | 1.0.0 | ai-artifacts/skills/shared/session/handoff/SKILL.md | Compact the current conversation into a handoff document for another agent to pick up. |
| recon | 1.0.0 | ai-artifacts/skills/shared/session/recon/SKILL.md | Before generating code (SQL, PowerShell, Bash, Python, or any stack) whose correctness depends on environment facts you cannot see, generate a small read-only probe script the user runs to report ground truth — schema and column names/types, server version and edition, installed modules or importable packages, available cmdlets, file paths, config values, existing object definitions. The user pastes the probe's output back, and you generate the real code against what actually exists instead of against assumptions. Use when a request targets an existing system and correctness hinges on identifiers, versions, or availability you'd otherwise guess at; when the user says "recon", "check my environment first", "confirm what you know", or "help me help you"; or any time you're about to recite a column name, version, module, or path from memory. |
| write-a-skill | 1.0.0 | ai-artifacts/skills/shared/session/write-a-skill/SKILL.md | Create, update, or improve agent skills with proper structure, progressive disclosure, and bundled resources. Use when user wants to create, write, build, revise, update, or improve a skill or SKILL.md file. |
| check-skill-updates | 1.0.0 | ai-artifacts/skills/shared/setup/check-skill-updates/SKILL.md | Check whether the skills in this repo are stale against their upstream source on GitHub, and file a work item (GitHub issue or .scratch entry) for each stale one. It never edits or merges skills itself. Use when user wants to check for new skill versions, run "check-skill-updates", or sync with upstream changes. |
| git-guardrails | 1.0.0 | ai-artifacts/skills/shared/setup/git-guardrails/SKILL.md | Set up Claude Code hooks to block dangerous git commands (push, reset --hard, clean, branch -D, etc.) before they execute. Use when user wants to prevent destructive git operations, add git safety hooks, or block git push/reset in Claude Code. |
| import-upstream-skill | 1.0.0 | ai-artifacts/skills/shared/setup/import-upstream-skill/SKILL.md | Import a skill from any upstream source into this repo as a first-class, grouped, provenance-tracked skill. Snapshots the source, places it under the right intent group, writes OKF-style METADATA.md provenance, runs the capability-contract adaptation pass, and updates the origin map. Use when user wants to import, vendor, adopt, or pull in a skill from an upstream repo (GitHub, another project) or from a chat/global copy. |
| setup-pre-commit | 1.0.0 | ai-artifacts/skills/shared/setup/setup-pre-commit/SKILL.md | Set up pre-commit hooks for PowerShell, Markdown, AsciiDoc, and SQL repositories using the pre-commit framework. Use when user wants to add pre-commit hooks, set up linting/formatting on commit, configure PSScriptAnalyzer, markdownlint, vale, or sqlfluff. |
| setup-repo | 1.0.0 | ai-artifacts/skills/shared/setup/setup-repo/SKILL.md | Bootstrap this repository after clone by enabling git hooks and syncing generated skill mirrors. Use when user asks to set up the repo, bootstrap local tooling, or initialize mirrors/hooks for this clone. |
| simulate-workflows | 1.0.0 | ai-artifacts/skills/shared/workflow/simulate-workflows/SKILL.md | Run the repository's GitHub quality workflow checks locally in a deterministic sequence with a bundled script, so no push/PR or GitHub Actions minutes are required. Use when user wants to run, simulate, reproduce, create, update, or improve local workflow checks for Python, PowerShell, and repo linting. |

## Skill Metadata (`METADATA.md`)

| Title | Type | Path |
| --- | --- | --- |
| "diagnose" | Agent Skill Metadata | ai-artifacts/skills/shared/coding/diagnose/METADATA.md |
| "improve-codebase-architecture" | Agent Skill Metadata | ai-artifacts/skills/shared/coding/improve-codebase-architecture/METADATA.md |
| "prototype" | Agent Skill Metadata | ai-artifacts/skills/shared/coding/prototype/METADATA.md |
| "tdd" | Agent Skill Metadata | ai-artifacts/skills/shared/coding/tdd/METADATA.md |
| "zoom-out" | Agent Skill Metadata | ai-artifacts/skills/shared/coding/zoom-out/METADATA.md |
| "mail-to-adoc" | Agent Skill Metadata | ai-artifacts/skills/shared/documents/mail-to-adoc/METADATA.md |
| "scratch-plan" | Agent Skill Metadata | ai-artifacts/skills/shared/planning/scratch-plan/METADATA.md |
| "scratch" | Agent Skill Metadata | ai-artifacts/skills/shared/planning/scratch/METADATA.md |
| "caveman" | Agent Skill Metadata | ai-artifacts/skills/shared/session/caveman/METADATA.md |
| "grill-me" | Agent Skill Metadata | ai-artifacts/skills/shared/session/grill-me/METADATA.md |
| "handoff" | Agent Skill Metadata | ai-artifacts/skills/shared/session/handoff/METADATA.md |
| "recon" | Agent Skill Metadata | ai-artifacts/skills/shared/session/recon/METADATA.md |
| "write-a-skill" | Agent Skill Metadata | ai-artifacts/skills/shared/session/write-a-skill/METADATA.md |
| "check-skill-updates" | Agent Skill Metadata | ai-artifacts/skills/shared/setup/check-skill-updates/METADATA.md |
| "git-guardrails" | Agent Skill Metadata | ai-artifacts/skills/shared/setup/git-guardrails/METADATA.md |
| "import-upstream-skill" | Agent Skill Metadata | ai-artifacts/skills/shared/setup/import-upstream-skill/METADATA.md |
| "setup-pre-commit" | Agent Skill Metadata | ai-artifacts/skills/shared/setup/setup-pre-commit/METADATA.md |
| "setup-repo" | Agent Skill Metadata | ai-artifacts/skills/shared/setup/setup-repo/METADATA.md |
| "simulate-workflows" | Agent Skill Metadata | ai-artifacts/skills/shared/workflow/simulate-workflows/METADATA.md |

## Frontmatter Catalog (Markdown)

| Path | Name/Title | Type | Version | Tags |
| --- | --- | --- | --- | --- |
| ai-artifacts/skills/shared/coding/diagnose/METADATA.md | "diagnose" | Agent Skill Metadata |  | [coding, skill] |
| ai-artifacts/skills/shared/coding/diagnose/SKILL.md | diagnose |  | 1.0.0 |  |
| ai-artifacts/skills/shared/coding/improve-codebase-architecture/METADATA.md | "improve-codebase-architecture" | Agent Skill Metadata |  | [coding, skill] |
| ai-artifacts/skills/shared/coding/improve-codebase-architecture/SKILL.md | improve-codebase-architecture |  | 1.0.0 |  |
| ai-artifacts/skills/shared/coding/prototype/METADATA.md | "prototype" | Agent Skill Metadata |  | [coding, skill] |
| ai-artifacts/skills/shared/coding/prototype/SKILL.md | prototype |  | 1.0.0 |  |
| ai-artifacts/skills/shared/coding/tdd/METADATA.md | "tdd" | Agent Skill Metadata |  | [coding, skill] |
| ai-artifacts/skills/shared/coding/tdd/SKILL.md | tdd |  | 1.0.0 |  |
| ai-artifacts/skills/shared/coding/zoom-out/METADATA.md | "zoom-out" | Agent Skill Metadata |  | [coding, skill] |
| ai-artifacts/skills/shared/coding/zoom-out/SKILL.md | zoom-out |  | 1.0.0 |  |
| ai-artifacts/skills/shared/documents/mail-to-adoc/METADATA.md | "mail-to-adoc" | Agent Skill Metadata |  | [documents, skill] |
| ai-artifacts/skills/shared/documents/mail-to-adoc/SKILL.md | mail-to-adoc |  | 0.1.0 |  |
| ai-artifacts/skills/shared/planning/scratch-plan/METADATA.md | "scratch-plan" | Agent Skill Metadata |  | [planning, skill] |
| ai-artifacts/skills/shared/planning/scratch-plan/SKILL.md | scratch-plan |  | 1.0.0 |  |
| ai-artifacts/skills/shared/planning/scratch/METADATA.md | "scratch" | Agent Skill Metadata |  | [planning, skill] |
| ai-artifacts/skills/shared/planning/scratch/SKILL.md | scratch |  | 1.0.0 |  |
| ai-artifacts/skills/shared/session/caveman/METADATA.md | "caveman" | Agent Skill Metadata |  | [session, skill] |
| ai-artifacts/skills/shared/session/caveman/SKILL.md | caveman |  | 1.0.0 |  |
| ai-artifacts/skills/shared/session/grill-me/METADATA.md | "grill-me" | Agent Skill Metadata |  | [session, skill] |
| ai-artifacts/skills/shared/session/grill-me/SKILL.md | grill-me |  | 1.0.0 |  |
| ai-artifacts/skills/shared/session/handoff/METADATA.md | "handoff" | Agent Skill Metadata |  | [session, skill] |
| ai-artifacts/skills/shared/session/handoff/SKILL.md | handoff |  | 1.0.0 |  |
| ai-artifacts/skills/shared/session/recon/METADATA.md | "recon" | Agent Skill Metadata |  | [session, skill] |
| ai-artifacts/skills/shared/session/recon/SKILL.md | recon |  | 1.0.0 |  |
| ai-artifacts/skills/shared/session/write-a-skill/docs/EXAMPLES.md | write-a-skill / examples |  |  |  |
| ai-artifacts/skills/shared/session/write-a-skill/METADATA.md | "write-a-skill" | Agent Skill Metadata |  | [session, skill] |
| ai-artifacts/skills/shared/session/write-a-skill/SKILL.md | write-a-skill |  | 1.0.0 |  |
| ai-artifacts/skills/shared/setup/check-skill-updates/METADATA.md | "check-skill-updates" | Agent Skill Metadata |  | [setup, skill] |
| ai-artifacts/skills/shared/setup/check-skill-updates/SKILL.md | check-skill-updates |  | 1.0.0 |  |
| ai-artifacts/skills/shared/setup/git-guardrails/METADATA.md | "git-guardrails" | Agent Skill Metadata |  | [setup, skill] |
| ai-artifacts/skills/shared/setup/git-guardrails/SKILL.md | git-guardrails |  | 1.0.0 |  |
| ai-artifacts/skills/shared/setup/import-upstream-skill/METADATA.md | "import-upstream-skill" | Agent Skill Metadata |  | [setup, skill] |
| ai-artifacts/skills/shared/setup/import-upstream-skill/SKILL.md | import-upstream-skill |  | 1.0.0 |  |
| ai-artifacts/skills/shared/setup/setup-pre-commit/METADATA.md | "setup-pre-commit" | Agent Skill Metadata |  | [setup, skill] |
| ai-artifacts/skills/shared/setup/setup-pre-commit/SKILL.md | setup-pre-commit |  | 1.0.0 |  |
| ai-artifacts/skills/shared/setup/setup-repo/METADATA.md | "setup-repo" | Agent Skill Metadata |  | [setup, skill] |
| ai-artifacts/skills/shared/setup/setup-repo/SKILL.md | setup-repo |  | 1.0.0 |  |
| ai-artifacts/skills/shared/workflow/simulate-workflows/METADATA.md | "simulate-workflows" | Agent Skill Metadata |  | [workflow, skill] |
| ai-artifacts/skills/shared/workflow/simulate-workflows/SKILL.md | simulate-workflows |  | 1.0.0 |  |
| docs/okf-adoption.md | OKF adoption | Reference |  | [okf, metadata, documentation] |
| README.md | AI Lab Repository Entry Point | Reference |  | [ai-lab, onboarding, repository, agents] |
| REPO_INDEX.md | Repository Index | Reference |  | [index, generated, repository, ai-lab] |

## GitHub Workflows and Local Executors

| Workflow | Local executor |
| --- | --- |
| .github/workflows/config-lint.yml | .github/workflows/scripts/config-lint/execute-workflow-config-lint.ps1 |
| .github/workflows/dependabot-auto-merge.yml | n/a |
| .github/workflows/policy-check.yml | .github/workflows/scripts/policy-check/execute-workflow-policy-check.ps1 |
| .github/workflows/powershell-quality.yml | .github/workflows/scripts/powershell-quality/execute-workflow-powershell-quality.ps1 |
| .github/workflows/powershell-runtime-compat.yml | .github/workflows/scripts/powershell-runtime-compat/execute-workflow-powershell-runtime-compat.ps1 |
| .github/workflows/powershell-tests.yml | .github/workflows/scripts/powershell-tests/execute-workflow-powershell-tests.ps1 |
| .github/workflows/python-quality.yml | .github/workflows/scripts/python-quality/execute-workflow-python-quality.ps1 |
| .github/workflows/python-tests.yml | .github/workflows/scripts/python-tests/execute-workflow-python-tests.ps1 |
| .github/workflows/secret-scan.yml | n/a |
| .github/workflows/shell-quality.yml | .github/workflows/scripts/shell-quality/execute-workflow-shell-quality.ps1 |
| .github/workflows/shell-tests.yml | .github/workflows/scripts/shell-tests/execute-workflow-shell-tests.ps1 |

## Key Config and Entry Files

- `.markdownlint.json`
- `.yamllint`
- `.asciidoctor-lint.yml`
- `.github/workflows`
- `.github/workflows/scripts`
- `.githooks/pre-commit`
- `coding-policies/polyglot-policy.yaml`
- `coding-policies/usage-policy.yaml`
- `scripts/setup-repo.ps1`
- `scripts/simulate-workflows.ps1`

<!-- markdownlint-enable MD060 -->
