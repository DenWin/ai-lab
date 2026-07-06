# Skills

Agent skills for this repo, grouped by intent. This README is the **origin map** — what each skill is
and where it came from. It deliberately does *not* explain how to update skills: that is the job of
the `/setup:check-skill-updates` skill, and anything about that process lives in the skill itself.

## Layout

`shared/skills/<group>/<name>/SKILL.md` (+ bundled resources) is the **single source of truth**. The
invocable copies under `.claude/commands/<group>/<name>.md` are a **generated mirror** — never edit
them; edit the source and re-run:

```powershell
pwsh scripts/sync-skills.ps1
```

Namespacing follows the directory: `shared/skills/coding/tdd/` → `/coding:tdd`.

| Group | Intent |
| --- | --- |
| `coding`    | Used while writing/changing code |
| `planning`  | Backlog / PRD / issue workflow (the `.scratch/` tracker) |
| `session`   | Conversational / process skills that shape a working session |
| `setup`     | Repo tooling and skill maintenance |
| `documents` | Producing / converting documents (e.g. email → AsciiDoc/Markdown) |

## Origins

Upstream is recorded in each skill's frontmatter (see [Provenance convention](#provenance-convention)).
This table is the human-readable summary.

| Skill | Group | Upstream | Notes |
| --- | --- | --- | --- |
| `tdd` | coding | mattpocock `skills/engineering/tdd` | Heavily localized: stack rules (PowerShell/SQL/Python/C#), reworked resources |
| `prototype` | coding | mattpocock `skills/engineering/prototype` | Localized |
| `diagnose` | coding | mattpocock `skills/engineering/diagnose` | Dual-mode capability contract; HITL loop ships pwsh (primary) + bash templates |
| `zoom-out` | coding | mattpocock `skills/engineering/zoom-out` | Prompt-only (`disable-model-invocation`); dual-mode note added |
| `improve-codebase-architecture` | coding | mattpocock `skills/engineering/improve-codebase-architecture` | Dual-mode (report → temp+open vs downloadable file); `grill-with-docs` links repointed to `session/grill-me`; resources DEEPENING/INTERFACE-DESIGN/LANGUAGE/HTML-REPORT |
| `caveman` | session | mattpocock `skills/productivity/caveman` | Minor edits |
| `grill-me` | session | mattpocock `skills/productivity/grill-me` | **Absorbed** `engineering/grill-with-docs`; `upstream-path` tracks the `grill-me` lineage only |
| `handoff` | session | mattpocock `skills/productivity/handoff` | Minor edits |
| `write-a-skill` | session | mattpocock `skills/productivity/write-a-skill` | Localized. Known issue: links `REFERENCE.md` but ships `EXAMPLES.md` — see below |
| `recon` | session | — (local original) | No upstream |
| `check-skill-updates` | setup | — (local original) | No upstream; the update tool itself |
| `import-upstream-skill` | setup | — (local original) | No upstream; the generic import process itself |
| `git-guardrails` | setup | mattpocock `skills/misc/git-guardrails-claude-code` | Localized from the global-prior (pwsh + bash guards); Claude-Code-hook skill, N/A in chat. **Forked at `62f43a18`**, not `aaf2453` |
| `setup-pre-commit` | setup | mattpocock `skills/misc/setup-pre-commit` (**local fork**) | Diverged entirely: `pre-commit` framework for PS/MD/AsciiDoc/SQL, not Husky/lint-staged/Prettier. Carries **no** `upstream-*` (lineage in a comment); `check-skill-updates` skips it |
| `scratch` | planning | — (local original) | The `.scratch/` tracker; owns `LAYOUT.md` / `RANKING.md` |
| `scratch-plan` | planning | — (local original) | Backlog ranking companion to `scratch` |
| `mail-to-adoc` | documents | — (local original) | `.msg`/`.eml` → AsciiDoc; personal-workflow tool (redacted). Rename to `mail-to-doc` + Markdown target is `.scratch/mail-to-doc` issue 03 |

All upstream-derived skills were forked at mattpocock/skills commit
`aaf2453fbdfe7a15c07f11d861224f34ab4b53cb` — **except `git-guardrails`** (`misc/`), reconciled to
`62f43a18177be6ec82da242e59ffbc490a4c22ea`. Per-skill `upstream-commit` frontmatter is authoritative.

## Provenance convention

Each upstream-derived skill carries these frontmatter fields so tooling can read its origin directly:

```yaml
upstream-author: mattpocock
upstream-repo: https://github.com/mattpocock/skills
upstream-path: skills/<author-folder>/<name>/SKILL.md   # path WITHIN the upstream repo
upstream-commit: <40-char SHA this copy was last reconciled to>
```

- `upstream-path` keeps the *author's* folder structure (`engineering/`, `productivity/`), independent
  of our intent grouping.
- Local originals (`recon`, `check-skill-updates`, `import-upstream-skill`, `scratch`, `scratch-plan`)
  carry **no** `upstream-*` fields. **Local forks** that share only a name with upstream
  (`setup-pre-commit`) also omit them, recording lineage in a comment instead — the staleness check
  skips both.
- To check these against upstream, run `/setup:check-skill-updates`.

## Known content issues (carried over verbatim)

Preserved from the claude.ai imports, queued in `.scratch/claude-code-skill-adaptation/`:

- **`write-a-skill`** links `REFERENCE.md` but bundles `EXAMPLES.md` / `SCRIPTS.md` — reconcile.
