# ai-lab

Source-of-truth workspace for AI-assisted-work configuration: portable agent skills, harness
documentation, instruction files, and the sync tooling that deploys them. The repo is the source
of truth; each harness loads live copies from its own locations.

## Layout

Canonical reference: [docs/repo-layout.adoc](docs/repo-layout.adoc). Short version:

- `shared/` — vendor- and harness-agnostic artifacts (the default home; all skills live here)
- `<vendor>/<harness>/` — harness-specific config (e.g. `anthropic/claude-ai/instructions/`)
- `docs/harnesses/` — per-harness self-descriptions: instruction surfaces, load models, limits
- `.scratch/` — committed local-markdown issue tracker (PRDs + issues + ranked `BACKLOG.md`)
- `scripts/` — sync tooling

Most-specific wins; folders are created on demand, never pre-scaffolded empty.

## Rules that prevent damage

- **Never edit `.claude/commands/`** — it is a generated, gitignored mirror. Edit the source under
  `shared/skills/<group>/<name>/`, then rebuild: `pwsh scripts/sync-skills.ps1`.
- On a fresh clone or a cloud/sandbox session the mirror does not exist. Run the sync script once —
  the SessionStart hook that does this locally lives in machine-local settings and won't be there.
- Files under `instructions/` and `anthropic/*/instructions/` are repo copies for editing; the live
  version sits in each harness's own surface (see [instructions/README.md](instructions/README.md)).
  Editing the repo copy changes nothing until it is deployed there.
- Use `git mv` when moving or renaming tracked files.
- This repo is **public**. No secrets anywhere — including instruction files and `.scratch/`.

## Work tracking (`.scratch/`)

One folder per feature: `.scratch/<feature-slug>/PRD.md` (+ optional `issues/`, `artifacts/`);
`.scratch/BACKLOG.md` is the ranked index. Capture ideas with `/planning:scratch`; rank with
`/planning:scratch-plan`.

**Capture ≠ execute.** When asked to "scratch" an idea, only record it (Status: `needs-triage`,
TBD backlog row) — do not implement, rank, decide, or restructure. Implementation happens only when
explicitly requested against a specific scratch.

## Conventions

- Primary environment: Windows, PowerShell 7 (`pwsh`). Write scripts in pwsh unless the target is
  cross-platform.
- Docs: Markdown by default; AsciiDoc (`docs/*.adoc`) where richer syntax is needed.
- Skills follow the **capability contract**: if shell/filesystem is available, take the full
  agentic path; otherwise degrade to a conversational fallback. Write "if shell available" —
  never "if <harness name>".
- Vendored/imported content carries `upstream-*` provenance frontmatter; the origin map is
  [shared/skills/README.md](shared/skills/README.md).

## Scope note

This file carries cross-harness **operational facts** only. Behavioral preferences live in the
harness-specific instruction files (claude.ai profile; global CLAUDE.md) until the planned overlap
hoist (`.scratch/incorporate-global-claude-setup/`) consolidates the shared subset here.
