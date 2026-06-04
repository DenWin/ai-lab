# 01 — Metadata model + backlog columns

Status: ready-for-human

## What to build

Introduce per-feature PRD frontmatter as the metadata source of truth (schema in the PRD), and make
`BACKLOG.md` a generated ranked view of a column subset. New fields: `blocked-by`, `due`,
`updated` (the user's three) plus `created`, `recurrence`, `area`.

Decide the **table subset**: which fields render as `BACKLOG.md` columns vs. stay frontmatter-only.
Recommended table columns (decision-relevant, ~10 wide): Rank, Feature, Priority, Importance,
Effort, Due, Updated, Blocked by, Score, Status. `created`, `recurrence`, `area` stay in frontmatter.

Update `LAYOUT.md` (frontmatter schema + "BACKLOG.md is generated") and migrate existing PRDs from a
bare `Status:` line to frontmatter.

## Acceptance criteria

- [ ] Frontmatter schema defined in `LAYOUT.md`; `scratch` writes it on capture
- [ ] `scratch-plan` reads frontmatter and renders the agreed `BACKLOG.md` column subset
- [ ] `blocked-by` references feature slugs; rendered in the table
- [ ] Existing PRDs migrated (or `Status:` line kept working alongside frontmatter)
- [ ] Table width sanity-checked — readable in a terminal/markdown preview

## Blocked by

None.
