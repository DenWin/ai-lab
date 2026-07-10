# ai-lab

Source-of-truth workspace for AI-assisted-work configuration: portable agent skills, harness
documentation, instruction files, and the sync tooling that deploys them. The repo is the source
of truth; each harness loads live copies from its own locations.

## Layout

Canonical reference: [docs/repo-layout.adoc](docs/repo-layout.adoc). Short version:

- `ai-artifacts/skills/shared/` — source skills; scope-specific skills go under `ai-artifacts/skills/<vendor>/<harness>/`
- `ai-artifacts/instructions/<vendor>/<harness>/` — repo copies of harness instruction surfaces
- `ai-artifacts/hooks/`, `ai-artifacts/mcp-config/`, `ai-artifacts/output-styles/`, `ai-artifacts/agents/`, `ai-artifacts/prompts/`, `ai-artifacts/plugins/` — artifact-type roots, each scoped below by
  `shared/`, `<vendor>/`, or `<vendor>/<harness>/`
- `docs/harnesses/` — per-harness self-descriptions: instruction surfaces, load models, limits
- `.scratch/` — committed local-markdown issue tracker (PRDs + issues + ranked `BACKLOG.md`)
- `.temp/` — gitignored landing zone for transient local working files, downloads, and scratch output
- `scripts/` — sync tooling

Most-specific wins; folders are created on demand, never pre-scaffolded empty.

## Rules that prevent damage

- **Never edit generated skill mirrors directly** (`.claude/commands/`, `.agents/skills/`,
  `.github/skills/`) — these are generated, gitignored harness mirrors. Edit the source under
  `ai-artifacts/skills/shared/<group>/<name>/`, then rebuild with `pwsh scripts/setup-repo.ps1`.
- For a fresh clone bootstrap, run `pwsh scripts/setup-repo.ps1` to enable git hooks and refresh mirrors in one pass.
- On a fresh clone or a cloud/sandbox session the generated mirrors may not exist. Run setup once —
  the SessionStart hook that does this locally lives in machine-local settings and won't be there.
- Files under `ai-artifacts/instructions/<vendor>/<harness>/` are repo copies for editing; the live version sits
  in each harness's own surface (see [ai-artifacts/instructions/README.md](ai-artifacts/instructions/README.md)).
  Editing the repo copy changes nothing until it is deployed there.
- Use `git mv` when moving or renaming tracked files.
- This repo is **public**. No secrets anywhere — including instruction files and `.scratch/`.
- Use `.temp/` for temporary files inside the workspace. Its contents are gitignored; promote only
  durable, redacted, intentionally committed support material into `.scratch/<feature>/artifacts/`.

## Work tracking (`.scratch/`)

One folder per feature: `.scratch/<feature-slug>/PRD.md` (+ optional `issues/`, `artifacts/`);
`.scratch/BACKLOG.md` is the ranked index. Capture ideas with `/planning:scratch`; rank with
`/planning:scratch-plan`.

**Capture ≠ execute.** When asked to "scratch" an idea, only record it (Status: `needs-triage`,
TBD backlog row) — do not implement, rank, decide, or restructure. Implementation happens only when
explicitly requested against a specific scratch.

The working rules for agents operating in `.scratch/` — capture≠execute, **deliverables live outside
the scratch** (`artifacts/` is supporting material only), and ranking hygiene — live in the folder
guide [.scratch/AGENTS.md](.scratch/AGENTS.md); structural layout stays in the `scratch` skill's
[LAYOUT.md](ai-artifacts/skills/shared/planning/scratch/LAYOUT.md).

## Conventions

- Primary environment: Windows, PowerShell 7 (`pwsh`). Write scripts in pwsh unless the target is
  cross-platform.
- PowerShell runtime policy: each script declares `# RuntimePolicy: core-first|dual-runtime|desktop-only`.
  Core-first is default (`#Requires -Version 7.0` + `#Requires -PSEdition Core`), dual-runtime must run
  in both Windows PowerShell 5.1 and pwsh 7+, and desktop-only exceptions must be named
  `*-windowsps.ps1` with `# RuntimeJustification: ...` plus
  `#Requires -Version 5.1` + `#Requires -PSEdition Desktop`.
- Docs: Markdown by default; AsciiDoc (`docs/*.adoc`) where richer syntax is needed.
- Keep `AGENTS.md` Markdown because harnesses load it directly; keep `docs/repo-layout.adoc`
  AsciiDoc because it is the richer canonical layout reference.
- OKF: durable markdown reference/catalog docs should follow [docs/okf-adoption.md](docs/okf-adoption.md)
  unless another local format owns the file.
- Skills follow the **capability contract**: if shell/filesystem is available, take the full
  agentic path; otherwise degrade to a conversational fallback. Write "if shell available" —
  never "if [harness name]".
- AI-generated code changes must follow the coding policies in `coding-policies/`:
  load `polyglot-policy.yaml` first, then the resolved language policy from
  `coding-policies/languages/` per `usage-policy.yaml`.
- Vendored/imported skill provenance lives in each skill's `METADATA.md`; the origin map is
  [ai-artifacts/skills/shared/README.md](ai-artifacts/skills/shared/README.md).
- **Single owner per fact:** each fact lives in one canonical file; other docs link to it instead
  of restating (layout → `docs/repo-layout.adoc`, skill origins → `ai-artifacts/skills/shared/README.md`,
  scratch working rules → `.scratch/AGENTS.md`, scratch structural layout → the `scratch` skill's
  `LAYOUT.md`).

## Scope note

This file carries cross-harness **operational facts** only. Behavioral preferences live in the
harness-specific instruction files (claude.ai profile; global CLAUDE.md) until the planned overlap
hoist (`.scratch/incorporate-global-claude-setup/`) consolidates the shared subset here.

## PR and CI expectations (for human and AI contributors)

- Pull requests must use the template at `.github/pull_request_template.md` and fill every section
  (goal, plan, scope, policy compliance, risk, rollback, evidence).
- Keep changes scoped so only relevant workflows run; avoid touching unrelated files in the same PR.
- CI lints exclude `.scratch/*/artefacts/**` and `.scratch/*/artifacts/**` on purpose; those
  paths are treated as supporting artifacts. Safety checks (secret/policy) still apply.
- Run `pwsh scripts/setup-repo.ps1` to bootstrap hooks and generated mirrors.
