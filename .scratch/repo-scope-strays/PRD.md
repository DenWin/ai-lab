# PRD — Declare repo scope: home for stray non-lab projects

Status: needs-triage
Origin: fable (Claude Fable 5 repo review, 2026-07-04)

Quick capture — iron out in scratch-planning, don't action yet.

## Problem Statement

The repo's declared identity (AI-configuration lab: skills, harness docs, instructions, tracker) is
being diluted by undeclared strays:

- `VSCode_Extsion/` (note the folder-name typo — "Extsion") — a shipped VS Code extension at repo
  root, unrelated to the lab's stated purpose, with no README tying it in.
- [mail-to-doc](../mail-to-doc/PRD.md) — a general software project (eml→AsciiDoc converter) riding
  in the `.scratch` tracker.

Neither is wrong; the problem is the scope widening is silent. An agent (or future you) orienting
from [docs/repo-layout.adoc](../../docs/repo-layout.adoc) finds top-level content the layout doc
doesn't account for.

## Solution

_Proposed — refine in triage. Two clean options:_

1. **Declare incubation:** "the lab also incubates small tools" — give them a home
   (e.g. `tools/` or `projects/`), fix the folder-name typo, add a README per tool, and record the
   scope decision in repo-layout.adoc (and AGENTS.md once it exists).
2. **Evict:** move the extension (and eventually mail-to-doc's implementation) to their own repos;
   `.scratch` keeps only lab-related work.

Either answer is fine — the undeclared middle isn't. Renaming/moving the extension folder must use
`git mv` (see [[claude-md-planning-defaults]]).

## Further Notes

- Touches the repo-layout doc owned by [[repo-scaffold]]; coordinate if both are in flight.
- _Created by Claude Fable 5 via /planning:scratch._
