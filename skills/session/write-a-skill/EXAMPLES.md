---
name: write-a-skill / examples
---

# Skill Examples

## Complete example: `csv-import`

A realistic minimal skill covering a focused domain.

### File layout

```
csv-import/
├── SKILL.md
└── EXAMPLES.md
```

### `csv-import/SKILL.md`

```md
---
name: csv-import
description: Parse, validate, and import CSV files into SQL databases or dataframes. Use when user uploads a CSV, mentions CSV import, data ingestion, or asks to load tabular data into a database or script.
---

# CSV Import

## Quick start

1. Read first 5 rows to infer schema.
2. Confirm delimiter, encoding, and header presence with user if ambiguous.
3. Generate import script for the target (SQL Server, pandas, etc.).

## Workflows

### SQL Server import

- [ ] Detect delimiter and encoding (`file`, `chardet`, or manual inspection)
- [ ] Map CSV columns → SQL types (string→NVARCHAR, int→INT, date→DATE)
- [ ] Generate CREATE TABLE + BULK INSERT or bcp script
- [ ] Flag nullable columns and max string lengths
- [ ] Confirm with user before emitting final script

### Pandas import

- [ ] Use `pd.read_csv` with explicit `dtype` and `parse_dates`
- [ ] Report rows with nulls or type coercion failures
- [ ] Return a validated DataFrame; do not silently drop rows

## Notes

- Always prefer explicit dtypes over inferred ones.
- For files > 100 MB, suggest chunked reading.
- See [EXAMPLES.md](EXAMPLES.md) for sample SQL output.
```

### What makes this a good skill

| Property | Value |
|---|---|
| Description discriminates | Yes — "CSV", "import", "ingestion", "tabular data" |
| Update trigger covered | Not applicable (no update flow for this domain) |
| Line count | 38 — well under 100 |
| Concrete example | Checklist steps are actionable without guessing |
| Split decision | EXAMPLES.md added because SQL sample output would push SKILL.md over limit |
