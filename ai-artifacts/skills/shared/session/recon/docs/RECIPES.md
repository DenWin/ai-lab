# Recon — Stack recipes

Select by the current context. These are anchors for *what to query and how to emit it* — keep them as small as the question allows. The output convention and read-only bar from [SKILL.md](SKILL.md) apply to every recipe here.

Each recipe probes three fact classes: **existence** (is it there?), **shape** (name, type, version), and **behavioral settings** — config that leaves names and types untouched but silently changes whether otherwise-correct code behaves correctly. The last is the most under-probed because nothing about the schema looks wrong; probe it only for the settings the requested code actually depends on.

## SQL (MS-SQL)

Read structure from catalog views, scoped to named objects; return one result set, ideally `FOR JSON`.

- Version/edition: `SELECT @@VERSION;` · `SERVERPROPERTY('ProductVersion')`, `SERVERPROPERTY('Edition')`.
- Columns + types: `sys.columns` joined to `sys.types` (or `INFORMATION_SCHEMA.COLUMNS`) filtered to the target table(s) — name, type, length, nullability, identity/computed.
- Object existence/definition: `OBJECT_ID(N'schema.obj')`, `sys.sql_modules.definition` for views/procs/functions.
- Keys/indexes when the code depends on them: `sys.indexes`, `sys.foreign_keys`.
- Behavioral settings (silent-correctness): collation at server/db/column (`SERVERPROPERTY('Collation')`, `DATABASEPROPERTYEX(db,'Collation')`, `sys.columns.collation_name`); `compatibility_level` (`sys.databases`); `is_read_committed_snapshot_on`; session `QUOTED_IDENTIFIER`/`ANSI_NULLS` state if the code touches filtered indexes, indexed views, or computed columns; per-table temporal/trigger/Always-Encrypted flags (`sys.tables.temporal_type`, `sys.triggers`, `sys.columns.encryption_type`).
- Emit: wrap the final select in `FOR JSON PATH` so the output pastes back as one JSON block.
- Crossing the data bar: `SELECT DISTINCT TOP (50) <col> ...` for enum discovery; `SELECT COUNT(*)` for cardinality; never the full table.
- Self-check: record a row `COUNT` for any set you'll iterate *before* deriving from it (mode B) — `0` rows and "query never ran" are otherwise indistinguishable. Note `FOR JSON` emits an **empty string** for a zero-row result, which pastes back as nothing; carry an explicit count or an `IS NULL`/`COALESCE` sentinel alongside it so empty ≠ absent. If batching several probes, give each its own named result/key so one failing batch can't silently swallow the rest (mode A).

## PowerShell

**Probes must be portable; production code is not.** A recon probe runs on the *target* host, which may only have Windows PowerShell 5.1 — so the probe must run on 5.1 *and* 7. Do **not** put `#Requires -Version 7.0` in a probe; a 7.0 requirement fails on the very box whose version you're discovering. Capture `$PSVersionTable.PSVersion` as a probe fact, then write the *real* (production) code PS7-native once the discovered version permits it.

```powershell
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$report    = [ordered]@{}
$attempted = 0
$failed    = [System.Collections.Generic.List[string]]::new()

# Per-fact guard: failure becomes a recorded value, never an absent key (mode A).
function Probe([string]$Name, [scriptblock]$Block) {
    $script:attempted++
    try   { $report[$Name] = & $Block }
    catch { $report[$Name] = "ERROR: $($_.Exception.Message)"; $script:failed.Add($Name) }
}

# A genuine precondition (e.g. opening a connection) goes OUTSIDE the guard so it stops hard.
try {
    Probe 'PSVersion'      { $PSVersionTable.PSVersion.ToString() }
    Probe 'ModulePresent'  { [bool](Get-Module -ListAvailable Some.Module) }
    Probe 'TargetRowCount' { @(Get-Thing).Count }   # 0 is a real answer; record before deriving (mode B)
}
finally {
    # Integrity footer + single flush — runs even if a step threw.
    $report['_meta'] = [ordered]@{
        attempted = $attempted
        captured  = $attempted - $failed.Count
        failed    = $failed
    }
    $report | ConvertTo-Json -Depth 8   # depth high enough to avoid silent truncation
}
```

