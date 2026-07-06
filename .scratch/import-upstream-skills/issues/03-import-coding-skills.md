# 03 — Import the coding skills (diagnose, improve-codebase-architecture, zoom-out)

Status: done (all three coding skills imported + dual-mode adapted 2026-07-05)

## What to build

Import these three from Matt's repo into `shared/skills/coding/` with per-skill `METADATA.md`
provenance, copying bundled resources verbatim, then `scripts/sync-skills.ps1`:

- `diagnose` (+ `scripts/hitl-loop.template.sh` — keep the file; pwsh equivalent is an adaptation task)
- `improve-codebase-architecture` (+ DEEPENING, INTERFACE-DESIGN, LANGUAGE, HTML-REPORT)
- `zoom-out` (preserve `disable-model-invocation: true`)

Body adaptation (capability contract, pwsh) is tracked separately in issue 06 — this issue is the
faithful import + grouping + provenance only.

## Acceptance criteria

- [ ] Three skills under `skills/coding/<name>/` with correct `upstream-*` frontmatter
- [ ] Bundled resources present; `zoom-out` retains `disable-model-invocation`
- [ ] `sync-skills.ps1` run; `/coding:diagnose` etc. resolve; resource links rewritten correctly
- [ ] `/setup:check-skill-updates` shows them `UP-TO-DATE`

## Progress (2026-07-05)

Per the corrected scope (actually import + adapt the skills, dual-mode), import and adaptation are
done together here rather than deferring adaptation to issue 06:

- ✅ **`diagnose`** → `shared/skills/coding/diagnose/` with `upstream-*` provenance. Added a **Modes
  (capability contract)** section — shell/FS present ⇒ build & run the loop; no shell (claude.ai) ⇒
  design the loop and drive the user through it, working off the signal they paste. HITL helper now
  ships **pwsh** (`scripts/hitl-loop.template.ps1`, primary) **+ bash** (`.sh`, cross-platform).
- ✅ **`zoom-out`** → `shared/skills/coding/zoom-out/` with provenance; `disable-model-invocation`
  preserved; added a one-line "if a filesystem is available… else work from pasted context" note.
- ✅ **`improve-codebase-architecture`** → `shared/skills/coding/improve-codebase-architecture/` with
  provenance + all four resources (DEEPENING / INTERFACE-DESIGN / LANGUAGE / HTML-REPORT). Added a
  **Modes** section (Explore subagent + temp-file report vs. reason over pasted code + downloadable
  report; CONTEXT/ADR edits inline vs. proposed-as-text). Repointed the two `../grill-with-docs/`
  resource links to `../../session/grill-me/` (that skill was absorbed into `grill-me` here).

**Coding cluster (issue 03) complete.** Next clusters: 04 (planning), 05 (setup).

## Blocked by

- 01 (grouping confirmed)
