# PRD — Public-repo compliance: attribution, profile exposure, quick hardening wins

Status: done (items 1 + 3 done 2026-07-04; item 2 decided 2026-07-05 — see Progress)
Origin: fable (Claude Fable 5 repo review, 2026-07-04)

Quick capture — iron out in scratch-planning, don't action yet.

## Problem Statement

The repo is already **PUBLIC** (`github.com/DenWin/ai-lab`), but the items gated on "before
publishing" never ran:

1. **Third-party attribution.** [import-upstream-skills](../import-upstream-skills/PRD.md) says to
  add upstream's LICENSE (historically tracked in a dedicated third-party attribution folder) "before publishing, since
   the repo redistributes adapted copies of his work." Vendored copies are committed (mattpocock
   skills under `ai-artifacts/skills/shared/` + `.scratch/*/artifacts/`; MIT-licensed `claude-video` under
   `.scratch/add-watch-skill/artifacts/`), and the repo is live.
2. **Profile exposure.** The personal behavioral profile
   ([ai-artifacts/instructions/anthropic/claude-ai/profile.md](../../ai-artifacts/instructions/anthropic/claude-ai/profile.md))
   and committed `.scratch` history are public. Probably fine — but it should be a conscious
   decision, not a side effect of `gh repo create`.
3. **Free hardening wins.** [[harden-github-repo]] is still needs-triage, and its central open
   question ("does a remote exist? is it public?") is now answered. Secret scanning, push
   protection, and branch protection are free for public repos and shouldn't wait for the full
   hardening design.

## Solution

*Proposed — refine in triage:*

- Add attribution files for all vendored upstream content; audit `.scratch/*/artifacts/`
  for anything else redistributed.
- Explicit go/no-go on public visibility of the profile and scratch history (alternative: flip repo
  to private until [[harden-github-repo]] lands).
- Pull the free GitHub toggles forward (may simply be executed as the first slice of
  [[harden-github-repo]] rather than a separate build — decide in triage whether to merge).

## Progress (2026-07-04)

- ✅ **Item 1 — attribution:** both upstreams verified MIT.
  Attribution files were created in a dedicated third-party folder at the time, with license copies for vendored sources
  (`mattpocock-skills.LICENSE`, `bradautomates-claude-video.LICENSE`) plus a notice map. Exact
  upstream checkpoints for skills live in each skill's `METADATA.md`, not in summary docs.
- ✅ **Item 3 — free hardening wins:** secret scanning, push protection, and Dependabot alerts
  enabled via `gh api`. **Branch protection deliberately NOT enabled** — it would block the current
  direct-to-main workflow; decide it together with [[gated-work-prd-issue-approval]] (which wants a
  PR flow anyway) inside [[harden-github-repo]].
- ✅ **Item 2 — decided 2026-07-05: keep public, after a scrub.** Decision: `keep-public`. Before
  confirming, a redaction audit swept the personal profile
  ([ai-artifacts/instructions/anthropic/claude-ai/profile.md](../../ai-artifacts/instructions/anthropic/claude-ai/profile.md))
  and the full `.scratch/` tree (+ the committed config artifacts) for anything personal or sensitive.

  **Audit scope & result (nothing required redaction):**
  - Emails — none real; only a test fixture `a@b.com` in `docs/testing-methodologies-foundation.adoc`.
  - Real name / identity — no `Dennis`/`Winter` strings; `DenWin` appears only as the public
    `github.com/DenWin` repo owner.
  - Secrets/tokens — none (`ghp_`/`gho_`/`sk-`/`AKIA`/private-key/`password=`/`token=` patterns all clean).
  - Machine paths — only placeholders (`%USERPROFILE%`, `$env:USERPROFILE`) and the Claude container
    path `/home/claude`; no real Windows/Linux user directories.
  - IPs / hostnames / MAC addresses — none.

  The profile is a deliberate professional/behavioral profile (guidelines + a general skills/career
  "Facts about me" block) the user is comfortable exposing. The `private` alternative is therefore
  not exercised. Re-run this sweep before each future public push (the same greps).

## Further Notes

- Related: [[harden-github-repo]] (GitHub Actions/settings side), [[import-upstream-skills]] (where the
  attribution requirement was first recorded).
- *Created by Claude Fable 5 via /planning:scratch.*
