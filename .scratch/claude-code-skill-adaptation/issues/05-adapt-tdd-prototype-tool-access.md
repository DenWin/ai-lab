# 05 — Give tdd & prototype real tool access

Status: ready-for-agent

## What to build

Adapt the two agentic coding skills to use Claude Code's tools:

- `tdd` — run tests via shell in the red-green-refactor loop; read repo files, CONTEXT.md, and ADRs
  directly; keep the on-demand stack rules (PowerShell/SQL/Python/C#).
- `prototype` — build and run the throwaway terminal/UI prototype in-tool rather than describing it.

Both keep the capability-contract fallback for no-shell harnesses.

## Acceptance criteria

- [ ] `tdd` drives a real failing→passing test cycle via shell on a trivial target
- [ ] `prototype` builds and runs a minimal prototype end-to-end in-tool
- [ ] Stack-specific resources still load; conversational fallback preserved
- [ ] Each verified via `/session:write-a-skill`; `setup-repo.ps1 -SkipHooks` re-run

## Blocked by

- 01 (classification)
