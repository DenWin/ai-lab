# Probes

A probe is a throwaway script that **discovers facts that already exist** -
schema and column names, version and edition, module availability, cmdlets,
paths, config values, existing definitions. Generating code against an existing
system from memory is guessing; the probe replaces the guess with a fact.

Writing it is also a proportionality check: if you cannot say what you would
probe for, you do not yet understand the request.

**Boundary vs. `prototype`:** prototype is throwaway code exploring a design you
are *inventing* by driving it by hand. A probe is read-only introspection to
*discover* what is already there. Inventing vs. discovering - no overlap.

## The handshake

1. **Name the dependencies.** List the exact facts the requested code hinges on — table/column names + types, version/edition, module/package availability and versions, cmdlet existence, paths, config values, existing definitions — **and the preconditions the result's validity rests on**: session/console type, a selection domain being non-empty, an API call returning success vs. returning empty. A fact you'll read and a condition under which that reading is valid are both dependencies; both get probed.
2. **Emit a probe** scoped to just those facts (see contract below). Show it in chat so the user can read it before running.
3. **User runs it, pastes the output block back.**
4. **Generate the real code** grounded in the reported facts. Where a reported value contradicts what you'd have assumed, say so explicitly — that contradiction is the whole reason the probe exists.

## Scale the probe to the question

A probe is not "always emit a big script." Match the probe to what's actually uncertain — and to where you are in the work: a cold one-shot ask wants the minimum; deep triage earns a wider net.

- **One fact → one line.** "Which SQL Server version?" → emit `SELECT @@VERSION;`, not a sweep. A one-liner the user runs beats both guessing and a back-and-forth in chat.
- **Several interdependent facts → a surgical probe** (default). Collect exactly the named dependencies, nothing more.
- **First contact with an unknown environment → a broad baseline sweep is legitimate.** When you have no map at all, one wider probe to establish a baseline can be the right call. Treat it as a deliberate exception to "surgical," not the default — and still scope it to the domain in play (the relevant database, the relevant module set), not the whole machine.
- **Deep in triage → widen deliberately.** A cold "give me a script to check X" wants the *minimum* that answers X — a single line if one will do, not an elaborate instrumented script. But several diagnostic cycles into a live problem, another round-trip is expensive and a fuller picture pays off: become bolder about what you capture (capture-wide across the bounded objects in play) so one paste advances the diagnosis instead of forcing yet another. Match boldness to triage depth, not just to the literal question.

## Probe contract

**Read-only is the high bar.** The default probe inspects structure and metadata, never the data itself — catalog/metadata views, version functions, module listings, path existence. This bar is high but **crossable when the data *is* the required fact**: distinct enum values stored in a column, an actual config-table value, row cardinality that changes the approach, the real stored format of a field. When you cross it:

- Cross with a **cardinality** cap, never an unbounded dump — `TOP (n)`, `DISTINCT`, `COUNT`, a single keyed lookup bound how many rows you pull. The cap is on rows/volume, not on columns; within a bounded slice, capture the fields rather than re-querying (see *capture wide* below).
- Mask or omit anything plausibly sensitive (PII, secrets); report shape/cardinality over raw content only where shape genuinely answers the question — not as a reflex that drops the payload you'll need next.
- **Flag the crossing** in the probe and again at handoff: state that the probe reads data, which data, and why metadata alone was insufficient.

**Output convention** (applies to every stack):

