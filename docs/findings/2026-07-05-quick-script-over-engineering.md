# Finding — "Quick" script requests get over-engineered

- **Date:** 2026-07-05
- **Origin:** [`.scratch/quick-script-over-engineering`](../../.scratch/quick-script-over-engineering/PRD.md)
- **Type:** behavioral root-cause analysis (why the model ignores the "quick" signal)
- **Downstream action:** a drafted patch for the live global `CLAUDE.md`, to be folded in via
  [`.scratch/incorporate-global-claude-setup`](../../.scratch/incorporate-global-claude-setup/PRD.md).
- **Point-in-time artifact:** traced against the global CLAUDE.md snapshot at
  `.scratch/incorporate-global-claude-setup/artifacts/global-CLAUDE.md` (§8 Code Generation,
  §9 Diagnostic Scripts, §10 PowerShell). Not updated as that file changes.

## Symptom

When the user scopes a request as **"quick"** / **"quick and dirty"**, the model still returns a
full production-grade PowerShell script — `#Requires -Version 7.0`, `[CmdletBinding()]`, a `param()`
block, dry-run toggles. The explicit "quick" signal is ignored. The user appreciates the rigor in
general, but not when the task was scoped to a throwaway helper.

## Root cause (five, traced to the guidance)

1. **"Quick" carries no teeth — it isn't defined as a mode.** §9 exists ("Quick & Dirty") but is
   scoped to *diagnostic/inspection* scripts and their **output convention**; it relaxes input
   validation and structure but **never lists the scaffolding to drop**. A *quick helper* (not a
   probe) isn't recognized as covered by §9, so §8's "maximum rigor" default wins. "Quick" maps to no
   concrete suppression rule, so it's ignored.
2. **Rigor is the default and nothing overrides it.** §8 + §10 make `#Requires`, `[CmdletBinding()]`,
   and `param()` the "correct" PowerShell idiom; with no rule saying "quick ⇒ omit these," the model
   applies the idiom unconditionally — as hygiene, not because the task needs it.
3. **`#Requires -Version 7.0` is emitted as a badge, not a claim.** Version pinning is treated as good
   practice rather than an assertion justified by an actual 7.0-only feature. No rule ties the pin to a
   real dependency, so it appears reflexively.
4. **Form and depth aren't independent axes.** When a follow-up constrains *form* ("I need both as
   actionable executables"), the model conflates that with a request to *reduce depth* and strips
   substance. Nothing says form-constraints and depth are orthogonal.
5. **The output convention invites result/interpretation conflation.** §9's "optional: Description,
   incl. the meaning of the found content" permits appending meaning **inline** with the value
   (`-> 1  (1 = enabled)`), so it's ambiguous whether the value is `1` or the literal string. §9 never
   requires separating raw value / verdict / legend into distinct columns.

## Fix

Add a first-class *quick mode* trigger with an explicit suppression list; make version-pinning
conditional on a real dependency; state that form-constraints don't reduce depth; and tighten the
output convention to separate value / verdict / legend. The concrete patch (new §9a quick-helper
mode, §8 version-pin rule, form≠depth rule, value/verdict/legend separation) plus a verification
recipe using the two originating prompts lives at
[`.scratch/quick-script-over-engineering/artifacts/proposed-CLAUDE-guidance.md`](../../.scratch/quick-script-over-engineering/artifacts/proposed-CLAUDE-guidance.md).
It targets the **live global CLAUDE.md** (outside this repo); apply it there or fold it in via
`incorporate-global-claude-setup` when the global config is hoisted.
