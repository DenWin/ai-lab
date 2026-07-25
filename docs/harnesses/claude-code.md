# Harness: Claude Code + Cowork (Anthropic desktop harnesses)

**Vendor:** Anthropic
**Source:** Claude Code self-described from inside; Cowork section from shared-engine knowledge + external observation, 2026-06
**Covers:** Claude Code CLI, Desktop Code tab, Cowork Desktop — all three share the same engine
and `~/.claude/` tree. Differences are in [the Cowork section](#cowork-differences-from-claude-code).
**Not covered here:** Desktop Chat tab — see [claude-ai.md](claude-ai.md).

---

## 1. Instruction surfaces + precedence

Load order (later overrides earlier where they conflict; more-specific wins over less-specific):

1. **Managed/enterprise** — OS-specific system path (set by org policy; highest precedence)
2. **User-global** — `~/.claude/CLAUDE.md` (all projects)
3. **Project** — `./CLAUDE.md` + nested per-subdirectory `CLAUDE.md` (more-specific subdir wins)
4. **Local** — `CLAUDE.local.md` (personal, gitignored; sits alongside `CLAUDE.md`)
5. **`.claude/rules/*.md`** — topic-scoped instruction files, same priority tier as `CLAUDE.md`.
   A rule with no `paths:` frontmatter loads at session start like `CLAUDE.md`; a rule with
   `paths:` (glob list) loads only when Claude reads a matching file. Exists at both project
   (`.claude/rules/`) and user-global (`~/.claude/rules/`) scope. This is the native mechanism
   for splitting a growing `CLAUDE.md` (recommended past ~200 lines) and for `applyTo`-style
   path-scoped instructions.
6. **`AGENTS.md`** — at repo root; cross-compatible preferred format (read alongside CLAUDE.md,
   not instead of it — both load)
7. **Auto-memory** — `~/.claude/projects/<sanitized-cwd>/memory/MEMORY.md` (first ~200 lines,
   capped at 25KB)
8. **`settings.json`** — permissions, hooks, MCP config (not instruction text; different mechanism)

Within instruction files, more-specific path wins. Managed > project > user for policy conflicts.

## 2. Storage split

- **Repo-scoped (committed):** `CLAUDE.md`, `AGENTS.md`, `.claude/settings.json`,
  `ai-artifacts/skills/shared/<group>/<name>/`, `.mcp.json`, `.claude/rules/*.md`,
  `.claude/skills/<name>/SKILL.md`, `.claude/agents/*.md`, `.claude/workflows/*.js`,
  `.claude/agent-memory/<agent>/MEMORY.md` (subagent with `memory: project`)
- **Machine-local (gitignored):** `CLAUDE.local.md`, `.claude/settings.local.json`,
  `~/.claude/projects/<project>/memory/` (auto-memory),
  `.claude/agent-memory-local/` (subagent with `memory: local`)
- **User-global (all repos):** `~/.claude/CLAUDE.md`, `~/.claude/settings.json`,
  `~/.claude.json` (app state — theme, trust decisions, personal MCP servers; distinct from
  `settings.json`), `~/.claude/commands/` (global skills mirror), `~/.claude/skills/`,
  `~/.claude/rules/`, `~/.claude/workflows/`, `~/.claude/agents/`, `~/.claude/agent-memory/`
  (subagent with `memory: user`), `~/.claude/plugins/`

## 3. Disk locations

| Tier                        | Windows                                                  | macOS / Linux                                |
| --------------------------- | -------------------------------------------------------- | -------------------------------------------- |
| User-global Claude config   | `%USERPROFILE%\.claude\`                                 | `~/.claude/`                                 |
| Global instruction file     | `%USERPROFILE%\.claude\CLAUDE.md`                        | `~/.claude/CLAUDE.md`                        |
| Global skills mirror        | `%USERPROFILE%\.claude\commands\`                        | `~/.claude/commands/`                        |
| Auto-memory                 | `%USERPROFILE%\.claude\projects\<slug>\memory\MEMORY.md` | `~/.claude/projects/<slug>/memory/MEMORY.md` |
| Global settings             | `%USERPROFILE%\.claude\settings.json`                    | `~/.claude/settings.json`                    |
| Project instruction         | `<repo>\CLAUDE.md` or `<repo>\AGENTS.md`                 | same                                         |
| Project-local override      | `<repo>\CLAUDE.local.md`                                 | same                                         |
| Project settings            | `<repo>\.claude\settings.json`                           | same                                         |
| Project-local settings      | `<repo>\.claude\settings.local.json`                     | same                                         |
| Project MCP config          | `<repo>\.mcp.json`                                       | same                                         |
| Project rules               | `<repo>\.claude\rules\*.md`                              | same                                         |
| Project skills              | `<repo>\.claude\skills\<name>\SKILL.md`                  | same                                         |
| Project subagents           | `<repo>\.claude\agents\*.md`                             | same                                         |
| Project workflows           | `<repo>\.claude\workflows\*.js`                          | same                                         |
| Project subagent memory     | `<repo>\.claude\agent-memory\<agent>\MEMORY.md`          | same                                         |
| Global rules                | `%USERPROFILE%\.claude\rules\`                           | `~/.claude/rules/`                           |
| Global skills               | `%USERPROFILE%\.claude\skills\`                          | `~/.claude/skills/`                          |
| Global subagents            | `%USERPROFILE%\.claude\agents\`                          | `~/.claude/agents/`                          |
| Global workflows            | `%USERPROFILE%\.claude\workflows\`                       | `~/.claude/workflows/`                       |
| App state (non-instruction) | `%USERPROFILE%\.claude.json`                             | `~/.claude.json`                             |

## 4. Artifact mapping

| Artifact type                               | Support                                                                                                                         |
| ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| Instruction docs (`AGENTS.md`, `CLAUDE.md`) | **Native** — file-based, auto-loaded every session start                                                                        |
| Rules                                       | **Native** — `.claude/rules/*.md`; see note below                                                                               |
| Skills / slash commands                     | **Native** — `.claude/skills/` and legacy `.claude/commands/`; see note below                                                   |
| Subagents                                   | **Native** — `.claude/agents/*.md`                                                                                              |
| Dynamic workflows                           | **Native** — `.claude/workflows/*.js`; see note below                                                                           |
| Subagent persistent memory                  | **Native** — `.claude/agent-memory/`; see note below                                                                            |
| Hooks                                       | **Native** — `settings.json` (`PreToolUse`, `PostToolUse`, `SessionStart`, etc.); scripts conventionally under `.claude/hooks/` |
| MCP servers                                 | **Native** — `.mcp.json` (project), `~/.claude.json` (personal), Desktop `claude_desktop_config.json`                           |
| Output styles                               | **Native** — `ai-artifacts/output-styles/` (referenced in settings)                                                             |
| Settings / permissions                      | **Native** — `settings.json` / `settings.local.json`                                                                            |
| Plugins / bundles                           | **Native** — `.claude-plugin/plugin.json` wrapping skills/agents/hooks/mcp                                                      |

- **Rules:** `.claude/rules/*.md` (project) or `~/.claude/rules/*.md` (global) — same priority
  tier as `CLAUDE.md`. No `paths:` frontmatter → loads at session start like `CLAUDE.md`. With
  `paths:` (glob list) → loads only when Claude reads a matching file — the native
  `applyTo`-equivalent. This repo does not currently use rules; all guidance lives in `CLAUDE.md`
  and skills.
- **Skills vs. commands:** `.claude/skills/<name>/SKILL.md` is the vendor-recommended mechanism —
  directory bundling, `paths:`-scoped auto-load, `disable-model-invocation`, `context: fork` for
  subagent execution. The legacy `.claude/commands/<name>.md` (single file) still works
  identically for `/name` invocation; a skill wins on a name clash. **This repo mirrors
  `ai-artifacts/skills/shared/` to `.claude/commands/<group>/<name>.md` — the legacy path, not
  `.claude/skills/`.**
- **Dynamic workflows:** `.claude/workflows/*.js` (project) or `~/.claude/workflows/*.js`
  (global) — each file becomes a `/<name>` command that spawns and orchestrates multiple
  subagents. Authored via `/workflows`, not hand-written.
- **Subagent persistent memory:** `.claude/agent-memory/<agent>/MEMORY.md` (project, committed),
  `.claude/agent-memory-local/` (project, gitignored), `~/.claude/agent-memory/` (user-global) —
  opt-in per subagent via `memory:` frontmatter. Distinct from main-session auto-memory
  (`~/.claude/projects/<slug>/memory/`).

## 5. Cross-compatibility

- **Reads `AGENTS.md`:** yes, auto-loaded from repo root alongside `CLAUDE.md`
- **Preferred cross-harness file:** `AGENTS.md` (also read by Codex CLI — the primary cross-compat position)
- **`CLAUDE.md` scope:** read only by Claude Code; not auto-loaded by other harnesses
- **MCP:** cross-vendor protocol — the config location differs per harness but the servers work everywhere
- **Capability-contract skills:** this harness takes the **full path** (shell, filesystem, git, network);
  write skills to degrade gracefully for harnesses that lack these

## 6. Composition mechanics

- **`applyTo` / path-scoped rules:** natively supported via `.claude/rules/*.md` frontmatter
  `paths:` (glob list) — the rule loads only when Claude reads a matching file. Skills carry the
  same `paths:` field for auto-load scoping. `CLAUDE.md`/`AGENTS.md` themselves are not
  path-scoped; nesting a subdir `CLAUDE.md` is the only scoping mechanism for those two files
  specifically.
- **`@import` / include:** `@path/to/file` syntax in CLAUDE.md injects another file's content inline
- **Frontmatter:** skills carry YAML frontmatter (`name`, `description`, `paths`,
  `disable-model-invocation`, `user-invocable`, `allowed-tools`, `context`, `agent`, `model`,
  `effort`, `hooks`, `arguments`, `argument-hint`); source-skill provenance lives in sibling
  `METADATA.md`
- **Merge:** settings files merge across tiers (user → project → local); later/more-specific wins

## 7. Activation + load model

| Surface                   | Load model                                                                             |
| ------------------------- | -------------------------------------------------------------------------------------- |
| `CLAUDE.md` / `AGENTS.md` | Auto, every session start (loaded into system prompt)                                  |
| Rules, no `paths:`        | Auto, every session start — same tier as `CLAUDE.md`                                   |
| Rules, with `paths:`      | Auto, on-demand — loads when Claude reads a matching file                              |
| Auto-memory (`MEMORY.md`) | Auto-injected, first ~200 lines (25KB cap)                                             |
| Skills / commands         | Description always listed; full body loads on `/name` invocation or Claude's own match |
| Dynamic workflows         | Explicit `/name` invocation or schedule; spawns/orchestrates subagents                 |
| Hooks                     | Event-triggered (pre/post tool, session start, stop, etc.) — run shell commands        |
| MCP servers               | On-demand tool calls                                                                   |
| Subagents                 | Spawned explicitly by the model or via hooks                                           |

Skills are **not** loaded into context every turn — only the name+description listing is; the
full body loads once invoked and then persists for the rest of the session (re-invocations with
identical content are deduplicated rather than re-appended). `CLAUDE.md` and unscoped rules are
loaded every turn and compete with code for context budget — keep both concise.

## 8. Validation

- `/memory` — shows what's in auto-memory
- `/context` — shows current context usage
- Ask the model: "what CLAUDE.md / AGENTS.md instructions are active?" — behavioral verification
- Hook execution: visible in the spinner ("Running hook…"); `--debug` flag for full logs
- Skill loading: check `/skills` or the available skills list in the session
- Settings: `cat .claude/settings.json` — direct file inspection

## 9. Security / secrets boundary

- **Never** in `CLAUDE.md`, `AGENTS.md`, or any committed instruction file — these are in git
- **Never** in `settings.json` (committed) — env var injection via `settings.json`'s `env` block
  is acceptable for non-secret config; for secrets use the OS secret store or `.env` (gitignored)
- `settings.local.json` is gitignored — acceptable for machine-local non-secret config
- MCP server secrets: inject via environment variables in the MCP server config, not inline
- Auto-memory (`MEMORY.md`) persists across sessions — treat it as semi-public; no secrets

## 10. Capability limits / notable absences

- Requires local install + auth — not available without setup
- Auto-memory truncates at ~200 lines — MEMORY.md beyond that is not loaded
- Skills cache may be siloed inconsistently across Desktop tabs (known issue: anthropics/claude-code#53414)
- No scheduled background tasks without the session open (Cowork has these in a limited form)
- `CLAUDE.md` is weighted **above** chat messages in the context — noise is disproportionately costly

## 11. Evidence metadata

- **Verified on:** 2026-07-04 (re-checked from inside a Claude Code session; original
  self-description 2026-06). Sections 1–4, 6, 7 patched 2026-07-13 to add `rules/`, `skills/`,
  `workflows/`, and `agent-memory/` — these shipped after the 2026-07-04 pass and were missing
  entirely. Source for the patch: official docs (`code.claude.com/docs/en/claude-directory`,
  `/en/skills`), not a fresh in-session self-description — re-verify from inside a session at the
  next full pass per the decay contract.
- **Harness/App:** Claude Code VS Code extension, Windows 11; model `claude-fable-5`
- **Not yet answered:** the newer TEMPLATE questions 12–13 (command + argument mapping, capability
  contract) postdate this doc — answer them at the next full re-verification rather than guessing now.

| Section                              | Confidence | Why                                                                                                                                                                          |
| ------------------------------------ | ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1. Instruction surfaces + precedence | high       | Load order observed in-session; `rules/` tier confirmed against official docs 2026-07-13; managed/enterprise tier not exercised (`?` on exact path)                          |
| 2. Storage split                     | high       | Paths confirmed on this machine; new paths (`rules/`, `skills/`, `workflows/`, `agent-memory/`, `~/.claude.json`) sourced from official docs, not yet exercised in this repo |
| 3. Disk locations                    | high       | Standard stable paths; auto-memory location confirmed in-session 2026-07                                                                                                     |
| 4. Artifact mapping                  | medium     | Existing rows exercised in this repo; `rules/`, `.claude/skills/`, `workflows/`, `agent-memory/` are documented but unused here — doc-sourced, not repo-verified             |
| 5. Cross-compatibility               | medium     | `AGENTS.md` auto-load is documented behavior; other harnesses' reads are external observation                                                                                |
| 6. Composition mechanics             | medium     | `@import` / frontmatter used; `paths:` scoping confirmed against official docs 2026-07-13 but not exercised in this repo                                                     |
| 7. Activation + load model           | high       | Observed in-session: skills resolve on invocation, hooks fire on events; rules/workflows load model doc-sourced 2026-07-13                                                   |
| 8. Validation                        | high       | Commands verified                                                                                                                                                            |
| 9. Security / secrets boundary       | high       | Matches documented settings behavior                                                                                                                                         |
| 10. Capability limits                | medium     | Fast-moving (line limits, known issues); re-verify per the TEMPLATE decay contract                                                                                           |
| Cowork section                       | low–medium | External observation + shared-engine knowledge — never self-described from inside Cowork                                                                                     |

## 12. Validation smoke tests

1. **Instruction load check** — Prompt: "Which instruction files are active in this session? Quote
   the first heading of each." Pass: names the repo-root `AGENTS.md` and any present `CLAUDE.md`
   tiers with real content. Fail: invents files or misses `AGENTS.md`.
2. **Skill invocation check** — Run `/planning:scratch` with no arguments. Pass: the ranked table
  from `.scratch/BACKLOG.md` is displayed (command body + resources resolved from the mirror).
  Fail: skill unknown → mirror missing; run `pwsh scripts/setup-repo.ps1 -SkipHooks`.
3. **Hook check** — Start a new session on a machine with the SessionStart hook configured in
   `.claude/settings.local.json`. Pass: the "Synced skills → …" hook output appears at session
   start. Fail: no output → hook not installed on this machine or script error (`--debug` for logs).

---

## Cross-compatibility

| Artifact                | Cross-compat position                                  | Notes                                                        |
| ----------------------- | ------------------------------------------------------ | ------------------------------------------------------------ |
| `AGENTS.md`             | **Primary cross-compat file** — also read by Codex CLI | Prefer over `CLAUDE.md` when writing for portability         |
| `CLAUDE.md`             | Claude-family only                                     | Not read as a native instruction file by other harnesses     |
| MCP (`.mcp.json`)       | Cross-vendor                                           | Config location differs; servers are vendor-neutral          |
| Skills (`commands/`)    | Claude-family only                                     | No equivalent in other harnesses without adaptation          |
| Hooks (`settings.json`) | Claude Code only                                       | Represent as `.vscode/tasks.json` for Copilot; CI for others |
| Plugins                 | Claude Code only                                       | No cross-harness packaging format                            |

**Design principle:** `AGENTS.md` at root is the cross-compat anchor. `CLAUDE.md` carries
Claude-specific config. MCP is the only natively cross-vendor artifact type.

---

## What I need from instruction files

- **Concise** — `CLAUDE.md` is in context every turn and competes with code; every line costs tokens
- **Accurate facts** — build/test/lint commands and file paths are load-bearing; stale paths cause
  real errors
- **File-based, not UI** — I load from files in the repo and `~/.claude/`, not from any UI field
- **Tier-aware placement** — global (`~/.claude/CLAUDE.md`) vs project (`./CLAUDE.md`) vs local
  (`CLAUDE.local.md`) serve different audiences; don't conflate them
- **No secrets in committed files** — use `settings.local.json` or env vars for anything sensitive

---

## Cowork: differences from Claude Code

Everything above applies to Cowork unless overridden here. The two harnesses share the engine,
`~/.claude/` (same settings, commands, plugins, auto-memory), and skills. The defining difference
is Cowork's **sandboxed VM** — it has no shell, no git, no terminal.

### Instruction surfaces (Cowork)

- **Settings → Cowork → Global Instructions** (account-level UI field) — replaces `~/.claude/CLAUDE.md` as the user-global surface
- **`CLAUDE.md` in the pointed folder** — Cowork reads and can self-update this file before each task
- Shared: `~/.claude/` settings, commands, plugins, auto-memory

### Storage (Cowork)

- **Local-granted only** — file access restricted to folders explicitly granted to Cowork; no full filesystem access
- User-global `~/.claude/` is shared with Claude Code

### Capability differences

| Capability                               | Claude Code          | Cowork                                                   |
| ---------------------------------------- | -------------------- | -------------------------------------------------------- |
| Shell / terminal                         | ✅ full              | ❌ sandboxed VM — defining constraint                    |
| Git                                      | ✅                   | ❌                                                       |
| File access                              | local-full           | local-granted (granted folders only)                     |
| Hooks (`settings.json`)                  | ✅ full lifecycle    | `?` — likely limited without shell                       |
| Scheduled tasks                          | ❌ (unless external) | ✅ while app is open                                     |
| Document generation (xlsx/pptx/docx/pdf) | ❌                   | ✅                                                       |
| Connectors (Google Workspace, Slack, …)  | via MCP              | ✅ native + MCP                                          |
| Skills with `!command` preprocessing     | ✅                   | ❌ — shell not available; `!command` lines don't execute |

### Skills in Cowork

Skills load from the same `~/.claude/commands/` cache. The key constraint: skills that use
`!command` preprocessing or shell tool calls must **degrade gracefully** — Cowork takes the
conversational / no-shell fallback branch. Write skills to a capability contract, not a
harness branch: "if shell available → full path; else → describe and ask the user to run."

### What Cowork needs from instruction files

- **Concise folder `CLAUDE.md`** — read before every task; bloat burns token budget up front
- **Shell-free skill design** — every skill must have a no-shell fallback
- **Granted-folder awareness** — don't reference paths outside granted folders
