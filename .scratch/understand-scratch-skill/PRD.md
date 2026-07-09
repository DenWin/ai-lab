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
  canonical [LAYOUT.md](../../ai-artifacts/skills/shared/planning/scratch/LAYOUT.md) they all reference?
- Does the skill's documented behavior match what's been happening in practice (e.g. the stub PRDs +
  TBD backlog rows captured this session)? Any gaps between the SKILL.md and actual effect?

## Notes

- Source of truth: `ai-artifacts/skills/shared/planning/scratch/SKILL.md` (+ `LAYOUT.md`, `RANKING.md`); deployed
  mirror under `.claude/commands/planning/scratch/`.
- Motivation seems to be calibrating trust in the scratch workflow before leaning on it more (cf.
  [[gated-work-prd-issue-approval]], [[capture-not-execute]]).

## Findings (investigation 2026-07-05)

Ground truth read from `ai-artifacts/skills/shared/planning/scratch/SKILL.md` (+ `LAYOUT.md`, `RANKING.md`) and
`scratch-plan/SKILL.md`, cross-checked against the actual `.scratch/` tree — and, for the sibling
relationship, against the committed mattpocock upstream artifacts of `to-issues`/`to-prd`/`triage`
(§3a).

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
- **`to-issues` / `to-prd` / `triage` aren't imported into `ai-artifacts/skills/shared/` yet** — but their
  mattpocock **upstream versions are committed as artifacts** under
  `import-upstream-skills/artifacts/engineering/{to-issues,to-prd,triage}/SKILL.md` (plus the config
  docs `setup-matt-pocock-skills/{issue-tracker-local,triage-labels,domain}.md`). Import into
  `shared/` is deferred to `import-upstream-skills` issue 04. Today the only skills that actually
  consume `LAYOUT.md` are `scratch`, `scratch-plan`, and `check-skill-updates`, so the "single owner"
  wiring for the planning cluster is **forward-looking**. What the upstream artifacts *expect* of the
  tracker is analysed in §3a — it matters because it tells us what `LAYOUT.md` must expose before those
  skills can be wired to `.scratch/`.

### 3a. Sibling-skill compatibility — `scratch`/`LAYOUT.md` vs. the upstream artifacts

Analysed the committed mattpocock artifacts (`to-issues`, `to-prd`, `triage` + `issue-tracker-local.md`,
`triage-labels.md`, `domain.md`) against `LAYOUT.md`/`RANKING.md` to see what the planning cluster
needs from the tracker `scratch` owns. The interface is a **near-fit with four concrete gaps** — worth
capturing on `import-upstream-skills` issue 04 (and issue 02 for the config side):

1. **Storage contract already matches — except `## Comments`.** `issue-tracker-local.md` describes the
   exact tracker `LAYOUT.md` defines: one `.scratch/<feature-slug>/` dir, `PRD.md`,
   `issues/<NN>-<slug>.md` numbered from 01, and the `Status:` line as triage state. The **one thing it
   adds that `LAYOUT.md` lacks** is a `## Comments` append convention — `triage` posts triage
   notes / agent-brief comments and `to-issues`/`to-prd` "publish to the tracker" by writing there.
   `LAYOUT.md` must define a `## Comments` section before those skills land.

2. **Status vocabularies diverge — needs a reconciliation decision.**
   `LAYOUT.md` enum: `needs-triage · ready-for-human · ready-for-agent · in-progress · done · wontfix`.
   `triage` **state** roles: `needs-triage · needs-info · ready-for-agent · ready-for-human · wontfix`.
   Delta: `triage` adds `needs-info` (absent from `LAYOUT.md`) **and** a `bug`/`enhancement`
   **category** dimension `scratch` has no equivalent for; `LAYOUT.md` has `in-progress`/`done` that
   `triage` lacks (it *closes* issues instead). `triage-labels.md` is the intended mapping seam, but on
   a *feature/PRD* tracker the bug/enhancement category and `needs-info` are awkward fits — import must
   decide: extend `LAYOUT.md`'s enum (add `needs-info`), or map the roles onto the existing vocabulary.

3. **`to-prd` explains "PRDs richer than the stub" (§4).** `to-prd`'s template — Problem / Solution /
   User Stories / Implementation Decisions / **Testing Decisions** / Out of Scope / Further Notes — is
   far richer than `scratch`'s 3-section stub, and it matches the shape the **matured** `.scratch/`
   PRDs already use. So the roles are complementary: `scratch` = thin quick-capture; `to-prd` =
   synthesize a full PRD from context (applies `ready-for-agent` directly → maps cleanly to a
   `LAYOUT.md` Status). The one scratch-side gap: `to-prd`'s **Testing Decisions / seams** section is a
   mattpocock TDD-ism absent from the stub and from most current PRDs.

4. **`to-issues` output already fits — plus the `Status:` line and a methodology layer.** Its
   issue-template (Parent / What to build / Acceptance criteria / Blocked by) aligns with `LAYOUT.md`'s
   issue shape; the repo's existing `issues/01–07` already follow it. Deltas: `to-issues` adds an
   optional **Parent** link (harmless), and its template omits the `Status:` line `LAYOUT.md` requires
   (the local adaptation must add it). Its tracer-bullet / HITL-AFK vertical-slicing is how issues are
   *derived*, not how they're *stored*, so `LAYOUT.md` is unaffected.

**Unmet dependencies the cluster expects (non-blocking):** all three read a domain glossary —
`CONTEXT.md` + `docs/adr/` per `domain.md` — which **do not exist** in the repo; `domain.md` says to
"proceed silently if absent," so it's soft, but it's the domain-doc side of `import-upstream-skills`
issue 02. And all three currently say "run `/setup-matt-pocock-skills`" for the tracker/label config —
the repo plan (issue 07 decision) drops that monolithic skill so the imported skills read `.scratch/`
conventions from `LAYOUT.md` directly plus a small triage-label map.

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

### Reevaluation (2026-07-06)

User-requested recheck of the last open question ("how does it relate to the sibling skills?"):
**confirmed answered** by §3 + §3a above — `scratch-plan` division of labour is documented, and the
`to-issues`/`to-prd`/`triage` compatibility analysis (four gaps) is already propagated as the
"Tracker-contract prerequisites" checklist on
[`import-upstream-skills` issue 04](../import-upstream-skills/issues/04-import-planning-cluster.md).
Verified against the repo today: the three siblings are still not imported
(`ai-artifacts/skills/shared/planning/` = `scratch` + `scratch-plan` only), so the §3a answer stands unchanged.
Nothing remains in this scratch; follow-up work lives in [[import-upstream-skills]] issues 02/04.

### Verdict

The `scratch` skill does exactly what its SKILL.md says: a two-mode capture/list tool that owns the
`.scratch/` conventions and hands ranking to `scratch-plan`. Trust in the workflow is warranted; no
change to `scratch` itself is needed today. The actionable output of this investigation is the **§3a
compatibility list** — before `to-issues`/`to-prd`/`triage` are imported (issue 04), `LAYOUT.md` needs
a `## Comments` convention and a status-vocabulary reconciliation (the `needs-info` + `bug`/`enhancement`
delta), and the imported skills must add the `Status:` line to `to-issues` output and read tracker/
domain config from `LAYOUT.md` (+ a triage-label map) rather than `/setup-matt-pocock-skills`. Those are
inputs to `import-upstream-skills` issues 04/02, not changes to `scratch`.
