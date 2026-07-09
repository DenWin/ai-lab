# PRD — Bake general agent-behavior rules into the Claude Code instructions (CLAUDE.md)

Status: needs-triage

Quick capture — iron out in scratch-planning, don't action yet. These are **general, cross-project**
rules (not ai-lab specific). Home: the global Claude Code instructions (`~/.claude/CLAUDE.md`; repo
copy will live at `instructions/anthropic/claude-code/CLAUDE.md` per `incorporate-global-claude-setup`).

Rough rules to encode (not final):

- **Plan/capture over execute.** Default to capturing/planning, not doing; confirm before doing
  anything beyond what was literally asked.
- **Capture, don't execute, when told to scratch.** "Update the scratch" (change capture content) ≠
  "do the scratch" (implement). When told to scratch an idea, only record it in the PRD (single source
  of truth) — don't assign IDs, move files, build, decide, or rank.
- **At most a brief reasoning question.** The only acceptable follow-up after a scratch request is a
  **1-2 question, no-detail** ask to elaborate the reasoning — never execution/decision questions.
- **Scratch workflow.** New thought → quick offload into funnel/undefined (minimal detail);
  scratch-planning = iron out (discuss, answer, resolve contradictions, rank), **not** implement;
  revisit → if no longer understood, `won't_fix`.
- **Use `git mv` for tracked files.** When moving/renaming a git-tracked file inside a real git repo,
  use `git mv` (not a plain filesystem move) so the rename is staged correctly.

Related: `../backlog-enhancements/PRD.md` (funnel stage + browse-by-status, concepts 5/6).
