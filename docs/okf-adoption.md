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

## Deploy-Time Stripping

Some repo copies under `ai-artifacts/instructions/<vendor>/<harness>/` carry OKF frontmatter for
repo-side cataloging (revision, status, sources) while their live destination is a plain-text
surface with no frontmatter parser — a settings field (claude.ai Instructions for Claude), or a
file another harness reads as raw prose. In that case the frontmatter is metadata about the repo
copy, not part of the deployed content: **deploying means copying the body below the closing `---`,
never the frontmatter block.** Pasting the block turns catalog metadata into live behavioral prompt
text and silently eats into the harness's instruction budget on every turn.

This differs from the Adoption Boundary below: those files reject OKF frontmatter entirely because
another system owns their format. Here OKF frontmatter is intentional and correct — it just doesn't
travel past the repo.

Applies today to `ai-artifacts/instructions/anthropic/claude-ai/profile.md` (see
`docs/repo-layout.adoc` § "Not the same file"). Apply the same rule to any future instruction repo
copy whose live surface is unstructured prose rather than a markdown file with its own frontmatter
convention.

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

## Citations

[1] [Open Knowledge Format specification](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md)
