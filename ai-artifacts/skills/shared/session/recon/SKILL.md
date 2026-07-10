---
name: recon
version: 1.0.0
description: Before generating code (SQL, PowerShell, Bash, Python, or any stack) whose correctness depends on environment facts you cannot see, generate a small read-only probe script the user runs to report ground truth — schema and column names/types, server version and edition, installed modules or importable packages, available cmdlets, file paths, config values, existing object definitions. The user pastes the probe's output back, and you generate the real code against what actually exists instead of against assumptions. Use when a request targets an existing system and correctness hinges on identifiers, versions, or availability you'd otherwise guess at; when the user says "recon", "check my environment first", "confirm what you know", or "help me help you"; or any time you're about to recite a column name, version, module, or path from memory.
---

# Recon

Generating code against an existing system from memory is guessing. Column names drift, versions differ, modules aren't installed, paths move, imports aren't present. **Recon replaces the guess with a fact** via a short handshake: emit a small read-only probe, the user runs it, the real output grounds the generated code.

The probe is also a **proportionality check** — writing it forces you to name exactly which facts the code depends on. If you can't say what you'd probe for, you don't yet understand the request.

**Boundary vs. `prototype`:** prototype is throwaway code to explore a design you're *inventing* by driving it by hand. Recon is read-only introspection to *discover* facts that already exist. Inventing vs. discovering — no overlap.

## The handshake

1. **Name the dependencies.** List the exact facts the requested code hinges on — table/column names + types, version/edition, module/package availability and versions, cmdlet existence, paths, config values, existing definitions.
2. **Emit a probe** scoped to just those facts (see contract below). Show it in chat so the user can read it before running.
3. **User runs it, pastes the output block back.**
4. **Generate the real code** grounded in the reported facts. Where a reported value contradicts what you'd have assumed, say so explicitly — that contradiction is the whole reason recon exists.

## Scale the probe to the question

Recon is not "always emit a big script." Match the probe to what's actually uncertain.

- **One fact → one line.** "Which SQL Server version?" → emit `SELECT @@VERSION;`, not a sweep. A one-liner the user runs beats both guessing and a back-and-forth in chat.
- **Several interdependent facts → a surgical probe** (default). Collect exactly the named dependencies, nothing more.
- **First contact with an unknown environment → a broad baseline sweep is legitimate.** When you have no map at all, one wider probe to establish a baseline can be the right call. Treat it as a deliberate exception to "surgical," not the default — and still scope it to the domain in play (the relevant database, the relevant module set), not the whole machine.

## Probe contract

**Read-only is the high bar.** The default probe inspects structure and metadata, never the data itself — catalog/metadata views, version functions, module listings, path existence. This bar is high but **crossable when the data *is* the required fact**: distinct enum values stored in a column, an actual config-table value, row cardinality that changes the approach, the real stored format of a field. When you cross it:

- Cross only for the specific value needed, never a dump. `TOP (n)`, `DISTINCT`, `COUNT`, a single keyed lookup — not `SELECT *`.
- Mask or omit anything plausibly sensitive (PII, secrets); report shape/cardinality over raw content where shape answers the question.
- **Flag the crossing** in the probe and again at handoff: state that the probe reads data, which data, and why metadata alone was insufficient.

**Output convention** (applies to every stack):

- Collect all results into one structure; flush **once** at the end as a single block. No interleaved result output scattered through execution.
- Emit the final block as **JSON** — the consumer is the model, and exact identifiers matter. Shape: `requested fact → value`, neutral, no assumptions baked in. `null` / `"not present"` is a valid reported value, not a failure.
- Progress and diagnostics go to a separate stream (verbose/progress/stderr), never into the result block.
- **Fail fast on infrastructure failure** (can't connect, command not found, permission denied) with a message naming what was missing. "Object not found" when *checking for existence* is a result, not a failure.
- Keep it short enough to read and verify as safe before running.

## Probe self-check

A probe whose own failures are silent is worse than no probe — it grounds code in facts that were never actually collected. Two failure modes must be prevented *structurally* (by output design, not by "being careful"):

**A — a failed step vanishes.** Under `$ErrorActionPreference='Stop'` / `set -e`, a throwing step can abort before the flush, or a per-fact failure can leave its key simply absent while later facts succeed — you read the report and never notice fact 1 died. Prevent it: guard each fact probe so its failure is *recorded as a failure value*, never absent; flush the buffer in a `finally`/`trap` so a partial report always emits; include an integrity footer — `attempted` vs `captured` counts plus the names that errored. `attempted ≠ captured` means something was dropped.

**B — empty and absent collapse.** Request dataA, derive dataB from it. If dataB is empty you cannot tell "dataA had no children" from "dataA was never obtained / came back malformed." Prevent it: record dataA's own outcome — obtained? row count? — *as its own fact, before* deriving dataB. Then an empty dataB has exactly one cause.

This needs a **tri-state, not a bare `null`**: distinguish *present-with-value*, *present-but-empty* (0 rows is a real answer), *probed-but-errored*, and *not-probed*. `null` alone is overloaded.

**Before emitting the probe, verify:**

- [ ] Every named dependency has a fact key — nothing silently skipped.
- [ ] Each fact carries a status; failure is a recorded value, not an absence.
- [ ] The flush runs even if a step throws (`finally`/`trap`); a genuine precondition failure (can't connect at all) still stops hard, outside the per-fact guard.
- [ ] Dependent facts record their source's outcome; an empty derived set is attributable.
- [ ] Output is valid parseable JSON — depth sufficient (no silent truncation), quotes/newlines escaped, no BOM, no locale-formatted numbers (decimal comma breaks JSON).

**Before generating code from the pasted-back output, verify:**

- [ ] All expected keys present; `attempted == captured`; no errored fact you're about to build on.
- [ ] Values match expected shape — version matches a version pattern, counts are integers ≥ 0, expected arrays are arrays.
- [ ] A value that contradicts your assumption is surfaced; a fact that errored or is empty gets re-probed or asked about — never generate over a hole.

## Stack recipes

Per-stack probe anchors — what to query and how to emit it for SQL, PowerShell, Bash, and Python — live in [RECIPES.md](RECIPES.md). Load the one recipe for the stack in play; keep the probe as small as the question allows.

## Anti-patterns

- **Don't guess then caveat.** Emitting code with "adjust the column names if they differ" is the failure recon exists to kill. Probe first.
- **Don't over-collect.** Surgical by default; a broad sweep is a conscious baseline exception, not a habit.
- **Don't cross the data bar casually.** Metadata first; touch data only when the value itself is the fact, and flag it.
- **Don't bury the result.** One JSON block at the end; progress lives in another stream.
- **Don't continue silently on a broken probe.** Infra failure stops with a named reason; "not present" is reported, not fatal.
- **Don't probe what's already known.** If the user stated the fact, or it's visible in context, or it's stack-invariant, skip the probe and proceed.
