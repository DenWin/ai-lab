# Throwaway — Stack recipes for probes

Select by the current context. These are anchors for *what to query and how to emit it* — keep them as small as the question allows. The output convention and read-only bar from [SKILL.md](SKILL.md) apply to every recipe here.

Each recipe probes three fact classes: **existence** (is it there?), **shape** (name, type, version), and **behavioral settings** — config that leaves names and types untouched but silently changes whether otherwise-correct code behaves correctly. The last is the most under-probed because nothing about the schema looks wrong; probe it only for the settings the requested code actually depends on.

A fourth concern cuts across all three — **preconditions** (SKILL.md mode C): the conditions under which a probed fact is even *meaningful*. The session/environment the probe ran in (interactive console vs. remote/non-interactive), and any domain the code will *select from* being non-empty. Emit these as their own fields up front, so a result is never read in a context whose validity you only guessed at afterward.

## SQL (MS-SQL)

Read structure from catalog views, scoped to named objects; return one result set, ideally `FOR JSON`.

- Version/edition: `SELECT @@VERSION;` · `SERVERPROPERTY('ProductVersion')`, `SERVERPROPERTY('Edition')`.
- Columns + types: `sys.columns` joined to `sys.types` (or `INFORMATION_SCHEMA.COLUMNS`) filtered to the target table(s) — name, type, length, nullability, identity/computed.
- Object existence/definition: `OBJECT_ID(N'schema.obj')`, `sys.sql_modules.definition` for views/procs/functions.
- Keys/indexes when the code depends on them: `sys.indexes`, `sys.foreign_keys`.
- Behavioral settings (silent-correctness): collation at server/db/column (`SERVERPROPERTY('Collation')`, `DATABASEPROPERTYEX(db,'Collation')`, `sys.columns.collation_name`); `compatibility_level` (`sys.databases`); `is_read_committed_snapshot_on`; session `QUOTED_IDENTIFIER`/`ANSI_NULLS` state if the code touches filtered indexes, indexed views, or computed columns; per-table temporal/trigger/Always-Encrypted flags (`sys.tables.temporal_type`, `sys.triggers`, `sys.columns.encryption_type`).
- Emit: wrap the final select in `FOR JSON PATH` so the output pastes back as one JSON block.
- Crossing the data bar: `SELECT DISTINCT TOP (50) <col> ...` for enum discovery; `SELECT COUNT(*)` for cardinality; never the full table. The cap is on **rows** — within a bounded slice (a keyed lookup, the top-n), take the columns you'll need rather than re-querying; a wide projection of a bounded row is capture-wide, not a dump.
- Self-check: record a row `COUNT` for any set you'll iterate *before* deriving from it (mode B) — `0` rows and "query never ran" are otherwise indistinguishable. Note `FOR JSON` emits an **empty string** for a zero-row result, which pastes back as nothing; carry an explicit count or an `IS NULL`/`COALESCE` sentinel alongside it so empty ≠ absent. If batching several probes, give each its own named result/key so one failing batch can't silently swallow the rest (mode A). Mode C: when the code will *select from* a set — pick one of N rows — that count is a precondition, not a detail; emit it as its own field so `N=0` reads as "nothing to pick from," never as a silent empty pick.

## PowerShell

**Probes must be portable; production code is not.** A recon probe runs on the *target* host, which may only have Windows PowerShell 5.1 — so the probe must run on 5.1 *and* 7. Do **not** put `#Requires -Version 7.0` in a probe; a 7.0 requirement fails on the very box whose version you're discovering. Capture `$PSVersionTable.PSVersion` as a probe fact, then write the *real* (production) code PS7-native once the discovered version permits it.

```powershell
$ErrorActionPreference = 'Stop'
$report    = [ordered]@{}
$attempted = 0
$failed    = [System.Collections.Generic.List[string]]::new()
$fatal     = $null

# Per-fact guard: failure becomes a recorded value, never an absent key (mode A).
function Probe([string]$Name, [scriptblock]$Block) {
    $script:attempted++
    try   { $report[$Name] = & $Block }
    catch { $report[$Name] = "ERROR: $($_.Exception.Message)"; $script:failed.Add($Name) }
}

# A genuine precondition (e.g. opening a connection) goes OUTSIDE the guard, so it
# stops the fact-gathering dead — and is recorded as _meta.fatal rather than thrown away.
try {
    Probe 'PSVersion'      { $PSVersionTable.PSVersion.ToString() }
    Probe 'ModulePresent'  { [bool](Get-Module -ListAvailable Some.Module) }
    Probe 'TargetRowCount' { @(Get-Thing).Count }   # 0 is a real answer; record before deriving (mode B)
    Probe 'SessionContext' { [ordered]@{             # mode C: is the result even valid for THIS session?
        Interactive = [Environment]::UserInteractive
        SessionName = $env:SESSIONNAME               # 'Console' = local console; 'RDP-Tcp#n' = remote
    } }
}
catch { $fatal = "FATAL: $($_.Exception.Message)" }

# Integrity footer, then the one emission — reached whether or not a precondition broke.
$report['_meta'] = [ordered]@{
    attempted = $attempted
    captured  = $attempted - $failed.Count
    failed    = $failed
    fatal     = $fatal            # $null on a clean run; a string means the run stopped early
}
$return = $report | ConvertTo-Json -Depth 8   # depth high enough to avoid silent truncation
$return
```

