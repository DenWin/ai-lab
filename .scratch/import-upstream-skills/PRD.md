# PRD — Import Upstream Skills (Generic Process)

Status: process-delivered (imports pending) — see Progress

Define and implement a generic, repeatable process for importing skills from any upstream source
into this repo as first-class, grouped, provenance-tracked skills. The mattpocock GitHub repo at a
pinned upstream checkpoint is the first concrete use case that drove the need for this, but the process itself
must be source-agnostic.

> **Scope decision (2026-07-05):** this feature delivers **the skill that enables importing** — not
> the actual mattpocock import run. The generic process now lives as a first-class skill,
> `/setup:import-upstream-skill` (`ai-artifacts/skills/shared/setup/import-upstream-skill/SKILL.md`). Running the
> concrete 9-skill mattpocock import stays as follow-up work — issues 03 (coding), 04 (planning), 05
> (setup) — each executed by invoking the new skill.

## Progress (2026-07-05)

- ✅ **Generic import process extracted as a skill:** `/setup:import-upstream-skill` codifies the
  8-step process (snapshot → intent group → placement → `METADATA.md` provenance → capability-contract
  adaptation → verify via `write-a-skill` → origin-map update → sync). Source-agnostic; handles
  GitHub upstreams, local/global copies, and local forks (no dangling `upstream-commit`).
- ✅ **Origin map updated:** `ai-artifacts/skills/shared/README.md` lists `import-upstream-skill` as a local original.
- ⏳ **Actual imports remain:** issues 03/04/05 (import the coding / planning / setup clusters) are the
  first consumers of the new skill; the config-placement decision (issue 02) is only needed when the
  planning cluster is actually imported, so it stays deferred until then.

## Problem Statement

I imported my 7 polished claude.ai skills already. Matt's repo has more skills I want (his whole
`engineering/` set plus two `misc/` setup skills). They aren't in my repo yet, they're raw (chat /
bash flavored, not adapted to Claude Code on Windows/pwsh), and one of them — `setup-matt-pocock-skills`
— bakes in a configuration-distribution model I want to reconsider before adopting.

## Solution

Import each missing skill into `ai-artifacts/skills/shared/<group>/<name>/` under my intent-based grouping, with
`METADATA.md` provenance pointing at Matt's repo/path/checkpoint, then run the Claude Code
capability-contract adaptation pass on them. Resolve two design decisions first (grouping + the
config-distribution question) because they shape where things land.

## Scope — skills to import

Already present (imported in pass 1, **not** re-imported here): `tdd`, `prototype` (both
`engineering/`), and `grill-me` (the `productivity/grill-me` **+** `engineering/grill-with-docs`
merge). Their Claude Code adaptation is tracked in `.scratch/claude-code-skill-adaptation/`.

To import (source → proposed group):

| Upstream                                    | Skill                         | Proposed group           | Notes                                                                                                                              |
| ------------------------------------------- | ----------------------------- | ------------------------ | ---------------------------------------------------------------------------------------------------------------------------------- |
| `engineering/diagnose`                      | diagnose                      | `coding`                 | Ships `scripts/hitl-loop.template.sh` — needs a pwsh equivalent                                                                    |
| `engineering/improve-codebase-architecture` | improve-codebase-architecture | `coding`                 | Resources: DEEPENING, INTERFACE-DESIGN, LANGUAGE, HTML-REPORT                                                                      |
| `engineering/zoom-out`                      | zoom-out                      | `coding`                 | `disable-model-invocation: true` — preserve                                                                                        |
| `engineering/to-issues`                     | to-issues                     | `planning` *(new group)* | Reads the issue tracker (see decision 2)                                                                                           |
| `engineering/to-prd`                        | to-prd                        | `planning`               | Reads the issue tracker                                                                                                            |
| `engineering/triage`                        | triage                        | `planning`               | Resources: AGENT-BRIEF, OUT-OF-SCOPE; reads triage labels                                                                          |
| `engineering/setup-matt-pocock-skills`      | *(see decision 2)*            | `setup`                  | Subject of redesign — do not import as-is                                                                                          |
| `misc/git-guardrails-claude-code`           | git-guardrails                | `setup`                  | Ships `scripts/block-dangerous-git.sh` — needs pwsh equivalent; reconcile with existing global version                             |
| `misc/setup-pre-commit`                     | setup-pre-commit              | `setup`                  | **Diverges hard:** Matt's = Husky/lint-staged (JS); my prior version = pre-commit framework for PS/MD/AsciiDoc/SQL. See decision 3 |

