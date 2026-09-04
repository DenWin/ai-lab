# 1. The name of the artefact

## Status

Accepted

## Context

Three names were in circulation for one thing: the skill was `control-block`,
the file was `action-register.html`, the heading said Action Register, and the
instructions used both. One of the five row kinds is evidence rather than an
action, so `action` did not cover it either.

`block` was already an epic and already a wait state. `panel` was already the
outbox, and collides with a product this page visually resembles. `register` is
the only candidate that says the file is a record, which is what the ID,
supersede and prune rules are built on.

## Decision

It is a control register. Not panel, not block, not action.

## Consequences

The word `panel` had to be freed inside the skill: the outbox was called "the
panel" in twelve places and is now called the outbox. Every earlier bundle name
is dead, and registers generated before 2.19.0 carry a heading that no longer
matches the skill.

## Alternatives considered

`docket` — precise and unclaimed, but uncommon enough to need explaining.
`action register` — "action" does not cover an `ack`.
`control panel` — recognisable, and confused with a product this resembles.
