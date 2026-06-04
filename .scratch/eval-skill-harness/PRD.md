# PRD — Build the evaluate-source skill + behavioral eval harness

Status: ready-for-human

All design decisions are settled (from the originating claude.ai session). Do not re-litigate.
The full handoff is in `artifacts/HANDOFF-eval-skill-harness.md`; read it before starting.

> **[RE-CONFIRM]** "Settled" here means decided in a claude.ai session before this repo reached
> its current state — not frozen forever. Before building, verify each item in `## Settled
> decisions` below still holds (esp. #4 harness language and #5 architecture). Flag any that
> circumstances have overtaken instead of inheriting it silently.
The rubric the skill applies is in `artifacts/INSTRUCTION-EVAL.md`; read that first.

## What to build

Two artifacts:

1. **`evaluate-source` skill** — reviews an instruction doc against the `INSTRUCTION-EVAL.md`
   rubric. Produces: static findings table + per-dimension score table + headline band (Ship /
   Revise / Rework) + a probe pack (`probes/<doc>.probes.json`) for the behavioral half. Review-
   only: never auto-applies findings.

2. **`eval/eval-harness.py`** — the invariant behavioral engine. Runs probe packs against the
   Anthropic API, aggregates pass-rates (N trials, no binary pass/fail), A/B diffs with-doc vs
   without-doc, serializes results (JSON + CSV), prints report. All doc-independent logic lives
   here; only the probe pack is per-doc.

## Architecture

```
artifacts/INSTRUCTION-EVAL.md       ← the rubric (already built — load it, don't rewrite it)
skills/coding/evaluate-source/      ← the skill (to build)
  SKILL.md
eval/
  eval-harness.py                   ← the invariant engine (to build)
  probes/
    <doc>.probes.json               ← per-doc probe packs (emitted by the skill, not committed here)
```

## Settled decisions (don't reopen)

> **[RE-CONFIRM]** claude.ai-origin decisions — confirm each is still valid before building on it.

1. **Scope:** instruction-doc-only (profile, project-instructions, CLAUDE.md, SKILL.md), file-type-aware
2. **Behavioral coverage:** static pass + emitted probe pack the user runs separately; skill does not self-run behavioral tests
3. **Claim-checking:** text-internal by default; `web_search` only behind an explicit flag
4. **Harness language:** Python — stdlib + `anthropic` SDK (or stdlib + `requests`)
5. **Architecture:** fixed engine + per-doc probe packs; one reusable engine, skill emits the pack

## eval-harness.py spec (invariant engine)

- API auth from env var — never hardcoded or logged
- N-trials-per-probe runner + pass-rate aggregation (not binary)
- A/B differential: same prompt with-doc vs without-doc; the delta is the efficacy measure
- Tier-1 assertion runners: regex / string / format matchers
- Results: JSON + CSV; report per-probe pass-rate, A/B delta, headline
- CLI arg handling: model, probe-pack path, N trials
- Validity guards baked in: assert rubric/expected-behavior text NOT in subject context; enforce subject ≠ evaluator

## Probe pack spec (`*.probes.json`, per-doc 15-20%)

Human-readable JSON. Per probe: natural-language prompt, rule ID from rubric, tier, assertion (Tier 1) or expected behavior (Tier 2/3), path to doc under test. Naturalistic phrasing only — no meta/test framing.

## Tiered behavioral model

| Tier | What | Grading | In suite? |
|------|------|---------|-----------|
| 1 — Regression | Surface-observable rules (preamble, banned bullets, length, ASCII vs unicode) | Deterministic assertions | Runnable |
| 2 — A/B efficacy | 3–5 load-bearing rules, with-doc vs without-doc | Diff arms | Runnable |
| 3 — Judgment | Non-surface (calibration, "did it lead with the answer") | Human / LLM-as-judge, noisy | Emitted as review matrix only — do NOT auto-grade |

## Validity protocol (bake into harness + skill output)

- Stateless or Incognito: run via API (no memory) or in-app Incognito with correct project scope
- Rubric hold-out: rubric and expected-behavior text never in subject's context
- Subject ≠ evaluator: the session producing behavior must not grade itself
- Naturalistic probes: phrase as a real user would; zero meta-framing
- A/B common-mode: identical prompt ± doc; eval-awareness cancels in the A/B delta
- N runs → pass-rate, never binary

## Code conventions (match user's profile §8)

- Minimum code; no handling for impossible scenarios
- Fail fast, meaningful messages; halt on severe errors
- Validate at entry; assert output before return
- No silent failure; no mixed stdout/stderr unless required

## Output format

Findings table: `ID | location (line) | current text | issue | operation`
Score table: per dimension, Pass/Warn/Fail
Headline: Ship / Revise / Rework
Fix proposals: `Fix: <new text>` as a suggestion only — never auto-applied

## Suggested skills to use during build

- `/session:write-a-skill` — author the evaluate-source skill with proper structure
- `/session:recon` — verify Python version, installed SDK, API access before coding
- `/session:grill-me` — optional adversarial pass on the skill design before finalizing

## Further Notes

- `INSTRUCTION-EVAL.md` belongs at `eval/INSTRUCTION-EVAL.md` in the repo (not yet placed — do it at build time)
- API key: env var only; do not log
- Residual limits (state honestly in skill output): eval-awareness reducible not removable; nondeterminism makes probes directional; drift (rule holds at turn 1, fails at turn 40) stays uncovered
