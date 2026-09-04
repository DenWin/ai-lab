# 4. The verifier does not keep its own constants

## Status

Accepted

## Context

Four constants existed twice with nothing linking them. The verdict counts were
the dangerous pair: adding a button left the verifier expecting the old number,
so it blamed the register for a stale constant in itself.

The verifier already loads the page, so the real values are available for free.

## Decision

The template publishes `RANK`, `STATUS` and `VERDICTS` on `window.__cb` and
`checks.js` reads them.

## Consequences

Every generated register carries the handle, which nothing at runtime uses.
`TPL` stays duplicated deliberately — its whole job is to disagree with the
template.

## Alternatives considered

Exposing the pure functions as well, so tests could call them without loading
the page. It buys a better failure message rather than more coverage, and puts
a seam in every register whose only user is a test.
