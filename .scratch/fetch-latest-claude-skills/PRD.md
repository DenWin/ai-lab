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

## Open Questions

- How are claude.ai skills distributed? (CLI sync, web download, GitHub repo, API?)
- Which local skills have claude.ai as their upstream source?
- Should updates be applied automatically or require human review?
- How does this interact with `/setup:check-skill-updates`?

## Further Notes

- Related: [import-upstream-skills](../import-upstream-skills/PRD.md) (mattpocock GitHub — different source, different process)
- Related: [check-updates-detection-scope](../check-updates-detection-scope/PRD.md)
- _Created by /planning:scratch._
