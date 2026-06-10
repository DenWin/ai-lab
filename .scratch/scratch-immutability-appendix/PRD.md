# PRD — Capture-first by default; human-reviewed scratches are immutable (append, don't edit)

Status: needs-triage

## Problem Statement

Two related rules the user wants enforced on how the agent handles change requests:

1. **Capture-first by default.** Do **not** act upon *any* change request or prompt
   directly. Always create a scratch first, to be reviewed by a human before any work
   begins. (This is the "default to capture" stance — the soft/behavioral side of the
   hard gate in [[gated-work-prd-issue-approval]].)

2. **Human-reviewed scratches are immutable.** Once a scratch has been reviewed by a
   human, **never** modify it in place. Instead:
   - Create an **appendix** to that scratch.
   - In the appendix, record **all new information** *plus* an explicit list of **what
     would need to change in the original** scratch.
   - **Reset the status** of the scratch to something like `needs human review` so the
     human knows it has pending un-reviewed changes.

## Solution

_Fill in. Open design points to resolve in triage / scratch-planning:_

- **Trigger boundary for rule 1.** "Do not act upon *any* prompt" is absolute as written —
  needs a carve-out for trivial/read-only requests, questions, and the scratch-management
  commands themselves, or the agent can't even create the scratch it's told to create.
  Define what counts as a "change request" vs a benign request. Overlaps heavily with
  [[capture-not-execute]] and [[claude-md-planning-defaults]].
- **What marks a scratch as "human-reviewed"** (the immutability trigger)? A status value,
  a frontmatter flag, a separate marker file? Ties into the approval state question in
  [[gated-work-prd-issue-approval]].
- **Appendix mechanism & layout.** File naming/location (e.g. `APPENDIX-NN.md` inside the
  feature folder), structure (new info + proposed-changes-to-original), and how
  `.scratch` LAYOUT.md should document it.
- **Status reset value.** Exact string — reuse an existing status or add a new
  `needs-human-review` / `needs-re-review`? Must be distinct from the initial
  `needs-triage`.
- **Enforcement.** Convention/skill-instruction only, or a hard hook (PreToolUse on
  Edit/Write) that blocks in-place edits to a scratch once it's flagged human-reviewed and
  forces the appendix path? Same hard-vs-soft question as the gate scratch.

## Further Notes

- Strongly coupled to [[gated-work-prd-issue-approval]] (the human-approval gate) and
  [[capture-not-execute]] (don't execute, just record). Consider whether these should be
  consolidated into one workflow spec during scratch-planning rather than three separate
  scratches.
- _Created by /planning:scratch._
