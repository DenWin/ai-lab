# PRD — Complete harness self-descriptions

Status: ready-for-human

Three harnesses are documented in `docs/harnesses/`:
- `claude-ai.md` — claude.ai (self-described from inside)
- `claude-code.md` — Claude Code + Cowork combined (same engine; differences section included)
- `copilot.md` — GitHub Copilot VS Code (self-described from inside)

**Scope now — Claude's take only.** Getting each *other* harness to self-describe from inside
(Codex, ChatGPT, Cursor, …) is deferred to a later phase — that's the "Remaining harnesses" /
"Process per harness" work below. For now the deliverable is the Claude-family perspective: the
existing `claude-ai.md` / `claude-code.md`, plus Claude's own take on cross-compatibility positions
as it encounters them (see Cross-compatibility doc).

Claude's take **includes its outside view of how the other harnesses interoperate** (e.g. "Codex
auto-loads `AGENTS.md`"). Record these as Claude's **external observation**, explicitly marked as a
draft for that harness to **confirm/correct from inside** in the deferred phase — same pattern as the
"external observation by claude.ai; confirm from inside" cells in the handoff. Do not wait for the
inside session to start populating cross-compat rows.

Remaining harnesses (LATER) need a session run *inside* each one using the template in
`docs/harnesses/TEMPLATE.md`. Completed docs go back into `docs/harnesses/<slug>.md` and the
table in `TEMPLATE.md` is updated.

Reference artifacts (completed docs + handoff seed section) are in `artifacts/`.

## Remaining harnesses (LATER — deferred)

| Harness | Session needed | Notes |
|---|---|---|
| Codex CLI | Codex session | Uses `AGENTS.md` natively — key cross-compat position to verify; fill in the rest |
| ChatGPT (Projects) | ChatGPT session | Not in the handoff; start from template |
| Others as adopted | Per harness | Cursor, Cline, etc. — add when relevant |

## Process per harness (LATER — deferred)

1. Open a session inside the target harness.
2. Paste the prompt from `docs/harnesses/TEMPLATE.md` (or `artifacts/TEMPLATE.md`).
3. Have the harness fill out all 10 questions + cross-compatibility + "what I need" sections.
4. Save result to `docs/harnesses/<slug>.md`.
5. Update the Known harness docs table in `docs/harnesses/TEMPLATE.md`.

## Cross-compatibility doc

`docs/harnesses/cross-compatibility.md` is a **living document** — not a one-time summary gated on
all harnesses being documented. Update it on **each occurrence** of a cross-compatibility position:
every time a harness doc records how it interoperates with another (shared `AGENTS.md`,
skill/command portability, hook equivalents, shared instruction files, sandbox/disk-location
differences, …), add or revise the corresponding row in the same pass.

It starts from **Claude's take** (the only perspective in scope now) and accretes the other
harnesses' positions as they are documented in the deferred later phase. Relates to the
compatibility matrix in the repo-scaffold handoff.

## Blocked by

Nothing — each harness is independent.
