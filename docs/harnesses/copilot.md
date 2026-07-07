# Harness: GitHub Copilot (VS Code Chat / Agent)

**Vendor:** Multi (Anthropic / OpenAI / Google / xAI — model-selectable)
**Source:** Self-described from inside Copilot, 2026-06
**Note:** Behavior varies by extension version, trust policy, and enabled features. Mark
fast-moving cells with the date verified; re-verify when building.

---

## 1. Instruction surfaces + precedence

1. **Repo/workspace** — `.github/copilot-instructions.md` (primary Copilot contract)
2. **Scoped** — `*.instructions.md` files with `applyTo` frontmatter (path-scoped deltas)
   - Quick sample (`python.instructions.md`):

```md
---
applyTo: "src/**/*.py"
---

Prefer pytest fixtures.
Use type hints on new functions.
```

3. **Prompts** — `.github/prompts/*.prompt.md` (reusable, invokable commands from the Chat)

4. **Cross-harness contract** — `AGENTS.md` at repo root (read as a base layer)
   - Only the root `AGENTS.md` is read. Nested `AGENTS.md` files in subfolders are not discovered by Copilot.
5. **VS Code workspace settings** — `.vscode/settings.json` (MCP wiring, feature flags)
6. **VS Code user settings** — `%APPDATA%\Code\User\settings.json` (Windows) — global defaults

Precedence: more-specific `applyTo` globs win over broader ones; workspace settings override
user settings. Conflict resolution between `copilot-instructions.md` and `AGENTS.md` is `?` —
treat them as additive layers and avoid contradictions.

## 2. Storage split

- **Repo-scoped (committed):** `.github/copilot-instructions.md`, `.github/prompts/`,
  `*.instructions.md`, `AGENTS.md`, `.vscode/settings.json`
- **Machine-local:** `.vscode/settings.local.json` (personal overrides) — typically excluded from git using `.gitignore`
- **User-global:** VS Code user `settings.json` (cross-repo Copilot preferences)

## 3. Disk locations

| Tier                  | Windows                                  | macOS                                                   | Linux                               |
| --------------------- | ---------------------------------------- | ------------------------------------------------------- | ----------------------------------- |
| VS Code user settings | `%APPDATA%\Code\User\settings.json`      | `~/Library/Application Support/Code/User/settings.json` | `~/.config/Code/User/settings.json` |
| Workspace settings    | `<repo>\.vscode\settings.json`           | same                                                    | same                                |
| Repo instructions     | `<repo>\.github\copilot-instructions.md` | same                                                    | same                                |
| Scoped instructions   | `<repo>\**\*.instructions.md`            | same                                                    | same                                |
| Prompts               | `<repo>\.github\prompts\*.prompt.md`     | same                                                    | same                                |

## 4. Artifact mapping

| Artifact type (taxonomy) | Support                           | Recommended representation                                            |
| ------------------------ | --------------------------------- | --------------------------------------------------------------------- |
| Instruction docs / rules | **Native**                        | `.github/copilot-instructions.md` + `*.instructions.md` + `AGENTS.md` |
| Skills / slash commands  | **Emulated**                      | `.github/prompts/*.prompt.md` (invokable from Chat)                   |
| Subagents                | **Emulated**                      | Mode-specific instructions + prompt workflows                         |
| Hooks                    | **Emulated**                      | `.vscode/tasks.json`, git hooks, CI workflows                         |
| MCP servers              | **Native** (via extension config) | Workspace/user MCP config in VS Code settings                         |
| Output styles            | **Partial**                       | Style contracts in instructions/prompts; formatter scripts            |
| Settings / permissions   | **Native**                        | `.vscode/settings.json` (workspace) + user settings                   |
| Plugins / bundles        | **No native format**              | VS Code extension packs + repo conventions in `docs/`                 |

## 5. Cross-compatibility

- **Reads `AGENTS.md`:** yes — treated as a base instruction layer alongside
  `.github/copilot-instructions.md`
- **Preferred cross-harness position:** `AGENTS.md` as the shared contract across Copilot,
  Claude Code, and Codex
- **MCP:** supported via extension; protocol is cross-vendor — only config location differs
- **Capability-contract degradation:** shell/terminal access is conditional (agent mode +
  trust policy + enabled features); write skills that check and degrade if unavailable

