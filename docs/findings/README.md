# Findings

Durable, cross-cutting insights and analyses extracted from scratch work — kept **here** so they
survive the scratch that produced them. A `.scratch/<feature>/` entry is *work-tracking*: once the
feature is done (or merged and archived) its PRD stops being read, and anything of lasting value
buried inside it is effectively lost. When a scratch produces a finding worth remembering — a
root-cause analysis, a compatibility assessment, a "why does X happen" investigation — promote it to
a file here and leave a pointer from the scratch.

**Rule of thumb:** if a piece of analysis would still be useful to someone who never touches the
originating scratch, it belongs here.

Each finding is a **point-in-time artifact**: it records what was learned and what to do about it,
links back to its originating scratch, and is not rewritten as facts drift (the living state is the
[backlog](../../.scratch/BACKLOG.md) and the code).

Distinct from [`docs/reviews/`](../reviews/) — those are whole-repo point-in-time *reviews*; a
finding is a single insight or analysis with concrete downstream actions.

## Naming

`docs/findings/YYYY-MM-DD-<slug>.md` — date the finding was recorded, then the topic slug.

## Index

| Finding | Date | Origin | Downstream |
|---|---|---|---|
| [quick-script-over-engineering](2026-07-05-quick-script-over-engineering.md) | 2026-07-05 | [quick-script-over-engineering](../../.scratch/quick-script-over-engineering/PRD.md) | CLAUDE.md quick-mode patch → [incorporate-global-claude-setup](../../.scratch/incorporate-global-claude-setup/PRD.md) |
