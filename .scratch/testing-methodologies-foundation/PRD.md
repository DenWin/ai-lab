# PRD — Testing Methodologies Foundation: finish the doc & wire it to the tdd skill

Status: needs-triage

Complete the deferred scope additions to the testing-methodologies foundation document,
finish the unfinished `/grill-me` pass, relocate the doc into the repo at
[docs/testing-methodologies-foundation.adoc](../../docs/testing-methodologies-foundation.adoc),
and reference it from the `tdd` skill. Captured from a session handoff
([artifacts/handoff.md](artifacts/handoff.md)).

## Problem Statement

The foundation document (`docs/testing-methodologies-foundation.adoc`, 1622 lines — formerly
`.temp/TDD.adoc`) is the single source of truth for the `tdd` skill: §11 is canonical and the skill
is regenerated from it. Three things are open:

1. **Doc content is incomplete.** Four confirmed-but-unexecuted additions remain, plus the skill has
   drifted from §11.
2. **The `/grill-me` review stopped mid-tree.** Two rubric dimensions are unresolved.
3. **The doc and skill aren't linked.** The doc now lives in `docs/`, but nothing in the `tdd` skill
   points a reader at it as the authoritative source.

This PRD captures *only what is not yet done* — it does not restate the document's content. The
handoff ([artifacts/handoff.md](artifacts/handoff.md)) is the detailed reference for placements and conventions.

## Solution

Three workstreams, roughly in order:

### A. Finish the document

Four deferred additions (placements are recommendations — confirm before building):

1. **Test-data construction patterns** (builders, object-mother, factories) — new cross-cutting
   subsection in §7. Closes the "no fixture sprawl" gap (stated but never shown how).
2. **Concurrency / non-determinism testing — bounded.** One principle (make non-determinism
   injectable: clock, scheduler, seed), scoped as its own field, not taught. Extend §7's
   "Isolate the Variable" bullet. Half a subsection.
3. **Observability / testing-in-production — brief note only** (~3–4 sentences). NOT a full
   treatment (would pull toward SRE/ops and dilute the thesis). §6, after "Integration and
   End-to-End Testing"; cross-ref the integration-vs-operational-check distinction (§3.5.1).
4. **Bash stack section** (bats-core etc.) — new §9 subsection. **Knock-on:** add a matching
   ` ```stacks/bash.md``` ` block in §11 and a `stacks/bash.md` file in the skill.

**Sync knock-on for 1 & 2:** if they become cross-cutting principles, add a corresponding §11 AI
rule each ("prefer builders over inline fixture construction"; "make non-determinism injectable").

### B. Finish the `/grill-me` pass

Resolved already — **do not relitigate:** purpose = practitioner reference + skeptic-defense +
AI-skill source (reader = experienced practitioner); beginner-accessibility removed from the rubric
(declined, not deferred); TDD-depth vs companion-thinness imbalance deliberately declined under that
purpose.

> **[RE-CONFIRM]** These three were resolved in a prior (chat) session. Confirm they still reflect
> your intent before resuming the grill — "resolved then" is not "frozen now".

Still to walk:

- **AI-block length (dim 12)** — per-deployment rule length is unaddressed (the multi-file split
  helps loading, not length).
- **Hidden-gap pass** on the currently-maxed dimensions (4 claim validity, 5 breadth, 9 consistency,
  10 neutrality, 11 self-containment) — probe for weaknesses the 5/5 scores might hide.

### C. Wire doc ↔ skill

- The doc's home is now `docs/testing-methodologies-foundation.adoc` (relocated from `.temp/TDD.adoc`).
- Add a reference from the `tdd` skill (`skills/coding/tdd/SKILL.md`) to the doc **as a git-repo
  reference** (repo-relative path / git URL), establishing it as the skill's source-of-truth document.
- **Unblocked 2026-07-04:** `git init` was done 2026-06-04 and the repo is published
  (`github.com/DenWin/ai-lab`), so a git-repo reference can now be authored — see
  [issues/01-reference-doc-from-tdd-skill.md](issues/01-reference-doc-from-tdd-skill.md).
  (The earlier blocker pointed at `init-git-repo`, which was folded into
  repo-scaffold, now done and removed from `.scratch/`.) Still gated on **Open Decision 3** below
  (doc home: this repo vs its own repo) per the issue's own note — settle before authoring the link.
- Once the doc changes in (A) land, **regenerate the skill from §11** (it is canonical; the skill is
  never edited directly). Known drift to fix on regen: `behaviors.md` is missing the
  "don't overclaim TDD empirically" rule; add `stacks/bash.md`.

## Open Decisions

1. **`design-for-testability.md`** is the one skill file *not* derived from the document (adapted from
   an external skill; covers interface design, which the doc scopes out). Keep skill-only
   (recommended) or fold a treatment into the doc so the doc fully owns the skill?
2. **Bash stack placement** in §9 — after PowerShell (shell sibling) or at the end of the stack list?
3. **Doc home — repo vs separate repo.** Parked in `docs/` for now; may move to its own repo later.
   If it does, the skill reference (C) must point at that repo instead. Decide before authoring the
   reference so it isn't rewritten twice.

## Conventions (from the handoff — so they aren't reinvented)

- **AsciiDoc.** Em-dashes (—) and arrows (→) are literal UTF-8; match exactly in any `str_replace`.
- **Cross-refs:** `<<anchor,text>>` with explicit `[[anchor]]` targets (AsciiDoc auto-IDs won't match
  custom names). 17 anchors today, all resolve; 8 are `pitfall-*`.
- **Headings:** stack subsections H4 (`====`, in TOC depth 3); pitfall examples & triangulation
  movements H5 (`=====`, excluded from TOC). Section-sized chunk → heading; short parallel parts →
  bold lead-in.
- **Claims:** mechanism-not-metric; no unbacked empirical claims; attributions verified.
- **"Answering the Skeptic" pattern:** steelman → "What's true" → "The answer" → "What Survives".
  Reuse for any new contested material.
- **Single source of truth:** §11 is canonical for the AI rules; the skill is regenerated from it,
  never edited directly.

## Suggested skills (when resuming)

- `/session:grill-me` — resume the unfinished grilling (dim 12 + hidden-gap pass).
- `/session:write-a-skill` — when regenerating the skill after doc changes (missing behaviors rule +
  new `stacks/bash.md`).
- Plain file editing for the AsciiDoc edits — no skill needed.

## Further Notes

- Artefact (the doc itself): [docs/testing-methodologies-foundation.adoc](../../docs/testing-methodologies-foundation.adoc).
  Source handoff: [artifacts/handoff.md](artifacts/handoff.md).
- The handoff references an earlier `tdd.zip` skill package built in a prior (chat-based) session —
  **stale**, superseded by the repo's `skills/coding/tdd/`. Not carried over.
- Created from a handoff via `/planning:scratch`.
