# PRD — Scaffold the `ai-lab` repo & initialize git

Status: in-progress

Finish **Phase 2** of the ai-lab repo-structure handoff: make the repo an actual git repository
(`git init` + remote), add the artifact-type folders that have no home yet, author the root
`AGENTS.md`, place the remaining non-skill files, and land an initial commit. Source of truth:
[artifacts/HANDOFF-ai-lab-repo-structure.md](artifacts/HANDOFF-ai-lab-repo-structure.md).

## Problem Statement

The repo is now a git repository (`git init` done 2026-06-04, branch `main`; nothing committed yet).
The structure decisions were resolved via grill-me (2026-06-04) and the layout migrated.

> **[RESOLVED 2026-06-04 via grill-me]** The handoff's uniform `<vendor>/<harness>/` taxonomy was
> superseded. Canonical layout is now `shared/` (default) + `<vendor>/` + `<vendor>/<harness>/`,
> most-specific-wins; **loose folders** (no plugin bundles); folders created **on demand**. See
> [docs/repo-layout.adoc](../../docs/repo-layout.adoc) — the canonical layout reference.
> Done so far: `git init`; skills → `shared/skills/`; profile →
> `anthropic/claude-ai/instructions/profile.md`; `sync-skills.ps1` retargeted + re-run; layout doc
> authored. Remaining: `AGENTS.md`, file placement, remote, initial commit.

`git init` (done) unblocks the `tdd`-skill→foundation-doc git-repo reference (see
[testing-methodologies-foundation › issue 01](../testing-methodologies-foundation/issues/01-reference-doc-from-tdd-skill.md)).
This also folded in the earlier `init-git-repo` stub.

## Scope

Phase 1 of the handoff (skill adaptation) is largely done — skills live under `shared/skills/` and
remaining work is tracked in [claude-code-skill-adaptation](../claude-code-skill-adaptation/PRD.md)
and [import-upstream-skills](../import-upstream-skills/PRD.md). This feature is **Phase 2 only**:

1. ✅ `git init`, default branch `main`. `.gitignore` already reconciled (`.claude/commands/*`
   generated; `.temp/*` staged) — no change needed.
2. ✅ Structure resolved + migrated: skills → `shared/skills/`, profile →
   `anthropic/claude-ai/instructions/`, `sync-skills.ps1` retargeted, [docs/repo-layout.adoc](../../docs/repo-layout.adoc)
   authored. Per-harness artifact folders (`settings/`, `mcp/`, `hooks/`, `output-styles/`) are
   created **on demand**, not pre-scaffolded.
3. ⏳ Author the root `AGENTS.md` (cross-harness shared layer; coordinate with
   `incorporate-global-claude-setup` so it isn't written twice).
4. ⏳ Place remaining non-skill files: `INSTRUCTION-EVAL.md` → `eval/` (owned by eval-skill-harness);
   claude.ai project files → `anthropic/claude-ai/projects/<project-name>/`.
5. ⏳ Decide remote (host + visibility) → `gh repo create ai-lab --public|--private`; initial commit + push.

## Decisions

1. **#6 Taxonomy keying — RESOLVED (grill-me 2026-06-04).** `shared/` (default) + `<vendor>/` +
   `<vendor>/<harness>/`, most-specific-wins. Skills default to `shared/skills/`; config
   (instructions/settings/mcp/hooks/output-styles) lives under `<vendor>/<harness>/`. claude.ai adds
   a `projects/<project-name>/` layer. No vendor-only "platform" key. Ref: docs/repo-layout.adoc.
2. **#7 Packaging — RESOLVED.** Loose folders, not plugin bundles (personal use; can be wrapped into a
   plugin later if distribution ever matters).
3. **Tracker — settled by practice:** local-markdown `.scratch/`.
4. **Remote visibility — OPEN:** public vs private (affects license/attribution notes in
   [import-upstream-skills](../import-upstream-skills/PRD.md)). Decide before `gh repo create`.
5. **Project-specific files — RESOLVED:** the pwsh project files (`02-project-instructions.md`,
   `POWERSHELL.md`, `powershell.yml`) live under `anthropic/claude-ai/projects/<project-name>/`.

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
