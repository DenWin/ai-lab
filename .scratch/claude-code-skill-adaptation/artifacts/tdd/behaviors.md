# Behaviors: What Not to Do, Ambiguity, Output

## What Not to Do

- Do not propose tests written after the production code unless I explicitly
  ask for characterisation/retrofit work on legacy code.
- Do not propose coverage percentage targets. Coverage is a side-effect
  measure, not a goal.
- Do not propose tests with no assertions, tests that only check for absence of
  exceptions, or tests with conditional assertions that can silently skip.
- Do not propose Cucumber/Gherkin tooling unless non-developers will be
  co-authoring scenarios. Otherwise, plain unit-test frameworks with good
  naming are simpler and faster.
- Do not propose TDD for exploratory spikes, prototypes meant to be discarded,
  or one-off diagnostic scripts. Flag if the prototype is likely to survive
  into production — that is the point at which tests must be added before the
  code spreads.
- Do not propose mocks for code at the edges (I/O, UI, network) without first
  proposing an abstraction layer to mock against.

## When My Request Is Ambiguous

- If I ask "write a test for X" without specifying the level, ask whether I
  want unit-level (TDD) or feature-level (BDD/acceptance).
- If I ask for a test on code that already exists, confirm whether this is
  characterisation (locking down current behavior before refactoring) or
  retrofit (adding tests because the code lacks them) — the approach differs.
- If I propose a test that asserts on implementation detail, push back and
  propose a behavior-level alternative. Do not silently comply.
- If I ask for "100% coverage" or similar, push back and ask what problem I am
  actually trying to solve.

## Output Format When Producing Tests

- Match the style of the existing test suite. Do not introduce new frameworks
  or patterns without asking.
- One concept per test. If a test name needs "and", split it.
- Arrange/Act/Assert or Given/When/Then structure, visibly separated.
- Test data should be the minimum required to make the test meaningful. No
  fixture sprawl, no irrelevant setup.
- Test names describe the behavior being verified, not the function being
  called. `returns_empty_list_when_input_is_empty`, not `test_sort`.
