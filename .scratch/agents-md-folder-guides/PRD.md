# PRD — Add AGENTS.md folder guides across significant subtrees

Status: needs-triage

Quick capture — iron out in scratch-planning, don't action yet.

## Problem Statement

Place an `AGENTS.md` file in each significant folder that explains what that folder subtree is about —
its purpose, what lives there, and conventions an agent should know before working in it. Goal: an
agent (or human) landing in a subtree gets oriented from the local file instead of re-deriving context
from the whole repo each run.

## First task (the gate before building anything)

Analyse the hypothesis: **"AGENTS.md files per significant folder make it easier to navigate the repo
in a future run."** Don't assume it's true — test it.

- Define "easier to navigate" in measurable terms (fewer files opened to orient? faster to locate the
  right subtree? fewer wrong turns?).
- Consider the counter-case: maintenance cost, staleness/drift risk (guides that lie are worse than
  none), duplication with CLAUDE.md / existing READMEs / [[gated-work-prd-issue-approval]] docs, and
  context-budget cost of agents reading many small files.
- Decide whether the payoff justifies the upkeep before generating any AGENTS.md files. If the
  hypothesis doesn't hold, this scratch is `wontfix`.

## Notes / open questions (for triage, not to action now)

- What counts as "significant"? Threshold by depth, file count, or role (e.g. `skills/`, `shared/`,
  `.claude/`, `src/`, `docs/`) — not every leaf folder.
- `AGENTS.md` as the chosen filename (cross-tool convention) vs. reusing the repo's existing
  README/CLAUDE.md pattern — pick one and be consistent.
- Generation + freshness: one-time hand-write, or a generator/hook that flags drift when a subtree
  changes? Overlap with the auto-sync hooks already in the repo.

_Solution: Fill in (gated on the hypothesis analysis above)._
