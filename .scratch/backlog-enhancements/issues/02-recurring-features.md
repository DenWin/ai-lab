# 02 — Recurring features

Status: ready-for-human

## What to build

Support recurring work. The original PRD's `recurrence` frontmatter (e.g. `2weeks`, `1month`)
defines the cadence. When a recurring feature is marked `done`, it reappears with a fresh due date
(`done-date + recurrence`).

Recommended mechanism (**reset in place**): on detecting a `done` feature with `recurrence != none`,
`scratch-plan` sets `status` back to `ready-for-human`, sets `due = done-date + recurrence`, bumps
`updated`, and appends a line to a `## Recurrence log` section in the PRD recording the completion.
Keeps history without spawning folders.

Alternative to weigh: spawn `.scratch/<slug>-<YYYY-MM-DD>/` per occurrence (full per-occurrence
history, but clutters `.scratch` and `BACKLOG.md`).

Trigger: checked when `scratch-plan` runs (no daemon/background process).

## Acceptance criteria

- [ ] `recurrence` frequency read from PRD frontmatter
- [ ] Marking a recurring feature `done` → it re-opens with `due = done-date + recurrence` on next `scratch-plan`
- [ ] Completion history preserved (recurrence log or per-occurrence folder, per decision)
- [ ] Non-recurring features (`recurrence: none`) unaffected
- [ ] `scratch-plan` documents the reset behavior so it isn't surprising

## Blocked by

- 01 (frontmatter / `recurrence` field must exist)
