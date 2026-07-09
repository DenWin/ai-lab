# Policy Rule Rationales

## Usage Policy (`usage-policy.yaml`)

id: directional_not_absolute
description:
    Policies are steering constraints, not rigid laws.
    This exists so the policy set stays practical for real-world edge cases.
    Example: If a rule says "collect first, report second," a progress bar line is still acceptable.

id: keep_only_behavior_shaping_constraints
description:
    Keep only rules that materially change likely model output.
    This avoids policy bloat from advice the model would already follow in a professional default run.
    Example: Keep "no global strict mode in bash"; drop generic "write readable code" guidance.

id: load_order
description:
    Load polyglot baseline first, then resolved language policy if available.
    This preserves consistent defaults while allowing language-specific overrides.
    Example: A SQL task loads `polyglot-policy.yaml` + `languages/sql-policy.yaml`.

id: specificity_precedence
description:
    More specific policy wins over broader policy.
    This prevents global defaults from overriding context-critical rules.
    It also avoids contradictory behavior when a generic rule and a language rule both apply.
    Example: A SQL ordering rule overrides a generic "query output" heuristic.

id: direct_language_policy
description:
    If a direct language policy exists, use it first.
    This ensures precision where dedicated guidance exists.
    Example: `powershell` resolves to `languages/powershell-policy.yaml`.

id: jvm_family_policy
description:
    JVM languages resolve to a shared JVM family policy.
    This captures shared concurrency/testing pitfalls without duplicating files.
    Example: `kotlin` and `java` both use `languages/jvm-policy.yaml`.

id: dotnet_family_policy
description:
    .NET languages resolve to a shared .NET family policy.
    This captures shared async pitfalls across C#/F#/VB.NET.
    Example: `fsharp` resolves to `languages/dotnet-policy.yaml`.

## Polyglot Policy (`polyglot-policy.yaml`)

id: data_vs_diagnostics
type: coding
description:
    Keep machine data and diagnostics on separate channels.
    This exists because mixed output breaks parsers and automation pipelines.
    Note: Runtime-specific streams (for example PowerShell Output/Error/Warning/Verbose) should still map cleanly into this model: machine result data stays in one contract channel, diagnostics stay in non-data channels.
    Example: JSON report to stdout (or Output stream contract), warnings/errors to stderr (or warning/error streams).

id: collect_then_report
type: coding
description:
    Collect and validate data first, emit final report after collection.
    This avoids long interleaved output where key failures are buried.
    Example: Gather all checks, then print one summary table.
    Exception: progress/status reporting is allowed during collection.

id: explicit_error_policy
type: coding
description:
    Required failures must be explicit and machine-detectable.
    This prevents "success-looking" output from failed workflows.
    Pattern: assert/validate preconditions before expensive processing or output transformation, then fail fast with a deterministic error signal.
    Example: Non-zero exit code with clear error text when input file is missing.

id: fail_on_warning_default
type: coding
description:
    Treat warnings as failures by default in automated runs.
    This keeps warning debt from silently becoming normal and preserves signal quality in CI and scripts.
    Override model: allow specific warning downgrades only when explicitly documented with rationale.
    Example: pipeline fails on warning unless warning code `W1234` is allowlisted for a known transitional dependency.

id: defer_projection_for_broad_analysis
type: coding
description:
    For broad analysis flows, defer projection/filtering until reporting boundaries.
    Premature projection can discard fields needed for later correlation, validation, and diagnostics.
    Example: collect host objects with `Name`, `Cluster`, `PatchLevel`, and `LastSeen`; if projection to `Name` runs early, later drift-correlation by `Cluster` and `PatchLevel` is impossible.
    Exception: early projection is acceptable when the output contract is explicitly narrow.

id: safe_destructive_ops
type: security
description:
    Validate targets and require explicit intent before destructive actions.
    This reduces accidental data loss.
    The goal is to make deletion or overwrite impossible to trigger by ambiguous input.
    Pseudo-code pattern:
        target = normalize(userInputPath)
        if not isWithinWorkspace(target): fail("refusing delete outside workspace")
        if not flags.confirmDelete: fail("explicit --confirm-delete required")
        if hasProtectedMarker(target): fail("protected target")
        delete(target)
    Example: Confirm path is inside workspace and require `--confirm-delete` before deleting generated artifacts.

id: secure_composition
type: security
description:
    Never execute untrusted input as code/command/query fragments.
    This rule blocks SQL injection, shell/command injection, template/code injection, and prompt/AI-instruction injection where untrusted text can change execution intent.
    Example: use parameterized SQL, allowlisted command dispatch, and strict prompt/data boundary handling for LLM calls.

id: behavior_boundary
type: tdd
description:
    Tests should target externally observable behavior.
    This keeps tests stable under internal refactoring.
Pattern pseudo-code:

