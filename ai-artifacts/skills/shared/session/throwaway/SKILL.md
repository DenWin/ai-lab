---
name: throwaway
description: Rules for code that is run once and discarded - probes that survey a system, one-off fixes, scratch deploy steps. Covers the throwaway-vs-keeper test, ceremony, single emission, parameter/execution split, and the probe handshake that grounds generated code in facts instead of recall. Use when writing, generating, revising, or reviewing a one-off script or snippet in any stack; when about to recite a schema, version, module, cmdlet or path not verified this session; or when the user says "recon", "throwaway", "quick script", "check my environment first", or "help me help you".
metadata:
  version: 2.1.0
  supersedes: recon 1.2.0
---

# Throwaway

Code that stops existing once its output has been read. It gets **less ceremony
and more rigour** than code that stays: no tests will ever back it, so every
guarantee has to hold on first run.

**The test is not length or complexity: does this file still exist after the
output has been read?**

|                                                    | Ceremony | Single emission | Fail fast | TDD      |
| -------------------------------------------------- | -------- | --------------- | --------- | -------- |
| **Throwaway** - run once, read, discarded          | none     | required        | required  | no       |
| **Keeper** - saved, re-run, or run by someone else | full     | required        | required  | required |

No ceremony = no parameter block, no `[CmdletBinding()]`, no `#Requires`, no
usage text, no preamble. Lean throwaway when unstated, but read the signals - a
named file, a path in a repo, parameterised by nature, or "save" / "reuse"
means keeper. Mixed signals → ask. Promotion to keeper is the user's call and
means **rebuilt test-first**; never retrofit tests and call it TDD.

## Quick start

Most throwaway scripts read rather than write. If this one reads - "which
version", "does that column exist", "what is installed" - it is a probe: go to
[PROBES.md](PROBES.md) before writing a line. If it changes something, stay
here and give it a dry-run mode.

## Workflows

### Any throwaway script

- [ ] **Single emission.** One pasteable unit, exactly one emission. Multiple
      statements are assigned to a variable, and that variable is emitted on
      its own as the last statement: `$return = & { ... }`, then `$return` -
      so the result stays addressable and can be piped onward without a second
      variant. Nothing inside the block may write to the success stream except
      the value being returned. Two or more top-level value-producing
      statements is wrong. No `Format-*`, no raw objects mid-stream. Throwaway
      relaxes ceremony only, never output discipline.
- [ ] **Split out values the user supplies.** A path, server name or credential
      target goes in a short **parameter prep** block of assignments only,
      followed by the **execution** block that consumes them. Never bury an
      assignment inside the logic. The execution block asserts the values are
      set; the prep block emits nothing.
- [ ] **Fail fast** at entry: required command missing, elevation required but
      absent, output not the expected shape (assert the specific field
      extracted, not a general shape).
- [ ] **Simplest route to the data** - no script where a direct call returns it.
- [ ] **Fall back on absence** - check availability once up front, not per call
      site. "Not present" is a valid result; report it, don't fail on it.

### A throwaway that mutates

- [ ] Give it a dry-run mode and default to it.
- [ ] Report what it *would* change as its single emission.
- [ ] Probe first for anything the mutation depends on - these are the scripts
      where an assumed path or name does damage rather than just erroring.

## Notes

- Uncertainty in a throwaway is settled by a probe, not by a caveat. In a keeper
  the same uncertainty is settled by a test. Emitting code with "adjust the
  column names if they differ" is the failure this skill exists to kill.
- Neutral output: label a value only where it is not self-identifying, and never
  assume the current context as a basis.
- Progress and diagnostics go to a separate stream, never into the result.

## Details

Probe handshake, read-only bar, output contract and self-check:
[PROBES.md](PROBES.md). Per-stack probe anchors for SQL, PowerShell, Bash and
Python: [RECIPES.md](RECIPES.md).