This introduces a new top-level group: **`planning`** (issue/PRD/triage workflow).

The upstream source for all nine is committed under **`artifacts/`** in this feature folder
(mirroring Matt's `engineering/`/`misc/` layout), so the import is reproducible after `.temp/` is
cleared. `setup-matt-pocock-skills`'s config docs (`issue-tracker-local.md`, `triage-labels.md`,
`domain.md`) live there too — they feed decision 2. The user's prior *global* command-form versions
of all nine are committed under **`artifacts/global-prior/`** — mine them for local customizations
worth carrying into the import (especially `setup-pre-commit`, which diverges hard — decision 3).

### Issue coverage

| Skill                                                                   | Issue      |
| ----------------------------------------------------------------------- | ---------- |
| diagnose, improve-codebase-architecture, zoom-out                       | 03         |
| to-issues, to-prd, triage                                               | 04         |
| setup-matt-pocock-skills (config docs; skill itself replaced/dropped)   | 02         |
| git-guardrails, setup-pre-commit                                        | 05         |
| grouping + `planning` group (all)                                       | 01         |
| Claude Code adaptation (all imported)                                   | 06         |
| `/planning:scratch` + `/planning:scratch-plan` (local-markdown tracker) | 07 ✅ done |

## User Stories

1. As a Claude Code user, I want Matt's engineering skills available as `/coding:diagnose`,
   `/planning:to-issues`, etc., grouped by my intent scheme, so they fit alongside my existing set.
2. As a Claude Code user, I want each imported skill to carry `METADATA.md` provenance, so
   `/setup:check-skill-updates` tracks them against Matt's GitHub repo.
3. As a Claude Code user, I want the issue/PRD/triage skills wired to *this* repo's tracker
   (local-markdown `.scratch/`), so they work without GitHub Issues setup.
4. As a Claude Code user, I want the bash-script-bearing skills (diagnose, git-guardrails) to have
   Windows/pwsh equivalents, so they actually run on my machine.
5. As a Claude Code user, I want shared configuration (tracker, triage labels, domain-doc layout)
   stored once and read by every skill that needs it — without a heavyweight setup skill if a lighter
   model works (decision 2).
6. As a Claude Code user, I want `setup-pre-commit` to reflect *my* toolchain (pre-commit framework,
   PS/MD/AsciiDoc/SQL), not Matt's JS toolchain (decision 3).

## Implementation Decisions

- **Source of truth = Matt's repo** for these skills; each imported skill's `METADATA.md` records
  `upstream-author`, `upstream-repo`, `upstream-path`, and `upstream-commit`. Do not duplicate the
  exact upstream checkpoint in summary docs.
- **New `planning` group** for to-issues / to-prd / triage. Update `.gitignore` (add
  `/.claude/commands/planning/`) and re-run `scripts/sync-skills.ps1`.
- **Capability-contract adaptation** (same principle as pass 1): shell/tool path where available,
  conversational fallback otherwise. Convert Matt's `.sh` helpers to pwsh.
- **Tracker default = local-markdown `.scratch/`** (this repo already uses it). The planning skills
  read/write `.scratch/<feature>/` rather than `gh issue create`, unless decision 2 says otherwise.

### Decision 1 — grouping & the new `planning` group *(HITL)*

Confirm the group assignments above, especially introducing `planning`. Alternative: fold
to-issues/to-prd/triage into `coding`. Recommendation: separate `planning` group — issue/PRD/triage
is a distinct intent from writing code, and matches the prior global grouping.

### Decision 2 — config distribution: replace `setup-matt-pocock-skills`? *(HITL — grill-me first)*

Your question: *don't the issue-tracker docs belong in `to-issues` rather than a central setup skill?*

Premise check: the tracker config, triage-label vocabulary, and domain-doc layout are **shared** by
`to-issues`, `to-prd`, `triage` (and `diagnose`/`improve-codebase-architecture` read domain docs).
Putting that config *inside* one skill duplicates it across the others → drift. So per-skill *storage*
is the wrong axis. But two things Matt conflated are separable:

