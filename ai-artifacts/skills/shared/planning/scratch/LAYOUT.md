# .scratch — Layout

The canonical definition of the `.scratch/` folder structure. Other skills reference this file
rather than restating the conventions.

## Feature folder

Every feature lives in its own folder: `.scratch/<feature-slug>/`

```text
.scratch/
  BACKLOG.md                        ← ranked index of all features (repo-level, one file)
  <feature-slug>/
    PRD.md                          ← required; problem, solution, user stories, decisions
    issues/
      <NN>-<slug>.md                ← one file per issue; numbered from 01
    artifacts/                      ← optional; upstream source, prior versions, reference files
```

## PRD.md

Required fields near the top:

```markdown
# PRD — <title>

Status: <needs-triage | ready-for-human | ready-for-agent | in-progress | done | wontfix>

<body>
```

The `Status:` line is the triage state. Update it directly — no separate state machine file.

## issues/<NN>-<slug>.md

```markdown
# <NN> — <title>

Status: <needs-triage | ready-for-human | ready-for-agent | in-progress | done | wontfix>

## What to build
## Acceptance criteria
## Blocked by
```

## artifacts/

Supporting *inputs* only — reference material that feeds the work, **never the deliverable itself**.
Deliverables (a skill, script, report, or durable finding) live in their proper repo home; the rule
and the deliverable→home table are in the folder guide `.scratch/AGENTS.md`. No required structure;
common sub-folders:

- `artifacts/<upstream-name>/` — upstream source files (when `.temp/` is gitignored)
- `artifacts/global-prior/` — prior installed versions to mine for local customizations

## BACKLOG.md

One backlog for the entire `.scratch/` tree. Lives at `.scratch/BACKLOG.md`.

Rankings (priority, importance, effort, score) live in BACKLOG.md — **not** in individual PRDs.
The `/planning:scratch-plan` skill updates BACKLOG.md. The `/planning:scratch` skill appends to it
when quick-capturing a new feature.

### BACKLOG.md template (for initial creation)

```markdown
# .scratch Backlog

Ranked by score = P × I × E. Run `/planning:scratch-plan` to calibrate or update.
See `skills/planning/scratch/RANKING.md` for the formula.

| Rank | Feature | Priority | Importance | Effort | Score | Status |
|------|---------|----------|------------|--------|-------|--------|
```
