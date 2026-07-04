# PRD — Public-repo compliance: attribution, profile exposure, quick hardening wins

Status: needs-triage
Origin: fable (Claude Fable 5 repo review, 2026-07-04)

Quick capture — iron out in scratch-planning, don't action yet.

## Problem Statement

The repo is already **PUBLIC** (`github.com/DenWin/ai-lab`), but the items gated on "before
publishing" never ran:

1. **Third-party attribution.** [import-upstream-skills](../import-upstream-skills/PRD.md) says to
   add upstream's LICENSE (e.g. `THIRD-PARTY/mattpocock-skills.LICENSE`) "before publishing, since
   the repo redistributes adapted copies of his work." Vendored copies are committed (mattpocock
   skills under `shared/skills/` + `.scratch/*/artifacts/`; MIT-licensed `claude-video` under
   `.scratch/add-watch-skill/artifacts/`), and the repo is live.
2. **Profile exposure.** The personal behavioral profile
   ([anthropic/claude-ai/instructions/profile.md](../../anthropic/claude-ai/instructions/profile.md))
   and committed `.scratch` history are public. Probably fine — but it should be a conscious
   decision, not a side effect of `gh repo create`.
3. **Free hardening wins.** [[harden-github-repo]] is still needs-triage, and its central open
   question ("does a remote exist? is it public?") is now answered. Secret scanning, push
   protection, and branch protection are free for public repos and shouldn't wait for the full
   hardening design.

## Solution

_Proposed — refine in triage:_

- Add `THIRD-PARTY/` attribution files for all vendored upstream content; audit `.scratch/*/artifacts/`
  for anything else redistributed.
- Explicit go/no-go on public visibility of the profile and scratch history (alternative: flip repo
  to private until [[harden-github-repo]] lands).
- Pull the free GitHub toggles forward (may simply be executed as the first slice of
  [[harden-github-repo]] rather than a separate build — decide in triage whether to merge).

## Further Notes

- Related: [[harden-github-repo]] (settings/Actions side), [[import-upstream-skills]] (where the
  attribution requirement was first recorded).
- _Created by Claude Fable 5 via /planning:scratch._
