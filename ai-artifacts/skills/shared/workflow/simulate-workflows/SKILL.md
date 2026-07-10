---
name: simulate-workflows
version: 1.0.0
description: Run the repository's GitHub quality workflow checks locally in a deterministic sequence with a bundled script, so no push/PR or GitHub Actions minutes are required. Use when user wants to run, simulate, reproduce, create, update, or improve local workflow checks for Python, PowerShell, and repo linting.
---

# Simulate Workflows

Run a deterministic local sequence that mirrors this repo's workflow checks for:

- Python quality checks
- PowerShell quality checks
- Repo lint checks (YAML/Markdown/JSON)
- Coding policy validation

Execution model:

- GitHub Actions execution is defined in `.github/workflows/*.yml` and runs shell `run:` blocks there.
- Local execution is defined in `.github/workflows/scripts/execute-workflow-*.ps1`.
- Each local `execute-workflow-*` script runs the workflow shell logic in the same order.
- The simulator orchestrates all workflow executors via `.github/workflows/scripts/execute-all-workflow-scripts.ps1`.

The script is the source of execution order and commands; the agent should invoke it, not reinterpret
the workflow logic.

## Quick start

From repo root:

```powershell
pwsh scripts/simulate-workflows.ps1 -InstallTools
```

Then on later runs (without reinstalling tools each time):

```powershell
pwsh scripts/simulate-workflows.ps1
```

To run against a diff range instead of full tracked-file scan:

```powershell
pwsh scripts/simulate-workflows.ps1 -UseChangedFiles
```

## Workflow

1. Run the script from the repo root (or pass `-RepoRoot`).
2. Let the script execute checks in fixed order and fail fast on first error.
3. Fix findings and rerun until it exits cleanly.

## Capability contract

- If shell/filesystem is available: execute the bundled script directly.
- If shell is unavailable: provide the exact script path and commands for the user to run manually.
