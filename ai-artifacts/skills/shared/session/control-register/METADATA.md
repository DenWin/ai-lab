---
type: Agent Skill Metadata
title: "control-register"
description: "Render the decision-points control register as a self-contained HTML page with filter chips, sortable columns, expand-in-place detail rows, numbered code blocks, per-row verdict buttons feeding a single copyable outbox, jump buttons on every cross-reference, and collapsible epic header rows that can carry a model assignment and a blocker on the whole epic. Use when creating, writing, updating, revising, or rewriting `control-register.html`, whenever the protocol calls for emitting or refreshing the control register, and whenever rows are to be grouped into an epic or assigned to a particular model."
resource: ./SKILL.md
tags: [session, skill]
---

## Skill Metadata

- Runtime skill: [SKILL.md](SKILL.md)
- Group: `session`
- Origin: local
- Notes: Brought in from the 2026-08 claude.ai fetch at `metadata.version`
  2.33.0. Rendering-only skill; the register protocol (when a register is
  emitted, what an action means, how rows close) lives in the user's
  instructions, not here. Successor in lineage to the global `control-block`
  skill — it renames the artefact (`action-register.html` → `control-register.html`)
  and adds an outbox, epic header rows, model assignment and per-row verdict
  buttons. The two are **not** reconciled in this repo: the global
  `control-block` skill and its `action-register.html` protocol are unchanged.
  Bundled resources: `REFERENCE.md`, `CHANGELOG.md`, `assets/template.html`,
  `scripts/*.js` (`register.js`, `verify.js`, `checks.js`, `verify.test.js`),
  `tests/mutations.js`, and six ADRs under `docs/adr/`.
