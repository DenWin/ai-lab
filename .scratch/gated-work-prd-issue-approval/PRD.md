# PRD — Gate all work behind a human-approved PRD + issues, branch-per-issue PR flow

Status: needs-triage

Quick capture — needs more refinement (user flagged). Iron out in scratch-planning, don't action yet.

## Problem Statement

Enforce that **nothing gets worked on** until a scratch exists with a PRD and broken-down issues, and
those have been **explicitly approved by a human** before any implementation begins. Add a
branch-per-issue + PR review step so the human reviews code as a PR before it merges to `main`.

## Intended workflow (rough, not final)

1. Idea → scratch with `PRD.md` (problem/solution) + `issues/NN-*.md` (per the existing `.scratch`
   layout and `/planning:to-issues`).
2. **Human gate:** a human reviews the PRD and issues and sets an explicit approval state (e.g.
   `human-approved`) — distinct from the current `needs-triage` / `ready-for-human` /
   `ready-for-agent` states. Only `human-approved` items may be worked on.
3. Per approved issue/feature: create a **dedicated branch**, do the work there, **push to remote**,
   open a **PR** so the human reviews the diff before it merges into `main`.

## Refinement questions (for scratch-planning — do NOT resolve now)

- Approval state: reuse/rename an existing status (`ready-for-agent`?) or add a new `human-approved`?
  At PRD level, issue level, or both? Does an agent need every child issue approved, or just the PRD?
- Enforcement mechanism: convention only, a pre-work checklist in the relevant skills, or a hard
  **hook** (PreToolUse on Edit/Write) that blocks edits when no approved work item covers them? How
  would a hook know which issue an edit belongs to?
- Granularity of branch-per-issue vs branch-per-feature; naming convention; who opens the PR (agent
  vs human); whether agents may push to remote at all under git-guardrails.
- Interaction with [[capture-not-execute]] and the planning defaults already being captured in
  `claude-md-planning-defaults` — this is the "execute" side of the same gate.
- The **content** of what "approved" checks against is `[[backlog-enhancements]]` concept 8's
  Definition of Ready — this scratch owns *who* approves and the branch/PR flow after, not the
  checklist itself.

## Acceptance (rough)

- A documented, enforceable rule set for the gate, plus a decision on hard vs soft enforcement.

*Solution: Fill in.*
