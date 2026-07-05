# PRD — Fetch Latest claude.ai Skills

Status: needs-triage

## Problem Statement

The skills in this repo that originate from the claude.ai skill distribution channel can drift
out of date. There is currently no process to pull down the latest versions from claude.ai and
integrate them.

This is distinct from the mattpocock upstream import (`import-upstream-skills`) — that is a
one-time structured import from a known GitHub repo snapshot. This entry covers the ongoing
process of staying current with whatever claude.ai publishes.

## Solution

_Fill in — identify the claude.ai skill source (URL, API, CLI mechanism), define the fetch
process, determine how to diff against local versions, and decide the integration/review step._

**Reuse the generic import skill for the integration step.** The "place it in the repo as a
first-class, grouped, provenance-tracked skill and adapt it" half is already solved by
[`/setup:import-upstream-skill`](../../shared/skills/setup/import-upstream-skill/SKILL.md) (delivered
by `import-upstream-skills`). This scratch only needs to solve the **claude.ai-specific source half** —
how to *discover and fetch* the latest versions — then hand each fetched skill to
`/setup:import-upstream-skill` for placement, `upstream-*` provenance, and the capability-contract
adaptation. Don't reinvent the import mechanics.

## Open Questions

- How are claude.ai skills distributed? (CLI sync, web download, GitHub repo, API?)
- Which local skills have claude.ai as their upstream source?
- Should updates be applied automatically or require human review?
- How does this interact with `/setup:check-skill-updates` and `/setup:import-upstream-skill`?
  (Working split: `check-skill-updates` *detects* staleness and files a work item;
  `import-upstream-skill` *performs* the import/adaptation; this scratch supplies the claude.ai
  *fetch/source* mechanism the other two don't cover.)

## Further Notes

- Related: [import-upstream-skills](../import-upstream-skills/PRD.md) (mattpocock GitHub — different *source*, but its `/setup:import-upstream-skill` is the shared *integration* step to reuse)
- Related: [check-updates-detection-scope](../check-updates-detection-scope/PRD.md)
- _Created by /planning:scratch._
