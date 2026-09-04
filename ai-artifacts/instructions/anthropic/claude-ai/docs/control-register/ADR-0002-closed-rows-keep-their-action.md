---
type: Decision
title: ADR-0002 Closed rows keep their action
status: stable
generated:
  by: Dennis Winter
  at: 2026-09-04
rev:
  number: 1
  remark: First record. Reasoning removed from profile.md during the 2026-09 quality pass.
sources: SPEC-0001
---

# ADR-0002: Closed rows keep their action

## Status

Accepted

## Context

- Specification: SPEC-0001, acceptance "closed rows keep their action and
  their detail".
- Options that fit it:
  - A closing action `done` replaces the row's action. Costs: it erases what
    the row had asked - a closed `done` no longer says whether it was a
    decision, a paste or an exec.
  - The action stays and a status mark is added: ✅ resolved, ↩️ superseded.
    Costs: the mark and the action must both be read to know the row's state.

## Decision

The action stays; closing adds a mark. A resolved decision reads `decide ✅`, a
superseded one `decide ↩️`.

One transition is not a close: `agent` → `review` when the output lands. The
row keeps its ID and changes owner, from the AI to Dennis, because the item is
unchanged and only who it waits on has moved. A `review` is never created on
its own; it is always the second phase of an `agent` row that Dennis agreed
to. Every other outcome closes the row, and anything it produces - the work an
answered `decide` creates, the reopening a rejected `review` needs - is a new
row.

| prior (action; owner; state) | event         | result (action; owner; state) | additional                            |
| ---------------------------- | ------------- | ----------------------------- | ------------------------------------- |
| `agent`; AI; open            | output lands  | `review`; human; open         | same ID; ownership shifts             |
| `review`; human; open        | resolved      | `review`; human; closed       | a new row is created from the verdict |
| `decide`; human; open        | resolved      | `decide`; human; closed       | a new row is created from the answer  |

## Consequences

- Filtering by action still finds closed rows of that action.
- A `decide` that says "an agent shall do X" closes as `decide ✅` and a new
  `agent` row carries X; the decision is not edited into the work.