## 6. Composition mechanics

- **`applyTo` frontmatter:** supported in `*.instructions.md` — glob-based path scoping
- **Frontmatter metadata:** supported in prompt/instruction files; not all keys honored in all modes
- **Include/import:** no universal first-class include system across Copilot instruction files;
  use explicit links + a small index file instead of hidden transclusion
- **Recommended composition pattern:**
  `AGENTS.md` (cross-harness base) + `.github/copilot-instructions.md` (Copilot contract) +
  `*.instructions.md` with `applyTo` (path-scoped deltas) + `.github/prompts/*.prompt.md`
  (procedural prompt files)

## 7. Activation + load model

| Surface                           | Load model                                   |
| --------------------------------- | -------------------------------------------- |
| `.github/copilot-instructions.md` | Auto, every chat turn                        |
| `AGENTS.md`                       | Auto (as base layer)                         |
| `*.instructions.md`               | Auto when `applyTo` glob matches active file |
| `.github/prompts/*.prompt.md`     | User-invoked from Chat (`/filename`)         |
| MCP tools                         | On-demand tool calls                         |
| VS Code tasks                     | User-triggered or via task runner            |

## 8. Validation

- Ask Copilot: "what instructions are currently active?" — behavioral verification
- Check VS Code Output panel → GitHub Copilot for load logs
- Verify `applyTo` is firing by testing with a file that matches/doesn't match the glob
- MCP: test via a tool call and observe response

## 9. Security / secrets boundary

- **Never** in any committed instruction file (`.github/`, `AGENTS.md`, `*.instructions.md`)
- **Never** in `.vscode/settings.json` (committed) — use environment variables or VS Code's
  secret storage for tokens
- MCP server secrets: inject via environment variables in the server config, not inline
- Local overrides (`.vscode/settings.local.json`) are gitignored — acceptable for machine-local
  non-secret config

## 10. Capability limits / notable absences

- Shell/terminal access is **conditional** — requires agent mode, correct trust policy, and
  enabled features; not always available
- No persistent cross-session memory built into Copilot itself (relies on VS Code state)
- No native hooks/lifecycle events (represent via tasks.json or CI)
- Skills/agents/output-styles are not first-class primitives — must be represented via prompts,
  instructions, and scripts
- Behavior varies significantly by extension version and org trust policy — re-verify on upgrade
- Multi-vendor: model selection affects capability; instruction files work the same regardless
  of which model is behind Copilot

## 11. Evidence metadata

Verification metadata for this document:

- **Verified on:** 2026-06-09
- **Harness/App:** VS Code + GitHub Copilot extension
- **Extension version:** `?` (capture from local extension details when re-verifying)
- **Not yet answered:** TEMPLATE questions 15–16 (Agentic work model, Operational edge cases)
  postdate this doc — answer them at the next full re-verification rather than guessing now.

Confidence by section:

| Section                              | Confidence | Why                                                                                                                                    |
| ------------------------------------ | ---------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| 1. Instruction surfaces + precedence | medium     | Surfaces and load behavior are observed; exact conflict semantics between `AGENTS.md` and `.github/copilot-instructions.md` remain `?` |
| 2. Storage split                     | high       | Paths and ownership tiers are stable in VS Code                                                                                        |
| 3. Disk locations                    | high       | Standard VS Code paths are well-known and consistent                                                                                   |
| 4. Artifact mapping                  | medium     | Mapping is practical but some areas are emulated by convention, not first-class primitives                                             |
| 5. Cross-compatibility               | medium     | `AGENTS.md` and MCP behavior are observed; details can vary by extension/policy                                                        |
| 6. Composition mechanics             | medium     | `applyTo` behavior is reliable; include/import semantics can vary by mode/version                                                      |
| 7. Activation + load model           | high       | Activation model is consistent in normal VS Code Copilot workflows                                                                     |
| 8. Validation                        | high       | Verification methods are reproducible (Output logs, scoped tests, tool calls)                                                          |
| 9. Security / secrets boundary       | high       | Secret-handling guidance follows established VS Code and repo hygiene practices                                                        |
| 10. Capability limits                | medium     | Limits are policy/version dependent and should be re-verified after upgrades                                                           |

