# Skills

Agent skills for this repo, grouped by intent. This README is the **origin map** — what each skill is
and where it came from. It deliberately does *not* explain how to update skills: that is the job of
the `/setup:check-skill-updates` skill, and anything about that process lives in the skill itself.

## Layout

`ai-artifacts/skills/shared/<group>/<name>/SKILL.md` (+ bundled runtime resources) is the **single source of
truth** for skill behavior. `ai-artifacts/skills/shared/<group>/<name>/METADATA.md` is the OKF-style catalog and
provenance file for that skill. The invocable copies under generated harness mirrors are build
artifacts — never edit them; edit the source and re-run:

```powershell
pwsh scripts/setup-repo.ps1 -SkipHooks
```

That updates every supported generated skill mirror. `METADATA.md` files are source catalog files and
are not deployed as runtime skill resources:

- Claude Code: `.claude/commands/<group>/<name>.md` plus resources
- Codex: `.agents/skills/<group>_<name>/SKILL.md` plus resources
- Copilot: `.github/skills/<group>_<name>/SKILL.md` plus resources

All generated trees are gitignored; never edit them directly. Use
`pwsh scripts/setup-repo.ps1 -SkipHooks -Target Claude`, `-Target Codex`, or `-Target Copilot` only when you intentionally want a
single mirror.

Namespacing follows the directory: `ai-artifacts/skills/shared/coding/tdd/` → `/coding:tdd`.

| Group       | Intent                                                            |
| ----------- | ----------------------------------------------------------------- |
| `coding`    | Used while writing/changing code                                  |
| `planning`  | Backlog / PRD / issue workflow (the `.scratch/` tracker)          |
| `session`   | Conversational / process skills that shape a working session      |
| `setup`     | Repo tooling and skill maintenance                                |
| `workflow`  | Running deterministic local workflow/CI-equivalent sequences      |
| `documents` | Producing / converting documents (e.g. email → AsciiDoc/Markdown) |

## Skill Metadata

Every skill has a `METADATA.md` file with OKF-style frontmatter:

```yaml
---
type: Agent Skill Metadata
title: <skill-name>
description: <one-line summary>
resource: ./SKILL.md
tags: [<group>, skill]
upstream-author: <author>              # upstream-derived skills only
upstream-repo: https://github.com/...
upstream-path: skills/<path>/SKILL.md
upstream-commit: <40-char SHA>
---
```

Runtime `SKILL.md` frontmatter carries harness-facing fields and a SemVer `version`. Upstream
provenance belongs in `METADATA.md` so agents do not load update bookkeeping as part of the skill
instructions.

## Origins

Upstream is recorded in each skill's `METADATA.md` (see [Skill Metadata](#skill-metadata)). This
table is the human-readable summary.

| Skill                           | Group     | Upstream                                                      | Notes                                                                                                                                                                                |
| ------------------------------- | --------- | ------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `tdd`                           | coding    | mattpocock `skills/engineering/tdd`                           | Heavily localized: stack rules (PowerShell/SQL/Python/C#), reworked resources                                                                                                        |
| `prototype`                     | coding    | mattpocock `skills/engineering/prototype`                     | Localized                                                                                                                                                                            |
| `diagnose`                      | coding    | mattpocock `skills/engineering/diagnose`                      | Dual-mode capability contract; HITL loop ships pwsh (primary) + bash templates                                                                                                       |
| `zoom-out`                      | coding    | mattpocock `skills/engineering/zoom-out`                      | Prompt-only (`disable-model-invocation`); dual-mode note added                                                                                                                       |
| `improve-codebase-architecture` | coding    | mattpocock `skills/engineering/improve-codebase-architecture` | Dual-mode (report → temp+open vs downloadable file); `grill-with-docs` links repointed to `session/grill-me`; resources DEEPENING/INTERFACE-DESIGN/LANGUAGE/HTML-REPORT              |
| `caveman`                       | session   | mattpocock `skills/productivity/caveman`                      | Minor edits                                                                                                                                                                          |
| `grill-me`                      | session   | mattpocock `skills/productivity/grill-me`                     | **Absorbed** `engineering/grill-with-docs`; `upstream-path` tracks the `grill-me` lineage only                                                                                       |
| `handoff`                       | session   | mattpocock `skills/productivity/handoff`                      | Minor edits                                                                                                                                                                          |
| `write-a-skill`                 | session   | mattpocock `skills/productivity/write-a-skill`                | Localized. Known issue: links `REFERENCE.md` but ships `EXAMPLES.md` — see below                                                                                                     |
| `recon`                         | session   | — (local original)                                            | No upstream                                                                                                                                                                          |
| `check-skill-updates`           | setup     | — (local original)                                            | No upstream; the update tool itself                                                                                                                                                  |
| `import-upstream-skill`         | setup     | — (local original)                                            | No upstream; the generic import process itself                                                                                                                                       |
| `setup-repo`                    | setup     | — (local original)                                            | Self-contained bootstrap skill for clone setup (hooks + mirror generation in one command)                                                                                            |
| `git-guardrails`                | setup     | mattpocock `skills/misc/git-guardrails-claude-code`           | Localized from the global-prior (pwsh + bash guards); Claude-Code-hook skill, N/A in chat. Exact upstream checkpoint lives only in the skill's `METADATA.md`                         |
| `setup-pre-commit`              | setup     | mattpocock `skills/misc/setup-pre-commit` (**local fork**)    | Diverged entirely: `pre-commit` framework for PS/MD/AsciiDoc/SQL, not Husky/lint-staged/Prettier. Carries **no** `upstream-*` (lineage in a comment); `check-skill-updates` skips it |
| `simulate-workflows`            | workflow  | — (local original)                                            | Deterministic script that runs local CI-equivalent workflow checks (Python, PowerShell, linting)                                                                                     |
| `scratch`                       | planning  | — (local original)                                            | The `.scratch/` tracker; owns `LAYOUT.md` / `RANKING.md`                                                                                                                             |
| `scratch-plan`                  | planning  | — (local original)                                            | Backlog ranking companion to `scratch`                                                                                                                                               |
| `mail-to-adoc`                  | documents | — (local original)                                            | `.msg`/`.eml` → AsciiDoc; personal-workflow tool (redacted). Rename to `mail-to-doc` + Markdown target is `.scratch/mail-to-doc` issue 03                                            |

For upstream-derived skills, the exact upstream checkpoint is recorded only in that skill's
`METADATA.md`. Summary docs should not duplicate pinned commits; they drift and create a second owner
for update state.

- `upstream-path` keeps the *author's* folder structure (`engineering/`, `productivity/`), independent
  of our intent grouping.
- Local originals (`recon`, `check-skill-updates`, `import-upstream-skill`, `scratch`, `scratch-plan`)
  carry **no** `upstream-*` fields in `METADATA.md`. **Local forks** that share only a name with
  upstream (`setup-pre-commit`) also omit them, recording lineage in the metadata body instead — the
  staleness check skips both.
- To check these against upstream, run `/setup:check-skill-updates`.

## Known content issues (carried over verbatim)

Preserved from the claude.ai imports, queued in `.scratch/claude-code-skill-adaptation/`:

- **`write-a-skill`** links `REFERENCE.md` but bundles `EXAMPLES.md` / `SCRIPTS.md` — reconcile.
