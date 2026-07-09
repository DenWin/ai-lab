# Harness: Codex CLI / Codex coding agent

**Vendor:** OpenAI
**Source:** Self-described from inside a Codex coding-agent session, 2026-07-06
**Covers:** Codex running as a local/workspace coding agent with shell/filesystem tools, skills,
plugins/connectors, and the managed approval/sandbox model shown in-session.
**Not covered here:** ChatGPT Projects, Codex cloud/task variants, or other OpenAI chat surfaces
whose load model is not visible from this session.

---

## 1. Instruction surfaces + precedence

Observed load order in this session, from broadest to most specific:

1. **System instructions** — platform-level behavior, tool policy, browsing rules, and safety rules.
   These are not stored in the repo and cannot be edited by the user.
2. **Developer instructions** — Codex-specific operating rules, sandbox/approval policy, available
   tools, skill/plugin metadata, and collaboration mode. These override ordinary user/repo guidance
   when they conflict.
3. **Repo instructions** — root `AGENTS.md`, supplied as the workspace instruction file for this
   repo. This is the cross-harness instruction anchor for project-specific operating facts.
4. **User messages** — the explicit task and any follow-up corrections in the conversation.
5. **Skill instructions** — when a skill is selected, its `SKILL.md` must be read from disk before
   task actions. Skill instructions apply only for the turn/task that triggered them.
6. **Tool/runtime constraints** — sandbox mode, writable roots, approved command prefixes, and
   network restrictions are enforced by the harness and override file instructions.

Precedence: system > developer/runtime policy > user/task > repo instructions where they conflict.
For repo-specific working conventions, `AGENTS.md` is the active project contract.

## 2. Storage split

- **Repo-scoped (committed):** `AGENTS.md`, `docs/harnesses/*.md`, shared skills under
  `ai-artifacts/skills/shared/`, repo scripts, and any future Codex-specific repo config under
  `ai-artifacts/mcp-config/openai/codex/`, `ai-artifacts/plugins/openai/codex/`, or instruction
  files under `ai-artifacts/instructions/openai/codex/` if added.
- **Repo-scoped generated (gitignored):** `.agents/skills/`, rebuilt from `ai-artifacts/skills/shared/` by
  `pwsh scripts/sync-skills.ps1`.
- **Machine-local:** Codex home and plugin/skill caches under the user's profile, local approval
  state, local settings, and sandbox/session metadata. These are not committed to this repo.
- **User-global:** account/session-level Codex instructions, installed skills/plugins/connectors,
  and tool availability configured outside the repo.
- **Ephemeral session state:** conversation context, active tool list, current sandbox grants,
  current working directory, and temporary files.

## 3. Disk locations

