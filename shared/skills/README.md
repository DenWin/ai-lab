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
| `coding`   | Used while writing/changing code |
| `planning` | Backlog / PRD / issue workflow (the `.scratch/` tracker) |
| `session`  | Conversational / process skills that shape a working session |
| `setup`    | Repo tooling and skill maintenance |

## Origins

Upstream is recorded in each skill's frontmatter (see [Provenance convention](#provenance-convention)).
This table is the human-readable summary.

| Skill | Group | Upstream | Notes |
| --- | --- | --- | --- |
| `tdd` | coding | mattpocock `skills/engineering/tdd` | Heavily localized: stack rules (PowerShell/SQL/Python/C#), reworked resources |
| `prototype` | coding | mattpocock `skills/engineering/prototype` | Localized |
| `caveman` | session | mattpocock `skills/productivity/caveman` | Minor edits |
| `grill-me` | session | mattpocock `skills/productivity/grill-me` | **Absorbed** `engineering/grill-with-docs`; `upstream-path` tracks the `grill-me` lineage only |
| `handoff` | session | mattpocock `skills/productivity/handoff` | Minor edits |
| `write-a-skill` | session | mattpocock `skills/productivity/write-a-skill` | Localized. Known issue: links `REFERENCE.md` but ships `EXAMPLES.md` — see below |
| `recon` | session | — (local original) | No upstream |
| `check-skill-updates` | setup | — (local original) | No upstream; the update tool itself |
| `scratch` | planning | — (local original) | The `.scratch/` tracker; owns `LAYOUT.md` / `RANKING.md` |
| `scratch-plan` | planning | — (local original) | Backlog ranking companion to `scratch` |

All upstream-derived skills were forked at mattpocock/skills commit
`aaf2453fbdfe7a15c07f11d861224f34ab4b53cb`.

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
- Local originals (`recon`, `check-skill-updates`, `scratch`, `scratch-plan`) carry **no**
  `upstream-*` fields.
- To check these against upstream, run `/setup:check-skill-updates`.

## Known content issues (carried over verbatim)

Preserved from the claude.ai imports, queued in `.scratch/claude-code-skill-adaptation/`:

- **`write-a-skill`** links `REFERENCE.md` but bundles `EXAMPLES.md` / `SCRIPTS.md` — reconcile.
