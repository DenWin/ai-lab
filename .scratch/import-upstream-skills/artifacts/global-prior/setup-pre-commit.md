---
name: setup-pre-commit
description: Set up pre-commit hooks for PowerShell, Markdown, AsciiDoc, and SQL repositories using the pre-commit framework. Use when user wants to add pre-commit hooks, set up linting/formatting on commit, configure PSScriptAnalyzer, markdownlint, vale, or sqlfluff.
upstream-author: mattpocock
upstream-repo: https://github.com/mattpocock/skills
upstream-path: skills/misc/setup-pre-commit/SKILL.md
upstream-commit: 62f43a18177be6ec82da242e59ffbc490a4c22ea
---

# Setup Pre-Commit Hooks

Sets up the [pre-commit](https://pre-commit.com/) framework with hooks tailored for PowerShell, Markdown, AsciiDoc, and SQL.

## Prerequisites

`pre-commit` is Python-based and works on Windows with Python installed:

```powershell
pip install pre-commit
```

Or with winget / scoop:

```powershell
winget install pre-commit
# or
scoop install pre-commit
```

## Steps

### 1. Check what file types are present

Scan the repo for which types are actually used:

```powershell
Get-ChildItem -Recurse -Include *.ps1,*.psm1,*.psd1 | Measure-Object  # PowerShell
Get-ChildItem -Recurse -Include *.md                 | Measure-Object  # Markdown
Get-ChildItem -Recurse -Include *.adoc,*.asciidoc    | Measure-Object  # AsciiDoc
Get-ChildItem -Recurse -Include *.sql                | Measure-Object  # SQL
```

Only include hooks for file types that are actually present in the repo.

### 2. Install tool dependencies

Install only what is needed based on the file types found.

| File type  | Hook tool        | Install command                   |
| ---------- | ---------------- | --------------------------------- |
| PowerShell | PSScriptAnalyzer | `Install-Module PSScriptAnalyzer` |
| Markdown   | markdownlint-cli | `npm install -g markdownlint-cli` |
| AsciiDoc   | vale             | `winget install errata-ai.vale`   |
| SQL        | sqlfluff         | `pip install sqlfluff`            |

For vale, also initialize the config after install:

```powershell
vale sync
```

### 3. Create `.pre-commit-config.yaml`

Compose from the applicable sections below:

```yaml
repos:
  # ── PowerShell ────────────────────────────────────────────────────────────
  - repo: local
    hooks:
      - id: psscriptanalyzer
        name: PSScriptAnalyzer
        language: powershell
        entry: pwsh -NoProfile -Command "
          $files = $args;
          $results = $files | ForEach-Object { Invoke-ScriptAnalyzer -Path $_ -Severity Warning,Error };
          if ($results) { $results | Format-Table -AutoSize; exit 1 }
        "
        types: [file]
        files: \.(ps1|psm1|psd1)$

  # ── Markdown ──────────────────────────────────────────────────────────────
  - repo: https://github.com/igorshubovych/markdownlint-cli
    rev: v0.43.0    # check https://github.com/igorshubovych/markdownlint-cli/releases for latest
    hooks:
      - id: markdownlint
        args: [--fix]

  # ── AsciiDoc (vale prose linter) ─────────────────────────────────────────
  - repo: local
    hooks:
      - id: vale
        name: vale
        language: system
        entry: vale
        types: [file]
        files: \.(adoc|asciidoc)$

  # ── SQL ───────────────────────────────────────────────────────────────────
  - repo: https://github.com/sqlfluff/sqlfluff
    rev: 3.3.1    # check https://github.com/sqlfluff/sqlfluff/releases for latest
    hooks:
      - id: sqlfluff-lint
      - id: sqlfluff-fix
        args: [--force]
```

**Omit any section for file types not present in the repo.**

### 4. Create tool config files (if missing)

**`.markdownlint.jsonc`** — only if no markdownlint config exists:

```jsonc
{
  // MD013: line length — disabled, long lines are acceptable in docs
  "MD013": false,
  // MD033: inline HTML — disabled, useful in docs
  "MD033": false,
}
```

**`.vale.ini`** — only if no vale config exists:

```ini
StylesPath = .vale/styles
MinAlertLevel = suggestion

[*.adoc]
BasedOnStyles = Vale
```

Then sync styles:

```powershell
vale sync
```

**`.sqlfluff`** — only if no sqlfluff config exists. Ask the user which SQL dialect they use (e.g. `tsql`, `ansi`, `postgres`):

```ini
[sqlfluff]
dialect = tsql

[sqlfluff:indentation]
indent_unit = space
tab_space_size = 4
```

### 5. Initialize hooks

```powershell
pre-commit install
```

This installs the hook into `.git/hooks/pre-commit`.

Optionally also install for commit-msg linting:

```powershell
pre-commit install --hook-type commit-msg
```

### 6. Run against all files (initial pass)

```powershell
pre-commit run --all-files
```

Review failures, apply auto-fixes where available, manually fix the rest. Expect some noise on first run — tune the configs before committing.

### 7. Verify

- [ ] `.pre-commit-config.yaml` exists
- [ ] Tool configs exist for each linter used
- [ ] `pre-commit run --all-files` passes (or known violations are suppressed)
- [ ] `.git/hooks/pre-commit` exists

### 8. Commit

Stage all created config files and commit:

```powershell
git add .pre-commit-config.yaml .markdownlint.jsonc .vale.ini .sqlfluff
git commit -m "Add pre-commit hooks (PSScriptAnalyzer, markdownlint, vale, sqlfluff)"
```

This will run through the new hooks — a good smoke test.

## Notes

- `pre-commit` caches environments; first run per hook is slow, subsequent runs are fast
- `sqlfluff --fix` is aggressive — review its changes before committing
- For vale, pick a style pack matching your writing style (`Microsoft`, `Google`, `Vale`) from https://vale.sh/hub/
- To skip hooks temporarily: `git commit --no-verify` (use sparingly)
- To update all hooks to latest versions: `pre-commit autoupdate`
