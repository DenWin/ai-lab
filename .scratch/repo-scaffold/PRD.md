# PRD — Scaffold the `ai-lab` repo & initialize git

Status: needs-triage

Finish **Phase 2** of the ai-lab repo-structure handoff: make the repo an actual git repository
(`git init` + remote), add the artifact-type folders that have no home yet, author the root
`AGENTS.md`, place the remaining non-skill files, and land an initial commit. Source of truth:
[artifacts/HANDOFF-ai-lab-repo-structure.md](artifacts/HANDOFF-ai-lab-repo-structure.md).

## Problem Statement

The repo is **partially scaffolded but not under version control** — the environment reports
`Is a git repository: false`. Present today: `docs/`, `instructions/`, `skills/`, `scripts/`,
`.scratch/`, `.gitignore`, `LICENSE`. **Missing** per the settled handoff structure: root
`AGENTS.md`, and homes for the other artifact types — `mcp/`, `output-styles/`, `settings/`,
`agents/`, `hooks/`, `eval/`.

> **[RE-CONFIRM]** The "settled handoff structure" (artifact-type taxonomy) comes from the
> claude.ai session that produced `HANDOFF-ai-lab-repo-structure.md`. Confirm the folder taxonomy
> still matches how you want the repo laid out before creating the folders (scope item 2). Note the
> handoff's *own* open decisions (#6/#7 below) are already correctly flagged as not-settled.

Because there is no git repo, downstream work is blocked — notably the `tdd` skill cannot reference
the foundation doc by a git-repo path (see
[testing-methodologies-foundation › issue 01](../testing-methodologies-foundation/issues/01-reference-doc-from-tdd-skill.md)).

This was the gap behind the earlier `init-git-repo` stub — now folded here, because `git init` is
**step 5 of Phase 2**, not standalone work.

## Scope

Phase 1 of the handoff (skill adaptation) is largely done — `skills/` is populated and its remaining
work is tracked in [claude-code-skill-adaptation](../claude-code-skill-adaptation/PRD.md) and
[import-upstream-skills](../import-upstream-skills/PRD.md). This feature is **Phase 2 only**:

1. `git init`, establish the default branch, confirm `.gitignore` (reconcile with the sync-skills
   flow — `.claude/commands/**` is generated — and the `.temp/` staging convention).
2. Create the missing artifact-type folders: `mcp/`, `output-styles/`, `settings/`, `agents/`,
   `hooks/`, `eval/` (each per the handoff's artifact-type taxonomy).
3. Author the root `AGENTS.md` stub (broadest-compatible entrypoint; harness/vendor-specific files
   live under `instructions/`).
4. Place remaining non-skill files per the handoff's artifact inventory (profile →
   `instructions/global/profile.md`, `INSTRUCTION-EVAL.md` → `eval/`, project-specific files per
   decision #3).
5. Decide remote (host + visibility) → `gh repo create ai-lab --public|--private`; initial commit + push.

## Open Decisions (from the handoff — confirm before committing structure)

These are settled-as-questions in the handoff; **do not pre-answer** — the handoff says to grill them:

1. **#6 Taxonomy keying** — folder keys use **harness** (primary) + **vendor** (tag); drop "platform".
   Decide concrete keys: `instructions/<vendor>/<harness>/`, `skills/<vendor>/<harness>/`, etc.
   (`docs/platforms/` is already `docs/harnesses/` — good.)
2. **#7 Packaging** — loose artifact folders vs Claude Code **plugin bundles**
   (`.claude-plugin/plugin.json`). If plugins win, `skills/`/`agents/`/`hooks/`/`mcp/`/`output-styles/`
   nest inside `plugins/<name>/` rather than top-level. Resolve **before** creating the folders in
   scope item 2, since it changes where they live.
3. **Tracker** — GitHub Issues (`gh issue create`) vs local-markdown `.scratch/`. This repo already
   uses `.scratch/`; default to it unless the init decision says otherwise.
4. **Remote visibility** — public vs private (affects the license/attribution notes in
   [import-upstream-skills](../import-upstream-skills/PRD.md)).
5. **Project-specific files** (#3 in handoff) — `02-project-instructions.md`, `POWERSHELL.md`,
   `powershell.yml` etc.: move under `instructions/` keyed per #6, leave in the claude.ai project, or
   both.

## Relationship to existing backlog features

This is the **umbrella/parent** the handoff spawned; several siblings are already decomposed out and
are **not** re-scoped here:

- [harness-docs](../harness-docs/PRD.md) — the compatibility-matrix / `docs/harnesses/` living doc.
- [eval-skill-harness](../eval-skill-harness/PRD.md) — the `eval/` build (separate handoff).
- [incorporate-global-claude-setup](../incorporate-global-claude-setup/PRD.md) — global `~/.claude/`
  config → repo; touches the same root `AGENTS.md`.
- [claude-code-skill-adaptation](../claude-code-skill-adaptation/PRD.md) /
  [import-upstream-skills](../import-upstream-skills/PRD.md) — Phase 1 skill work.

Coordinate the root `AGENTS.md` authoring (scope item 3) with `incorporate-global-claude-setup`
decision 2 (the overlap hoist) so it isn't written twice.

## Blocks

- [testing-methodologies-foundation › issue 01](../testing-methodologies-foundation/issues/01-reference-doc-from-tdd-skill.md)
  — the tdd-skill→doc git-repo reference needs `git init` (scope item 1) done first.

## Further Notes

- Source handoff: [artifacts/HANDOFF-ai-lab-repo-structure.md](artifacts/HANDOFF-ai-lab-repo-structure.md)
  (recovered from VS Code Local History; the live `.temp/` copy was already cleared).
- Handoff explicitly directs `/session:grill-me` on the structure (decisions #6/#7) and on the
  setup/init-skill design before scaffolding, and `/session:recon` to verify `git`/`gh` auth first.
- Created via `/planning:scratch`; replaces the earlier over-narrow `init-git-repo` stub.
