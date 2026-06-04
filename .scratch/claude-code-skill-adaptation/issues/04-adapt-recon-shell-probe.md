# 04 — Adapt recon to run its own probe (shell)

Status: ready-for-agent

## What to build

`recon` currently generates a read-only probe script and asks the user to paste the output back. In
Claude Code the agent can run the probe itself. Add the agentic path: generate the probe, run it via
shell, read the output directly, then generate the real code against ground truth — while keeping the
conversational fallback (emit probe + ask for paste) for harnesses without a shell. Express this as a
capability contract, not a harness branch.

## Acceptance criteria

- [ ] Agentic path: probe is generated, executed read-only, and its output consumed in-tool
- [ ] Fallback path preserved for no-shell harnesses
- [ ] Probe remains strictly read-only (no state changes)
- [ ] `RECIPES.md` still referenced correctly; `sync-skills.ps1` re-run

## Blocked by

- 01 (classification)
