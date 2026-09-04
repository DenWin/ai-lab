# 5. Every check must be shown to fail

## Status

Accepted

## Context

A check with a broken selector returns an empty failure list, which reads
exactly like success. Twenty-six checks had never been seen to fail.

Mutations generated from the register under test cannot go stale the way stored
fixture files do.

## Decision

`tests/mutations.js` holds one mutation per check. A check with no mutation is
listed with the reason it has none, and the suite fails if a check appears in
neither list.

## Consequences

The first run found two checks that would not have caught what they were
written for. Seven checks are listed as unmutatable, which is a visible gap
rather than a hidden one.

## Alternatives considered

Mutation testing over `checks.js` itself — stronger, since it finds weak checks
and not only dead ones, and it costs a tool, a slow run and a score to argue
about.
