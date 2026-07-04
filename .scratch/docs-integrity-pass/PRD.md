# PRD — Docs integrity pass: fix drift, de-duplicate facts, add decay contract

Status: needs-triage
Origin: fable (Claude Fable 5 repo review, 2026-07-04)

Quick capture — iron out in scratch-planning, don't action yet.

## Problem Statement

Facts are stated in more than one place and have started to drift. Concrete instances found in the
2026-07-04 review:

1. [shared/skills/README.md](../../shared/skills/README.md) — group table lists only
   `coding`/`session`/`setup` (missing `planning`), and body text still says `skills/<group>/…`
   paths (actual: `shared/skills/`).
2. [testing-methodologies-foundation/PRD.md](../testing-methodologies-foundation/PRD.md) — still says
   "**Blocked:** this repo is not yet a git repository"; `git init` was done 2026-06-04 per
   [repo-scaffold](../repo-scaffold/PRD.md). The blocker is stale and the issue it points at is
   unblocked.
3. "Not the same file (common confusion)" exists near-verbatim in both
   [instructions/README.md](../../instructions/README.md) and
   [docs/repo-layout.adoc](../../docs/repo-layout.adoc) — two owners for one fact.
4. [docs/harnesses/claude-code.md](../../docs/harnesses/claude-code.md) lacks the per-section
   confidence table and validation smoke tests that [copilot.md](../../docs/harnesses/copilot.md)
   has; harness docs carry a single "verified 2026-06" stamp with no re-verification trigger,
   although they describe fast-moving products.

## Solution

_Proposed — refine in triage:_

- Single-owner rule: each fact has one canonical location; other files link instead of restating
  (e.g. repo-layout.adoc owns "Not the same file"; instructions/README links to it).
- Fix the four listed drift instances.
- Add a "decay contract" to harness docs: per-section confidence + verified date (copilot.md
  pattern), and a defined re-verify trigger (recurring scratch per [[backlog-enhancements]]
  concept 2, or "re-verify on major product release").
- Note: correcting item 2 edits a human-reviewed scratch — touches the
  [[scratch-immutability-appendix]] question; decide whether it's an in-place fix or an appendix.

## Further Notes

- The duplication cost is exactly what [[backlog-enhancements]] concept 1 (frontmatter → generated
  BACKLOG) eliminates for status fields; this scratch covers the prose-facts side.
- _Created by Claude Fable 5 via /planning:scratch._
