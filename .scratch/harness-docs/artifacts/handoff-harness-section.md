### Harness self-descriptions

Each harness documents its own needs/characteristics/limits — it knows itself best. claude.ai's is
filled below (authored from inside claude.ai). **Claude Code: add your own section when you pick
this up; you may also draft Cowork's from shared-engine knowledge, or defer it to a Cowork session.**

Before adding any new harness section, answer this same checklist so results are comparable:

1. **Instruction surfaces + precedence:** Which files/settings are read, and which one wins on conflict?
2. **Storage split:** Which artifacts are repo-scoped, machine-local, and user-global?
3. **Disk locations:** What are the concrete paths on Windows, macOS, and Linux?
4. **Artifact mapping:** For instruction docs, prompts, skills, agents, hooks, MCP, output styles,
   settings, and plugins/bundles: what is native, what is emulated, what is unsupported?
5. **Cross-capability variants:** Which patterns work across vendors/harnesses, and which are
   harness-specific fallbacks?
6. **Composition mechanics:** Is there `applyTo`, frontmatter, include/import, insert/merge, or only
   manual linking? State exact supported mechanisms.
7. **Activation and load model:** Auto-loaded every turn, command-invoked, description match,
   or user-pick at runtime?
8. **Validation method:** How to verify loading happened (diagnostics, test prompt, logs,
   or explicit tool evidence).
9. **Security/secrets boundary:** Where secrets must never be stored and how they are injected.
10. **Capability limits / notable absences:** What can this harness _not_ do that a sibling can —
    shell, git, background/scheduled tasks, write access, persistent cross-session state? List the
    gaps that matter for choosing a harness or writing a capability-contract fallback.

**claude.ai (web / mobile / Desktop Chat tab) — self-description** _(answers the 10-point checklist; this is the worked example for other harnesses to match)_

1. _Instruction surfaces + precedence:_ Settings → Instructions for Claude (account-wide profile);
   project instructions field; project knowledge files; styles; user preferences; memory (past-chat
   - generated, off in Incognito). **Precedence:** the latest in-conversation instruction wins;
     **style > preferences** on conflict; profile and project instructions both apply every turn
     (project layer is additive, scoped to the project). No single documented chain beyond this —
     treat finer ordering as `?`.

2. _Storage split:_ **user-global** (account-bound) — profile, styles, preferences, cloud skills,
   memory. **Project-scoped** (the nearest thing to repo-scoped) — project instructions + project
   knowledge. **Ephemeral** — the code-execution sandbox. **Per-artifact persistent** — the artifact
   key-value store. There is **no machine-local** tier.

3. _Disk locations:_ **none on the user's machine** — this is the defining trait vs Code/Cowork.
   All surfaces are server/account-side; uploads are transient; the only filesystem is a server-side
   Linux container (`/home/claude`, `/mnt/user-data/…`), not Windows/macOS/Linux client paths.

4. _Artifact mapping (native / emulated / unsupported):_ **native** — prose instruction docs (as UI
   fields, not files), prompts/styles, skills (cloud), MCP (connectors), output styles (Styles),
   settings (UI toggles). **emulated** — file-form instruction docs: a `CLAUDE.md`/`AGENTS.md` placed
   in project knowledge is read as _content_, not as an instruction file. **unsupported** — hooks,
   subagents, plugins/bundles.

