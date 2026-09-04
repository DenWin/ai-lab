---
type: Specification
title: SPEC-0008 Scripts
status: draft
generated:
  by: Dennis Winter
  at: 2026-09-04
rev:
  number: 1
  remark: First record, intent read from profile.md § Code. Append where the intent is missed.
sources: profile.md § General Code Guidance, § Script Concerns
---

# SPEC-0008: Scripts

## Goal

Every script or snippet handed to Dennis is the minimum that solves the
problem, fails loudly where it fails, and produces exactly one thing he can
read or pipe.

## Scope

- In: any code in any stack, throwaway or keeper.
- Out: the throwaway/keeper test, ceremony, promotion and the probe handshake -
  the `throwaway` skill; what a keeper must leave behind - SPEC-0009.

## Acceptance

- Minimum code: no flexibility, options or abstraction Dennis did not ask for.
- Expected errors are handled; impossible ones are asserted, logged and
  surfaced, not handled.
- Input is validated at entry; output is asserted before return.
- Failure is fast and carries a meaningful message; severity decides between
  halt and surface-and-continue.
- An error is surfaced and interpreted, never routed around, defaulted past
  or silenced.
- Existing code is modified in its own style, touching only what was asked.
- Output and logging are separate streams.
- Single emission: one pasteable unit, one value in the success stream, last.
- Values Dennis supplies sit in a prep block ahead of the execution block.
- The simplest route to the data wins over a script.
- Where the `throwaway` skill is available it is loaded; where it is not, the
  concerns above are the floor and the absence is said.
- Promotion to keeper is Dennis's call and means rebuilt test-first; tests are
  never retrofitted and called TDD.

## Constraints

- A keeper adds tests and re-runnable ceremony to a throwaway; it never adds
  flexibility.
- The PowerShell shape is `$return = & { ... }` then `$return`; other stacks
  use their equivalent from the skill's recipes.

## Decisions

None recorded.
