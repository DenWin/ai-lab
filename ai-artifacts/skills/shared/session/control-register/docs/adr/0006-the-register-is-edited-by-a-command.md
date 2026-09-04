# 6. The register is edited by a command, not re-authored

## Status

Accepted

## Context

Every edit cost the old text and the new text, quoted in full, in the
conversation. Seventy of seventy-six rows were closed and held 97.5% of the
content.

The file is spliced on disk, so its size is free; what is not free is what gets
typed. An append is not a rewrite, which is why an archive can grow without
cost.

## Decision

`scripts/register.js` writes, closes, edits, blocks, promotes and archives rows.
Closed rows carry `data-closed` and are archived past the newest fifteen.

## Consequences

Every mutating command runs the checks and restores the file if they fail. The
batch-order rule left `checks.js` for the CLI, because the file cannot tell one
closing batch from three.

## Alternatives considered

Sourcing the rows from JSON, or an iframe — both fail under `file://`, and
neither changes what has to be typed.