- Repo root: Windows `C:\GIT\DenWin\ai-lab` in this session; macOS / Linux `<repo>`
- Repo instruction file: Windows `<repo>\AGENTS.md`; macOS / Linux `<repo>/AGENTS.md`
- Repo Codex skill mirror: Windows `<repo>\.agents\skills\`; macOS / Linux `<repo>/.agents/skills/`
- Suggested Codex repo config home: Windows `<repo>\ai-artifacts\mcp-config\openai\codex\` if needed; macOS / Linux `<repo>/ai-artifacts/mcp-config/openai/codex/` if needed
- User Codex home: Windows `%USERPROFILE%\.codex\` observed from skill/plugin paths; macOS / Linux `~/.codex/` presumed (`?`)
- User skills: Windows `%USERPROFILE%\.codex\skills\` observed; macOS / Linux `~/.codex/skills/` presumed (`?`)
- Plugin cache: Windows `%USERPROFILE%\.codex\plugins\cache\` observed; macOS / Linux `~/.codex/plugins/cache/` presumed (`?`)
- Temporary writable area: harness-provided temp directory (`:tmpdir`) on both platforms

Exact Codex settings filenames and all OS-specific config paths are `?` unless observed in a live
session or documented by the active runtime.

## 4. Artifact mapping

| Artifact type                                       | Support                                                                                         |
| --------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| Instruction docs (`AGENTS.md`, custom instructions) | **Native** — root `AGENTS.md` is supplied as repo instructions                                  |
| Skills / slash commands                             | **Native** — repo skills are mirrored to `.agents/skills/<group>-<name>/SKILL.md`               |
| Subagents                                           | **Native / optional** — multi-agent tools may be available through deferred tool discovery      |
| Hooks                                               | **Unsupported / ?** — no Codex lifecycle hook surface is visible in this session                |
| MCP servers                                         | **Native / optional** — MCP resources/tools and app connectors may be available when configured |
| Output styles                                       | **Emulated** — use instructions; no first-class output-style artifact observed                  |
| Settings / permissions                              | **Native** — sandbox mode, writable roots, approval rules, and tool availability are enforced   |
| Plugins / bundles                                   | **Native / optional** — plugin-contributed skills/tools are listed when installed               |

## 5. Cross-compatibility

- **Reads `AGENTS.md`:** yes in this workspace; it is the active cross-harness repo instruction file.
- **Preferred cross-harness file:** `AGENTS.md` for shared operational facts and repo conventions.
- **MCP:** cross-vendor protocol; Codex can use MCP resources/tools when configured, but exact config
  location is runtime-specific.
- **Capability-contract skills:** Codex usually takes the full agentic path when shell/filesystem
  tools are available. If sandbox, network, or write access blocks an operation, the skill should
  degrade to analysis/manual steps or request approval when appropriate.

## 6. Composition mechanics

- **Path-scoped rules:** supported indirectly through nested `AGENTS.md` files when the harness
  supplies them. This session received root `AGENTS.md`; nested loading behavior is `?`.
- **`@import` / include:** no Codex-native instruction transclusion observed.
- **Merge directives:** no explicit repo instruction merge syntax observed.
- **Frontmatter metadata:** skills may use frontmatter or metadata, but the authoritative trigger
  list is the harness-provided skill registry.
- **Plugins/connectors:** installed plugin metadata can contribute skills, tools, and app connectors.

## 7. Activation + load model

| Surface                       | Load model                                                                                                    |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------- |
| System/developer instructions | Auto, every turn                                                                                              |
| `AGENTS.md`                   | Auto-supplied for the workspace/session                                                                       |
| Skills                        | Description-match or explicit user mention; mirrored `.agents/skills/<group>-<name>/SKILL.md` read before use |
| Shell/filesystem tools        | Model-invoked, subject to sandbox and approval policy                                                         |
| MCP resources/tools           | On-demand when configured and exposed                                                                         |
| Plugins/connectors            | Available through installed capabilities or deferred tool discovery                                           |
| Web browsing                  | On-demand, subject to browsing policy and network/tool availability                                           |

Context behavior observed from this session:

- The active conversation, system/developer instructions, repo instructions, and tool results share
  the context budget.
- A context compaction mechanism may summarize older conversation state when needed.
- Skill files are not assumed to be fully loaded until selected; when selected, the relevant
  `.agents/skills/<group>-<name>/SKILL.md` must be read before task actions.
- File contents are not automatically re-read after edits unless the model uses filesystem tools.
- Exact context window size, truncation thresholds, and prefix-caching behavior are `?`.

## 8. Validation

- Ask the model which repo instructions are active and compare against `AGENTS.md`.
- Read `AGENTS.md` directly with filesystem tools and verify behavior follows it.
- For skills, run `pwsh scripts/sync-skills.ps1 -Target Codex -Check` and check that the selected
  `.agents/skills/<group>-<name>/SKILL.md` was read before task actions.
- For shell/tool access, run a harmless command such as `Get-Content AGENTS.md` or `rg --files`.
- For sandbox behavior, attempt an operation that should require approval and confirm the harness
  requests escalation rather than silently bypassing policy.
- For precedence, create a harmless conflict between a user request and repo preference in chat.
  Pass signal: the explicit current user request controls task direction unless system/developer
  policy blocks it; repo conventions still govern how the work is performed.

There is no observed `/context` equivalent or universal diagnostic command in this session.

## 9. Security / secrets boundary

- **Never** put secrets in `AGENTS.md`, docs, skills, `.scratch/`, committed settings, or examples.
- **Never** paste secrets into chat unless the task explicitly requires temporary handling and the
  harness has an appropriate secret path; this session exposes no dedicated secret-injection surface.
- Use environment variables, OS secret stores, MCP connector auth, or local gitignored config for
  secrets when the target tool supports them.
- Treat plugin caches, conversation context, and generated artifacts as non-secret locations.
- This repo is public, so committed files must be safe to publish.
- Remote-processing, telemetry, connector logging, and retention details are not exposed in-session;
  mark them `?` unless confirmed from current product documentation or admin controls.

## 10. Capability limits / notable absences

- Filesystem writes are limited to the workspace and declared writable roots unless approval is
  granted.
- Network access may be restricted; failed dependency downloads or remote calls may require
  escalation or official web-tool browsing.
- GUI/browser control is not inherently available unless a browser/computer-use plugin is installed.
- Background or scheduled tasks are not a first-class Codex primitive in this session.
- Hook lifecycle support was not observed.
- Exact global settings paths and product-version behavior are fast-moving and should be re-verified.

## 11. Evidence metadata

- **Verified on:** 2026-07-06
- **Harness/App:** Codex coding agent in managed workspace, Windows/PowerShell session
- **Version:** `?` (not exposed in-session)

| Section                              | Confidence | Why                                                                                |
| ------------------------------------ | ---------- | ---------------------------------------------------------------------------------- |
| 1. Instruction surfaces + precedence | medium     | Current session shows active layers; exact loader internals are not exposed        |
| 2. Storage split                     | medium     | Repo/session split observed; global config details partly inferred from paths      |
| 3. Disk locations                    | low-medium | Windows paths observed; macOS/Linux paths presumed from convention                 |
| 4. Artifact mapping                  | medium     | Tool/skill/plugin surfaces observed; hooks/settings filenames not verified         |
| 5. Cross-compatibility               | high       | `AGENTS.md` is active in this repo and is the documented shared anchor             |
| 6. Composition mechanics             | low-medium | Absences are based on what is visible in-session                                   |
| 7. Activation + load model           | medium     | Observed through active tool and skill instructions                                |
| 8. Validation                        | medium     | Behavioral/file checks are reproducible; no dedicated diagnostic command observed  |
| 9. Security / secrets boundary       | high       | Matches repo publicness and harness context behavior                               |
| 10. Capability limits                | medium     | Sandbox policy observed; product behavior may change                               |
| 12. Command + argument mapping       | medium     | Chat/tool invocation observed; no native slash-command surface verified            |
| 13. Capability contract              | medium     | Current session capabilities observed; future sessions may differ                  |
| 14. Validation smoke tests           | medium     | Smoke tests are copy-pasteable in this repo                                        |
| 15. Agentic work model               | medium     | Based on active Codex operating instructions and observed tool flow                |
| 16. Operational edge cases           | medium     | Session-specific sandbox/tool behavior observed; global product details remain `?` |

## 12. Command + argument mapping

Codex workflow invocation patterns:

- **Plain chat request:** primary interface. Arguments are natural-language task details, file paths,
  constraints, and follow-up corrections.
- **Skill mention:** user names a skill or the task matches a skill description. The model reads the
  mirrored `.agents/skills/<group>-<name>/SKILL.md` file and follows it for that turn.
- **Tool calls:** arguments are structured by each tool schema, for example shell command, working
  directory, timeout, and escalation request.
- **Plugin/app connectors:** discovered tools expose their own schemas when installed.
- **Repo scripts:** invoked through shell tools, for example `pwsh scripts/sync-skills.ps1`.

Fallback pattern when no native command system exists: write a short prompt template with explicit
placeholders, have the user fill it in chat, then treat the filled prompt as the workflow invocation.

Reusable prompt pattern:

```md
Goal: <what should change or be answered>
Scope: <files, folders, docs, or systems in bounds>
Constraints: <style, safety, compatibility, time, or test constraints>
Expected output: <patch, review, plan, explanation, artifact, or commands>
Verification: <tests/checks to run or explain why they cannot run>
```

## 13. Capability contract

| Capability                        | Contract               | Notes                                                                        |
| --------------------------------- | ---------------------- | ---------------------------------------------------------------------------- |
| Filesystem read                   | required               | Needed for grounded repo work; available in this session                     |
| Filesystem write                  | optional               | Available in workspace/writable roots; approval needed outside them          |
| Shell/terminal execution          | optional               | Available in this session, subject to sandbox/approval                       |
| Network access                    | optional               | Restricted; browse/web tools may be available separately                     |
| External tool calls (MCP/plugins) | optional               | Available when configured and exposed                                        |
| Background/long-running tasks     | unavailable / optional | No first-class scheduler observed; long shell commands may run with timeouts |

Degradation rule: if filesystem or shell is unavailable, switch to read-only/conversational
instructions and provide exact manual commands or patches. If approval is required, request it
through the harness escalation mechanism rather than bypassing the sandbox.

## 14. Validation smoke tests

1. **Instruction load check**

- Prompt: "Which repo instruction file is active for this workspace, and what is its first heading?"
- Pass signal: names `AGENTS.md` and identifies `# ai-lab`.
- Fail signal: misses `AGENTS.md` or invents another repo instruction file.

