# Bundled Scripts

## When to add

Add a utility script when:

- The operation is deterministic (validation, formatting)
- The same code would otherwise be generated repeatedly
- Errors need explicit handling

Otherwise, inline instructions in SKILL.md are enough.

## How to build

Route through the `tdd` skill — failing test → pass → refactor, one
behavior at a time. Load the matching stack file (PowerShell, SQL, Python,
C#). Applies to creating *and* updating bundled scripts.
