---
type: Reference
title: OKF adoption
description: Where this repo applies Open Knowledge Format conventions and where harness-owned formats remain unchanged.
resource: https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md
tags: [okf, metadata, documentation]
timestamp: 2026-07-07T00:00:00Z
---

# OKF Adoption

This repo uses Open Knowledge Format (OKF) conventions for markdown files whose primary purpose is
knowledge/catalog metadata: human- and agent-readable concepts with YAML frontmatter and markdown
bodies.

## Applied Now

- `ai-artifacts/skills/shared/<group>/<name>/METADATA.md` is the OKF-style concept document for each skill.
- Skill provenance (`upstream-*`) lives in `METADATA.md`, not in runtime `SKILL.md` frontmatter.
- Runtime `SKILL.md` frontmatter keeps harness-facing fields such as `name`, `description`,
  `argument-hint`, `disable-model-invocation`, and `version`.

## Adoption Boundary

Do not force OKF frontmatter onto files whose format is owned by another system:

- `SKILL.md` is a harness skill artifact.
- `.scratch/*/PRD.md` and `.scratch/*/issues/*.md` use the scratch tracker format.
- AsciiDoc files under `docs/` keep AsciiDoc-native structure.
- Generated mirrors under `.claude/commands/` and `.agents/skills/` are build artifacts.

New durable markdown reference documents should use OKF frontmatter when it does not conflict with a
more specific format. At minimum include:

```yaml
---
type: Reference
title: <display title>
description: <one-line summary>
tags: [<tag>]
---
```

## Reviewed Targets

- **Skills:** adopted through per-skill `METADATA.md` files.
- **Skill provenance/update tooling:** adopted; `/setup:check-skill-updates` reads `METADATA.md`.
- **General docs:** use OKF for new markdown reference docs when there is no stronger local format.
- **Scratch tracker:** not adopted directly; `.scratch/AGENTS.md` and the scratch skill own that
  schema.

# Citations

[1] [Open Knowledge Format specification](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md)
