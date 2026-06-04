# 07 — Dedicated `/planning:scratch` skill for the local-markdown tracker

Status: done

Built in the session following this issue being opened.

## What was built

- `skills/planning/scratch/` — quick-capture and backlog listing; `LAYOUT.md` as the canonical
  `.scratch/` convention definition; `RANKING.md` for the score formula (P × I × E with inverted
  effort; tiebreakers; escalation rule).
- `skills/planning/scratch-plan/` — structured grill-me per feature to calibrate/update rankings;
  rewrites `BACKLOG.md` in sorted order.
- `.scratch/BACKLOG.md` — the ranked index (initially TBD, pending a `/planning:scratch-plan` run).

## Decision recorded

The `.scratch/` layout is defined once in `skills/planning/scratch/LAYOUT.md`. Other skills
(`to-issues`, `to-prd`, `triage`, `check-skill-updates`) reference that file rather than restating
conventions. `docs/agents/issue-tracker.md` (from issue 02) will point at it for the local-markdown
tracker description rather than duplicating it.
