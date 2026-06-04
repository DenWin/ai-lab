# 02 — ChatGPT (Projects) self-description

Status: ready-for-human

## What to build

Run inside a ChatGPT session with Projects enabled. Paste the prompt from `artifacts/TEMPLATE.md`
and have ChatGPT fill out all 10 questions. Key things to verify:

- Instruction surfaces: custom instructions, system prompt, project instructions — which wins?
- Does it read `AGENTS.md`? (Expected: only if uploaded to the project, not auto-loaded from repo)
- File access: none / sandbox / project files?
- MCP: available? how configured?
- Memory: what persists across sessions?
- Disk locations: server-side only or any local paths?

Save result to `docs/harnesses/chatgpt.md`. Update `TEMPLATE.md` table.

## Acceptance criteria

- [ ] All 10 questions answered with `?` for uncertain cells
- [ ] Cross-compatibility section completed
- [ ] `docs/harnesses/chatgpt.md` committed
- [ ] `TEMPLATE.md` known-harnesses table updated

## Blocked by

None.
