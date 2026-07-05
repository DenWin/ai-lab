# Proposed global CLAUDE.md guidance — "quick" as a real mode

Target: the **live global CLAUDE.md** (`~/.claude/CLAUDE.md` / `%USERPROFILE%\.claude\CLAUDE.md`) —
not a repo file. A committed snapshot lives at
`../../incorporate-global-claude-setup/artifacts/global-CLAUDE.md`; when that scratch hoists the
global config into the repo, fold these edits in there instead of pasting by hand.

The changes below address the five root causes in the PRD. Section numbers follow the current
artifact (§8 Code Generation, §9 Diagnostic Scripts, §10 PowerShell).

---

## Edit 1 — §8 Code Generation: make version-pinning a justified claim, not a badge

Add under the "minimum surface" bullets:

> - Do not emit capability/version declarations as hygiene. Include `#Requires -Version <x>` (or an
>   equivalent runtime/version pin) **only** when the script actually uses a feature that needs it;
>   name that feature in a comment. A pin is a claim of dependency, not a badge — no dependency, no pin.

## Edit 2 — new §9a "Quick helper mode" (a sibling to §9, for scripts that aren't diagnostics)

§9 covers diagnostic/inspection scripts and their output convention. "Quick" helpers that *do* a
small task need their own trigger, because today nothing tells the model what scaffolding to drop.

> ## 9a. Quick Helper Mode (triggered by "quick" / "quick and dirty" / "throwaway" / "one-off")
>
> **The words are a mode switch, not flavour text.** When the request is scoped as quick, default to
> the smallest thing that runs — then stop.
>
> - **Suppress by default** (add back only when the task genuinely needs it, and say why):
>   - `#Requires` lines
>   - `[CmdletBinding()]` / `param()` blocks and advanced-function ceremony
>   - dry-run / `-Apply` / `-WhatIf` toggles, config surfaces, help banners
>   - functions/modules — keep it flat and procedural
> - **Keep (non-negotiable even when quick):** fail fast on infrastructure failure with a meaningful
>   message; "not present" is a valid result; separate output from logging (§9).
> - **Scope is about form, not depth.** A quick request lowers *ceremony*, not *correctness*. If a
>   follow-up constrains **form** ("give me both as runnable pwsh", "inline it"), change the form —
>   do **not** strip substance or downgrade a good answer. Form and depth are independent axes.
> - If you think the rigor is genuinely warranted, offer it as a one-line follow-up ("want the
>   hardened version?") — don't pre-build it.

## Edit 3 — §9 output convention: separate value / verdict / legend (never inline)

Replace the "Output must be neutral" block's optional-description bullet with:

> - Output must be neutral — do not assume the current context as a basis:
>   - `Requested Counter/Property/Path -> Value` (the **raw** value, verbatim, nothing appended)
>   - if the value's validity is knowable, add a separate **verdict** column/field (e.g. `OK` /
>     `NOT OK`) — interpret it, don't make the reader decode a legend
>   - never inline the legend with the value (`-> 1  (1 = enabled)` is ambiguous about whether the
>     value is `1` or the string `1  (1 = enabled)`); if a legend is genuinely needed, put it on its
>     own line/column
>
> Example (aligned columns, value ≠ verdict ≠ legend):
>
> ```
> Source       Property            Value      Verdict
> Registry     LongPathsEnabled    1          OK
> GroupPolicy  Enable              (not set)  n/a
>
> Legend: LongPathsEnabled — 1 = enabled, 0/absent = disabled
> ```

---

## Verification (once pasted into the live CLAUDE.md)

Re-run the two originating prompts and confirm the guidance now fires:

- `give me a quick script to "free up space" on my local copy of onedrive`
  → expect: no `#Requires`/`[CmdletBinding()]`/`param()`, no `-Apply` toggle unless asked.
- `give me a quick and dirty recon script to check <long-path support>`
  → expect: flat probe, buffered single flush, value/verdict/legend separated per Edit 3.
- Follow-up `I need both as actionable executables within pwsh`
  → expect: form changes to runnable pwsh, **depth preserved** (no reduction to two `reg` one-liners).
