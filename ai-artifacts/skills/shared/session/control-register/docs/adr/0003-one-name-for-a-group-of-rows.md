# 3. One name for a group of rows

## Status

Accepted

## Context

The concept answered to four names at once: epic in the markup, block in the
description, segment in the script, group in the `g-` prefixes. Reading the
script meant holding all four and knowing they were one thing.

`block` collides with `blocked`. `phase` implies an order the rows do not have.
`segment` and `group` are true of anything.

## Decision

It is an epic: `epics`, `epic.entries`, `epic.collapsed`, `epicIsAllClosed()`.

## Consequences

`epic` carries a hint of size from agile that it does not mean here. The CSS
hooks `epichead`, `gcount` and `gtoggle` keep their old names in the markup.

## Alternatives considered

`group` — neutral and unclaimed, and it would have made the `g-` prefixes
correct instead of orphaned.
