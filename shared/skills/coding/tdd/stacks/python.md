# Stack Rules: Python

- Use pytest for new work. Do not mix pytest and unittest patterns in the same
  module.
- Use plain `assert` statements — pytest rewrites them for detailed failure
  messages. Do not import separate assertion libraries.
- Do not put `assert` statements in production code; they are stripped under
  `python -O`.
- Patch the **lookup location**, not the definition location. Patching
  `requests.get` rarely works; patching `mymodule.requests.get` does.
- Wrap third-party libraries (requests, boto3, sqlalchemy) in your own
  abstractions and patch those, not the library directly.
- Treat mypy/pyright errors as test failures. Static typing is a compensating
  control for the dynamic-typing trap (wrong-shape calls fail only at runtime,
  and only if that branch executes).
- Default pytest fixture scope to `function`. Widen only with explicit
  justification; never share mutable state across tests.
- Use `AsyncMock` (not `MagicMock`) for async dependencies. Mark async tests
  with `@pytest.mark.asyncio` or set `asyncio_mode=auto`.
- Do not mock the database. Use SQLite in-memory or Testcontainers.
- Use Hypothesis (property-based) for any code with a non-trivial input space —
  Python's flexibility makes hand-written test data especially prone to
  happy-path-only coverage.
- Use freezegun, time-machine, or an injected clock for time-dependent code.
  Never call `datetime.now()` in testable code.
- Compare floats with `pytest.approx` or `math.isclose`, never `==`.
- Catch specific exception types in tests, never bare `except Exception`.
- Assert on equality, not truthiness, unless you specifically mean truthiness.
  `assert result` passes for `1`, `"x"`, `[0]`.

## LLM Tools, Skills, and Agents

- Test **tool functions** as ordinary deterministic units.
- Test **schemas / argument validation** deterministically (schema matches the
  signature, required args marked required, malformed input rejected).
- Verify **agent behaviour** with **evals** — score outputs across a set of
  representative inputs and track the success rate. Never assert that the real
  model chose a specific tool inside a unit test.
- Mock the model client to make the agent loop's control flow deterministic
  (does it stop when no tool call is returned, does it pass results back).
- Tool/schema tests live in the repo, version-locked, run in CI. Evals live in
  the repo but on a separate cadence (not the per-commit path). Ship no tests
  in the runtime artifact; include tests in the **sdist** of a shared tool
  package as contract documentation, not in the runtime wheel.
