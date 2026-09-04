# Changelog

## [2.1.0] - single emission tightened, probe recipe reconciled

- Single emission now prescribes the shape, not just the count: multiple
  statements are assigned to a variable and that variable is emitted alone as
  the last statement (`$return = & { ... }`, then `$return`). `@( ... )` and a
  bare `& { ... }` produced a value that could only be read, not addressed - a
  second, differently-shaped variant had to be written the moment the result
  needed piping onward. The block is also barred from writing anything to the
  success stream except the returned value.
- The PowerShell probe recipe no longer emits from `finally`. The `finally`
  existed to guarantee the report even when a precondition threw, so the value
  was a side effect of unwinding rather than the block's result and did not
  convert mechanically. A precondition failure is now caught and recorded as
  `_meta.fatal`, after which control reaches the footer and the single emission
  on every path. This keeps the guarantee without depending on whether output
  raised during unwinding survives an assignment - behaviour the recipe should
  not rest on. The recipe carries the reason inline so the deviation is not
  read as an oversight.
- Resolved a standing self-contradiction: the recipe opened with
  `[CmdletBinding()]` and an empty `param()`, which SKILL.md forbids outright
  for throwaway code. RECIPES.md gives way - both lines are gone. Follow-on:
  the progress note now says `Write-Verbose` needs `$VerbosePreference` to be
  set, since there is no longer a `-Verbose` switch to pass.

## [2.0.0] - renamed from `recon`, scope widened

- Renamed `recon` → `throwaway`. The rules it carried are throwaway-script rules,
  not probe-specific ones: a keeper settles the same uncertainty with tests, so
  the probe discipline only ever applied to code that is run once.
- SKILL.md is now the throwaway-vs-keeper test, ceremony table, single emission,
  parameter/execution split, fail fast, and the dry-run requirement for a
  mutating one-off.
- The probe handshake, read-only bar, output contract and self-check moved
  verbatim to PROBES.md, reached when the script reads rather than writes -
  which is most of them.
- RECIPES.md carried over unchanged.
- `recon` remains a trigger word in the description; nothing that matched the old
  skill stops matching.

## [1.2.0] and earlier

See the `recon` skill history.
