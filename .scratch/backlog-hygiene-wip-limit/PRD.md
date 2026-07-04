# PRD — Backlog hygiene: consolidate process cluster, WIP limit, re-plan cadence

Status: needs-triage
Origin: fable (Claude Fable 5 repo review, 2026-07-04)

Quick capture — iron out in scratch-planning, don't action yet.

## Problem Statement

Capture is outpacing planning and completion. Evidence (2026-07-04): 13 of 22 scratches are
`needs-triage` with TBD ranks; `BACKLOG.md` says "Last updated: 2026-06-04" (a month stale); recent
commits are predominantly "added more scratches." Meanwhile several open scratches propose *more*
process (approval gates, immutability, funnel stages, stable IDs, recurrence) before the current
top-ranked features have shipped. Risk: the lab becomes a backlog about its own backlog.

## Solution

_Proposed — refine in triage:_

1. **Consolidate the process cluster.** [[gated-work-prd-issue-approval]],
   [[scratch-immutability-appendix]], and the capture rules in [[claude-md-planning-defaults]] are
   three views of one workflow spec — their PRDs already cross-reference each other and suggest
   consolidation. Merge into one scratch; start with **soft** enforcement (skill conventions +
   CLAUDE.md rules) and only build hard hooks (PreToolUse blocks) after the rules have proven their
   fit for solo use.
2. **WIP rule.** E.g. at most one process/meta feature `in-progress` at a time; bias toward
   finishing ranks 1–3 before capturing further process features.
3. **Re-plan trigger.** Run `/planning:scratch-plan` on a defined trigger — `needs-triage > 5`, or
   monthly — instead of ad hoc. Candidate first use case for the recurrence concept in
   [[backlog-enhancements]].

## Further Notes

- This scratch is itself meta — apply the WIP rule to it too: it should ride along with the next
  scratch-plan sweep, not become a build project.
- _Created by Claude Fable 5 via /planning:scratch._
