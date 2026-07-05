# 03 — Propose improvements (incl. skill split decision)

Status: needs-triage

## What to build

An improvement proposal based on the findings of issue 02. Must explicitly evaluate
the split the user is considering:

- **`mail-to-doc`** — mail parsing, metadata, attachments, filename tagging;
  emits **both** Markdown and AsciiDoc (`--format md|adoc`).
- **`html-to-adoc` / `html-to-md`** — standalone HTML→document conversion,
  decoupled so it can be tested and reused independently (one skill with two
  targets, or two skills — recommend one).

This extends PRD.md Solution #1 (which only extracts `html-to-adoc` as a module):
the new idea is full decoupling into separate skills, plus a Markdown target for
the HTML converter itself.

Also propose fixes/priorities for whatever issue 02 finds (defects, test gaps,
hardcoded personal data, ergonomics).

## Acceptance criteria

- [ ] Recommendation on the split: one skill vs two vs keep module-only extraction, with rationale
- [ ] Proposed skill boundaries: what lives in `mail-to-doc`, what in the HTML converter(s), how they call each other
- [ ] Prioritised improvement list from the 02 findings
- [ ] PRD.md Solution section updated (or superseded) once the user picks a direction

## Blocked by

- [02-analyse-effectiveness](02-analyse-effectiveness.md) — proposals need the analysis as evidence.
