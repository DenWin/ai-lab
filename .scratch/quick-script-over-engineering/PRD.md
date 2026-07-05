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

Why the model reaches for the full script even when "quick" is stated — the guidance in the
[global CLAUDE.md artifact](../incorporate-global-claude-setup/artifacts/global-CLAUDE.md) (§8 Code
Generation, §9 Diagnostic Scripts, §10 PowerShell) was read to trace each symptom to a cause:

1. **"Quick" carries no teeth — it isn't defined as a mode.** §9 exists ("Quick & Dirty") but is
   scoped to *diagnostic/inspection* scripts and their **output convention**; it relaxes input
   validation and structure but **never lists the scaffolding to drop**. So a *quick helper* (not a
   probe) isn't recognized as covered by §9 at all, and §8's "maximum rigor" default wins. The word
   "quick" maps to no concrete suppression rule, so it's ignored.

2. **Rigor is the default and nothing overrides it.** §8 + §10 make `#Requires`, `[CmdletBinding()]`,
   and `param()` the "correct" PowerShell idiom; with no rule saying "quick ⇒ omit these," the model
   applies the idiom unconditionally. The scaffolding is emitted as hygiene, not because the task
   needs it.

3. **`#Requires -Version 7.0` is emitted as a badge, not a claim.** Version pinning is treated as good
   practice rather than an assertion that must be justified by an actual 7.0-only feature. No rule ties
   the pin to a real dependency, so it appears reflexively.

4. **Form and depth aren't independent axes.** When a follow-up constrains *form* ("I need both as
   actionable executables"), the model conflates that with a request to *reduce depth* and strips
   substance. Nothing in the guidance says form-constraints and depth are orthogonal.

5. **The output convention invites result/interpretation conflation.** §9's "optional: Description,
   incl. the meaning of the found content" permits appending meaning **inline** with the value
   (`-> 1  (1 = enabled)`), so it's ambiguous whether the value is `1` or the literal string. §9 never
   requires separating raw value / verdict / legend into distinct columns.

**Fix:** add a first-class *quick mode* trigger with an explicit suppression list, make version-pinning
conditional on a real dependency, state that form-constraints don't reduce depth, and tighten the
output convention to separate value / verdict / legend. Drafted as a concrete patch in
[artifacts/proposed-CLAUDE-guidance.md](artifacts/proposed-CLAUDE-guidance.md) — it targets the **live
global CLAUDE.md** (outside this repo); paste it there, or fold it in via
[[incorporate-global-claude-setup]] when the global config is hoisted into the repo.

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