The constructs above (`[ordered]@{}`, `ConvertTo-Json -Depth`, `Get-Module -ListAvailable`, `Get-Command`, `Test-Path`, `$ErrorActionPreference='Stop'`, the `function`/`try`/`finally` shape) are all 5.1-compatible. The `Probe` guard + `finally` flush + `_meta` footer satisfy the self-check: a failed fact is recorded (not absent), the report always emits, and `attempted ≠ captured` flags a drop. Progress via `Write-Verbose`/`Write-Progress`; known permission noise may be silenced with `-ErrorAction SilentlyContinue`, but a precondition failure outside the guard must stop.

Behavioral settings (silent-correctness): `$PSVersionTable.PSEdition` (Desktop vs Core gates .NET-type/module availability); `$ExecutionContext.SessionState.LanguageMode` (ConstrainedLanguage under WDAC/AppLocker blocks `Add-Type`, .NET types, COM); default file encoding if the code writes files (5.1 `Out-File`=UTF-16LE, `Set-Content`=ANSI; 7=UTF-8 no BOM — always pass `-Encoding` explicitly across versions); `[cultureinfo]::CurrentCulture` if parsing/formatting numbers or dates.

## Bash

```bash
set -euo pipefail
# progress -> stderr; result -> stdout as one JSON block
ver=$(psql --version 2>/dev/null || echo "not present")
has_jq=$(command -v jq >/dev/null 2>&1 && echo true || echo false)
printf '{"psql_version":"%s","jq_present":%s}\n' "$ver" "$has_jq"
```

Use `command -v` for tool presence, `--version` for versions, `[[ -e ]]` for paths. Prefer `jq` to assemble JSON if present; otherwise `printf` a flat object. All progress to stderr, the JSON block alone to stdout.

Self-check: the `|| echo "not present"` idiom conflates *absent* with *errored* (mode A) — capture each fact's exit status (`rc=$?`) and emit it beside the value, or distinguish the two sentinels. Record the size of any list before looping it (mode B). With `set -e`, wrap fact collection so one failure doesn't abort before the final `printf`/`jq` flush (a `trap '... ' EXIT` that emits the buffer works); a genuine precondition failure should still exit non-zero with a named reason. If hand-building JSON via `printf`, escape values — an unescaped quote/newline yields invalid JSON the consumer can't parse.

Behavioral settings (silent-correctness): actual interpreter (`readlink -f /bin/sh` — dash, not bash, on Debian/Ubuntu, where bashisms like `[[ ]]`/arrays/`set -euo pipefail` break) and `$BASH_VERSION` (associative arrays, `mapfile`, `${x^^}` need 4.0+; macOS ships 3.2); GNU vs BSD coreutils if using `sed -i`, `date`, `readlink -f`, `grep -P`, `stat` (probe e.g. `sed --version` — BSD has no `--version`); `$LC_COLLATE`/`$LANG` if sorting/comparing (`C` vs `*.UTF-8` changes `sort`/`uniq`/`[[ < ]]` order).

## Python

```python
import importlib.util, importlib.metadata as md, sys, json
report = {"python": sys.version.split()[0]}
for pkg in ("pandas", "pyodbc"):
    spec = importlib.util.find_spec(pkg)
    report[pkg] = md.version(pkg) if spec else None   # None == not importable
print(json.dumps(report, indent=2))                   # single flush to stdout
```

Import availability via `importlib.util.find_spec` (no side-effect import); installed version via `importlib.metadata.version`; interpreter via `sys.version`. Diagnostics to `stderr`/`logging`, the JSON to stdout.

Self-check: wrap each fact in its own `try` and record an explicit error string on failure rather than letting an exception abort the run (mode A) — `None` alone is overloaded (not-importable vs. errored vs. legitimately empty), so use distinct sentinels or a `{"value":..., "status":...}` shape. Emit the report from a `finally` so a partial result still prints. Record `len(x)` of any collection before iterating it (mode B). Include an integrity footer (attempted vs. captured) as in the PowerShell recipe.

Behavioral settings (silent-correctness): `sys.executable`/`sys.prefix` vs `sys.base_prefix` (right venv?); package **major** version, not just presence (pandas 1→2, numpy 1→2, SQLAlchemy 1.4→2.0, pydantic v1→v2 change generated calls); `open()` default encoding if reading/writing text (`locale.getpreferredencoding()` — cp1252 on Windows pre-UTF-8-default; pass `encoding="utf-8"` explicitly); for the pyodbc + MS-SQL path, the ODBC **driver name/version** (a fact outside Python — "ODBC Driver 18" defaults `Encrypt=yes`/`TrustServerCertificate=no`, breaking connections that worked on Driver 17).