- Collect all results into one structure; flush **once** at the end as a single block. No interleaved result output scattered through execution.
- Emit the final block as **JSON** — the consumer is the model, and exact identifiers matter. Shape: `requested fact → value`, neutral, no assumptions baked in. `null` / `"not present"` is a valid reported value, not a failure.
- Progress and diagnostics go to a separate stream (verbose/progress/stderr), never into the result block.
- **Fail fast on infrastructure failure** (can't connect, command not found, permission denied) with a message naming what was missing. "Object not found" when *checking for existence* is a result, not a failure.
- Keep it short enough to read and verify as safe before running.

**Capture wide, select in the view.** A round-trip to re-run the probe costs far more than the bytes saved by pre-trimming — prefer more information over asking twice. On a *bounded* source (one object's full property set, one row's columns, a small fixed collection) capture every field, then compute the selected view *from* that captured raw and carry the raw alongside it. Pre-filtering fields before capture — emitting `byte_len` instead of the actual `BlockContent` — is the false economy. Bound **cardinality**, never field breadth: an unbounded source (event logs, full tables, recursive walks) gets a hard cap (`TOP n`, `-MaxEvents`, `-First`, depth limit), and you capture all fields *of that capped slice*. Selection is a view over captured data, never a filter before capture: emit the pre-selected view for reading **and** the full raw block, so the next question is answered from data already in hand. Route bulky raw to a side channel if it clutters — a file, or `Set-Clipboard` on an interactive console session (per mode C, clipboard is unavailable non-interactive/remote; fall back to stdout/file there).

## Probe self-check

A probe whose own failures are silent is worse than no probe — it grounds code in facts that were never actually collected. Two failure modes must be prevented *structurally* (by output design, not by "being careful"):

**A — a failed step vanishes.** Under `$ErrorActionPreference='Stop'` / `set -e`, a throwing step can abort before the flush, or a per-fact failure can leave its key simply absent while later facts succeed — you read the report and never notice fact 1 died. Prevent it: guard each fact probe so its failure is *recorded as a failure value*, never absent; flush the buffer in a `finally`/`trap` so a partial report always emits; include an integrity footer — `attempted` vs `captured` counts plus the names that errored. `attempted ≠ captured` means something was dropped.

**B — empty and absent collapse.** Request dataA, derive dataB from it. If dataB is empty you cannot tell "dataA had no children" from "dataA was never obtained / came back malformed." Prevent it: record dataA's own outcome — obtained? row count? — *as its own fact, before* deriving dataB. Then an empty dataB has exactly one cause.

**C — the result is valid but its meaning is conditional.** A fact can be captured, non-empty, and well-formed — and still mean the opposite of what you'll read into it, because its interpretation rests on a precondition you never checked. `adapter_count=0` means "monitor absent" *only if* enumeration was actually available in this session; on a non-console/remote session the same 0 means "the API yielded nothing here." A selection — "pick from the list" — assumes a non-empty domain; an empty list is not a failed pick, it's an absent precondition. Prevent it: for every condition the result's *meaning* depends on — session is interactive/console, module is loaded, the domain to choose from is non-empty, the call returned success vs. empty — probe that condition as its own field, emitted whether or not it's the "interesting" one. Then a result is always read in a context where its preconditions are already known true or false — never retrofitted as a post-hoc "this looks odd, could you have been connected remotely?"

This needs a **tri-state, not a bare `null`**: distinguish *present-with-value*, *present-but-empty* (0 rows is a real answer), *probed-but-errored*, and *not-probed*. `null` alone is overloaded.

**Before emitting the probe, verify:**

- [ ] Every named dependency has a fact key — nothing silently skipped.
- [ ] Each fact carries a status; failure is a recorded value, not an absence.
- [ ] The flush runs even if a step throws (`finally`/`trap`); a genuine precondition failure (can't connect at all) still stops hard, outside the per-fact guard.
- [ ] Dependent facts record their source's outcome; an empty derived set is attributable.
- [ ] Every precondition the result's *meaning* depends on — session/console type, a selection domain being non-empty, call-succeeded vs. returned-empty — is itself a probed field, emitted before the dependent fact. No meaning is left to be inferred after the output looks odd.
- [ ] Output is valid parseable JSON — depth sufficient (no silent truncation), quotes/newlines escaped, no BOM, no locale-formatted numbers (decimal comma breaks JSON).

**Before generating code from the pasted-back output, verify:**

- [ ] All expected keys present; `attempted == captured`; no errored fact you're about to build on.
- [ ] Values match expected shape — version matches a version pattern, counts are integers ≥ 0, expected arrays are arrays.
- [ ] A value that contradicts your assumption is surfaced; a fact that errored or is empty gets re-probed or asked about — never generate over a hole.

## Anti-patterns

- **Don't guess then caveat.** Emitting code with "adjust the column names if they differ" is the failure the probe exists to kill. Probe first.
- **Don't over-collect — and don't under-capture.** Bound *cardinality* (rows, events, depth); a broad multi-domain sweep is a conscious baseline exception, not a habit. But on a bounded source, capture the whole object's fields — pre-trimming fields to save bytes only buys a second round-trip.
- **Don't cross the data bar casually.** Metadata first; touch data only when the value itself is the fact, and flag it.
- **Don't bury the result.** One JSON block at the end; progress lives in another stream.
- **Don't continue silently on a broken probe.** Infra failure stops with a named reason; "not present" is reported, not fatal.
- **Don't probe what's already known.** If the user stated the fact, or it's visible in context, or it's stack-invariant, skip the probe and proceed.
- **Don't retrofit the cause.** A well-formed but conditional result read without its precondition produces "this looks odd — were you remote?" *after* the output is in hand. The precondition was probeable; probe it as a field up front. Never explain an anomaly with a guess the probe could have settled.
