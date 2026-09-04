---
type: Decision
title: ADR-0001 One register per session
status: stable
generated:
  by: Dennis Winter
  at: 2026-09-04
rev:
  number: 1
  remark: First record. Reasoning removed from profile.md during the 2026-09 quality pass.
sources: SPEC-0001
---

# ADR-0001: One register per session

## Status

Accepted

## Context

- Specification: SPEC-0001, acceptance "two concurrent sessions cannot
  overwrite each other's rows".
- Options that fit it:
  - One shared file per repository, rows tagged by session. Costs: IDs are
    per conversation, so two sessions cannot share one numbering; a file
    rewritten in place each turn loses the other writer's rows silently.
  - One folder per session under `.temp/registers/<session>/`, the file always
    named `control-register.html`. Costs: a reader has to know the session
    token to find it.

## Decision

One folder per session. `<session>` is the first 8 characters of
`$env:CLAUDE_CODE_SESSION_ID`, or an 8-character token minted once where that
is empty. The rewrite probe runs per session, against that session's folder.

## Consequences

- A session never reads another session's rows; handoff between sessions goes
  through the handoff document, not the register.
- The folder name, not the file name, carries identity - every register is
  `control-register.html`.
