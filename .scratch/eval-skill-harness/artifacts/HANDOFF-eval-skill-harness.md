# Handoff — Build the "evaluate source" skill + behavioral eval harness

**Next session focus:** build two artifacts — (1) an instruction-doc **review skill** and (2) a
**Python eval harness** it feeds. All design decisions below are *confirmed*; don't re-litigate.
The profile-refinement work is continuing in a *separate* chat — out of scope here.

## Already built (reference, don't recreate)
| Artifact | Role | Status |
|----------|------|--------|
| `INSTRUCTION-EVAL.md` | The metric/rubric: 14 dimensions in 5 groups (A Efficacy, B Integrity, C Structure, D Fit, E Safety), Pass/Warn/Fail, hard gates, per-file-type weighting matrix, static-vs-behavioral process | **Final.** This is the skill's core — load it, don't rewrite it. |

The skill *applies* this rubric; the harness *executes* the behavioral half of it. Read it first.

## Confirmed decisions (settled — do not reopen)
1. **Skill scope:** instruction-doc-only (profile / project-instructions / CLAUDE.md / SKILL.md),
   file-type-aware. NOT general-purpose source review. (General is a later superset.)
2. **Behavioral coverage:** static rubric pass **+** an emitted, tiered test suite the user runs in a
   separate session. The skill does not self-run the behavioral tests.
3. **Claim-checking:** text-internal by default; `web_search` verification only behind an explicit
   flag (the CLAUDE.md-accuracy case is real but opt-in, to keep the static pass deterministic).
4. **Harness language:** **Python** (API client + statistical aggregation is Python's turf; chosen on
   merit, not shell preference). Dependency-light — stdlib + the `anthropic` SDK, or stdlib + `requests`.
5. **Architecture:** **fixed harness + per-doc probe packs** (the middle ground). One reusable engine;
   the skill emits only a per-doc probe pack. Each `harness + pack` run is a self-contained unit, but
   the engine is written once (fix-once-benefit-all).

## Architecture
```
INSTRUCTION-EVAL.md          # the rubric (built)
evaluate-source skill        # applies rubric -> static findings + scores; ALSO emits a probe pack
eval-harness.py              # the invariant engine (~80%): runs probes, A/B diff, assertions, report
probes/<doc>.probes.json     # per-doc (~15-20%): prompts + assertions + expected behavior + doc path
```
**Flow:** point skill at a doc → skill runs static review (findings + scores) **and** writes
`probes/<doc>.probes.json` → user runs `python eval-harness.py --probes probes/<doc>.probes.json`
in a fresh stateless session → pastes results back for the behavioral half.

## `eval-harness.py` spec (the invariant engine)
Everything doc-independent lives here:
- API call wrapper: auth from **env var, never hardcoded**; model as an arg; retry/backoff; typed error handling.
- N-trials-per-probe runner + **pass-rate** aggregation (no binary pass/fail — nondeterminism).
- **A/B differential:** run each probe twice — system prompt *with* the doc vs *without* it — and diff the arms. This is the actual efficacy measure.
- Tier-1 assertion runners: regex / string / format matchers.
- Results serialization (JSON + CSV) and the report shape (per-probe pass-rate, A/B delta, headline).
- CLI/arg handling.
- **Validity guards baked in** (see protocol below): assert the rubric / expected-behavior text is NOT present in the subject's context; enforce subject≠evaluator.

## Probe-pack spec (`*.probes.json`, the per-doc 15-20%)
Human-readable so the user can hand-edit/add probes. Per probe: the natural-language prompt, the
rule it tests (ID from the rubric), tier, the assertion (Tier 1) or expected behavior (Tier 2/3),
and the path to the doc-under-test. Naturalistic phrasing only — no meta/test framing.

## Tiered behavioral model
| Tier | What | Grading | In the suite? |
|------|------|---------|---------------|
| 1 — Regression | surface-observable rules (preamble? banned bullets? length? rule cited aloud? ASCII vs unicode) | deterministic assertions | runnable |
| 2 — A/B efficacy | the 3-5 *load-bearing* rules, **with-doc vs without-doc** | diff the two arms | runnable |
| 3 — Judgment | non-surface (calibration, "did it lead with the answer") | human / LLM-as-judge, noisy | **emitted as a review matrix only — do NOT auto-grade** |

## Validity protocol (mandatory — bake into harness + skill output)
- **Stateless or Incognito.** Run via the API (no memory) — or in-app Incognito with correct project
  scope. Never a normal chat (memory/past-chat search leaks target answers).
- **Rubric hold-out.** The rubric and expected-behavior text must never sit in the subject's context.
- **Subject ≠ evaluator.** The session producing the behavior must not grade itself; grading is the
  harness's assertions or a *separate* fresh-context judge call.
- **Naturalistic probes.** Phrase exactly as a real user would; zero meta-framing.
- **A/B common-mode.** Identical prompt, with/without doc; eval-awareness from framing cancels in the
  *difference*, so the A/B delta stays valid even under some eval-awareness.
- **N runs → pass-rate**, never binary.

## Key insights to preserve (these drove the design)
- **Quality ≠ Efficacy.** Static quality (reads well) does not imply the doc changes behavior. The
  whole behavioral half exists because a clean doc can silently fail (proof: dropping
  "actually/clearly" from a tagline broke anti-sycophancy while the doc still read perfectly).
- **With-doc-only measures the model, not the doc.** Only the with/without *differential* isolates the
  instruction's effect.
- **Identical behavior with and without the doc = the rule is redundant with model defaults = dead
  weight** (a *finding*, not a confound), even when the behavior is correct.
- **Residual limits (state honestly, don't over-trust the suite):** eval-awareness is reducible, not
  fully removable; nondeterminism makes every probe directional; probes test rules in isolation, so
  **drift** (rule holds at turn 1, fails at turn 40 in loaded context) stays uncovered.

## Output format (match the user's established convention)
Findings table columns: `ID | location (line) | current text | issue | operation`. Plus the
per-dimension score table and the headline band (Ship / Revise / Rework). **Review-only — never
auto-apply** (profile §9). "Fix: <new text>" alone is rejected as unactionable.

## Suggested skills for the build
- `write-a-skill` — to author the evaluate-source skill with proper structure/progressive disclosure.
- `recon` — if the harness needs environment facts (Python version, installed SDK, API access).
- `grill-me` — optional adversarial pass on the skill's design before finalizing.

## User context relevant to the build
- Stack: Linux, C#, MS-SQL, Python, bash/pwsh. Fluent in Python. (Harness is Python by decision #4.)
- Wants minimum code, fail-fast with meaningful messages, validate-at-entry/assert-output, no silent
  failure, match-style-when-editing (profile §8). Apply these to the harness code.

## Sensitive info
None present. The harness must read the API key from an environment variable — do not hardcode or log it.
