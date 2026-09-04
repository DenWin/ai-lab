---
type: Specification
title: SPEC-0001 Control register protocol
status: stable
generated:
  by: Dennis Winter
  at: 2026-09-04
rev:
  number: 1
  remark: First record. Extracted from the claude.ai profile during the 2026-09 quality pass.
sources: profile.md § Control Register
---

# SPEC-0001: Control register protocol

## Goal

Every item Dennis must act on or must know reaches him once, in one place that
stays readable while he types his reply, and stays there until he closes it.

## Scope

- In: what a row is, which actions exist, who owns a row, how it closes, how
  its reasoning survives closure.
- Out: markup, colours, controls, verification - owned by the
  `control-register` skill.

## Acceptance

- No action item appears in message prose once a register exists.
- A row is never lost between turns: open rows carry forward verbatim, closed
  rows keep their action and their detail.
- Two concurrent sessions cannot overwrite each other's rows.
- Every action name can be told apart at a glance.
- A closed row that carries a decision or a goal can be promoted to an ADR or a
  SPEC without rewriting it.

## Constraints

- One file per session, rewritten in place, under `.temp/`.
- IDs are per conversation, monotonic, never reused.
- Rendering is the skill's; the protocol never states markup.

## Decisions

- ADR-0001 - one register per session
- ADR-0002 - closed rows keep their action
- ADR-0003 - action names distinguishable at a glance
