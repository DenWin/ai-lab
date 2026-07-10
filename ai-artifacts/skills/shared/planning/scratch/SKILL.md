---
name: scratch
version: 1.0.0
description: >
  Manage .scratch/ feature entries and the backlog. Two modes: with $ARGUMENTS quick-captures a new
  feature idea as a stub PRD; without arguments, lists the ranked backlog. The canonical definition
  of the .scratch/ layout — other skills (to-issues, to-prd, triage, check-skill-updates) reference
  [LAYOUT.md](docs/LAYOUT.md) rather than restating the conventions. For re-ranking the backlog
  use /planning:scratch-plan.
argument-hint: "<feature idea or slug>"
---

# Scratch

Manages `.scratch/` feature entries and the backlog. Determine mode from `$ARGUMENTS`:

## Mode A — Quick capture  (`/planning:scratch <idea>`)

When `$ARGUMENTS` is provided:

1. Derive a `<feature-slug>` (lowercase, hyphenated, ≤ 5 words) from the argument.
2. Check `.scratch/` for an existing folder with a similar name — confirm before creating a
   duplicate.
3. Create `.scratch/<feature-slug>/PRD.md` from the stub template below.
4. Append the feature to `.scratch/BACKLOG.md` with all ranking fields set to `TBD` and
   score `?`. If `BACKLOG.md` does not exist, create it from the template in
   [LAYOUT.md](docs/LAYOUT.md).
5. Tell the user: `Created .scratch/<feature-slug>/. Run /planning:scratch-plan to set its rank.`

### PRD stub

```markdown
# PRD — <idea title>

Status: needs-triage

## Problem Statement

_Fill in._

## Solution

_Fill in._

## Further Notes

_Created by /planning:scratch._
```

## Mode B — List backlog  (no arguments)

When `$ARGUMENTS` is empty, read `.scratch/BACKLOG.md` and display it. If it does not exist,
say so and suggest running with an argument to capture the first feature.

## Layout and ranking conventions

See [LAYOUT.md](docs/LAYOUT.md) — the canonical `.scratch/` folder layout. Reference this from
other skills; do not restate the conventions inline.

See [RANKING.md](docs/RANKING.md) — the score formula and tiebreaker rules.
