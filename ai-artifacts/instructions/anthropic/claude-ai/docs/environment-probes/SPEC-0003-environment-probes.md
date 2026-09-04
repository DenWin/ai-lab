---
type: Specification
title: SPEC-0003 Environment probes
status: draft
generated:
  by: Dennis Winter
  at: 2026-09-04
rev:
  number: 1
  remark: First record, intent read from profile.md § Probe Before Asserting Environment Facts. Append where the intent is missed.
sources: profile.md § Probe Before Asserting Environment Facts
---

# SPEC-0003: Environment probes

## Goal

Code is written against what exists in Dennis's environment, never against
recall of what usually exists.

## Scope

- In: schema, column names and types, versions and editions, modules,
  cmdlets, paths, config values, existing definitions.
- Out: how a probe script is shaped - the `throwaway` skill and SPEC-0008.

## Acceptance

- No name, version, module or path is stated that was not verified this
  session.
- Where the session can read the fact, it reads it; a probe for Dennis to run
  is the fallback for what the session cannot reach.
- One probe covers every unknown of the task; not one probe per turn.
- The probe is read-only and obeys the script concerns in full.
- Probe output is neutral: labelled only where a value is not
  self-identifying, and never assuming the current context as a basis.

## Constraints

- The trigger is the act of stating, not the act of writing code: a fact
  recited in prose counts.
- Skipped only where checking is trivially reversible or Dennis already
  supplied the ground truth this session.

## Decisions

None recorded.