1. **Scoped-rule check**

- Setup: add or inspect a nested `AGENTS.md` in a subdirectory only if the repo intentionally uses
  one.
- Prompt from work rooted in that subtree: "Which local instruction files affect this path?"
- Pass signal: accurately distinguishes root `AGENTS.md` from any nested file that was supplied.
- Fail signal: claims path-scoped rules without an actual file or loader evidence.

1. **Tool integration check**

- Action: run `Get-Content AGENTS.md` or `rg --files` through the shell tool.
- Pass signal: command returns real repo content/file paths.
- Fail signal: shell unavailable, wrong working directory, or sandbox denial without escalation path.

## 15. Agentic work model

Codex works best when the user states the goal, scope, constraints, and expected verification rather
than prescribing every edit. For normal coding tasks, Codex should inspect the repo, make scoped
changes, run relevant checks when feasible, and report the outcome. For planning or design tasks, it
should stop at analysis unless the user explicitly asks for implementation.

During exploratory or "vibe" work, the useful steering pattern is incremental: describe the desired
direction, react to a concrete draft or patch, then refine. Codex should preserve momentum by making
reasonable assumptions for low-risk choices and should ask only when the missing decision would
change architecture, data safety, public behavior, or destructive actions.

Operational expectations:

- **Planning:** use a short plan for multi-step work; skip ceremony for small edits.
- **Interruption/correction:** newest user message controls the current turn when it conflicts with
  earlier direction.
