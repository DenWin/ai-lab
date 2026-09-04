---
name: write-a-skill
description: Create, update, or improve agent skills with proper structure, progressive disclosure, and bundled resources. Use when user wants to create, write, build, revise, update, or improve a skill or SKILL.md file.
metadata:
  version: 1.1.0
---

# Writing Skills

## Process

0. **When updating an existing skill** - read *every* file in the skill
   directory first (SKILL.md and all bundled files), not just SKILL.md. An
   edit to one file can invalidate references in another.

1. **Establish scope** - infer task/domain, use cases, and whether scripts
   are needed from the request. State your reading and any assumption
   explicitly. Ask a focused question *only* when a choice needs domain
   knowledge you cannot infer and is costly to get wrong; otherwise proceed.

2. **Draft the skill** - create:
   - SKILL.md with concise instructions (see line limit in Review Checklist)
   - Additional reference files when a split is warranted (see When to Split)
   - Utility scripts if deterministic operations needed, built test-first
     per [SCRIPTS.md](SCRIPTS.md)

3. **Review** - present the draft with a one-line summary of the design
   decisions made (split or not, scripts or not, triggers chosen) and ask for
   confirmation on those decisions, not "is anything missing?".

## Skill Structure

```text
skill-name/
├── SKILL.md           # Main instructions (required)
├── REFERENCE.md       # Detailed docs (if needed)
├── EXAMPLES.md        # Usage examples (if needed)
└── scripts/           # Utility scripts (if needed)
    └── helper.js
```

## SKILL.md Template

Required sections: `# Title`, `## Quick start`, `## Workflows`. Copy the full
blank template from [TEMPLATE.md](TEMPLATE.md) and fill it in.

Frontmatter: `name` (kebab-case) and `description` required. Optional (Agent
Skills standard): `license`, `compatibility`, `allowed-tools` (restrict tool
access), `metadata`. No `<`/`>` allowed anywhere in frontmatter.

## Description Requirements

The description is **the only thing your agent sees** when deciding which skill to load.

**Format**: max 1024 chars, third person. First sentence: what it does. Second sentence: `Use when [triggers]` — include synonym variants (create/write/build, update/revise/improve).

Good: `Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF files or when user mentions PDFs, forms, or document extraction.`

Bad: `Helps with documents.`

## When to Split Files

Split into separate files when:

- SKILL.md would exceed the line limit (see Review Checklist)
- Content has distinct domains
- Advanced features are rarely needed

## Delivery

If the skill changed, bump `metadata.version` before packaging — patch for
fixes/wording, minor for new sections or added behavior, major for removals or
breaking restructures.
Package the finished skill as one archive and present that, not loose files,
unless the user asks otherwise. claude.ai exports skills as a zip with the
folder at its root and a `.skill` extension:

```bash
zip -r skill-name.skill skill-name/   # run from the parent directory
```

The folder must sit at the archive root (`skill-name/SKILL.md`); putting its
contents at the root causes "Could not find SKILL.md" on upload.

## Review Checklist

After drafting, verify:

- [ ] Description includes triggers ("Use when...") with synonym variants for create *and* update flows
- [ ] SKILL.md under 100 lines (including this checklist — count before delivery)
- [ ] No time-sensitive info
- [ ] Consistent terminology
- [ ] At least one complete realistic example exists (inline or in EXAMPLES.md)
- [ ] Any bundled script was built/updated test-first (via the `tdd` skill if available)
- [ ] References one level deep only
- [ ] Delivered as a single `.skill` archive with the folder at its root
