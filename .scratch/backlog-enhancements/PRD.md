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
- **Seeded 2026-07-11:** the 5 `Done` items were assigned `S0001`–`S0005` as part of the concept 5
  seed below — see Progress. Next assignment is `S0006`. Active scratches are **not** renamed yet;
  that one-time cost (rewriting every cross-reference across ~25 folders) is deliberately deferred
  until concept 7 (reference resolution index) exists, so the rewrite only has to happen once.

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

- Physical bucket folders vs grouped generated BACKLOG view for `funnel`/`backlog` (tension with
  concept 1's status-in-frontmatter; path churn on transitions). **Resolved for `done` only**
  (2026-07-11, by practice — see Progress): physical folder, `.scratch/DONE/<ID>-<slug>/`. `funnel`
  vs `backlog` still open.
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

### 7 — Reference resolution index (issue 07 — to create)

**Problem, paid for twice on 2026-07-11:** cross-references between scratches use real relative
paths (`../<slug>/PRD.md` or `[[slug]]` inconsistently). Every time a scratch moves, renames, or is
deleted, every file that links to it must be found and hand-fixed — moving the 5 `Done` items into
`DONE/<ID>-<slug>/` today required rewriting ~29 internal links across those 5 files plus 4 external
references in other scratches and `docs/reviews/`, all by hand.

**Proposal:** `.scratch/INDEX.md` — one row per scratch **ever created**, not just active ones:
`ID | slug | status | location`. `location` is the live path for active work, `DONE/<ID>-<slug>/`
for completed work, or a one-line redirect note (`merged into S00NN`, `superseded by S00NN`) for
anything gone. This is the **only** file whose `location` column changes when something moves —
no other file needs touching.

- **Reference convention:** cross-references switch from real paths to `[[slug]]` or `[[S<NNNN>]]`
  — a lookup key into `INDEX.md`, not a path. (Several PRDs already do this informally, e.g.
  `[[repo-scaffold]]` in `repo-scope-strays`; this makes it the rule instead of an accident.)
- **Validation, not a daemon:** extend `scripts/setup-repo.ps1 -Check` (already does generated-mirror
  drift detection) to also confirm every `[[..]]` reference resolves in `INDEX.md`, and flag any
  leftover raw `](.../PRD.md)` link into `.scratch/` that should be symbolic instead.
- **Relationship to concept 4:** concept 4 makes the ID itself durable (folder name never changes
  once assigned); concept 7 makes *referencing* that ID from anywhere survive the folder moving,
  merging, or disappearing. The ID is `INDEX.md`'s primary key.
- **Why a flat markdown table, not SQLite:** `.scratch/AGENTS.md` already commits to a "committed
  local-markdown issue tracker" — a table stays git-diffable and greppable without tooling; at this
  scale (~30 entries) a database buys nothing extra.

### 8 — Definition of Ready / Definition of Done for scratches (issue 08 — to create)

**Problem:** no explicit gate on when a scratch is detailed enough to start work, nor a checklist for
calling it actually done — which let at least one `Done` item's claim go stale unnoticed (a redaction
sweep that needed re-running after later content landed, caught only by a manual 2026-07-10 audit,
not by any built-in check).

**Definition of Ready** — a scratch may leave `needs-triage`/`funnel` only when:

1. Frontmatter is filled in with the core properties (concept 1's schema, at minimum
   `status`/`priority`/`importance`/`effort` — not `TBD`).
2. It has broken-down `issues/`, not just a `PRD.md` — the PRD is the idea, issues are the units of
   work. **Blocked on import:** the skill that generates these (`to-issues`) isn't in
   `ai-artifacts/skills/shared/` yet, only as an upstream artifact under `[[import-upstream-skills]]`
   (per `[[understand-scratch-skill]]`'s §3a findings) — DOR issue 2 can't be enforced until that
   import lands.
3. It states its **kind** — modifying an existing artifact vs. creating a new one — and names the
   artifact(s) touched.
4. It is **self-contained**: everything it references stays resolvable even if the source drifts.
   - Anything sourced from `.temp/` (gitignored, ephemeral) is **always** copied into the scratch's
     `artifacts/`, no question asked — otherwise the reference silently rots once `.temp/` is cleared.
   - A referenced standalone document elsewhere in the repo (e.g. a `docs/reviews/*.md`) is **always**
     cloned into `artifacts/` too, dated (`artifacts/YYYY-MM-DD-<name>.md`) — a snapshot, not a live
     pointer, so later edits to the original don't retroactively change what this scratch reasoned
     about.
   - A referenced **scratch** is never cloned — only referenced by its stable ID via concept 7's
     index, since scratches are already the durable record (cloning them would violate AGENTS.md's
     "single owner per fact" rule).
   - **Cap:** this covers the specific files a scratch's reasoning depends on, not a mirror of the
     repo. If a scratch's scope is repo-wide, it doesn't get a copy of the repo — the "do you want to
     save this artifact?" question only applies to content whose *current state* the reasoning
     actually leans on.
5. Acceptance criteria are written down as testable statements, not a vibe.

**Definition of Done:**

1. Every issue under the scratch is individually closed — not just the PRD's top `Status:` line
   flipped.
2. The PRD carries a dated Progress/Findings section stating what was actually done, checked against
   the DOR acceptance criteria — "done" means done-against-something, not just claimed.
3. Any deliverable produced lives in its real artifact-type home (`ai-artifacts/`, `docs/`, ...) per
   `.scratch/AGENTS.md` — nothing shippable is left stranded in `artifacts/`.
4. The scratch's `INDEX.md` entry (concept 7) is updated to `done` with `location` pointing at
   `DONE/<ID>-<slug>/` — the only place other references resolve through, so nothing else needs
   editing.
5. No unresolved "Refinement questions" / open decisions remain in the body — either answered inline,
   or spun out into a fresh scratch (its own ID) instead of left dangling in a closed record.

**Relationship to other scratches in this cluster:** `[[gated-work-prd-issue-approval]]` owns *who*
approves the DOR gate and the branch/PR flow after DOD is met; `[[scratch-immutability-appendix]]`
owns what happens *after* DOD — once a human has reviewed a done scratch, no more in-place edits,
only appendices. This concept owns the *content* of the two checklists those other two gate on.

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

## Progress (2026-07-11)

- ✅ Concept 5 seed: `.scratch/DONE/` created as the physical done-bucket. Resolves the "physical
  folder vs generated view" question for the `done` stage specifically; `funnel`/`backlog` still open.
- ✅ Concept 4 seed: the 5 existing `Done` items assigned stable IDs `S0001`–`S0005` and moved to
  `DONE/<ID>-<slug>/`. Their internal relative links (and 2 sibling links between `S0001` and `S0002`)
  were rewritten for the new nesting depth by hand — the exact cost concept 7 exists to eliminate.
  Active scratches are untouched; next ID is `S0006`.
- ✅ Concepts 7 (reference resolution index) and 8 (DOR/DOD) captured above, prompted directly by
  today's manual link-fixing and by the user noticing they no longer reliably remember what each
  scratch means after time passes.

## Further Notes

- Migrating existing PRDs (`Status:` line → frontmatter) is part of issue 01; keep `Status:` working
  during transition or convert all at once.
