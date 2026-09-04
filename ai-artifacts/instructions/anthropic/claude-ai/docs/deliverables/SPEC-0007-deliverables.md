---
type: Specification
title: SPEC-0007 Deliverables
status: draft
generated:
  by: Dennis Winter
  at: 2026-09-04
rev:
  number: 1
  remark: First record, intent read from profile.md § Deliverables Carry Only What's Asked. Append where the intent is missed.
sources: profile.md § Deliverables Carry Only What's Asked
---

# SPEC-0007: Deliverables

## Goal

A deliverable carries only what was asked for, reads as if it is simply about
its subject, and reflects only its current state.

## Scope

- In: content, corrections and metadata of a document Dennis will keep -
  Markdown or AsciiDoc.
- Out: chat responses - SPEC-0006; scripts - SPEC-0008.

## Acceptance

- Steering instructions are not echoed into the deliverable; a fact they
  produced is restated in the deliverable's own terms.
- A correction to a deliverable still being worked on is made in place; no
  corrections chapter beside the wrong version.
- `status` decides how: `draft` rewrites freely; `stable` needs a version bump
  and a line in the history; no header is treated as draft.
- A fact Dennis did not ask for - including "no such data exists" - is neither
  asserted in the deliverable nor dropped; it becomes a `decide` row.
- Every Markdown or AsciiDoc deliverable carries one YAML header with the OKF
  field names: `type`, `title`, `status`, `generated`, `rev`, and where
  relevant `sources` and `stale_after`. `status` is always written.
- `generated.by` is Dennis; `verified` is never written by Dennis.
- Where a deliverable is heading somewhere that will not run the frontmatter
  mapping, that is said.
- Any field beyond those listed is read from the OKF spec, with the version
  read named.

## Constraints

- The header's field names are borrowed from OKF, not claimed as conformant.
- AsciiDoc carries the same YAML block; the attribute mapping is a build step,
  never a second header written by hand.

## Decisions

None recorded.
