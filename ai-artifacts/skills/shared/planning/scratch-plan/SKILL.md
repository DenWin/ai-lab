---
name: scratch-plan
version: 1.0.0
description: >
  Review .scratch/ features one by one via a structured grill-me to calibrate or update each
  feature's priority, importance, and effort estimate — then rewrite .scratch/BACKLOG.md in ranked
  order. Use when the backlog has TBD rankings, when circumstances have changed, or when the order
  no longer feels right. Pass a feature slug as $ARGUMENTS to review a single feature; omit for all.
argument-hint: "[<feature-slug>]  — omit to review all features with TBD or outdated rankings"
---

# Scratch Plan

Reviews `.scratch/` features and keeps the backlog current. Reads the ranking formula from
`skills/planning/scratch/docs/RANKING.md` and the layout from `skills/planning/scratch/docs/LAYOUT.md`.

## Process

### 1. Discover features

- If `$ARGUMENTS` is provided: target only that feature slug.
- Otherwise: read `.scratch/BACKLOG.md` and identify features where any ranking field is `TBD`, or
  where the user has asked for a full re-review.

### 2. For each target feature — structured interview

Present the feature name and its current rankings (if any). Then ask **one question at a time**:

**A. Priority** — `high / medium / low`
> "How urgently does this need to happen? High = blocking other work or time-sensitive; Medium = should
> happen soon; Low = nice-to-have."

**B. Importance** — `high / medium / low`
> "How much does this matter to you personally? High = directly impacts daily use or key goals;
> Medium = valuable but not critical; Low = marginal benefit."

**C. Effort** — `4h / 1day / 2days / 1week / 2weeks / 1month / 2months`
> "Roughly how long would it take to complete this feature end-to-end, including decisions?"

If the user enters a non-standard value (e.g. "5h", "3 days"), round to the nearest bucket using
midpoints between adjacent buckets (bucket hours: 4h=4, 1day=8, 2days=16, 1week=40, 2weeks=80,
1month=160, 2months=320):

| Input         | Maps to |
| ------------- | ------- |
| < 6h          | 4h      |
| 6h – < 12h    | 1day    |
| 12h – < 28h   | 2days   |
| 28h – < 60h   | 1week   |
| 60h – < 120h  | 2weeks  |
| 120h – < 240h | 1month  |
| ≥ 240h        | 2months |

Silently apply the rounding and confirm the mapped bucket to the user before continuing.

**D. Sanity check** — only if rankings are being updated (not new)
> "The score changes from X to Y, moving it from rank N to rank M. Does that feel right?"
> Accept or adjust.

Do not ask D for features with all-TBD rankings (nothing to compare to).

### 3. Escalation rule

When the user wants to raise a feature's rank outside the normal interview:

- If `importance < high` → raise `importance` one level.
- If `importance = high` → raise `priority` one level instead (up to `high`).
- If both are already `high` and the user still wants a boost, note it and flag it:
  "Both importance and priority are already at high. Consider reducing effort scope to move it
  up on score, or confirm you want it at the top regardless."

### 4. Rewrite BACKLOG.md

After all interviews, compute each feature's score: `P × I × E` using the numeric values in
`skills/planning/scratch/docs/RANKING.md`. Sort descending by score; apply tiebreakers in order:
less effort → higher importance → higher priority → alphabetical.

Rewrite `.scratch/BACKLOG.md` with the updated table, numbered ranks, and a `Last updated:` line.

Show the final table to the user before writing; adjust if they redirect.

### 5. Done

Tell the user which features were updated and what the new top-3 are.

## Notes

- Features with `Status: done` or `Status: wontfix` stay in the table but are visually separated
  below the active items. They do not affect ranking of active features.
- If a feature has no PRD.md yet (stub only), note it and suggest the user fill in the problem
  statement before ranking — but don't block: TBD rankings are valid stubs.
