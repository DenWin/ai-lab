# PRD — Investigate what `/planning:scratch` actually does

Status: done (investigation complete 2026-07-05 — see Findings)

Quick capture — iron out in scratch-planning, don't action yet.

## Problem Statement

Investigate and document what the `scratch` skill (`/planning:scratch`) actually does end to end —
its real behavior, not the one-line description. Establish ground truth before relying on it further.

## Open questions to answer (for the investigation, not to action now)

- The two modes: with `$ARGUMENTS` (quick-capture a stub PRD) vs. without (list the ranked backlog).
  What exactly does each do, step by step?
- What files does quick-capture create/touch — `PRD.md`, the `BACKLOG.md` row, anything else? What
  status/ranking does a new entry get, and how is the slug chosen?
- How does it relate to the sibling skills (`scratch-plan`, `to-issues`, `to-prd`, `triage`) and the
  canonical [LAYOUT.md](../../shared/skills/planning/scratch/LAYOUT.md) they all reference?
- Does the skill's documented behavior match what's been happening in practice (e.g. the stub PRDs +
  TBD backlog rows captured this session)? Any gaps between the SKILL.md and actual effect?

## Notes

- Source of truth: `shared/skills/planning/scratch/SKILL.md` (+ `LAYOUT.md`, `RANKING.md`); deployed
  mirror under `.claude/commands/planning/scratch/`.
- Motivation seems to be calibrating trust in the scratch workflow before leaning on it more (cf.
  [[gated-work-prd-issue-approval]], [[capture-not-execute]]).

## Findings (investigation 2026-07-05)

Ground truth read from `shared/skills/planning/scratch/SKILL.md` (+ `LAYOUT.md`, `RANKING.md`) and
`scratch-plan/SKILL.md`, cross-checked against the actual `.scratch/` tree.

### 1. The two modes, step by step

Mode is chosen by whether `$ARGUMENTS` is present.

**Mode A — Quick capture** (`/planning:scratch <idea>`):
1. Derive `<feature-slug>` from the argument — lowercase, hyphenated, ≤ 5 words.
2. Check `.scratch/` for a folder with a similar name; confirm before creating a duplicate.
3. Create `.scratch/<feature-slug>/PRD.md` from the stub template (see §2).
4. Append one row to `.scratch/BACKLOG.md` with **all ranking fields `TBD`** and **score `?`**. If
   `BACKLOG.md` is missing, create it from the LAYOUT template first.
5. Tell the user: `Created .scratch/<feature-slug>/. Run /planning:scratch-plan to set its rank.`

**Mode B — List backlog** (no arguments): read `.scratch/BACKLOG.md` and display it; if it doesn't
exist, say so and suggest capturing the first feature. **Note:** the investigation PRD called Mode B
"list the *ranked* backlog," but the skill only *reads and displays* whatever is in `BACKLOG.md` — it
does no ranking. Ranking is `scratch-plan`'s job (§3).

### 2. What quick-capture creates / touches

- **Creates** exactly `.scratch/<feature-slug>/PRD.md`. It does **not** create `issues/` or
  `artifacts/` — those are added later, by hand or by `to-issues`/import work.
- **Appends** one row to `.scratch/BACKLOG.md` (and creates that file if absent).
- **New entry state:** `Status: needs-triage`; ranking fields `TBD`; score `?`. The stub body is
  `Problem Statement` / `Solution` / `Further Notes`, each `_Fill in._`, plus a
  `_Created by /planning:scratch._` line.
- **Slug rule:** lowercase, hyphenated, ≤ 5 words, derived from the argument; dup-checked against
  existing folders.

### 3. Relationship to siblings and the canonical docs

- **`scratch` owns the canonical facts.** `LAYOUT.md` (folder structure, PRD/issue/BACKLOG shape) and
  `RANKING.md` (score = P × I × E, inverted effort, tiebreakers, escalation) live under the `scratch`
  skill. This is the repo's "single owner per fact" rule (AGENTS.md).
- **`scratch-plan` is the ranking companion.** `scratch` *appends* rows with `TBD`/`?`; `scratch-plan`
  runs a one-question-at-a-time interview (priority / importance / effort, with fuzzy-input bucket
  rounding), computes `P × I × E`, and **rewrites** `BACKLOG.md` sorted with a `Last updated:` line.
  Division of labour: `scratch` = capture + display; `scratch-plan` = calibrate + rank.
- **`to-issues` / `to-prd` / `triage` do NOT exist in the repo yet.** They are referenced in
  `scratch`'s description and `LAYOUT.md` as siblings that *will* reference `LAYOUT.md` rather than
  restate it, but they are still pending import (`import-upstream-skills`, issue 04). Today the only
  skills that actually consume `LAYOUT.md` are `scratch`, `scratch-plan`, and `check-skill-updates`
  (which links it for its tracker-config note). So that part of the "single owner" wiring is
  **forward-looking**, not yet realised.

### 4. Documented behavior vs. practice — gaps

- **Capture ≠ execute holds.** Mode A only records (stub PRD + TBD row); it never ranks, decides, or
  implements. This matches AGENTS.md's "Capture ≠ execute" rule and the observed stub PRDs + TBD rows.
- **PRDs in the tree are richer than the bare stub** — many carry filled Problem/Solution, `issues/`,
  `artifacts/`, `Origin: fable`, and richer statuses. That is expected: the stub is the *initial*
  capture; features are elaborated across later sessions and by other authors/harnesses. Not a bug —
  but worth stating that "a PRD in `.scratch/` ≠ freshly `scratch`-captured."
- **`BACKLOG.md` reality vs. template.** The live backlog has extra structure the LAYOUT template
  doesn't show: a `Last updated:` line, a `## Done` section for completed items, and a `(fable)`
  provenance marker on some rows. These come from `scratch-plan` rewrites and manual edits, not from
  `scratch`'s append. The LAYOUT template documents only the minimal header a fresh `BACKLOG.md` gets.
- **Deployment caveat.** `/planning:scratch` only resolves after the generated mirror exists
  (`.claude/commands/planning/scratch.md`). On a fresh clone / non-Windows sandbox the mirror is
  absent (gitignored; `pwsh scripts/sync-skills.ps1` not yet run) — so the *source* behavior above is
  authoritative, but the slash command itself may be unavailable until sync runs.

### Verdict

The `scratch` skill does exactly what its SKILL.md says: a two-mode capture/list tool that owns the
`.scratch/` conventions and hands ranking to `scratch-plan`. The only real "gaps" are (a) the sibling
planning skills it references aren't imported yet, and (b) the LAYOUT template understates what a
matured `BACKLOG.md` accumulates. Trust in the workflow is warranted; no behavior change needed.
