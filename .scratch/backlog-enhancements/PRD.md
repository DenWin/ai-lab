# PRD — Backlog enhancements (metadata, recurrence, deadline ranking, stable IDs, browse-by-status)

Status: ready-for-human

Three enhancements to the `.scratch` system (the `/planning:scratch` + `/planning:scratch-plan`
skills, `LAYOUT.md`, `RANKING.md`, and `BACKLOG.md`). Captured as ideas; concept #3 explicitly
needs a `/session:grill-me` pass before building.

## Problem Statement

`BACKLOG.md` currently tracks only Rank / Feature / Priority / Importance / Effort / Score / Status.
It has no notion of dependencies, deadlines, staleness, or recurring work, and the ranking ignores
how close a deadline is relative to the remaining effort. As the backlog grows this becomes
insufficient for deciding what to do next.

## Solution (proposed — refine in grill)

Make each PRD's **frontmatter** the per-feature metadata source of truth. `BACKLOG.md` becomes a
*generated* ranked view rendering only the decision-relevant subset of columns — so the metadata can
be rich without the table becoming unreadable. `scratch-plan` reads frontmatter, applies a
deadline-aware ranking pass, handles recurrence, and re-renders `BACKLOG.md`.

## Concepts

### 1 — Extend backlog metadata (issue 01)

Introduce PRD frontmatter as the source of truth; a **generator** (a standalone script, invocable by
`scratch-plan`) reads each PRD's YAML frontmatter and renders a subset to `BACKLOG.md`. `BACKLOG.md`
is never hand-maintained for metadata — it is replaced by generated output.

Proposed frontmatter:

```yaml
---
status: ready-for-human        # needs-triage | ready-for-human | ready-for-agent | in-progress | done | wontfix
priority: TBD                  # high | medium | low
importance: TBD                # high | medium | low
effort: TBD                    # 4h | 1day | 2days | 1week | 2weeks | 1month | 2months
due: none                      # YYYY-MM-DD or none
created: 2026-06-03
updated: 2026-06-03
recurrence: none               # none | 1week | 2weeks | 1month | 3months | ...
blocked-by: []                 # list of feature slugs
area: none                     # optional tag: skills | infra | docs | eval | ...
---
```

New columns the user asked for: **blocked-by**, **due**, **last-updated**. Added on top:
**created** (pairs with updated to expose staleness), **recurrence** (needed by concept 2),
**area** (optional). Open question: exactly which subset renders into the `BACKLOG.md` table vs.
stays frontmatter-only (table width tradeoff).

### 2 — Recurring features (issue 02)

`recurrence` in the original PRD frontmatter defines the cadence. When a recurring feature is marked
`done`, it reappears with a fresh due date (`done-date + recurrence`).

Open design (recommend A): **reset in place** — same folder, `status` back to `ready-for-human`,
`due` bumped, append a `## Recurrence log` entry with the completion date. Keeps history, no clutter.
Alternative B: spawn a new `.scratch/<slug>-<date>/` per occurrence — full per-occurrence history but
clutters `.scratch` and `BACKLOG.md`. Trigger is checked when `scratch-plan` runs (no daemon).

### 3 — Deadline-aware ranking (issue 03 — NEEDS GRILLING)

Feed the due date into ranking, modifying **priority** before `Score = P × I × E` is computed
(priority = urgency, so deadline pressure → priority is semantically consistent with the existing
escalation rule).

User's draft rule:
- If no `due` is set at `scratch-plan` time: assume **4 weeks out** for ranking only — do **not**
  persist it.
- If `business_days(today → due) < effort_person_days × 2` **and** the feature was not `updated`
  within the last 7 days → raise priority one level (cap at high).

This is acknowledged as needing more grilling — see issue 03 for the open edge cases.

### 4 — Stable scratch IDs (issue 04 — to create)

Assign each feature an **immutable** ID `S<NNNN>-<feature-slug>` (e.g. `S0007-repo-scaffold`), used as
the folder name and as a short referenceable handle. The ID never encodes status or rank, so it never
needs to change.

- **Assignment:** next-free integer (max existing + 1), zero-padded to 4 — derivable from folder names,
  no separate counter file.
- **One-time cost:** renaming the 9 existing folders to `S<NNNN>-<slug>` **breaks every relative
  cross-reference** (`../<slug>/...`) in PRDs/issues/BACKLOG; all must be rewritten in the same pass.
- **Knock-on:** update `LAYOUT.md` (folder = `S<NNNN>-<slug>/`) and the `scratch` / `scratch-plan` /
  `to-issues` / `to-prd` / `triage` skills that currently assume a bare `<slug>/`.

### 5 — Organize scratches by lifecycle stage (issue 05 — to create)

**Problem:** once there are many scratches, it's hard to tell which stage each is in. `done` and
`won't_fix` especially clutter the active view — they should be out of the way.

**Idea:** separate scratches into **coarse lifecycle buckets**, not fine-grained status. Working
buckets:

- **funnel / undefined** — captured but not yet ironed out (open questions, not fully understood)
- **backlog** — fully understood features, including `in-progress`
- **done**
- **won't_fix**

Indifferent to *mechanism* — physical bucket folders or a grouped generated view — as long as the
separation is achieved, particularly pulling `done` / `won't_fix` out of the active set. How the coarse
buckets map onto the fine `Status:` values is part of this.

**Open for scratch-planning (do NOT decide here):**
- Physical bucket folders vs grouped generated BACKLOG view (tension with concept 1's
  status-in-frontmatter; path churn on transitions). Resolve when this feature is planned.
- Whether `funnel` / `undefined` becomes a real `Status:` value (see concept 6).

### 6 — Capture enters the funnel; ironing-out happens in scratch-planning (issue 06 — to create)

The intended workflow, made explicit:

- A **new** scratch is a quick offload (minimal detail) and lands in **funnel / undefined** by default
  — not a fully-detailed `needs-triage` entry.
- **scratch-planning** is where features get ironed out — discuss in detail, answer questions, tackle
  contradictions, rank. It is **not** where they get *worked on / implemented*.
- On revisit: if the captured thought is no longer understood, it goes to **won't_fix**.

Implication: `scratch` (capture) defaults `status` to `funnel`/`undefined`; `scratch-plan` promotes
funnel → backlog as items become understood. Adds `funnel`/`undefined` to the status vocabulary
(concept 1).

## Implementation Decisions (provisional)

- **Source of truth:** PRD frontmatter; `BACKLOG.md` is generated by `scratch-plan`, never hand-edited
  for metadata (only `scratch` appends a stub row on capture).
- **Deadline → priority, not a 4th score factor:** keeps `Score = P × I × E` intact; due date is a
  pre-processing step on P.
- **Ephemeral default due date:** the 4-week assumption is used in-memory for ranking and never
  written back.
- **Files touched:** `skills/planning/scratch/SKILL.md`, `skills/planning/scratch/LAYOUT.md`,
  `skills/planning/scratch/RANKING.md`, `skills/planning/scratch-plan/SKILL.md`, `.scratch/BACKLOG.md`.

## Out of Scope

- Any daemon/automation for recurrence or deadline alerts (no background process; checked on
  `scratch-plan` run).
- Time-tracking / burn-down. Assignees (solo use).

## Further Notes

- Migrating existing PRDs (`Status:` line → frontmatter) is part of issue 01; keep `Status:` working
  during transition or convert all at once.
