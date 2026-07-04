# PRD — Evaluate incorporating the prior AI-config set into the repo

Status: needs-triage

Quick capture — iron out in scratch-planning, don't action yet.

## Problem Statement

A set of prior AI-configuration artifacts was parked in `.temp/AI/` and is now vendored to
[artifacts/AI/](artifacts/AI/). Evaluate whether any of it should be incorporated into this repo (and
in what form) versus discarded as superseded.

Contents (`artifacts/AI/Claude/Powershell/`):

- **CLAUDE.md** (87 lines) — behavioral guidelines to reduce LLM coding mistakes. Overlaps heavily
  with the current global `~/.claude/CLAUDE.md`; likely an earlier version of the same.
- **POWERSHELL-old.md** (870 lines) — a pwsh 7+ best-practices reference. The `-old` suffix suggests
  it is already superseded; confirm whether a newer version exists and whether the repo wants a
  PowerShell reference doc at all.
- **Project-Instructions.md** (53 lines) — a PowerShell "project instructions" role/prompt.

## Solution

_Fill in during triage._ Open questions to resolve:

- Which artifacts are genuinely additive vs. already covered by the global `CLAUDE.md` and the repo's
  existing skills/docs?
- For anything kept: what is its home and format? (e.g. a PowerShell reference under `docs/`, folded
  into a skill, or distilled into the global guidelines.) Note the user prefers AsciiDoc for docs.
- Is `POWERSHELL-old.md` superseded by a newer copy elsewhere? Don't import a stale `-old` file.
- Anything not incorporated is discarded — the `artifacts/` copy is the only remaining record.

## Further Notes

_Created by /planning:scratch._