- **Approval:** request escalation for writes outside permitted roots, destructive actions, GUI
  launch, or blocked network/dependency operations.
- **Retries:** diagnose command failures from output first; retry with escalation only when failure
  is likely sandbox/network related and the command matters.
- **Testing/checkpointing:** run focused checks that match the risk and summarize anything not run.
- **Stop conditions:** stop and ask when required input is unknowable locally and a guess would be
  risky, when policy blocks the requested action, or when repeated attempts hit the same blocker.

## 16. Operational edge cases

- **Generated vs source artifacts:** In this repo, `.claude/commands/` and `.agents/skills/` are
  generated mirrors. Edit `ai-artifacts/skills/shared/<group>/<name>/`, then rebuild with
  `pwsh scripts/sync-skills.ps1`; never edit the mirrors directly.
- **Bootstrap requirements:** A fresh clone or sandbox may not have generated mirrors or local
  harness settings. Use repo scripts and docs to materialize generated state instead of inventing it.
- **Persistence:** Files written under the repo persist in the working tree. Conversation context,
  tool approvals, active tool lists, and plugin state are session/runtime concerns unless explicitly
  stored in files.
- **Sandbox/approval:** This session runs with workspace-write access, restricted network, and
  explicit escalation for operations outside policy.
- **Local caches:** User-global Codex/plugin/skill caches live outside the repo and should not be
  treated as source of truth for this workspace.
- **Generated outputs/logs:** Put durable findings under `docs/`; keep scratch support material under
  `.scratch/<feature>/artifacts/`; avoid committing transient logs unless they are intentionally
  part of a finding.
- **Version discovery:** No Codex version command or UI path was exposed in this session. Record the
  version when the harness exposes it; otherwise use `?`.
- **Known drift risks:** tool availability, plugin discovery, MCP/app connector behavior, sandbox
  policy, network access, and context-management behavior are likely to change faster than repo docs.

---

## Cross-compatibility

| Artifact                            | Cross-compat position                                 | Notes                                                                     |
| ----------------------------------- | ----------------------------------------------------- | ------------------------------------------------------------------------- |
| `AGENTS.md`                         | **Primary cross-harness file**                        | Active in Codex and intended to be shared with other repo-aware harnesses |
| Codex developer/system instructions | Codex-only                                            | Not stored in this repo; supplied by the harness                          |
| Skills                              | Portable by contract, native in Codex when registered | Keep shell/filesystem checks capability-based                             |
| MCP                                 | Cross-vendor                                          | Config and auth location differ by harness                                |
| Hooks                               | No verified Codex equivalent                          | Use scripts, CI, or harness-specific automation elsewhere                 |
| Plugins/connectors                  | Harness-specific packaging                            | Underlying tools may map to MCP or app connectors                         |

**Design principle:** keep shared repo facts in `AGENTS.md`; keep Codex-specific behavior in
`ai-artifacts/instructions/openai/codex/`, `ai-artifacts/mcp-config/openai/codex/`, or
`ai-artifacts/plugins/openai/codex/` only when it cannot be expressed portably.

---

## What I need from instruction files

- **Concise and operational** — repo commands, ownership rules, and safety boundaries matter most.
- **Capability-based wording** — say "if shell/filesystem is available", not "if Codex".
- **Concrete paths and commands** — prefer exact repo paths and PowerShell commands for this repo.
- **No secrets** — this public repo and conversation context are not secret stores.
- **Single owner per fact** — link to canonical docs instead of restating facts in multiple places.
