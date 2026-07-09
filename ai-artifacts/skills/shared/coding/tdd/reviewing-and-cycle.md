# Writing/Reviewing Tests & Cycle Discipline

## When Writing or Reviewing Tests

- Write tests against observable behavior at the boundary of the unit under
  test. Never assert on private state, internal call sequences, or
  implementation-specific data shapes unless the interaction is the actual
  user-visible behavior (e.g. "an email was sent").
- Verify through the same interface other callers use. Do not propose tests
  that query the database directly, inspect internal log files, or read private
  attributes to confirm a result, when a public retrieval interface for that
  result exists. Back-door verification couples the test to internal storage
  and proves the wrong thing. The narrow exception: when the internal artifact
  (a populated table consumed by downstream systems, a generated file) *is* the
  public interface, asserting on it is correct.

  ```python
  # BACK DOOR — couples to schema; misses a broken get_user
  def test_create_user_persists():
      create_user({"name": "Alice"})
      row = db.execute("SELECT name FROM users WHERE ...").fetchone()
      assert row["name"] == "Alice"

  # FRONT DOOR — verifies through the interface callers use
  def test_create_user_makes_user_retrievable():
      user = create_user({"name": "Alice"})
      assert get_user(user.id).name == "Alice"
  ```

- Phrase test names and scenarios in the vocabulary of the problem domain at
  the relevant layer, not the implementation language.
- Use Given/When/Then structure for acceptance-level scenarios. One When per
  scenario. If When has "and", split the scenario.
- Self-check every test: "if the implementation were rewritten in a completely
  different style, would this test still make sense?" If no, the test is
  structure-coupled — rewrite it.

## TDD Cycle Discipline

- **Red means assertion failure, not compilation failure.** The test must
  actually run and the assertion must actually fail before declaring red. If
  you only saw a compile error, you have not proven the test can detect wrong
  behavior — write the minimum stub to make it compile, re-run, and confirm the
  assertion fails before moving to green.

  ```python
  # 1. test + assertion written first
  def test_add(): assert add(2, 3) == 5
  # 2. stub so it RUNS (bookkeeping, not a phase):  def add(a, b): return 0
  # 3. run → "0 != 5" → THIS is red (an assertion failed, not a NameError)
  # 4. implement → return a + b → green
  ```

- **Red designs the external interface. Refactor designs the internals.** Green
  is deliberately minimal — hard-coded constants are acceptable.
- **Three valid strategies for green:**
  - *Obvious Implementation* — write the real code when it is obvious. Default.
  - *Fake It* — hard-code the answer, then generalise in refactor. Use when the
    design is unclear.
  - *Triangulation* — hard-code the answer, then let a further test force the
    generalisation. Use when the cases the code must handle are not knowable up
    front (parsers for human input, business rules with overlapping conditions,
    anything with open-ended input space).
- A bug report, production incident, or newly-discovered failing case is
  **discovered Triangulation**: write a failing test that reproduces the case,
  watch it fail against the current implementation, then generalise the code to
  handle it. The red→green→refactor loop is the same; only the timing of when
  the test was written differs.
- Do not mix structural and behavioral changes in one step or one commit.
  Either change what the code does or change how it is shaped, never both.
- **Drive vertical, not horizontal.** One test → one minimum implementation →
  next test. Do not propose writing all tests for a feature upfront and then
  bulk-implementing against them; that is horizontal slicing and it forfeits the
  design-feedback loop that is TDD's primary value. If I ask for a batch of
  tests upfront, push back and propose a vertical first cycle instead.
- If the green step takes more than a few minutes, the step is too large.
  Halve it. Pick a simpler case.
- Refactor is non-optional. Skipping refactor degrades TDD into "tests plus
  accumulating mess."
