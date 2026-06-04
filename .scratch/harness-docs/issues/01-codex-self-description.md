# 01 — Codex CLI self-description

Status: ready-for-human

## What to build

Run inside a Codex CLI session. Paste the prompt from `artifacts/TEMPLATE.md` and have Codex
fill out all 10 questions. Key things to verify:

- Does it auto-load `AGENTS.md`? (Expected yes — this is the primary cross-compat position)
- Shell/git access: full? sandboxed? gated?
- Skill equivalent: does it have a slash-command or prompt-file mechanism?
- Hooks equivalent: any lifecycle events?
- Disk locations on Windows / macOS / Linux

Save result to `docs/harnesses/codex.md`. Update `TEMPLATE.md` table.

## Acceptance criteria

- [ ] All 10 questions answered with `?` for uncertain cells (no guessing)
- [ ] Cross-compatibility section completed, especially re: `AGENTS.md`
- [ ] `docs/harnesses/codex.md` committed
- [ ] `TEMPLATE.md` known-harnesses table updated

## Blocked by

None.