- **Where config is stored** — centralized (one place all skills read) vs. duplicated per skill.
  Centralized wins (DRY). The question isn't *whether* to centralize, it's *where*: `AGENTS.md` block,
  `docs/agents/*.md`, or `CONTEXT.md`.
- **How config gets there** — a monolithic interactive *setup skill* (Matt's model) vs. skills that
  *self-configure / degrade gracefully* vs. *hand-edited* `AGENTS.md`.

Options (handoff decision #5):

1. Keep a lean setup/init skill (renamed, mine — not Matt's branding) — explicit one-time run.
2. Self-configuring skills — each discovers the tracker (`.scratch/` present? `gh` remote?) or degrades.
3. Config-in-`AGENTS.md` — a `## Agent skills` block + `docs/agents/*.md`; skills just read it; no setup skill.
4. Hybrid: minimal `init` that only records the tracker choice; everything else read from `AGENTS.md`.

Recommendation (provisional, **do not finalize without grilling**): **option 3/4** — centralized
config in `AGENTS.md` + `docs/agents/`, skills read it, drop the monolithic setup skill in favor of a
minimal `init` (or none). The handoff explicitly says run `/session:grill-me` on this before building,
because it shapes every agentic skill. So: import the *config docs* (`issue-tracker-local.md`,
`triage-labels.md`, `domain.md`) as the centralized store, but do **not** import
`setup-matt-pocock-skills` as-is — replace it per the grilled decision.

### Decision 3 — `setup-pre-commit`: which toolchain is the source of truth? *(HITL)*

Matt's `setup-pre-commit` installs Husky + lint-staged + Prettier (JS ecosystem). My prior global
version targets the **pre-commit framework** with PSScriptAnalyzer / markdownlint / vale / sqlfluff
(PS/MD/AsciiDoc/SQL). These are different tools, not a localization delta.

Options: (a) treat my version as a **local fork** — SoT = my toolchain, provenance noted as
"diverged from mattpocock/misc/setup-pre-commit" but not tracked for auto-merge; (b) keep both as
separate skills. Recommendation: **(a) fork** — my toolchain is the one I use; record the lineage in a
comment, omit `upstream-commit` so the staleness check skips it (it's no longer a faithful downstream).

## Testing Decisions

- After each import: `scripts/sync-skills.ps1`, then invoke `/group:name` and confirm body +
  resources load and any `!command`/script paths resolve.
- For pwsh-converted scripts (diagnose HITL loop, git-guardrails block hook): run them on a throwaway
  target and confirm they behave (and that the guardrail actually blocks a dangerous git command).
- Structural review of each via `/session:write-a-skill`.
- `/setup:check-skill-updates` lists every newly-imported skill with `UP-TO-DATE` against the
  checkpoint recorded in its own `METADATA.md`.

## Out of Scope

- Re-importing pass-1 skills (`tdd`, `prototype`, `grill-me`).
- The wider `ai-lab` repo scaffold (AGENTS.md root, compatibility matrix, instructions/, mcp/) —
  separate handoff. (But decision 2 touches `AGENTS.md`; coordinate.)
- Deciding the GitHub-Issues-vs-local tracker globally — here we default to local-markdown `.scratch/`.
- **Other mattpocock skills not adopted now** (recoverable from the upstream repo, not copied):
  `in-progress/{review, teach, writing-beats, writing-fragments, writing-shape}`,
  `personal/{edit-article, obsidian-vault}`, `misc/{migrate-to-shoehorn, scaffold-exercises}`,
  `deprecated/*`. Candidates for a future adoption pass — evaluate per intent before pulling in.

## Attribution

These skills derive from [mattpocock/skills](https://github.com/mattpocock/skills). Per-skill
provenance is in `METADATA.md`.

## Further Notes

- Upstream snapshot: `.temp/github.com_mattpocock/skills`; exact checkpoints belong in each imported
  skill's `METADATA.md`.
- Provenance convention + origin map: `ai-artifacts/skills/shared/README.md`. Update flow: the `/setup:check-skill-updates` skill.
- Claude Code adaptation principles & pass-1 backlog: `.scratch/claude-code-skill-adaptation/`.
