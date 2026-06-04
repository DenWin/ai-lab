# Instruction-File Evaluation Metric

A rubric for reviewing instruction documents: account-wide profiles, project-instruction
fields, CLAUDE.md files, and SKILL.md files. Review-only — produces findings, never auto-applies
(profile §9). Output = a per-dimension score table + a findings table + a headline band.

---

## Core principle: Quality is not Efficacy

Two different things, measured two different ways. Do not conflate them.

- **Quality (static):** internal soundness, build, order, calibration. Readable off the page,
  repeatable, deterministic. Dimensions B/C/D/E below + A2/A3.
- **Efficacy (behavioral):** does the model actually behave as intended when this doc loads?
  *Not* readable off the page. Only a behavioral test reveals it (A1), and even then it is a
  noisy estimate, not a clean number.

A doc can be high-quality and low-efficacy: a clean, uniform, well-ordered doc whose load-bearing
word was cut still reads perfectly and silently fails. The static pass cannot catch that. Run both.

---

## Scoring shape

- **Per dimension:** `Pass` (2) / `Warn` (1) / `Fail` (0). No single averaged 0-100 — a mean hides
  the failures that matter.
- **Hard gates** (cannot be averaged away): `E1` safety, `B1` internal consistency, `A2`
  actionability below threshold. Any gate at `Fail` caps the headline at **Rework**.
- **Headline band**, derived (not averaged):
  - **Rework** — any hard gate fails.
  - **Revise** — no gate fails, but any non-gate dimension is `Fail`.
  - **Ship** — all dimensions ≥ `Warn`, majority `Pass`.
- **Findings table** is the payload; scores are the summary. Findings columns:
  `ID | location (line) | current text | issue | operation`.

---

## Dimensions

### Group A — Efficacy (does it work)

| ID | Dimension | Checks |
|----|-----------|--------|
| A1 | **Behavioral testability** | Each rule maps to an observable behavior. A test prompt can be written whose output distinguishes "rule applied" from "rule ignored." Rules that cannot be tested cannot be known to work. *(For SKILL.md: the description is the highest-leverage testable unit — does it trigger on the right prompts and not mis-fire?)* |
| A2 | **Actionability / unambiguity** *(gate)* | Specific enough to apply without interpretation. "Be helpful" fails; "lead with the direct answer, then layer" passes. State location, current state, operation. |
| A3 | **Rule-strength calibration** | Claim strength matches reality. `never`/`always` only where truly absolute; `prefer`/`default` for tendencies. Overstatement → brittle, ignored on first counterexample. Understatement → treated as optional. |

### Group B — Integrity (is it internally sound)

| ID | Dimension | Checks |
|----|-----------|--------|
| B1 | **Internal consistency** *(gate)* | No two rules contradict. No circular definition (term defined by itself, rule justified by its own conclusion). |
| B2 | **Non-redundancy (unintentional)** | No accidental duplication of a rule across sections. *Deliberate* repetition of a high-salience anchor is exempt and good — distinguish the two. |
| B3 | **Self-application** | The doc obeys its own rules. A doc that mandates surface-consistency must itself be consistent; one that bans preamble must not preamble. |
| B4 | **Coverage / gaps** | Addresses the situations it must. The inverse of B2: not too much, but too little. Name the uncovered case. |

### Group C — Structure (organized for the reader)

| ID | Dimension | Checks |
|----|-----------|--------|
| C1 | **Ordering** | Load-bearing first; dependencies before dependents; related rules adjacent. Primacy/recency-aware — start and end of context are weighted heavier by the model. |
| C2 | **Uniformity** | Consistent register, format, enumeration style, and character set throughout. |
| C3 | **Surface correctness** | Typos/grammar — scored as *correctness*, not polish: in a rulebook a wrong word changes the rule. Low weight unless a slip is load-bearing. |

### Group D — Fit (in the right place)

