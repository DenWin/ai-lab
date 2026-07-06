# 02 — Where to place the central (DRY) config

Status: ready-for-human

**Settled:** centralized, DRY config is the right call — shared config (tracker, triage labels, domain
knowledge) lives in ONE place and every skill reads it, rather than each skill carrying its own copy
(which drifts). The open question is **where** it lives.

> **[RE-CONFIRM]** The "centralized DRY config" premise was settled in a prior session. Confirm it
> still holds before the grill-me on placement (A/B/C) — if it doesn't, the placement question is moot.

First, separate two things that get lumped together as "domain knowledge":

- **Domain language / glossary + architectural decisions** — what the project *is about* (ubiquitous
  terms, ADRs). Consumed by `diagnose`, `improve-codebase-architecture`, `to-issues`, `to-prd`.
  Natural home: **`CONTEXT.md`** (+ `docs/adr/`) at the repo root — the conventional place, and what
  Matt's `domain.md` points to.
- **Operational config** — *how this repo runs*: which issue tracker, which triage-label vocabulary.
  Consumed by `to-issues`, `to-prd`, `triage`, and the `check-skill-updates` filer. This is NOT domain
  language; it's wiring. It should not live in `CONTEXT.md`.

## What to build

Decide the home for the **operational config**, then create it and point the skills at it. Options:

| Option | Where | Pros | Cons |
| --- | --- | --- | --- |
| A. AGENTS.md block | `## Agent skills` section in root `AGENTS.md` | Always loaded; cross-harness; one obvious file | Bloats the always-in-context file; prose, not structured |
| B. AGENTS.md pointer + detail files | short block in `AGENTS.md` → `docs/agents/{issue-tracker,triage-labels}.md` | Keeps `AGENTS.md` lean; structured per concern; read on demand | Skills must know to open the detail file |
| C. Dedicated config file | `.agents/config.yml` (or similar) | Machine-readable, single parse | New convention; skills parse it; less human-friendly |

Recommendation: **B** — a thin `## Agent skills` block in `AGENTS.md` (pointer + one-liners, cheap to
keep always-loaded) that links `docs/agents/issue-tracker.md` and `docs/agents/triage-labels.md` for
the detail. Domain language stays in `CONTEXT.md` + `docs/adr/`. This is Matt's shape, minus the
monolithic setup skill: the files are hand-editable, and skills just read the known paths — no
`setup-matt-pocock-skills` needed (drop it, or replace with a minimal `init` that only scaffolds these
files on first run).

Run a `/session:grill-me` pass to confirm B vs A/C before building (the handoff flags this as shaping
every agentic skill).

## Acceptance criteria

- [ ] grill-me pass done; placement decision (A/B/C) recorded with rationale
- [ ] Operational-config home created: `docs/agents/issue-tracker.md` (default: local-markdown `.scratch/`) + `docs/agents/triage-labels.md`
- [ ] Domain-language home confirmed: `CONTEXT.md` (+ `docs/adr/`), separate from operational config
- [ ] `AGENTS.md` `## Agent skills` block points to the above (if B/A)
- [ ] `setup-matt-pocock-skills` resolved: dropped or replaced by a minimal `init` — not imported as-is
- [ ] `to-issues` / `to-prd` / `triage` / `check-skill-updates` read these paths, no per-skill copies

## Note — domain docs are a *soft* dependency (from `understand-scratch-skill` §3a)

The planning cluster reads `CONTEXT.md` + `docs/adr/` for the domain glossary, and neither exists in
the repo today. That is **non-blocking**: the upstream `domain.md` explicitly says to "proceed
silently if absent" (the docs are created lazily by `/session:grill-me` when terms/decisions actually
resolve). So this issue can scaffold the *operational* config without waiting on domain docs — just
confirm the `CONTEXT.md`/`docs/adr/` home so the skills know where to look once it exists.

## Blocked by

None to start the grill-me. Gates the planning-cluster import (04).
