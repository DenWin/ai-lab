# PRD — Finalize and improve account-wide profile

Status: ready-for-human

The live source-of-truth is Settings → Instructions for Claude (claude.ai / Claude Desktop Chat).
The repo copy is `ai-artifacts/instructions/anthropic/claude-ai/profile.md` — edit here, paste there.

Two versions are in `artifacts/`:

- `profile-current.md` — the version refined in a claude.ai session; live as of 2026-06
- `profile-prior.md` — the previous version; use as counterpart to identify what changed and whether
  any prior formulation was actually sharper

## Problem Statement

The profile went through one refinement pass in claude.ai and landed in a good place, but a prior
version exists that may have had tighter phrasing in some rules. The current version is longer and
more prose-heavy in places; the prior was more compressed. Before treating the current version as
final, compare the two and consciously decide which formulation wins per rule — rather than
defaulting to "newer = better."

Additionally, the profile has not yet been evaluated against the `INSTRUCTION-EVAL.md` rubric
(see `.scratch/eval-skill-harness/` for that work). The improvement pass here is a human/editorial
review; the behavioral eval is a separate session.

## Solution

Diff the two versions rule by rule. For each rule where they differ, decide: is the current
version more precise, or did compression in the prior version lose something, or did the current
version introduce unnecessary verbosity? Apply the better formulation back to
`ai-artifacts/instructions/anthropic/claude-ai/profile.md` and paste the final result into Settings.

## User Stories

1. As a Claude user, I want my profile to be as concise as possible without losing precision, so
   instructions are cheap in context and unambiguous to the model.
2. As a Claude user, I want any rule that was sharper in the prior version preserved, so the
   refinement pass didn't accidentally dilute something that worked.
3. As a Claude user, I want the profile ready to pass through the behavioral eval harness once
   `.scratch/eval-skill-harness/` is built, so its efficacy (not just quality) is verified.

## Implementation Decisions

- **Source of truth:** `ai-artifacts/instructions/anthropic/claude-ai/profile.md`; paste into Settings when updated
- **Diff axis:** per-rule comparison, not whole-file; the structure (§1–§9 + Facts) is settled
  <!-- [RE-CONFIRM] "structure is settled" was decided in a claude.ai session; confirm before the diff pass. -->

- **Compression bias:** prefer the shorter formulation when both are equally precise
- **Scope:** editorial pass only — no behavioral eval here (that is eval-skill-harness)
- **Prior version:** `artifacts/profile-prior.md` is reference, not the target; don't regress to it wholesale

## Out of Scope

- Behavioral evaluation (`.scratch/eval-skill-harness/`)
- Adding new rules or sections
- Changing the structure (§1–§9 + Facts)

## Further Notes

- The CLAUDE.md at `~/.claude/CLAUDE.md` is a different file (global Claude Code instructions);
  do not conflate with this profile
- The profile header "Paste into: Settings → Instructions for Claude" should stay in
  `ai-artifacts/instructions/anthropic/claude-ai/profile.md` as a placement reminder but must be stripped before pasting
