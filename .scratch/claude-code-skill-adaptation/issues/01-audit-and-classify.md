# 01 — Audit & classify each skill for adaptation

Status: ready-for-agent

## What to build

A short audit note (append to this file under `## Findings`) recording, per skill, what claude.ai-isms
it contains and which adaptation it needs: `$ARGUMENTS`, `!command` preprocessing,
`disable-model-invocation`, tool/file access, prose→steps. Confirm the conversational/agentic split
from the PRD against the actual bodies.

## Acceptance criteria

- [ ] Every skill under `skills/` listed with its classification (conversational / agentic)
- [ ] Per skill: concrete list of mechanics to change (or "none")
- [ ] Any additional carried-over content bugs noted (beyond the two already known)

## Blocked by

None — can start immediately.
