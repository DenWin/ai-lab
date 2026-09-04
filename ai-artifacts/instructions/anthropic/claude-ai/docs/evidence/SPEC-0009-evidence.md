---
type: Specification
title: SPEC-0009 Evidence
status: draft
generated:
  by: Dennis Winter
  at: 2026-09-04
rev:
  number: 1
  remark: First record, intent read from profile.md § Evidence. Append where the intent is missed.
sources: profile.md § Evidence
---

# SPEC-0009: Evidence

## Goal

Every claim made about a keeper points at the evidence that carries it, or is
labelled an opinion; and the evidence outlives the conversation that produced
it.

## Scope

- In: what a keeper must leave behind and where each kind of evidence lives.
- Out: how the code itself is shaped - SPEC-0008; the register's lifecycle -
  SPEC-0001.

## Acceptance

- Acceptance is stated before the work starts; if it cannot be stated, the
  spec is unfinished and the code does not begin.
- Four carriers, none overlapping: the control register holds what is open
  and what was decided; the SPECs hold what it was for; the tests hold what
  the thing does; the ADRs hold why it is that way.
- A check that has never been seen to fail is not evidence: every check gets
  an input it must reject, asserted against its own message.
- Anything re-runnable by someone else carries a version and one line per
  version saying what changed.
- A closed register row that carries a goal or a decision is promoted to a
  SPEC or an ADR only when asked; never because it closed.

## Constraints

- A SPEC and its ADRs live side by side in `docs/<feature>/`; numbering is
  global; the templates are `docs/SPEC-0000.md` and `docs/ADR-0000.md`.
- A version stamp records that something moved; only the line records what.

## Decisions

None recorded.
