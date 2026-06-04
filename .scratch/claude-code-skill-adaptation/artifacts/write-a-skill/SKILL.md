---
name: write-a-skill
description: Create, update, or improve agent skills with proper structure, progressive disclosure, and bundled resources. Use when user wants to create, write, build, revise, update, or improve a skill or SKILL.md file.
---

# Writing Skills

## Process

1. **Gather requirements** - ask user about:
   - What task/domain does the skill cover?
   - What specific use cases should it handle?
   - Does it need executable scripts or just instructions?
   - Any reference materials to include?

2. **Draft the skill** - create:
   - SKILL.md with concise instructions
   - Additional reference files if content exceeds 500 lines
   - Utility scripts if deterministic operations needed

3. **Review with user** - present draft and ask:
   - Does this cover your use cases?
   - Anything missing or unclear?
   - Should any section be more/less detailed?

## Skill Structure

```
skill-name/
├── SKILL.md           # Main instructions (required)
├── REFERENCE.md       # Detailed docs (if needed)
├── EXAMPLES.md        # Usage examples (if needed)
└── scripts/           # Utility scripts (if needed)
    └── helper.js
```

## SKILL.md Template

```md
---
name: skill-name
description: Brief description of capability. Use when [specific triggers].
---

# Skill Name

## Quick start

[Minimal working example]

## Workflows

[Step-by-step processes with checklists for complex tasks]

## Advanced features

[Link to separate files: See [REFERENCE.md](REFERENCE.md)]
```

## Description Requirements

The description is **the only thing your agent sees** when deciding which skill to load.

**Format**: max 1024 chars, third person. First sentence: what it does. Second sentence: `Use when [triggers]` — include synonym variants (create/write/build, update/revise/improve).

Good: `Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF files or when user mentions PDFs, forms, or document extraction.`

Bad: `Helps with documents.`

## Scripts

If the skill needs bundled executable scripts, see [SCRIPTS.md](SCRIPTS.md)
for when to add them and how to build them test-first.

## When to Split Files

Split into separate files when:

- SKILL.md exceeds 100 lines
- Content has distinct domains
- Advanced features are rarely needed

## Review Checklist

After drafting, verify:

- [ ] Description includes triggers ("Use when...") with synonym variants for create *and* update flows
- [ ] SKILL.md under 100 lines (including this checklist — count before delivery)
- [ ] No time-sensitive info
- [ ] Consistent terminology
- [ ] At least one complete realistic example exists (inline or in EXAMPLES.md)
- [ ] Any bundled script was built/updated test-first via the `tdd` skill
- [ ] References one level deep only
