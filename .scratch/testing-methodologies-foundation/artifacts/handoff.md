# Handoff — Testing Methodologies Foundation: What's Missing

**Next session focus:** complete the deferred scope additions to
`testing-methodologies-foundation.adoc` and finish the unfinished `/grill-me`
pass. This doc lists only what is _not yet done_ plus the state/conventions a
cold agent needs. It does not restate the document's content.

## Files / state

- **Working copy (latest):** `/home/claude/testing-methodologies-foundation.adoc`
  — 1623 lines. Also copied to `/mnt/user-data/outputs/`.
- **Read-only source:** `/mnt/project/testing-methodologies-foundation.adoc`
  (user saves the working copy back here themselves).
- **Skill package:** `tdd.zip` (built earlier, in outputs). **Stale** — see
  "Skill drift" below. Skill source-of-truth is the document's §11.
- Edits are made with `str_replace` on the working copy, then copied to outputs
  and presented.

## Missing / deferred work (the actual task)

All four were confirmed in a grilling session but **not executed**. Placements
are recommendations; confirm with user before building.

1. **Test-data construction patterns** — builders, object-mother, factories.
   New cross-cutting subsection. Recommended home: §7 Cross-Cutting Principles
   (applies across all methodologies). Gap today: the doc says "no fixture
   sprawl" but never shows how to build test data cleanly.

2. **Concurrency / non-determinism testing** — _bounded_. Name it, give the one
   principle (make the non-determinism injectable: clock, scheduler, seed),
   explicitly scope it as its own field rather than teaching it. Recommended
   home: §7, extending the existing "Isolate the Variable" clock/randomness/IDs
   bullet. Half a subsection, not a chapter.

3. **Observability / testing-in-production** — _brief note only_, ~3–4
   sentences. NOT a full treatment (that would pull the doc toward SRE/ops and
   dilute the thesis). Recommended home: §6 Companion Methodologies, in/after
   "Integration and End-to-End Testing." Name the relation and cross-reference
   the existing integration-vs-operational-check distinction (in the
   notification example, §3.5.1 "Mocking Third-Party Libraries Directly"). User
   proposed this framing and it is the agreed approach.

4. **Bash stack section** — user writes tested Bash (bats-core etc.). New §9
   subsection (stack order today: PowerShell, SQL, Python, C# — Bash could sit
   after PowerShell as a shell sibling or at the end). **Knock-on:** also add a
   matching ` ```stacks/bash.md``` ` block in §11's "The Operating Rules," and a
   `stacks/bash.md` file in the skill, to keep the single-source mapping intact.

**Sync knock-on for 1 & 2:** if they become cross-cutting principles, the §11 AI
rules should get a corresponding bullet each (e.g. "prefer builders over inline
fixture construction"; "make non-determinism injectable — clock, scheduler,
seed") so the rules stay in sync with the body.

## Unfinished /grill-me pass

Resolved already (do not relitigate):

- **Purpose = A**: practitioner reference + skeptic-defense + AI-skill source.
  Primary reader is an experienced practitioner.
- **Dimension 6 (beginner accessibility) removed from the rubric** — not a goal.
  Beginner-onramp work is declined, not deferred. A teaching version, if ever
  needed, gets generated _from_ this document later.
- **Detail calibration (dim 3)** — the TDD-depth vs companion-thinness imbalance
  is **deliberately declined** under purpose A (depth where the hard parts are
  is correct for this reader). Not a defect; do not "fix" it.

Still to walk (tree stopped mid-way):

- **AI-block length (dim 12)** — total rule length risk; the multi-file split
  helps (load only what's needed) but per-deployment length is unaddressed.
- **Hidden-gap pass** on the currently-maxed dimensions (4 claim validity,
  5 breadth, 9 consistency, 10 neutrality, 11 self-containment) — probe for
  weaknesses the 5/5 scores might be hiding.

## Current rubric snapshot (post last session)

12 dimensions, 1–5. Aggregate ~4.6/5. Sub-5 remaining: dim 1 coverage (4 — the
items above close most of it), dim 3 (3 — declined), dim 12 (4). Dim 6 retired.
Dims 4, 5, 8, 10 reached 5 last session via the "Answering the Skeptic" section
and softened benefit claims.

## Skill drift (decide / fix)

- The skill's `behaviors.md` is **missing the "don't overclaim TDD empirically"
  rule** that was added to §11 after the skill was built. Regenerate from §11.
- Adding the Bash stack (#4) means the skill needs `stacks/bash.md`.
- `design-for-testability.md` is the **one skill file not derived from the
  document** (adapted from an external skill; covers interface design, which the
  doc scopes out). Open decision: keep skill-only (recommended) or fold a
  treatment into the doc so the doc fully owns the skill.

## Conventions (so they aren't reinvented)

- AsciiDoc. Em-dashes (—) and arrows (→) are literal UTF-8 — match exactly in
  `str_replace` `old_str`.
- Cross-refs: `<<anchor,text>>` with `[[anchor]]` targets. Currently 17 anchors,
  all resolve; 8 are `pitfall-*`. Adding sections that are referenced needs
  explicit `[[anchor]]` lines (AsciiDoc auto-IDs won't match custom names).
- Headings: stack subsections at **H4** (`====`), shown in TOC (depth 3).
  Pitfall examples and Triangulation movements at **H5** (`=====`), excluded
  from TOC. Principle: section-sized chunk → heading; short parallel parts →
  bold/labeled lead-in, not a heading.
- Tables: per-sentence hard breaks (` +`) in multi-sentence prose cells.
  Glossary and Given/When/Then tables are the deliberate exceptions.
- Claims: mechanism-not-metric; no unbacked empirical claims; attributions are
  verified (Beck, North, Dinwiddie "popularised by", Cohn, Dodds, Meszaros 2007,
  Feathers 2004, Cockburn).
- "Answering the Skeptic" pattern: steelman → "What's true" → "The answer", with
  a "What Survives" close. Reuse this structure for any new contested material.
- **Single source of truth:** §11 is canonical for the AI rules; the skill is
  regenerated from it, never edited directly.

## Suggested skills

- **grill-me** — to resume the unfinished grilling (dim 12 + hidden-gap pass).
- **write-a-skill** — when regenerating/updating `tdd.zip` after doc changes
  (the missing behaviors rule + new `stacks/bash.md`).
- No skill needed for the AsciiDoc edits themselves — plain file editing.
- `docx`/`pdf` only if the user asks to export (AsciiDoc→PDF normally via
  asciidoctor-pdf, not the pdf skill).
- video-distillation-skill — not relevant unless new transcripts arrive.
