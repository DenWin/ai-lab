---
type: Decision
title: ADR-0003 Action names distinguishable at a glance
status: stable
generated:
  by: Dennis Winter
  at: 2026-09-04
rev:
  number: 1
  remark: First record. Reasoning removed from profile.md during the 2026-09 quality pass.
sources: SPEC-0001
---

# ADR-0003: Action names distinguishable at a glance

## Status

Accepted

## Context

- Specification: SPEC-0001, acceptance "every action name can be told apart at
  a glance".
- Options that fit it:
  - Any set of distinct strings. Costs: `act` and `ack` are distinct strings,
    differ by one letter, and one of them means the absence of action.
  - Names that differ in shape, not only in spelling. Costs: a candidate name
    can be rejected for looking like an existing one.

## Decision

Names must differ in shape. The set is `decide`, `paste`, `exec`, `agent`,
`review`, `ack`; the pair `act`/`ack` is the example that rules a candidate out.

## Consequences

- This constrains the `control-register` skill's action set: adding an action
  is checked against this record before the skill's five edits are made.
- Colour never carries the distinction alone; the text label always stays.
