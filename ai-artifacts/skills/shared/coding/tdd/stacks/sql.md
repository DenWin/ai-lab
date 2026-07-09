# Stack Rules: SQL and Database Code

- **Do not mock the database.** Test against the real engine in a controlled
  environment: Testcontainers, transactional-rollback-per-test, or in-database
  frameworks (tSQLt for SQL Server, pgTAP for PostgreSQL). A mocked database
  tests that the ORM produces certain calls, not that those calls do the right
  thing.
- Test the **behavior** of stored procedures and functions (given inputs and
  initial data, the outputs and data changes), not query plans or index
  choices. A test that breaks when an index is added is testing the wrong
  thing — structure should be invisible to tests.
- Inject the clock for any code touching `GETDATE`/`NOW`/`CURRENT_TIMESTAMP`,
  or use a database-side test clock if the engine supports one.
- Each test owns its data. Either roll back transactions or use distinct
  schemas per test run. Do not depend on `IDENTITY`/auto-generated keys —
  reset sequences or use deterministic seeds.
- For legacy schema work, suggest approval/characterisation tests against
  current behavior **before** refactoring procedures or schema.
- Performance assertions need a controlled, representative dataset and a stable
  environment, or they are noise — never "tests" that only pass on the
  developer's machine.

## Honest hierarchy for SQL tests

1. Schema/migration tests — migrations apply cleanly to clean and populated DBs.
2. Stored-procedure/function tests — real logic against a real engine.
3. Query-behavior tests — execution plans or row counts at scale for hot paths.
4. Integration tests — application code against the real database.
