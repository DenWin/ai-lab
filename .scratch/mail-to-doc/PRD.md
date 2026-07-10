# PRD — mail-to-doc

Status: in-progress (issue 01 markers landed 2026-07-05; issues 02/03 pending)

## Problem Statement

The existing `mail-to-adoc` tool — now a first-class skill at
[`ai-artifacts/skills/shared/documents/mail-to-adoc/`](../../ai-artifacts/skills/shared/documents/mail-to-adoc/) — converts
`.eml` files to AsciiDoc but has several issues blocking a 1.0.0 release:

1. The HTML→AsciiDoc conversion logic is tangled with the main orchestration code, making it hard
   to test or reuse independently.
2. Only AsciiDoc output is supported; Markdown is a common request.
3. Image attachments are rendered as AsciiDoc image macros (e.g. `image::Gothar.png[]`) instead of
   links (e.g. `* link:../../Attachments/20250410_1452-Gothar.png[Gothar.png]`).
4. Tables produced by the converter contain a spurious `+` character after each row, breaking
   table rendering.

Reference: Mail "Scratch 'mail-to-adoc'" from 28.06.2026 (see `artifacts/` for the zip).

**Reconciliation against the 2026-07-05 drop (issue 01):**

1. Tangled HTML→AsciiDoc logic — **still present** (one monolithic `scripts/mail_to_adoc.py`
   with the HTML parser embedded). Target for the split in issue 03.
2. adoc-only output — **still present** (no `--format md`).
3. Image attachments as macros not links — **still present** (`scripts/mail_to_adoc.py:762`
   emits `image::…`).
4. Spurious `+` after table rows — **appears fixed** in this drop: the table converter
   (`handle_endtag`, ~`scripts/mail_to_adoc.py:204-212`) emits clean `|cell` rows with no trailing
   `+`. Confirm with a real table `.eml` in issue 02.

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

## Issues

- [01 — Incorporate latest changes](issues/01-incorporate-latest-changes.md)
- [02 — Analyse effectiveness](issues/02-analyse-effectiveness.md) (blocked by 01)
- [03 — Propose improvements](issues/03-propose-improvements.md) (blocked by 02)

## Further Notes

- **The deliverable lives outside the scratch (2026-07-05).** A scratch holds the *idea*; a working
  skill is a *deliverable* and belongs in the repo's skills tree. The tool was promoted from
  `artifacts/mail-to-adoc/` to the first-class skill
  [`ai-artifacts/skills/shared/documents/mail-to-adoc/`](../../ai-artifacts/skills/shared/documents/mail-to-adoc/) (new
  `documents` group — no existing group fits document conversion). This scratch keeps only the
  idea + tracking; it no longer carries the code. Note: the skill's `_PROJECT_ROOT` assumes a
  `<root>/skills/<name>/` layout, so the extra `documents/` level shifts it in-repo — irrelevant here
  (it's a redacted reference; the user runs their real copy elsewhere), but flag for issue 02.
- Source drops: `.temp/mail-to-adoc-2026-06-28.zip` (prior) and
  `.temp/mail-to-adoc-2026-07-05.zip` (latest) — **gitignored local backups**, not in git.
  The latest drop's working copy is now the `documents/mail-to-adoc` skill, **redacted for the public
  repo**: real emails/party names replaced with placeholders (`owner@example.com`,
  `PartyA`/`PartyB`, `FamilyMember`); real values only in the `.temp/` originals.
  Note: the unredacted 2026-06-28 zip is still in public git history from an earlier
  commit — purging it needs a history rewrite (candidate for [[public-repo-compliance]]).
- User considers this close to 1.0.0 — only targeted fixes, no scope creep.
- 2026-07-04 scratch-plan: user has **additional requirements/material not yet in the repo** —
  collect those before triage so the scope here is complete.
- 2026-07-05: latest drop received and extracted; the missing material is now in the repo.
  New requirement: replace emoji filename markers (`✉`, `✎𓂃`, `📎`) with `[TO]`, `[FROM]`,
  `[CC]`, `[+]` at the **end** of the filename — verified not yet implemented in this drop
  (see issue 01). User is also considering splitting into `mail-to-doc` (md + adoc) and a
  decoupled `html-to-adoc`/`html-to-md` skill — extends Solution #1 (see issue 03).
- 2026-07-04 scratch-plan: user classifies mail-to-doc as a **skill**, not a standalone software
  project (relevant to [[repo-scope-strays]]).
- **2026-07-05 (issue 01 work):** emoji filename markers replaced with bracket tags
  (`[TO]`/`[FROM]`/`[CC]`/`[+]`, tags at end, `[CC]` appended alongside `[FROM]` when Dennis was
  only Cc'd). Implemented in `scripts/mail_to_adoc.py` (`_direction_tag` + new `_dennis_in` /
  `_meta_field` helpers + call-site wiring); unit-tested and verified end-to-end on a real Cc'd
  `.eml`. **Drop observation for issue 02:** the drop's own test suite arrived **stale** (4/6 red) —
  two path tests asserted the old `docs/` layout (fixed to `01_Korrespondenz/Attachments/`), and two
  referenced removed functions (`_add_hardbreaks_to_reply_headers`, `_auto_name`) now skipped pending
  a delete-vs-restore call. The zip-to-zip diff (`.temp/` originals) still needs the workstation.
- *Created by /planning:scratch.*
