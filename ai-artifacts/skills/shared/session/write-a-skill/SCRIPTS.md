# Bundled Scripts

## When to add

Add a utility script when:

- The operation is deterministic (validation, formatting)
- The same code would otherwise be generated repeatedly
- Errors need explicit handling

Otherwise, inline instructions in SKILL.md are enough.

## How to build

Build test-first — failing test → pass → refactor, one behavior at a time.
If the `tdd` skill is available, route through it (and load its matching stack
rules); otherwise apply the same loop by hand. Applies to creating *and*
updating bundled scripts.
