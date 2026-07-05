# PRD — Quick-script requests get over-engineered

Status: ready-for-human (root cause analysed + guidance drafted 2026-07-05 — paste into live CLAUDE.md)

## Problem Statement

When the user asks for a **"quick"** or **"quick and dirty"** helper, Claude reliably
returns a full production-grade PowerShell script instead. The word "quick" is the
explicit signal being ignored.

Observed pattern across two real exchanges:

- Prompt: `give me a quick script to "free up space" on my local copy of onedrive`
  → got `#Requires -Version 7.0`, `[CmdletBinding()]`, a `param()` block, and a
  `-Apply`/dry-run mode.
- Prompt: `give me a quick and dirty recon script to check [long-path support]`
  → got the same `#Requires`/`[CmdletBinding()]`/param scaffolding plus a 5-section probe.

The user generally **appreciates** that rigor — but not when the request was scoped to a
quick helper. The scaffolding is unrequested fluff for a throwaway task.

**Core ask of this scratch:** analyse *why* the model defaults to the full-fledged script
even when "quick" is stated, so the root cause can be addressed (likely via global
CLAUDE.md guidance under the existing "Diagnostic Scripts" / "Code Generation" sections).

## Root-cause analysis (2026-07-05)

The full root-cause analysis (five causes traced to the global CLAUDE.md guidance) is a durable
finding, kept where it survives this scratch:
**[docs/findings/2026-07-05-quick-script-over-engineering.md](../../docs/findings/2026-07-05-quick-script-over-engineering.md)**.

In brief: "quick" is not defined as a mode (§9 covers only diagnostics and never lists the
scaffolding to drop); rigor is the unconditional default (§8/§10); `#Requires` is a reflexive badge
not a justified claim; form and depth are conflated on follow-ups; and §9's output convention invites
inlining the legend with the value. The **fix** is drafted as a concrete patch in
[artifacts/proposed-CLAUDE-guidance.md](artifacts/proposed-CLAUDE-guidance.md), targeting the live
global CLAUDE.md — apply it there, or fold it in via [[incorporate-global-claude-setup]].

## Solution — candidate symptoms to address

1. **"Quick" is not honored as a mode switch.** A quick/quick-and-dirty request should
   suppress `#Requires`, `[CmdletBinding()]`, and `param()` scaffolding by default.

2. **Don't claim requirements that don't exist.** Only emit `#Requires -Version 7.0` when
   the script *actually* uses a 7.0-only feature. Appreciated ≠ warranted.

3. **Don't degrade a good first answer on a follow-up.** Stripping the second long-path
   answer down to two `reg` one-liners only because the user said "I need both as
   actionable executables within pwsh" was an over-correction — the follow-up constrained
   *form*, not depth.

4. **StringBuilder output is good, but the formatting is messy** (keep the buffered
   single-flush pattern — that part is right):
   - Conflates the *actual result* with the *interpretation* on one line, so it's
     ambiguous whether `LongPathsEnabled` holds `1` or the literal string
     `1  (1 = enabled)`:
     ```
     Registry  LongPathsEnabled -> 1  (1 = enabled)
     GroupPolicy Enable         -> (not set)  (1 = enabled)
     ```
   - Expected/valid values should be **interpreted into a verdict** (e.g. OK / not OK)
     rather than appended as a raw legend.
   - If a legend is genuinely needed (`1, 2 or 3 are OK; 4 is not`), keep it in a
     separate column/line — never inline with the value it describes.

## Further Notes

- Relevant existing guidance: global CLAUDE.md §8 "Code Generation" (minimum surface) and
  §9 "Diagnostic Scripts (Quick & Dirty)" (output convention, StringBuilder flush). The
  gap is that these are not being triggered by the word "quick".
- Verbatim prompts and both before/after script samples are preserved in the originating
  conversation.
- _Created by /planning:scratch._
