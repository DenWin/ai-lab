# Companion Methodologies — When to Suggest Each

These fill gaps TDD/BDD do not address. They are not alternatives to TDD.

- **Property-based testing** — suggest when code has clear invariants (parsers,
  serialisers, sort/search, roundtrip operations, algorithms). Do not suggest
  for glue code or UI. Complements TDD: drive design with concrete examples,
  then add properties once the design has stabilised.
- **Mutation testing** — suggest as a periodic quality check on critical
  modules, not as a per-commit gate. It answers what coverage cannot (do the
  tests actually verify anything). Coverage is not a substitute.
- **Contract testing** — suggest at every inter-service boundary where two
  independently-deployed components communicate. Catches contract drift at
  build time on whichever side broke the agreement.
- **Approval / golden-master testing** — suggest when correct output is hard to
  specify but easy to recognise (reports, codegen, complex transformations) and
  for characterising legacy code before refactoring.
- **Snapshot testing** — suggest with an explicit warning about review
  discipline. Auto-updated snapshots without review have no verification value.
- **Integration tests** — suggest for code that is mostly glue. Unit tests on
  pure glue produce structurally-coupled tests with low value. Match the test
  distribution to the code's centre of gravity (computation-heavy → more unit
  tests; glue-heavy → more integration tests).
