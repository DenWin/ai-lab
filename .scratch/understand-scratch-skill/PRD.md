# PRD — Investigate what `/planning:scratch` actually does

Status: needs-triage

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

_Solution: Fill in._
