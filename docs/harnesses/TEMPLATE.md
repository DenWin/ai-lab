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
> actually know to be true. Answer the 16 questions below as precisely as possible.
> Mark anything uncertain as `?` rather than guessing. You know your own load mechanics better
> than any external observer, but your training data has a cutoff and this product ships
> continuously — do not answer from memory alone. Do the ground-truth check below first, and
> treat anything it surfaces that you didn't expect as something to investigate, not omit.
>
> **Harness:** [fill in — e.g. "Claude Code CLI / Desktop Code tab", "GitHub Copilot VS Code",
>
> > "ChatGPT with Projects", "Codex CLI", "Cowork Desktop"]
>
> **Ground-truth check (do this before answering anything else):**
>
> - If you have filesystem access: list the actual contents of your primary config directory
>   one level deep, at both project and user-global scope (e.g. `.claude/`, `~/.claude/`,
>   `.cursor/`, `.codex/`, `.github/`). For every file or folder you find that you cannot
>   immediately explain from first-hand knowledge, stop and investigate it (read it, check its
>   own docs) before writing the artifact-mapping answer in Q4 — don't silently skip it because
>   it's unfamiliar.
> - If you have web/docs search: check your vendor's current official documentation for artifact
>   types (skills, rules, hooks, subagents, workflows, memory, or equivalents) before finalizing
>   Q4 and Q6. A feature that shipped after your training cutoff will not surface from recall no
>   matter how carefully you introspect — only a live check catches it.
> - If neither capability is available, answer from memory as before, but say so explicitly in
>   the evidence metadata (Q11) rather than implying the answer was ground-truth verified.
>
> 1. **Instruction surfaces + precedence** — Which files/settings/UI fields are read, and which
>    one wins on conflict? List them in load order. Mark anything unverified as `?`.
>    For each surface, explain the concept so a different harness can understand it without
>    prior product-specific knowledge.
>    If the concept is universal (for example, a general instruction file), a short description
>    is enough. If it is harness-specific or non-universal, add extra explanation or a small
>    example. Do not rely on unexplained vendor-specific jargon.
> 2. **Storage split** — Which artifacts are repo-scoped (committed), machine-local (gitignored,
>    per-machine), and user-global (account-bound, all repos)? List each tier with examples.
> 3. **Disk locations** — Concrete paths on Windows, macOS, Linux for each tier from question 2.
>    Use actual paths, not placeholders.
> 4. **Artifact mapping** — For each artifact type below, state whether it is native (first-class),
>    emulated (works but not the primary mechanism), or unsupported:
>    - Instruction docs (AGENTS.md, CLAUDE.md, custom-instructions, etc.)
>    - Rules / conditional instructions (topic-scoped, optionally path-gated)
>    - Skills / slash commands
>    - Subagents
>    - Subagent persistent memory (state that survives across a subagent's invocations)
>    - Hooks (pre/post-tool, session-start, etc.)
>    - MCP servers
>    - Output styles
>    - Settings / permissions
>    - Plugins / bundles
>    - Dynamic workflows / orchestration scripts (multi-subagent automation saved as a command)
> 5. **Cross-compatibility** — Which of your artifact types have a cross-harness equivalent?
>    Specifically: do you read `AGENTS.md`? What is your preferred cross-harness instruction file?
>    What degrades gracefully when running a capability-contract skill designed for a richer harness?
> 6. **Composition mechanics** — Which of these are supported: `applyTo` / path-scoped rules,
>    `@import` / include / transclusion, merge directives, frontmatter metadata? State exact
>    mechanisms with examples.
> 7. **Activation + load model** — For each artifact type: auto-loaded every turn, command-invoked
>    (`/name`), description-match (model decides), user-pick at runtime, or other? Include context
>    budget behavior when known: truncation, retrieval, prefix caching, and whether files are
>    re-read or cached.
> 8. **Validation** — How do you (or the user) verify that instructions/skills/hooks actually
>    loaded? Diagnostics, `/context`, test prompts, logs? Include at least one precedence/conflict
>    check when the harness supports multiple instruction layers.
> 9. **Security / secrets boundary** — Where must secrets never be stored in your harness?
>    How are secrets injected (env vars, vault, OAuth tokens managed externally)? If known, state
>    what repo/chat/tool content may be sent to remote services, logs, telemetry, or connectors.
> 10. **Capability limits / notable absences** — What can you NOT do that a sibling harness can?
>     Focus on: shell/git access, background/scheduled tasks, write access to user's filesystem,
>     persistent cross-session state, MCP availability.
> 11. **Evidence metadata** — For each answer above, include: verification date, harness/app
>     version or extension version, and confidence (`high` / `medium` / `low`). If unknown,
>     use `?`.
> 12. **Command + argument mapping** — How are reusable workflows invoked in your harness
>     (slash commands, prompts, files, UI actions)? Show how arguments are passed and what
>     fallback pattern to use when no native command system exists. Include prompting patterns for
>     reusable workflows, not just literal commands.
> 13. **Capability contract** — Classify each as `required`, `optional`, or `unavailable`:
>     filesystem read, filesystem write, shell/terminal execution, network access, external
>     tool calls (MCP/plugins), background/long-running tasks. State how instructions/skills should
>     degrade when an optional capability is missing.
> 14. **Validation smoke tests** — Provide copy-paste checks for:
>     - instruction load verification,
>     - path-scoped/scoped-rule verification,
>     - one tool-call/integration verification.
>       Include expected signals for pass/fail.
> 15. **Agentic work model** — How should users steer you during coding, debugging, planning,
>     exploratory/vibe work, prompting, and autonomous execution? Include planning expectations,
>     interruption/correction, approval moments, retry behavior, testing/checkpointing, and when you
>     should stop and ask.
> 16. **Operational edge cases** — Document generated-vs-source artifacts, bootstrap requirements,
>     persistence across sessions, sandbox/approval behavior, local caches, generated outputs/logs,
>     version-discovery steps, and known drift risks. Mark unknowns as `?`.
>
> After answering, add a brief **"What I need from instruction files"** section: what makes
> instructions work well for you (length, format, placement, things to avoid).

---

## Known harness docs in this repo

| Harness                                  | File                             | Source                                                                  | Last verified                               |
| ---------------------------------------- | -------------------------------- | ----------------------------------------------------------------------- | ------------------------------------------- |
| claude.ai (web/mobile/Desktop Chat)      | [claude-ai.md](claude-ai.md)     | Self-described (inside claude.ai)                                       | 2026-06                                     |
| Claude Code + Cowork (Anthropic desktop) | [claude-code.md](claude-code.md) | Claude Code self-described; Cowork section from shared-engine knowledge | 2026-07 (Cowork section: 2026-06, external) |
| GitHub Copilot (VS Code)                 | [copilot.md](copilot.md)         | Self-described (inside Copilot)                                         | 2026-06                                     |
| GitHub Copilot CLI (desktop app)         | [copilot-cli.md](copilot-cli.md) | Self-described (inside Copilot CLI)                                     | 2026-07                                     |
| Codex CLI / Codex coding agent           | [codex.md](codex.md)             | Self-described (inside Codex)                                           | 2026-07                                     |
| ChatGPT (Projects)                       | *(pending)*                      | —                                                                       | —                                           |

## Format note

Each harness doc answers the 16 questions, then has a **Cross-compatibility** section and a
**What I need from instruction files** section. No other structure required. Mark uncertain
cells `?` — a precise `?` is better than a confident wrong answer.

## Re-verification (decay contract)

Harness docs describe fast-moving products; every doc carries a **verified-on date** and a
**per-section confidence table** (see `copilot.md` / `claude-code.md` for the pattern). Re-verify a
doc — from inside the harness, using the prompt above — when **any** of these hits, whichever comes
first:

1. The harness ships a major version or visibly changes load behavior.
2. Observed behavior contradicts the doc (fix the doc in the same session that caught it).
3. The verified-on date is more than ~6 months old.
4. The answering model's training cutoff is more than ~2–3 months before today. Memory-only
   self-description is a known blind spot for features that shipped after that cutoff (this is
   how `.claude/rules/`, `.claude/skills/`, and `.claude/workflows/` were missing from
   `claude-code.md` despite existing on disk) — run the ground-truth check in the prompt above
   rather than trusting recall.

Update the **Last verified** column in the table above in the same pass. Sections older docs never
answered (for example, questions added after the doc's last verification) are filled at the next
full re-verification — never from memory.

**Authoring restriction:** Describe only your own behavior. Do not explain or reference what
another harness does or does not do — that belongs in the Cross-compatibility section only,
and only to state equivalence or incompatibility at artifact level.
