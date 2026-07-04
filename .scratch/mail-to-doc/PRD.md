# PRD — mail-to-doc

Status: needs-triage

## Problem Statement

The existing `mail-to-adoc` tool (`.temp/mail-to-adoc/mail-to-adoc.zip`) converts `.eml` files to
AsciiDoc but has several issues blocking a 1.0.0 release:

1. The HTML→AsciiDoc conversion logic is tangled with the main orchestration code, making it hard
   to test or reuse independently.
2. Only AsciiDoc output is supported; Markdown is a common request.
3. Image attachments are rendered as AsciiDoc image macros (e.g. `image::Gothar.png[]`) instead of
   links (e.g. `* link:../../Attachments/20250410_1452-Gothar.png[Gothar.png]`).
4. Tables produced by the converter contain a spurious `+` character after each row, breaking
   table rendering.

Reference: Mail "Scratch 'mail-to-adoc'" from 28.06.2026 (see `artifacts/` for the zip).

## Solution

### 1 — Split conversion logic
Extract the HTML→AsciiDoc transformation into a standalone skill or module (e.g.
`html-to-adoc`), called by the main `mail-to-doc` orchestrator. This enables independent
testing and future reuse.

### 2 — Rename & add Markdown target
Rename the skill from `mail-to-adoc` to `mail-to-doc`. Add a `--format` / `-f` flag
(`adoc` | `md`; default `adoc`) so users can select the output format.

### 3 — Fix image attachments (links only)
When an attachment is an image, render it as a link rather than an image macro.
Expected AsciiDoc: `* link:../../Attachments/<timestamp>-<name>[<name>]`
Expected Markdown: `* [<name>](../../Attachments/<timestamp>-<name>)`

### 4 — Fix table row separator
Diagnose and remove the spurious `+` appended after each table row. Likely an off-by-one
in the row-close logic of the HTML table→AsciiDoc table converter.

## Acceptance Criteria

- [ ] Sample `.eml` converts with no embedded images and clean tables (ref: mail "Scratch 'mail-to-adoc'" 28.06.2026)
- [ ] `mail-to-doc --format md` produces valid Markdown
- [ ] HTML→AsciiDoc logic lives in a separate, independently callable module/skill
- [ ] All existing conversion tests pass

## Further Notes

- Source zip: `artifacts/mail-to-adoc.zip`
- User considers this close to 1.0.0 — only targeted fixes, no scope creep.
- 2026-07-04 scratch-plan: user has **additional requirements/material not yet in the repo** —
  collect those before triage so the scope here is complete.
- 2026-07-04 scratch-plan: user classifies mail-to-doc as a **skill**, not a standalone software
  project (relevant to [[repo-scope-strays]]).
- _Created by /planning:scratch._