```pseudo
result = call_public_api(input)
assert result.status == 200
assert result.body.total == 3
```

Anti-pattern pseudo-code:

```pseudo
call_public_api(input)
assert privateHelper.calledOnce
assert internalBuffer[0] == "tmp"
```

Example: for `POST /orders`, assert HTTP `201` and returned `total/tax` values; do not assert private helper invocation counts.

id: real_red
type: tdd
description:
    In TDD, red means assertion failure after test execution.
    Setup/import failures are not equivalent to meaningful red.
Pattern pseudo-code:

```pseudo
test "returns domain error for invalid id":
    result = parseId("bad")
    assert result.errorCode == "INVALID_ID"   # valid red if this fails
```

Anti-pattern pseudo-code:

```pseudo
test file fails to import module "missing-lib"
# this is harness/setup failure, not behavior-level red
```

Example: a failing assert on output is valid red; module-not-found is not.

id: vertical_slicing
type: tdd
description:
    Prefer one failing test -> minimal implementation -> refactor.
    This keeps feedback loops short and design iterative.
    Small slices reduce rework because each behavior is validated before the next is added.
    Pattern: one new behavior case at a time.
    Anti-pattern: many failing tests queued before any implementation.
    Example: Implement one behavior case, then add the next test.

id: separate_structure_behavior
type: tdd
description:
    Keep refactors separate from behavior changes.
    This improves traceability and rollback/debug clarity.
    Pattern: commit/refactor first, commit behavior change second.
    Anti-pattern: rename/extract and behavior mutation mixed in one diff.
    Example: Rename/extract methods in one commit, behavior change in another.

id: no_assertionless_tests
type: tdd
description:
    Tests without assertions are not valid verification.
    They provide execution smoke but no behavioral guarantee.
    Anti-pattern: test that only runs code and never checks result.
    Example: Replace "just run" test with explicit output/state assertion.

id: no_bulk_test_then_implement
type: tdd
description:
    Do not write all tests first and then bulk implement.
    This breaks TDD feedback mechanics.
    Anti-pattern: author 20 failing tests, then write production code once at the end.
    Example: Avoid authoring 20 failing tests before any production change.

id: no_coverage_as_primary_goal
type: tdd
description:
    Coverage is a signal, not the primary quality objective.
    High coverage can still miss critical behavior checks.
    Anti-pattern: chasing line coverage while missing error/cancellation behavior.
    Example: 90% coverage but no test for cancellation/error handling.

## Bash Policy (`languages/bash-policy.yaml`)

id: no_global_strict_mode
type: coding
description:
    Do not blanket-enable `set -e/-u/-euo pipefail` across an entire script.
    Global strict mode in Bash has edge cases where legitimate non-zero control flow causes brittle, non-obvious exits.
    Required replacement pattern: keep failure handling explicit and deterministic.
    Do not merely remove strict mode; replace it by capturing return codes, branching expected non-zero outcomes,
    and exiting non-zero on true failures.
    In CI and other automation scripts, prefer explicit guarded blocks with `set +e`, then check command exit codes.
    For pipelines (for example `cmd | tee report.txt`), explicitly inspect `PIPESTATUS` for the command that matters.
    Strict options are allowed only in narrow scopes where semantics are clear.
    Pseudo-code:
        set +e
        commandThatMayReturn1
        rc=$?
        if [ $rc -ne 0 ] && [ $rc -ne 1 ]; then
            echo "unexpected failure" >&2
            exit $rc
        fi
        commandThatMayPipe | tee report.txt
        pipe_rc=${PIPESTATUS[0]}
        if [ $pipe_rc -ne 0 ]; then
            exit $pipe_rc
        fi
    Example: handle expected grep no-match/non-zero explicitly instead of relying on global errexit semantics.

id: feature_detection
type: coding
description:
    Prefer capability checks over version checks.
    Versions vary across distros, patches, and packaging, so version gates often mispredict actual behavior.
    Capability probing tests what the script really needs and fails closer to true incompatibility.
    Pseudo-code:
        if declare -A tmp_assoc 2>/dev/null; then
            use_assoc_array=true
        else
            use_assoc_array=false
        fi
    Example: check `declare -A` support directly instead of parsing Bash version text.

id: read_safely
type: coding
description:
    Use `while IFS= read -r` for line input.
    This preserves literal content and avoids escape/whitespace corruption.
    Example: reading paths with spaces and backslashes reliably.

id: array_iteration
type: coding
description:
    Iterate arrays with quoted `"${arr[@]}"`.
    This prevents unintended splitting/globbing.
    Example: filenames with spaces stay single elements.

id: no_ls_parsing_loop
type: coding
description:
    Never iterate files via `for f in $(ls ...)`.
    `ls` output is presentation-oriented and unsafe for parsing.
    Example: filenames containing newline/tab break naive loops.