5. _Cross-capability variants:_ **portable** — MCP/connectors (cross-vendor), and prose instructions
   (map to other chat UIs' custom-instructions). **harness-specific** — profile, styles, memory,
   artifact storage, the sandbox. A capability-contract skill running here takes the **degraded /
   conversational branch** (no user-FS, no persistent shell).

6. _Composition mechanics:_ **layering only** — profile + project instructions + style + preferences
   are all loaded and stacked by the system. **No** `applyTo`/path-scoping, **no** `@import`/include,
   **no** explicit merge directives. Skills carry frontmatter (name/description); instruction surfaces
   are plain.

7. _Activation + load model:_ profile / project instructions / styles / preferences — **auto every
   turn**; project knowledge — **retrieved into context** within a project; skills — **description
   match** (model-invoked, not every turn); memory — auto-injected when enabled; connectors —
   **on-demand tool calls**. Account/project instructions are **prefix-cached**, so per-turn length
   cost is low after turn 1 (length is cheap here).

8. _Validation method:_ **behavioral only** — ask the model directly ("what instructions/style/memory
   are active?") or observe behavior. **No** user-facing diagnostics, `/context`, or logs (a real gap
   vs Claude Code's `/memory` etc.).

9. _Security / secrets boundary:_ secrets must **never** go in any surface (profile, project
   instructions/knowledge, styles, preferences, memory, artifacts, or chat) — memory and project
   knowledge **persist**, so anything sensitive lingers. There is **no env-var/secret-injection
   mechanism**; connector auth is handled by **OAuth tokens managed by the connector**, never exposed
   to the model. Don't hardcode secrets in sandbox code either.

10. _Capability limits / notable absences:_ no shell or git on the user's machine (only the ephemeral
    server-side sandbox); no background/scheduled tasks (Cowork has them); GitHub is **read-only**
    from here (no write/issues); **no automatic cross-chat shared state** — continuity is only via
    memory / past-chat search.

**Claude Code / CLI (terminal + Desktop Code tab) — draft (external observation by claude.ai; Claude Code: confirm/correct from inside):**

- _Instruction surfaces:_ `AGENTS.md` (cross-compat, preferred) and `~/.claude/CLAUDE.md` (user/global,
  all projects); `./CLAUDE.md` + nested per-subdir CLAUDE.md (project); `CLAUDE.local.md` (personal,
  gitignored — being superseded by `@import` / auto-memory); enterprise/managed CLAUDE.md at an
  OS-specific system path; auto-memory at `~/.claude/projects/<project>/memory/MEMORY.md` (only the
  first ~200 lines load — verify); `settings.json` for permissions/hooks/MCP.
- _Capabilities:_ full local filesystem read/write; full shell + git (incl. `gh`); skills with
  `!command` preprocessing and `$ARGUMENTS`, invocable via `/cmd`; hooks; sub-agents; MCP servers
  (`~/.claude.json`, `.mcp.json`, and Desktop's `claude_desktop_config.json`); unrestricted network.
- _Needs:_ CLAUDE.md kept concise — it competes with code for context and is weighted **above** chat
  messages, so noise is costly; build/test/lint commands and paths must be **accurate** (load-bearing
  facts — verify, don't recall); tier-precedence awareness (managed > project > user, more-specific wins).
- _Limits:_ CLAUDE.md is read only by this harness (terminal + Desktop Code tab), not by Chat/Cowork
  the same way; auto-memory truncates (~200 lines); skills cache is siloed/inconsistently synced across
  tabs (anthropics/claude-code#53414); requires local install + auth.

**Cowork (Desktop) — draft (external observation; shares the Claude Code engine but sandboxed; confirm from inside):**

- _Instruction surfaces:_ Settings → Cowork → Global instructions (account-level field); folder
  instructions (a `CLAUDE.md` in the pointed folder, which Cowork can self-update); Cowork Projects
  (persistent context across tasks).
- _Capabilities:_ local file read/write **within granted folders only**; document generation
  (xlsx/pptx/docx/pdf); connectors (Google Workspace, Slack, …); scheduled tasks (run while the app is
  open); sub-agents; same engine as Claude Code underneath.
- _Needs:_ skills must **degrade without a shell** (capability contract); folder context files
  (about-me, rules) kept concise — read before every task, so bloat burns token budget up front.
- _Limits:_ **no shell / git / terminal** (sandboxed VM) — the defining constraint; file access only in
  granted folders; reads the folder before each task (token cost); requires the app to stay open for
  scheduled tasks; skills cache siloing as above.

**GitHub Copilot (VS Code Chat / Agent) — self-description:**

- _Instruction surfaces:_ repo/workspace `.github/copilot-instructions.md`; reusable prompt files
  `.github/prompts/*.prompt.md`; scoped instruction files `*.instructions.md` (frontmatter with
  `applyTo` globs); optional `AGENTS.md` as cross-harness contract; VS Code workspace/user settings.
- _Capabilities:_ local workspace read/write via editor tools; semantic/code search; diagnostics;
  terminal execution; task execution; extension/tool integrations including MCP where configured;
  model/provider selection behind one harness.
- _Needs:_ explicit repo/local/global separation; concise and testable instruction files;
  capability-contract wording (filesystem/shell/network available?) instead of model-brand branching.
- _Limits:_ some taxonomy artifact types are not first-class Copilot primitives (skills/agents/hooks/
  output styles in Claude terms) and need representation via prompts, instructions, tasks, scripts,
  and extensions; behavior varies by extension version, trust policy, and enabled features.

**GitHub Copilot artifact placement (repo vs local vs global)**

| Scope                    | Purpose                        | Preferred location                                                   | Notes                                                                                     |
| ------------------------ | ------------------------------ | -------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| Repo (shared, versioned) | Team instructions              | `.github/copilot-instructions.md`                                    | Primary Copilot repo contract                                                             |
| Repo (shared, versioned) | Reusable prompts               | `.github/prompts/*.prompt.md`                                        | Prompt library invokable from Chat                                                        |
| Repo (shared, versioned) | Scoped instructions            | `**/*.instructions.md` with `applyTo`                                | Path-scoped rules for file groups                                                         |
| Repo (shared, versioned) | Cross-harness base contract    | `AGENTS.md`                                                          | Preferred common denominator across tools                                                 |
| Repo (shared, versioned) | Workspace settings/MCP wiring  | `.vscode/settings.json`                                              | Workspace-level only; no secrets                                                          |
| Repo (shared, versioned) | Task-based automations         | `.vscode/tasks.json`                                                 | Practical replacement for harness hooks                                                   |
| Local machine            | Clone-specific overrides       | local ignore-only files (for example, `.vscode/settings.local.json`) | Prefer user settings; avoid editing tracked workspace settings for personal-only behavior |
| Global user profile      | User-wide Copilot/editor prefs | VS Code User `settings.json`                                         | Cross-repo defaults and personal behavior                                                 |

Typical user settings path by OS:

- Windows: `%APPDATA%\\Code\\User\\settings.json`
- macOS: `$HOME/Library/Application Support/Code/User/settings.json`
- Linux: `$HOME/.config/Code/User/settings.json`

**GitHub Copilot mapping for all artifact types in this taxonomy**

| Artifact type (taxonomy) | Copilot-native?                   | Recommended representation in this repo                               |
| ------------------------ | --------------------------------- | --------------------------------------------------------------------- |
| Instruction docs / rules | Yes                               | `.github/copilot-instructions.md` + `*.instructions.md` + `AGENTS.md` |
| Prompts / prompt packs   | Yes                               | `.github/prompts/*.prompt.md`                                         |
| Skills (Claude-style)    | Not direct                        | Convert to prompts + instruction fragments + scripts/tasks            |
| Subagents                | Not direct                        | Mode-specific instructions + prompt workflows                         |
| Hooks                    | Not direct                        | `.vscode/tasks.json`, git hooks, CI workflows                         |
| MCP servers              | Yes (via config/extensions)       | Workspace/user MCP config via VS Code settings/extensions             |
| Output styles            | Partial                           | Style contracts in instructions/prompts; optional formatter scripts   |
| Settings / permissions   | Yes                               | `.vscode/settings.json` (workspace) + User settings                   |
| Plugins / bundles        | No single native packaging format | Extension packs + repo conventions documented in `docs/`              |

**Cross-capability preference order (Copilot-related authoring)**

1. Prefer `.github/copilot-instructions.md` for Copilot-native repository behavior.
2. Use `*.instructions.md` with `applyTo` for path-scoped deltas.
3. Use `.github/prompts/*.prompt.md` for reusable skill-like procedures.
4. Keep `AGENTS.md` as the cross-harness shared contract.
5. Prefer MCP for tool integration where possible; use vendor-locked mechanisms only when MCP is not viable.

**Methodology to connect files (Copilot)**

- `applyTo` in frontmatter: supported for scoped instruction files (`*.instructions.md`) to target
  paths by glob when the active mode/harness supports that file type.
- Frontmatter metadata: supported in prompt/instruction ecosystems and should declare scope/intent;
  do not assume all frontmatter keys are honored in all modes.
- Include/import: no universal first-class include system across Copilot instruction files.
  Prefer explicit links plus a small index file over hidden transclusion.
- Insert/merge behavior: runtime behavior of the agent/tooling, not a static file include primitive.
  Keep composition explicit and testable.
- Recommended composition pattern: one root contract (`AGENTS.md`) + one Copilot contract
  (`.github/copilot-instructions.md`) + path-scoped deltas (`*.instructions.md`) + procedural
  prompt files (`.github/prompts/*.prompt.md`).

_(All non-claude.ai cells lean on docs + community sources and fast-moving product behavior;
treat as provisional and re-verify when building.)_

### Seed table (harness primary; vendor tag; model excluded; `?` = unverified, don't guess)

| Harness                          | Vendor                              | Artifact      | Location / filename                                     | Load           | File access         | Shell                                           | Cross-compat notes                                                 |
| -------------------------------- | ----------------------------------- | ------------- | ------------------------------------------------------- | -------------- | ------------------- | ----------------------------------------------- | ------------------------------------------------------------------ |
| Claude Code (CLI + Desktop Code) | Anthropic                           | Global instr  | `AGENTS.md`, `~/.claude/CLAUDE.md`                      | Auto           | local-full          | ✅                                              | AGENTS.md preferred over CLAUDE.md                                 |
| Claude Code                      | Anthropic                           | Project instr | `./CLAUDE.md`, `CLAUDE.local.md`                        | Auto/repo      | local-full          | ✅                                              | tier precedence applies                                            |
| Claude Code                      | Anthropic                           | Skills        | `~/.claude/skills/<name>/SKILL.md`                      | Desc / `/cmd`  | local-full          | ✅                                              | `!cmd`, `$ARGUMENTS` available                                     |
| Cowork (Desktop)                 | Anthropic                           | Folder instr  | `CLAUDE.md` in pointed folder                           | Auto on select | local-granted       | ❌                                              | same engine as Code; sandboxed VM                                  |
| Cowork                           | Anthropic                           | Skills        | cloud-synced local cache                                | Desc match     | local-granted       | ❌                                              | no shell — skill must degrade                                      |
| claude.ai / Desktop Chat         | Anthropic                           | Project instr | Project instructions field                              | UI, every turn | sandbox (ephemeral) | sandboxed                                       | no file; set in UI                                                 |
| claude.ai                        | Anthropic                           | Skills        | cloud (account-bound)                                   | Desc match     | sandbox (ephemeral) | sandboxed                                       | don't assume user's local files                                    |
| Codex                            | OpenAI                              | Instructions  | `AGENTS.md`                                             | Auto           | local-full          | ✅                                              | same file as Claude Code — key cross-compat position               |
| Copilot                          | multi (Anthropic/OpenAI/Google/xAI) | Instructions  | `.github/copilot-instructions.md` + `*.instructions.md` | Auto           | local-workspace     | conditional (agent mode/policy/trust dependent) | one harness across models; keep `AGENTS.md` as cross-compat anchor |
| …                                | …                                   | …             | …                                                       | …              | …                   | …                                               | …                                                                  |

Sources for the Anthropic rows: claude.com desktop tutorial (Cowork & Code share one engine);
code.claude.com/docs/en/desktop (Desktop Code tab ≡ CLI for config; models selectable per session);
anthropics/claude-code#53414 (skills siloed across tabs). **Correction for the next agent:** an
earlier turn called Cowork a wholly separate `.claude` tree — stale; Cowork & Code share the engine,
the real difference is Cowork's sandbox (no shell/git). Re-verify capability cells when building;
product behavior here shifts fast.
