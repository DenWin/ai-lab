# 2. The outbox sits in the header, not over the page

## Status

Accepted

## Context

A floating outbox and an unobstructed table are in direct conflict. Reserving
its strip with a spacer balanced the two; sticking the header dissolves the
conflict instead.

Four mechanisms existed only to hold one overlap at bay: a measured spacer, a
`ResizeObserver`, a `pointer-events` rule and a breakpoint that dropped the
outbox into the flow.

## Decision

`#top` is sticky and holds the title, the outbox and the filter row. The outbox
is a flex child, not a floating layer.

## Consequences

All four mechanisms are gone rather than tuned. `#top` caps at `55vh` and
scrolls inside itself, because a fixed uncapped header leaves a narrow frame
with almost no table.

## Alternatives considered

Keeping the outbox fixed with header padding that tracks its height — the same
spacer under another name, and still wrong for one frame after a manual
resize.