id: no_backticks
type: coding
description:
    Avoid backtick command substitution; use `$(...)`.
    `$(...)` is easier to nest and less error-prone.
    This also improves readability in complex command pipelines.
    Pattern (readability): `echo $(echo $(echo $(echo "a\\b")))` is maintainable
    Anti-pattern: ``echo `echo \`echo \\\`echo "a\\\\\\\\b"\\\`\`` requires heavy escaping and is fragile.

## PowerShell Policy (`languages/powershell-policy.yaml`)

id: stream_specific_assertions
type: tdd
description:
    Assert PowerShell streams separately in tests.
    Streams carry different semantics and should not be conflated.
    Combining them can hide real failures behind normal informational output.
    Pattern: assert Output and Error/Warning streams independently.

id: no_format_table_logic
type: coding
description:
    Do not parse `Format-Table`/`Format-List` output for logic.
    Format cmdlets are for display, not stable data processing.
    Example: branch on object properties, not on formatted text lines.

## SQL Policy (`languages/sql-policy.yaml`)

id: explicit_order_assertions
type: tdd
description:
    If consumer behavior depends on ordering, assert it explicitly.
    This is the testing companion to `no_implicit_row_order`: coding rule enforces query determinism, test rule enforces behavior verification.
    They are complementary, not opposites.
    Example: test checks `ORDER BY created_at DESC` result sequence.

id: deterministic_seeded_data
type: tdd
description:
    Use seeded deterministic test data and reset state between runs.
    This keeps SQL tests repeatable and independent.
    Determinism is required to trust failures as product defects instead of data drift.
    Example: reset fixture tables before each integration test.

id: nolock_requires_justification
type: security
description:
    `NOLOCK` is allowed only with explicit rationale in code comments.
    It is not inherently bad, but tradeoffs must be intentional.
    Example: comment states tolerance for dirty reads in a non-critical telemetry query.

id: precompute_expression_arguments
type: coding
description:
    Precompute expression results into variables before passing them in sensitive procedural call positions.
    This avoids parser/runtime edge cases in statement argument binding.
    Anti-pattern (bad): inline expression directly in argument position where procedure requires variable/literal semantics.
    Pattern (good): compute once into variable, then pass the variable.
    Example: assign `UPPER(@msg)` to `@msgUpper` before `EXEC`/`RAISERROR` argument use.

```sql
EXEC #some_SP @input = UPPER(@msg);                         -- will fail
RAISERROR('UpperCase: %s', 0, 1, UPPER(@msg)) WITH NOWAIT;  -- will fail
--versus:
DECLARE @msgUpper NVARCHAR(100) = UPPER(@msg);
EXEC #some_SP @input = @msgUpper;                           -- a stored procedure requires a variable or literal
RAISERROR('UpperCase: %s', 0, 1, @msgUpper) WITH NOWAIT;    -- same for RAISERROR
```

id: no_implicit_row_order
type: coding
description:
    Do not rely on implicit row order where order matters.
    Determinism requires explicit ordering.
    Example: always use `ORDER BY` when report rows must be stable.

id: no_state_leakage
type: tdd
description:
    SQL tests must not depend on side effects from previous tests.
    State leakage causes flaky, order-dependent suites.
    Pattern: each test seeds/tears down its own state.
    Anti-pattern: test B passes only if test A ran first.
    Example: test run order changes should not change pass/fail outcomes.

## JVM Policy (`languages/jvm-policy.yaml`)

id: no_ignored_interruption
type: coding
description:
    Do not ignore interruption/cancellation semantics in concurrent code.
    Ignoring interruption leads to stuck threads and poor shutdown behavior.
    Example: catch `InterruptedException`, restore interrupt flag, and stop work appropriately.

id: no_sleep_based_timing_tests
type: tdd
description:
    Avoid sleep-based timing tests when deterministic coordination/time control exists.
    Sleep-based tests are flaky across machines and CI load.
    Pattern: latch/barrier/virtual-time based coordination.
    Anti-pattern: `Thread.sleep(...)` assertions tied to wall-clock assumptions.
    Example: use latches/virtual time instead of `Thread.sleep(500)` assertions.

## .NET Policy (`languages/dotnet-policy.yaml`)

id: async_behavior_contract
type: tdd
description:
    For async code, prefer async tests and assert timeout/cancellation where contractual.
    Many async defects appear only under real await/cancellation paths.
    Pattern: await the task and assert cancellation/timeout contract explicitly.
    Anti-pattern: synchronous wrappers that hide task lifecycle behavior.
    Example: assert token cancellation propagates and task ends with expected exception.

id: no_result_wait_blocking
type: coding
description:
    Avoid `.Result`/`.Wait()` unless interoperability constraints require it.
    Blocking can deadlock and mask scheduler/context issues.
    In tests, blocking can also hide cancellation/timeout behavior that async code must honor.
    Example: replace `.Result` with `await` in test and production flow.
