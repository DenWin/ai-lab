# Workflow Execution Model

This repository uses two complementary execution processes.

## 1) GitHub Actions execution

- Runs on GitHub runners.
- Defined by workflow files in `.github/workflows/*.yml`.
- Executes shell steps declared directly in each workflow `run:` block (for example the diff-range step that calls `Resolve-DiffRange.ps1`).

## 2) Local execution

- Runs on a developer machine.
- Defined by workflow executors in `.github/workflows/scripts/execute-workflow-*.ps1`.
- Each `execute-workflow-*` script executes the same workflow shell logic in the same order for its workflow.

## Global simulator

- `scripts/simulate-workflows.ps1` is the local entry point.
- It calls `ai-artifacts/skills/shared/workflow/simulate-workflows/scripts/Invoke-LocalWorkflowSimulation.ps1`.
- The simulator then executes `.github/workflows/scripts/execute-all-workflow-scripts.ps1`.
- The master script runs all `execute-workflow-*` scripts in deterministic order.

## Current local workflow executors

- `execute-workflow-policy-check.ps1`
- `execute-workflow-python-quality.ps1`
- `execute-workflow-python-tests.ps1`
- `execute-workflow-powershell-quality.ps1`
- `execute-workflow-powershell-tests.ps1`
- `execute-workflow-powershell-runtime-compat.ps1`
- `execute-workflow-shell-quality.ps1`
- `execute-workflow-shell-tests.ps1`
- `execute-workflow-config-lint.ps1`