| ID | Dimension | Checks |
|----|-----------|--------|
| D1 | **Scope / layer fit** | Each rule lives in the correct file: domain-agnostic vs domain-bound; always-loaded vs on-demand. A domain rule in an account-wide profile fails (leak); a project rule duplicated in the profile fails. |
| D2 | **Cross-layer precedence** | Where layers overlap (profile ↔ project ↔ CLAUDE.md ↔ skill), precedence is defined or the overlap is removed. No silent double-source for one rule. |

### Group E — Safety (preserves good judgment)

| ID | Dimension | Checks |
|----|-----------|--------|
| E1 | **Non-self-harmful** *(gate)* | No instruction that degrades honesty or judgment: "never disagree," "always praise," "never question me," "always assume I'm right." These hard-fail regardless of how well-written. |

**Deliberately excluded as dimensions:** "intent presented effectively" (decomposes into A1+A2+C1); "best
practices used" (that *is* the rubric); "self-evaluation present" (an optional doc feature, not a
quality of the rules). **Token cost** is not a dimension here — see per-file-type notes.

---

## Per-file-type weighting

Same dimensions, different criticality. `crit` = gate or near-gate; `high`/`med`/`low` = weight;
`n/a` = not applicable.

| Dim | Profile (account-wide) | Project-instructions | CLAUDE.md (Claude Code) | SKILL.md |
|-----|------------------------|----------------------|-------------------------|----------|
| A1 testability | crit | crit | high | crit *(description)* |
| A2 actionability | crit | crit | crit | crit |
| A3 calibration | high | high | high | med |
| B1 consistency | crit | crit | crit | crit |
| B2 redundancy | med | med | high | med |
| B3 self-application | high | med | med | low |
| B4 coverage | med | high | high | high |
| C1 ordering | med | med | high | med |
| C2 uniformity | med | med | med | med |
| C3 surface | low | low | high *(commands/paths)* | low |
| D1 scope-fit | crit *(domain leak)* | high | high | crit *(desc vs body split)* |
| D2 precedence | high *(cross-layer)* | high | crit *(tier precedence)* | n/a |
| E1 safety | crit | crit | crit | crit |

**Per-type notes (load-bearing, read these):**

- **Profile** — loads every turn but is prefix-cached (~10% nominal cost after turn 1): ignore length,
  optimize effectiveness. Highest risks: D1 domain leak, and drift over long contexts (does it still
  hold at turn 50?).
- **Project-instructions** — the only truly project-bound layer. Highest risks: B4 coverage of the
  workflow, skill-routing correctness, D2 precedence vs the profile.
- **CLAUDE.md** — competes with code for context *and* is weighted above chat messages, so C3 matters
  most here: build/test/lint commands and paths are **facts — verify them, don't trust recall.**
  Tier precedence (enterprise/project/user/local) is a `crit` (D2).
- **SKILL.md** — only the description is always-loaded; the body loads on trigger. The description is
  the single highest-leverage check (A1/D1): vague → mis-fires; too broad → fires always. Score the
  always-loaded surface separately from the on-demand body.

---

## Process

1. **Static pass (deterministic):** score B/C/D/E + A2/A3, produce findings. This is fully off-page.
2. **Behavioral pass (optional, for A1):** derive a test matrix — one prompt per rule whose output
   separates applied-from-ignored, plus the expected behavior. Run in a *separate* session (a doc
   cannot reliably test its own efficacy in the session that authored it). Record observed vs expected.
3. **Report:** score table → findings table → headline band. Never auto-apply; the human decides.

---

## Limits

- A1 efficacy is an estimate: model nondeterminism, prompt sensitivity, and context position make any
  single behavioral result noisy. Treat A1 as directional, not exact.
- The rubric scores the *document*, not the model's general competence.
- "Best order" (C1) and "calibration" (A3) involve judgment; surface the reasoning, don't assert a
  single correct answer.
