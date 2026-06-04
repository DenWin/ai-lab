---
name: grill-me
description: Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree. Optionally challenges the plan against the project's existing language and drafts/revises documentation (CONTEXT.md, ADRs). Use when the user wants to stress-test a plan, get grilled on a design, says "grill me", or wants a plan checked against documented decisions and terminology.
upstream-author: mattpocock
upstream-repo: https://github.com/mattpocock/skills
upstream-path: skills/productivity/grill-me/SKILL.md
upstream-commit: aaf2453fbdfe7a15c07f11d861224f34ab4b53cb
---

<environment>

This skill runs in claude.ai (chat). There is no writable repo and no autonomous codebase access: the project filesystem cannot be edited in place, and nothing persists between conversations. Existing project files are available only when attached as Project knowledge or uploaded. Any documentation is *delivered as downloadable files* the user commits themselves — never written into their repo.

</environment>

<mode-gate>

Decide this once, at the start, before grilling — it governs the whole session:

**Docs mode is OFF by default.** Run a pure grilling session: no glossary, no CONTEXT.md, no ADRs, no documentation output. Don't mention them.

**Engage docs mode only if** either is true:
1. A `CONTEXT.md`, `CONTEXT-MAP.md`, or other project documentation is attached/uploaded, or
2. The user explicitly asks for documentation, a glossary, or ADRs, or signals it by phrasing such as "with docs", "using the docs", or "against the docs".

If a documentable decision surfaces while docs mode is off, you may make **one** brief offer ("worth capturing this as an ADR?") and then drop it unless the user says yes. Never drift into glossary/ADR behavior unprompted.

</mode-gate>

<grilling>

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

Ask the questions one at a time, waiting for feedback on each before continuing.

If a question can be answered from provided files (Project knowledge or uploads), check there first instead of asking. If the relevant code isn't provided, ask me to paste/upload it — or proceed on a stated assumption and flag it as unverified.

</grilling>

<docs-mode>

Everything below applies **only when docs mode is engaged** (see mode-gate).

## Domain awareness — three input states

At the start, determine which applies from the files I've provided:

1. **Baseline provided** — a `CONTEXT.md` (and/or `CONTEXT-MAP.md`, existing ADRs) is attached or uploaded. Read it and treat it as the authoritative baseline. Grill against its existing glossary; continue ADR numbering from the highest provided number. You revise *a copy* and hand it back — you cannot edit the original.
2. **Code/docs only** — source files but no glossary. Cross-reference claims against them; build a `CONTEXT.md` from scratch.
3. **Explicit request, nothing attached** — create a `CONTEXT.md` from scratch as terms resolve, working from my stated assumptions (flag each as unverified until I confirm).

If a `CONTEXT-MAP.md` is provided, the project has multiple contexts; infer which one the current topic belongs to, and ask if unclear. Otherwise assume a single context.

## During the session

**Challenge against the glossary.** When I use a term that conflicts with the baseline `CONTEXT.md`, call it out: "Your glossary defines 'cancellation' as X, but you seem to mean Y — which is it?"

**Sharpen fuzzy language.** When I use vague or overloaded terms, propose a precise canonical term. "You're saying 'account' — do you mean the Customer or the User?"

**Discuss concrete scenarios.** Stress-test domain relationships with specific scenarios that probe edge cases and force precision about boundaries.

**Cross-reference with provided code.** When I state how something works *and* the code is in the provided files, check whether the code agrees and surface contradictions. If the code isn't provided, don't guess — ask for it or flag the claim as unverified.

**Maintain CONTEXT.md as we go.** Keep a working copy in the session. When a term resolves, update it and re-deliver the file as a download — don't wait and dump everything at the end. `CONTEXT.md` is a glossary and nothing else: no implementation details, not a spec, not a scratch pad. Use the format in [CONTEXT-FORMAT.md](./CONTEXT-FORMAT.md).

**Offer ADRs sparingly.** Only when all three are true: (1) hard to reverse, (2) surprising without context, (3) the result of a real trade-off. If any is missing, skip it. Deliver each ADR as a `docs/adr/NNNN-slug.md` file. Use the format in [ADR-FORMAT.md](./ADR-FORMAT.md).

</docs-mode>
