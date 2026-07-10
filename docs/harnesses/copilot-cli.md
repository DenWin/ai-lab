# Harness: GitHub Copilot CLI (desktop app / terminal agent)

**Vendor:** GitHub (Microsoft)
**Source:** Self-described from inside a Copilot CLI session, 2026-07-07
**Version:** 1.0.69-0 (check in-app for current version)
**Covers:** Copilot CLI — the desktop application that hosts agent sessions backed by git worktrees
or local folders, provides a rich tool set, and supports multi-model selection.
**Not covered here:** GitHub Copilot VS Code extension (Chat/Agent) — see [copilot.md](copilot.md).

---

## 1. Instruction surfaces + precedence

Load order observed in-session:

1. **System / harness platform rules** — built into the Copilot CLI runtime; not editable by the
   user. Sets tool policy, safety limits, session model, and base agent behavior.
2. **`custom_instruction` block** — contents of `.github/copilot-instructions.md` at the repo
   root, injected as a system-level instruction block every session turn. This is the primary
   per-repo instruction surface.
3. **`AGENTS.md`** — repo-root cross-harness instruction file. Read as a base instruction layer
   alongside `.github/copilot-instructions.md` (both load; they are additive, not competing).
4. **Extension-contributed instructions** — extensions in `.github/extensions/` can carry
   additional system-level guidance loaded at startup.
5. **User messages** — explicit task and corrections from the conversation.
6. **Canvas / tool context** — active canvas input and tool results injected per-turn.

Precedence: platform rules > repo instructions > user messages. The `custom_instruction` and
`AGENTS.md` layers are treated as additive; avoid contradictions between them.

## 2. Storage split

- **Repo-scoped (committed):** `.github/copilot-instructions.md`, `AGENTS.md`,
  `.github/extensions/` (project-scope extensions), `.github/prompts/*.prompt.md`
- **Session-scoped (ephemeral, not committed):** `~/.copilot/session-state/<session-id>/`
  — session artifacts (`files/`), `plan.md`, temporary working files
- **Machine-local (gitignored, across sessions):** `~/.copilot/repos/` (repo checkouts +
  worktrees); user-level extension directory (path not exposed in-session — `?`)
- **User-global / account-level:** Copilot CLI app settings, model preferences, user-scope
  extensions — stored by the app, not in the repo

## 3. Disk locations

