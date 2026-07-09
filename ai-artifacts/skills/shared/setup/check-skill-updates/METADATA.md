---
type: Agent Skill Metadata
title: "check-skill-updates"
description: "Check whether the skills in this repo are stale against their upstream source on GitHub, and file a work item (GitHub issue or .scratch entry) for each stale one. It never edits or merges skills itself. Use when user wants to check for new skill versions, run \"check-skill-updates\", or sync with upstream changes."
resource: ./SKILL.md
tags: [setup, skill]
---

# Skill Metadata

- Runtime skill: [SKILL.md](SKILL.md)
- Group: `setup`
- Origin: local
- Notes: Local original; reads skill METADATA.md files for upstream drift checks.