**Why this deviates from `$return = & { ... }`.** The general form assigns the
block's *result*. Here the value is not a result: the probe's emission guarantee
has to survive a precondition that throws, which is why the earlier form flushed
the report from a `finally`. Wrapping that in an assignment would make the
guarantee depend on whether output raised during unwinding still reaches the
assignment — not a property to build a probe on. Converting the hard stop into
data (`_meta.fatal`) removes the question: control flow reaches the last two
statements on every path, so the report always emits, the failure is visible in
the result rather than only in the error stream, and single emission holds with
`$return` as the final statement. If the loud abort is also wanted, a trailing
`if ($fatal) { throw $fatal }` writes to the error stream only and is not a
second emission.

The constructs above (`[ordered]@{}`, `ConvertTo-Json -Depth`, `Get-Module -ListAvailable`, `Get-Command`, `Test-Path`, `$ErrorActionPreference='Stop'`, the `function`/`try`/`catch` shape) are all 5.1-compatible. The `Probe` guard + the `catch`-to-`fatal` conversion + the `_meta` footer satisfy the self-check: a failed fact is recorded (not absent), the report always emits, `attempted ≠ captured` flags a drop, and a non-null `fatal` says the run stopped before the end. Progress via `Write-Progress`, or `Write-Verbose` with `$VerbosePreference = 'Continue'` set — there is no `[CmdletBinding()]` here to take a `-Verbose` switch, and a probe is pasted once, not invoked with arguments; known permission noise may be silenced with `-ErrorAction SilentlyContinue`, but a precondition failure outside the guard must stop.

Mode C (precondition): display, COM, and WMI results are session-conditional. `[Environment]::UserInteractive` + `$env:SESSIONNAME` are 5.1-portable and side-effect-free — no P/Invoke, no `Add-Type` (which ConstrainedLanguage would block anyway). An `EnumDisplayDevices`/GDI adapter count of 0 means "monitor absent" *only* on an interactive console session; under RDP or a service the same 0 means the API yielded nothing there. Probe the session as its own field and read the count against it — never infer "were you remote?" after the count already looks wrong.

Capture wide, select in the view: on a **bounded** WMI/CIM object, project nothing away — `ConvertTo-Json` the whole instance set so fields you didn't pre-pick are present for the follow-up. Compute a convenient view *from* the raw, carry both:

```powershell
Probe 'eedid' {
    $all = @(Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorRawEEDIDV1Block -EA Stop)
    $hit = @($all | Where-Object InstanceName -match $Match)
    [ordered]@{
        instance_count = $all.Count          # mode B/C: domain size, before any pick
        matched        = $hit.Count -gt 0     # mode C: empty match ≠ failed probe
        view = @($hit | ForEach-Object { [ordered]@{ block_id = $_.BlockId; byte_len = @($_.BlockContent).Count } } | Sort-Object block_id)
        raw  = $hit | Select-Object *          # every field incl. BlockContent bytes — the actual payload
    }
}
```

`view` is the readable summary; `raw` keeps the EDID bytes you'll need next so a CRU/override step needs no re-run. If `raw` is bulky and the session is interactive, `($report.eedid.raw | ConvertTo-Json -Depth 8) | Set-Clipboard` offstage instead of printing it — but on non-console/remote (the mode-C field), `Set-Clipboard` no-ops, so keep it in the JSON or write a file.

The counter-case — **unbounded** sources get a cardinality cap, not a field cut: `Get-WinEvent -FilterHashtable @{LogName='System'} -MaxEvents 50`, `Get-ChildItem -Depth 2`. Cap *how many*, then capture each survivor's full fields.

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

Self-check: the `|| echo "not present"` idiom conflates *absent* with *errored* (mode A) — capture each fact's exit status (`rc=$?`) and emit it beside the value, or distinguish the two sentinels. Record the size of any list before looping it (mode B). With `set -e`, wrap fact collection so one failure doesn't abort before the final `printf`/`jq` flush (a `trap '... ' EXIT` that emits the buffer works); a genuine precondition failure should still exit non-zero with a named reason. If hand-building JSON via `printf`, escape values — an unescaped quote/newline yields invalid JSON the consumer can't parse. Mode C: if behavior differs by session (cron/non-interactive vs. login shell — `$PATH`, locale, and `TERM` all change), probe `[[ -t 0 ]]` and `case $- in *i*)` and emit them as fields, rather than discovering a cron-only failure after the fact.

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

Self-check: wrap each fact in its own `try` and record an explicit error string on failure rather than letting an exception abort the run (mode A) — `None` alone is overloaded (not-importable vs. errored vs. legitimately empty), so use distinct sentinels or a `{"value":..., "status":...}` shape. Emit the report from a `finally` so a partial result still prints. Record `len(x)` of any collection before iterating it (mode B). Include an integrity footer (attempted vs. captured) as in the PowerShell recipe. Mode C: if correctness depends on runtime context (the right venv active, a required env var present), probe it as a field up front — `sys.prefix != sys.base_prefix`, `os.environ.get(...)` — not after an import quietly resolves against the wrong site-packages.

Behavioral settings (silent-correctness): `sys.executable`/`sys.prefix` vs `sys.base_prefix` (right venv?); package **major** version, not just presence (pandas 1→2, numpy 1→2, SQLAlchemy 1.4→2.0, pydantic v1→v2 change generated calls); `open()` default encoding if reading/writing text (`locale.getpreferredencoding()` — cp1252 on Windows pre-UTF-8-default; pass `encoding="utf-8"` explicitly); for the pyodbc + MS-SQL path, the ODBC **driver name/version** (a fact outside Python — "ODBC Driver 18" defaults `Encrypt=yes`/`TrustServerCertificate=no`, breaking connections that worked on Driver 17).