| Tier                   | Windows                                                                 | macOS / Linux                                               |
| ---------------------- | ----------------------------------------------------------------------- | ----------------------------------------------------------- |
| Repo main checkout     | `%USERPROFILE%\.copilot\repos\<owner-repo>\`                            | `~/.copilot/repos/<owner-repo>/`                            |
| Session worktree       | `%USERPROFILE%\.copilot\repos\copilot-worktrees\<owner-repo>\<branch>\` | `~/.copilot/repos/copilot-worktrees/<owner-repo>/<branch>/` |
| Session state folder   | `%USERPROFILE%\.copilot\session-state\<session-id>\`                    | `~/.copilot/session-state/<session-id>/`                    |
| Session artifacts      | `%USERPROFILE%\.copilot\session-state\<session-id>\files\`              | `~/.copilot/session-state/<session-id>/files/`              |
| Repo instructions      | `<repo>\.github\copilot-instructions.md`                                | `<repo>/.github/copilot-instructions.md`                    |
| Cross-harness contract | `<repo>\AGENTS.md`                                                      | `<repo>/AGENTS.md`                                          |
| Project extensions     | `<repo>\.github\extensions\`                                            | `<repo>/.github/extensions/`                                |
| Project prompt files   | `<repo>\.github\prompts\*.prompt.md`                                    | `<repo>/.github/prompts/*.prompt.md`                        |
| User-scope extensions  | `?` (not exposed in-session)                                            | `?`                                                         |
| App settings / config  | managed by Copilot CLI app — path `?`                                   | `?`                                                         |

## 4. Artifact mapping

| Artifact type           | Support                 | Notes                                                                                    |
| ----------------------- | ----------------------- | ---------------------------------------------------------------------------------------- |
| Instruction docs        | **Native**              | `.github/copilot-instructions.md` + `AGENTS.md`; auto-loaded every session               |
| Skills / slash commands | **Emulated**            | No dedicated skill format; represented via extensions (tools) or prompt files            |
| Subagents               | **Native**              | `task` tool spawns typed sub-agents (explore, task, general-purpose, code-review, etc.)  |
| Hooks                   | **Partial / Emulated**  | No declarative hook config; lifecycle events handled by extensions + app runtime         |
| MCP servers             | **Native**              | Configured via workspace or user settings; protocol is cross-vendor                      |
| Canvas panels           | **Native** (unique)     | Interactive side panels (editor, browser, terminal); opened by agent or user             |
| Output styles           | **Emulated**            | Style contracts in instruction files; no native style primitive                          |
| Settings / permissions  | **Native**              | App settings + extension `allow/deny` lists                                              |
| Plugins / bundles       | **Native** (extensions) | `.github/extensions/*.{js,ts,yml}` contribute tools / canvases to the session            |
| Scheduled workflows     | **Native**              | Built-in workflow scheduler (manual / hourly / daily / weekly / CRON)                    |
| Session store / history | **Native**              | Per-session SQLite (`sql` tool); cross-session DuckDB history (`session_store_sql` tool) |

## 5. Cross-compatibility

- **Reads `AGENTS.md`:** yes — auto-loaded from repo root as a base instruction layer
- **Reads `.github/copilot-instructions.md`:** yes — primary per-repo instruction surface;
  also shared with VS Code Copilot
- **Preferred cross-harness position:** `AGENTS.md` as the shared contract across
  Copilot CLI, VS Code Copilot, Claude Code, and Codex
- **MCP:** natively supported; config location differs per harness but servers are vendor-neutral
- **Capability-contract skills:** this harness takes the **full agentic path** (shell, filesystem,
  git, network, sub-agents); write skills to degrade gracefully for harnesses that lack these

## 6. Composition mechanics

- **`applyTo`:** not supported for `.github/copilot-instructions.md` or `AGENTS.md` in this
  harness — all instructions are session-global
- **`@import` / include:** no first-class include system; use explicit links in instruction files
- **Frontmatter:** extensions carry YAML/JSON manifests; prompt files may carry frontmatter
- **Merge:** multiple instruction layers (platform + repo + `AGENTS.md`) are stacked additively
- **Extension composition:** each extension `.js/.ts/.yml` declares its tools/canvases
  independently; the runtime merges them into the available tool set

## 7. Activation + load model

| Surface                           | Load model                                                                               |
| --------------------------------- | ---------------------------------------------------------------------------------------- |
| `.github/copilot-instructions.md` | Auto, every session turn (injected as `custom_instruction`)                              |
| `AGENTS.md`                       | Auto, every session turn (base instruction layer)                                        |
| Extensions                        | Loaded at app / session start; tools contributed are available for the full session      |
| MCP servers                       | On-demand tool calls (not loaded into context text)                                      |
| Canvas                            | Opened explicitly by agent (`open_canvas`) or user; persists as a side panel             |
| Scheduled workflows               | Time-triggered or manual; spawn a new session with a configured prompt and mode          |
| Sub-agents (task tool)            | Spawned on demand; background agents notify on completion                                |
| Prompt files (`.prompt.md`)       | User-invoked (`/filename` pattern from VS Code Copilot; not natively slash-invoked here) |

Instructions are **not** cached across sessions — each session starts fresh from disk.
Context budget: instruction files compete with code and conversation for the model's context
window; keep `.github/copilot-instructions.md` and `AGENTS.md` concise.

## 8. Validation

- Ask the model: "what instruction sources are active in this session?" — behavioral verification
- `extensions_manage list` — shows all loaded extensions with status and log path
- `extensions_manage inspect <name>` — shows extension details and tail of its log
- Extensions reload: `extensions_reload` — forces re-read of `.github/extensions/`
- MCP: invoke a configured tool and observe the response
- Workflows: `list_workflows` — shows configured schedules and last-run status
- Session state: `list_sessions_and_chats` — confirms session is active and branch is set

## 9. Security / secrets boundary

- **Never** in `.github/copilot-instructions.md`, `AGENTS.md`, or any committed file —
  this repo is **public**
- **Never** in extension source files in `.github/extensions/` (committed)
- Session state (`~/.copilot/session-state/`) is machine-local and not committed, but
  treat it as potentially readable by the app process — no secrets there either
- MCP server secrets: inject via environment variables in the server config; never inline
- Extension authentication: use OS secret stores or env vars injected at extension start
- The `sql` / `session_store_sql` tools store session data locally — no secrets in queries
  or inserted rows

## 10. Capability limits / notable absences

- Skills can be loaded from skill directories (Copilot SDK `skillDirectories`), where each immediate
  subdirectory contains `SKILL.md`. This repo mirrors to `.github/skills/<group>_<name>/SKILL.md`.
- No declarative hook system comparable to Claude Code's `settings.json` hooks
- No path-scoped instruction activation (`applyTo`) — all instructions apply session-wide
- No persistent cross-session memory built into the harness (relies on session state files
  and the session store database)
- Cloud sessions require network access and a GitHub-hosted runner
- Extension development requires understanding the extension authoring API
  (`extensions_manage guide` for the current spec)

## 11. Evidence metadata

- **Verified on:** 2026-07-07
- **Harness/App:** Copilot CLI 1.0.69-0
- **Session model:** Claude Sonnet 4.6 (multi-model; observed model at time of writing)

| Section                              | Confidence | Why                                                                                                    |
| ------------------------------------ | ---------- | ------------------------------------------------------------------------------------------------------ |
| 1. Instruction surfaces + precedence | high       | Load model visible in-session via `custom_instruction` injection; additive layer confirmed             |
| 2. Storage split                     | high       | Session state and worktree paths are directly observable in the session context                        |
| 3. Disk locations                    | medium     | Worktree and session paths confirmed from live context; user-scope extension path is `?`               |
| 4. Artifact mapping                  | high       | All tool categories exercised in this repo's sessions                                                  |
| 5. Cross-compatibility               | high       | `AGENTS.md` and `.github/copilot-instructions.md` auto-load confirmed in-session                       |
| 6. Composition mechanics             | medium     | Additive layering observed; exact precedence for instruction-level conflicts not systematically tested |
| 7. Activation + load model           | high       | Extension, MCP, canvas, and workflow load patterns all observed in-session                             |
| 8. Validation                        | high       | Commands verified in live sessions (`extensions_manage`, `list_workflows`, etc.)                       |
| 9. Security / secrets boundary       | high       | Follows repo-public constraint and standard env-var injection patterns                                 |
| 10. Capability limits                | medium     | Known absences confirmed; some edge cases (cloud sessions, extension API limits) not fully tested      |

## 12. Command + argument mapping

- **Prompt files:** `.github/prompts/*.prompt.md` — not natively slash-invoked in Copilot CLI
  (VS Code Chat invokes them as `/filename`); in CLI context, reference by path or include
  content inline in the session message
- **Extensions (tools):** invoked as tool calls by the agent; arguments are defined by the
  extension's tool schema
- **Workflows:** invoked via `run_workflow <workflow-id>` or on schedule; the prompt is the
  only argument
- **Sub-agents:** `task` tool with `prompt` and `agent_type`; arguments passed as natural
  language in the prompt
- **Canvas actions:** `invoke_canvas_action { instanceId, actionName, input }` — structured
  arguments per the canvas's action schema (discover via `list_canvas_capabilities`)

Fallback when no native command invocation exists:

1. Use a prompt template with explicit `<placeholder>` labels.
2. Ask the user to fill placeholders inline in the session message.
3. Treat the filled template as equivalent to command arguments.

## 13. Capability contract

| Capability                        | Contract | Notes                                                                         |
| --------------------------------- | -------- | ----------------------------------------------------------------------------- |
| Filesystem read                   | required | Core to codebase grounding; always available                                  |
| Filesystem write                  | required | Needed for code edits; always available                                       |
| Shell / terminal execution        | required | `powershell` tool; always available in local sessions                         |
| Network access                    | optional | `web_fetch` for URL retrieval; `gh` CLI for GitHub API                        |
| External tool calls (MCP/plugins) | optional | Available when extensions or MCP servers are configured                       |
| Sub-agents                        | optional | `task` tool for delegation; requires compatible model and agent type          |
| Canvas panels                     | optional | Available in the desktop app; degrade to text output in headless/API contexts |
| Background / scheduled tasks      | optional | Workflows for scheduled; background agents for async within a session         |

Degradation rule: if an optional capability is missing, continue with the nearest equivalent
(e.g., text output instead of canvas; inline shell command instructions if terminal is blocked).
If a required capability is missing, stop and emit explicit manual steps.

## 14. Validation smoke tests

1. **Instruction load check**
   - Prompt: "List the instruction files currently active in this session."
   - Pass: names `.github/copilot-instructions.md` and `AGENTS.md` from the repo root.
   - Fail: ignores known sources or reports incorrect paths.

2. **Extension load check**
   - Action: run `extensions_manage list`.
   - Pass: shows loaded extensions with status; no extensions in `failed` state unexpectedly.
   - Fail: expected extension missing or in `failed` state → inspect with
     `extensions_manage inspect <name>` and check the log tail.

3. **Tool integration check (MCP)**
   - Action: invoke one configured MCP tool with minimal valid input.
   - Pass: tool executes and returns structured output or a valid typed error.
   - Fail: unresolved tool, malformed invocation, or silent no-op.

## 15. Agentic work model

**Planning:** For multi-step or multi-file tasks, write a `plan.md` in the session state folder
(`~/.copilot/session-state/<session-id>/plan.md`) as a working reference — not in the repo.
Update it at major milestones. Skip the plan for straightforward tasks.

**Modes:**

- **Interactive** — step-by-step with user approval at each significant change; preferred for
  exploratory or risky work.
- **Autopilot** — agent drives to completion autonomously; use for well-defined tasks.
- **Plan** — agent proposes a plan, user approves before execution begins.

**Interruption / correction:** users can correct mid-task via a new message; the agent should
acknowledge, revise the plan, and continue without redoing already-correct work.

**Approval moments:** pause and ask before: destructive file operations, pushing to remote
branches, executing unfamiliar shell commands, and any action outside the stated scope.

**Retry behavior:** on tool failure, try at least one alternative approach before concluding the
task is impossible; report the failure clearly if retries are exhausted.

**Testing / checkpointing:** run existing tests after changes; commit at logical checkpoints so
progress is not lost. Use `git --no-pager log --oneline -5` to confirm checkpoint commits.

**When to stop and ask:** design decisions with significant implementation consequences,
behavioral questions (e.g., "should this be capped or unlimited?"), scope ambiguity, and
edge cases where multiple equally-valid approaches exist.

## 16. Operational edge cases

- **Worktree model:** each session runs in an isolated git worktree on its own branch; never
  read or write files in the main checkout path.
- **Branch naming:** the app generates an initial branch name; rename it immediately with
  `rename_branch` before the first commit (using `git branch -m` bypasses the session tracking).
- **Generated mirrors:** `.claude/commands/` (Claude Code skill mirror), `.agents/skills/`
  (Codex skill mirror), and `.github/skills/` (Copilot skill mirror) are gitignored
  and rebuilt by `pwsh scripts/setup-repo.ps1 -SkipHooks`. Run the sync step after any change to
  `ai-artifacts/skills/shared/`; these mirrors may not exist on a fresh clone.
- **Session state persistence:** session state folder (`~/.copilot/session-state/<session-id>/`)
  persists across checkpoints but is **not** committed. Promote only durable, redacted material
  to the repo.
- **Extension authoring:** call `extensions_manage guide` before writing any extension code;
  the API changes with app versions. Reload after edits with `extensions_reload`.
- **Model selection:** the active model affects capability and context budget; note the model
  in the evidence metadata when re-verifying this doc.
- **Version discovery:** current version is visible in the system prompt header
  (`<version_information>`); capture it when filing issues or re-verifying this doc.
- **Cloud sessions:** cloud-hosted sessions use a GitHub-provisioned runner; `copilot-setup-steps.yml`
  controls environment setup; local paths and tool availability may differ from local sessions.
- **Cross-session messaging:** sessions can message each other via `send_session_message`; the
  sender's `project_session_id` is needed and visible in the session context block.
- **Known drift risk:** extension API, canvas schemas, and sub-agent types evolve with app updates;
  re-verify this doc when the app version changes significantly.

---

## Cross-compatibility

| Artifact                          | Cross-compat position          | Notes                                                                                                          |
| --------------------------------- | ------------------------------ | -------------------------------------------------------------------------------------------------------------- |
| `AGENTS.md`                       | **Primary cross-compat file**  | Read by Copilot CLI, VS Code Copilot, Claude Code, Codex                                                       |
| `.github/copilot-instructions.md` | Copilot family (CLI + VS Code) | Not read by Claude Code or Codex as a native instruction file                                                  |
| `.github/extensions/`             | Copilot CLI-specific           | Extension format is not shared with other harnesses                                                            |
| `.github/prompts/*.prompt.md`     | Copilot family (shared format) | VS Code Copilot invokes as slash commands; Copilot CLI references by path                                      |
| MCP (workspace/user config)       | Cross-vendor                   | Config syntax and location differ per harness; protocol is vendor-neutral                                      |
| `ai-artifacts/skills/shared/`     | Source of truth                | Mirrored to `.claude/commands/` (Claude Code), `.agents/skills/` (Codex), and `.github/skills/<group>_<name>/SKILL.md` (Copilot skill mirror) |
| Scheduled workflows               | Copilot CLI-specific           | No equivalent native primitive in other harnesses                                                              |
| Canvas panels                     | Copilot CLI-specific           | No equivalent in other harnesses                                                                               |

**Cross-capability preference order for Copilot CLI authoring:**

1. `AGENTS.md` — shared contract for all harnesses
2. `.github/copilot-instructions.md` — Copilot-family repo behavior
3. `.github/extensions/` — tool / canvas contributions
4. MCP for external tool integration over vendor-locked mechanisms
5. Scheduled workflows for automation that must survive session boundaries

---

## What I need from instruction files

- **Concise and accurate** — instruction files are in context every turn; stale paths or bloated
  content waste tokens on every message
- **File-based, not UI** — I load from files in the repo (`AGENTS.md`,
  `.github/copilot-instructions.md`), not from any UI field
- **Capability-contract wording** — write "if shell available" not "if Copilot CLI" — I run
  multi-model and my capabilities are conditionally available in cloud vs local sessions
- **No `applyTo` assumptions** — path-scoped activation is not available here; all instructions
  are session-global
- **`AGENTS.md` for portability** — anything that should survive a harness switch belongs in
  `AGENTS.md`; Copilot CLI-specific wiring belongs in `.github/copilot-instructions.md`
- **No secrets** — this repo is public; use env vars or OS secret stores for any sensitive config