## 12. Command + argument mapping

Copilot workflow invocation patterns:

- **Prompt files:** invoke via chat command using prompt filename, for example `/my-prompt`.
- **Repo instructions:** no runtime arguments; always-on context loaded from instruction files.
- **Scoped instructions (`applyTo`):** arguments are implicit via active file path matching.
- **MCP tools:** arguments are structured tool-call parameters defined by each tool schema.
- **VS Code tasks:** arguments are passed through task inputs or task `args` in `tasks.json`.

Fallback when no native command system exists:

1. Use a prompt template section with explicit placeholders (for example, `<target-file>`,
   `<goal>`, `<constraints>`).
2. Ask the user to fill placeholders inline in chat.
3. Treat the filled template as the equivalent of command arguments.

## 13. Capability contract

| Capability                        | Contract    | Notes                                                                                        |
| --------------------------------- | ----------- | -------------------------------------------------------------------------------------------- |
| Filesystem read                   | required    | Needed for codebase grounding                                                                |
| Filesystem write                  | optional    | Depends on mode and trust/policy                                                             |
| Shell/terminal execution          | optional    | Conditional on agent mode and policy                                                         |
| Network access                    | optional    | Depends on environment and extension policy                                                  |
| External tool calls (MCP/plugins) | optional    | Available when configured and enabled                                                        |
| Background/long-running tasks     | unavailable | No first-class Copilot harness primitive; represent via VS Code tasks or external automation |

Degradation rule:

- If a required capability is missing, switch to read-only analysis and emit explicit manual steps.
- If an optional capability is missing, continue with the closest equivalent path.

## 14. Validation smoke tests

Copy-paste checks for this harness doc:

1. **Instruction load check**

- Prompt: "List the active instruction sources affecting this response."
- Pass signal: names `.github/copilot-instructions.md` and `AGENTS.md` (and scoped files when relevant).
- Fail signal: ignores known sources or invents non-existent ones.

2. **Scoped rule (`applyTo`) check**

- Setup: create two files, one matching a scoped glob and one not matching.
- Prompt in each file context: "Which scoped instructions are active here?"
- Pass signal: differing scoped-instruction activation aligned with glob match.
- Fail signal: identical scoped activation for both files without explanation.

3. **Tool integration check (MCP)**

- Action: call one configured MCP tool with a minimal valid input.
- Pass signal: tool executes and returns structured output or a valid, typed error.
- Fail signal: unresolved tool, malformed invocation, or silent no-op.

---

## Cross-compatibility

| Artifact                           | Cross-compat position         | Notes                                                   |
| ---------------------------------- | ----------------------------- | ------------------------------------------------------- |
| `AGENTS.md`                        | **Primary cross-compat file** | Read by Copilot, Claude Code, Codex — the shared anchor |
| `.github/copilot-instructions.md`  | Copilot-native only           | Not read by other harnesses                             |
| `*.instructions.md` with `applyTo` | Copilot-native only           | Path-scoping mechanism specific to Copilot              |
| `.github/prompts/*.prompt.md`      | Copilot-native only           | Closest equivalent to Claude Code skills                |
| MCP                                | Cross-vendor                  | Config location differs per harness                     |
| `.vscode/settings.json`            | VS Code ecosystem only        | Not read by CLI harnesses                               |

**Cross-capability preference order for Copilot authoring:**

1. `AGENTS.md` — shared contract for all harnesses
2. `.github/copilot-instructions.md` — Copilot-native repo behavior
3. `*.instructions.md` with `applyTo` — path-scoped deltas
4. `.github/prompts/*.prompt.md` — skill-like procedures
5. MCP for tool integration over vendor-locked mechanisms

---

## What I need from instruction files

- **Explicit repo/local/global separation** — I have three distinct tiers; conflating them causes
  unexpected sharing or missing instructions
- **Concise and testable** — instruction files should be verifiable; behavioral tests beat hoping
- **Capability-contract wording** — "if filesystem/shell available" not "if Claude Code" — I am
  multi-vendor and the model behind me may change
- **No `applyTo` assumptions** — not every instruction file format supports it; the root
  `.github/copilot-instructions.md` applies globally
- **`AGENTS.md` for portability** — keep anything that should survive a harness switch in `AGENTS.md`
