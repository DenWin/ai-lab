# Working in `.scratch/`

`.scratch/` is this repo's committed local-markdown issue tracker. Read this before creating or
editing anything here.

## What `.scratch/` is

A **vehicle for capturing and tracking ideas** — one folder per feature
(`.scratch/<feature-slug>/PRD.md` + optional `issues/`, `artifacts/`), indexed by the ranked
`BACKLOG.md`. Capture with `/planning:scratch`; rank with `/planning:scratch-plan`.

- Structural layout + file templates → the `scratch` skill's
  [LAYOUT.md](../shared/skills/planning/scratch/LAYOUT.md)
- Ranking formula → [RANKING.md](../shared/skills/planning/scratch/RANKING.md)

## Working rules

**Capture ≠ execute.** When asked to "scratch" an idea, only record it (Status: `needs-triage`, TBD
backlog row) — do not implement, rank, decide, or restructure. Act only when explicitly asked against
a specific scratch.

**Deliverables live outside the scratch.** A scratch tracks an *idea*; the working output it
produces — a skill or script, a report, a durable finding, any shippable output — is a **deliverable**
and belongs in its proper repo home, with the PRD linking to it. `artifacts/` holds only *supporting
inputs* (upstream snapshots, prior drafts, sample inputs) — **never the deliverable**.

| Deliverable | Home (not the scratch) |
| --- | --- |
| Skill / tool | `shared/skills/<group>/<name>/` (or a `<vendor>/<harness>/` skills dir) |
| Report / durable finding / review | `docs/` — `docs/findings/`, `docs/reviews/`, … |
| Instructions / settings / hooks | their harness-scoped home (`<vendor>/<harness>/…`) |

**Don't hand-maintain rankings.** `BACKLOG.md` order and scores are produced by
`/planning:scratch-plan`; flipping a single status cell is fine, re-ranking is the skill's job.

---

_This is the first per-folder `AGENTS.md` in the repo. Whether to add folder guides across other
significant subtrees is gated on the hypothesis test in
[`agents-md-folder-guides`](agents-md-folder-guides/PRD.md) — this file is a deliberate single
instance (it houses a decided convention), not a rollout._
