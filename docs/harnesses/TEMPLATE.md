# Harness Self-Description — Template & Prompt

Use this when setting up a new harness or verifying an existing one. Paste the prompt below
into a session running inside the target harness and ask it to fill out the checklist.
Keep the result as `docs/harnesses/<harness-slug>.md`.

Cross-compatibility notes (what works across harnesses, e.g. `AGENTS.md`) go in a dedicated
section within each harness doc — not in a shared file — so each harness is self-contained.

---

## Prompt to paste into the target harness

> I am setting up a multi-harness AI workspace (Claude Code, Copilot, Codex, ChatGPT, etc.)
> and I need you to document yourself as a harness — from the inside, with concrete facts you
> actually know to be true. Answer the 10 questions below as precisely as possible.
> Mark anything uncertain as `?` rather than guessing. Answer from inside your own context
> (you know your own load mechanics better than any external observer).
>
> **Harness:** [fill in — e.g. "Claude Code CLI / Desktop Code tab", "GitHub Copilot VS Code",
> "ChatGPT with Projects", "Codex CLI", "Cowork Desktop"]
>
> 1. **Instruction surfaces + precedence** — Which files/settings/UI fields are read, and which
>    one wins on conflict? List them in load order. Mark anything unverified as `?`.
>
> 2. **Storage split** — Which artifacts are repo-scoped (committed), machine-local (gitignored,
>    per-machine), and user-global (account-bound, all repos)? List each tier with examples.
>
> 3. **Disk locations** — Concrete paths on Windows, macOS, Linux for each tier from question 2.
>    Use actual paths, not placeholders.
>
> 4. **Artifact mapping** — For each artifact type below, state whether it is native (first-class),
>    emulated (works but not the primary mechanism), or unsupported:
>    - Instruction docs (AGENTS.md, CLAUDE.md, custom-instructions, etc.)
>    - Skills / slash commands
>    - Subagents
>    - Hooks (pre/post-tool, session-start, etc.)
>    - MCP servers
>    - Output styles
>    - Settings / permissions
>    - Plugins / bundles
>
> 5. **Cross-compatibility** — Which of your artifact types have a cross-harness equivalent?
>    Specifically: do you read `AGENTS.md`? What is your preferred cross-harness instruction file?
>    What degrades gracefully when running a capability-contract skill designed for a richer harness?
>
> 6. **Composition mechanics** — Which of these are supported: `applyTo` / path-scoped rules,
>    `@import` / include / transclusion, merge directives, frontmatter metadata? State exact
>    mechanisms with examples.
>
> 7. **Activation + load model** — For each artifact type: auto-loaded every turn, command-invoked
>    (`/name`), description-match (model decides), user-pick at runtime, or other?
>
> 8. **Validation** — How do you (or the user) verify that instructions/skills/hooks actually
>    loaded? Diagnostics, `/context`, test prompts, logs?
>
> 9. **Security / secrets boundary** — Where must secrets never be stored in your harness?
>    How are secrets injected (env vars, vault, OAuth tokens managed externally)?
>
> 10. **Capability limits / notable absences** — What can you NOT do that a sibling harness can?
>     Focus on: shell/git access, background/scheduled tasks, write access to user's filesystem,
>     persistent cross-session state, MCP availability.
>
> After answering, add a brief **"What I need from instruction files"** section: what makes
> instructions work well for you (length, format, placement, things to avoid).

---

## Known harness docs in this repo

| Harness | File | Source | Last verified |
|---|---|---|---|
| claude.ai (web/mobile/Desktop Chat) | [claude-ai.md](claude-ai.md) | Self-described (inside claude.ai) | 2026-06 |
| Claude Code + Cowork (Anthropic desktop) | [claude-code.md](claude-code.md) | Claude Code self-described; Cowork section from shared-engine knowledge | 2026-06 |
| GitHub Copilot (VS Code) | [copilot.md](copilot.md) | Self-described (inside Copilot) | 2026-06 |
| Codex CLI | *(pending)* | — | — |
| ChatGPT (Projects) | *(pending)* | — | — |

## Format note

Each harness doc answers the 10 questions, then has a **Cross-compatibility** section and a
**What I need from instruction files** section. No other structure required. Mark uncertain
cells `?` — a precise `?` is better than a confident wrong answer.
