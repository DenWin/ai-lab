---
name: tdd
description: Test-driven development applied as a workflow across unit, integration, and acceptance levels, with on-demand stack-specific rules for PowerShell, SQL, Python, and C#. Use when building features or fixing bugs test-first, when writing or reviewing tests, when choosing test doubles, when picking a companion technique (property-based, mutation, contract, approval, snapshot testing), or when the user mentions TDD, red-green-refactor, BDD, acceptance tests, or mocking.
upstream-author: mattpocock
upstream-repo: https://github.com/mattpocock/skills
upstream-path: skills/engineering/tdd/SKILL.md
upstream-commit: aaf2453fbdfe7a15c07f11d861224f34ab4b53cb
---

# Test-Driven Development

These are my operating rules for test and development work. Apply them; do
not restate them back to me; do not soften them. When a request of mine
conflicts with a rule, say so and ask before proceeding rather than
silently complying.

## Core Frame

- Tests do three jobs: **verification**, **design feedback**, **specification**.
  Identify which job applies before suggesting a test approach.
- TDD's primary value is design feedback and incremental progress.
  Verification is a side effect. Do not pitch TDD as "a way to find bugs."
- BDD is TDD with behavior-focused vocabulary and an outside-in perspective.
  It is not a separate methodology and not defined by Gherkin/Cucumber.
- TDD is a **workflow** (write failing test → pass → refactor), not a scope.
  It applies at unit, integration, acceptance, and E2E levels. Do not equate
  TDD with unit testing, and do not reject it because something cannot be
  unit-tested.
- A test must **fail on behavior change and pass on structure change.** If a
  proposed test would break on a legitimate refactor, reject it and propose a
  behavior-level alternative.

## Workflow

### 1. Plan

- Confirm what interface changes are needed and which behaviors matter most.
  I cannot test everything — focus on critical paths and complex logic.
- List behaviors to test (not implementation steps).
- Design interfaces for testability — see [design-for-testability.md](design-for-testability.md).
- Use the project's domain vocabulary for test names; respect existing ADRs
  and the existing test suite's style.
- **Load the stack file for the language in play, and only that one:**
  [PowerShell](stacks/powershell.md) · [SQL](stacks/sql.md) ·
  [Python](stacks/python.md) · [C#](stacks/csharp.md). Do not read stack files
  for languages not in use.
- Get my approval on the plan before writing code.

### 2. Tracer bullet

Write ONE test that confirms ONE thing end-to-end. Red → green. This proves
the path works before you build on it.

### 3. Incremental loop

For each remaining behavior: red → green, one test at a time, minimal code,
no anticipation of future tests. **Drive vertical, not horizontal** — one
test, one implementation, learn, then the next test. Never write all tests
first then all code (see [reviewing-and-cycle.md](reviewing-and-cycle.md)).

### 4. Refactor

Only once green (never while red). Look for: duplication, long methods,
shallow modules to deepen, logic that belongs where its data lives, and what
the new code reveals about existing code. Run tests after each step.
Refactor is non-optional — skipping it degrades TDD into "tests plus mess."

## Per-Cycle Checklist

```
[ ] Test describes behavior, not implementation
[ ] Test uses the public interface only
[ ] Test would survive an internal refactor
[ ] Red was a real assertion failure, not just a compile error
[ ] Code is minimal for this test; no speculative features
[ ] Structural and behavioral changes are not mixed in one step
```

## Reference Files (load as needed)

- [reviewing-and-cycle.md](reviewing-and-cycle.md) — rules for writing/reviewing
  tests and the red-green-refactor cycle (strategies, what counts as red).
- [test-doubles.md](test-doubles.md) — mock/stub/fake selection, mock at
  boundaries, third-party wrapping, classicist vs London.
- [companions.md](companions.md) — when to suggest property-based, mutation,
  contract, approval, snapshot, and integration testing.
- [behaviors.md](behaviors.md) — what not to do, how to handle ambiguous
  requests, and output format when producing tests.
- [design-for-testability.md](design-for-testability.md) — interface design
  that makes tests natural.
- `stacks/<language>.md` — stack-specific rules; load only the one in use.
