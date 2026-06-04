# Harness: claude.ai (web / mobile / Desktop Chat tab)

**Vendor:** Anthropic  
**Source:** Self-described from inside claude.ai, 2026-06  
**Note:** The Desktop Chat tab and web/mobile share this description. The Desktop Code tab is a
different harness — see [claude-code.md](claude-code.md).

---

## 1. Instruction surfaces + precedence

Settings → Instructions for Claude (account-wide profile); project instructions field; project
knowledge files; styles; user preferences; memory (past-chat generated, off in Incognito).

**Precedence:** latest in-conversation instruction wins; style > preferences on conflict; profile
and project instructions both apply every turn (project layer is additive, scoped to the project).
No single documented chain beyond this — treat finer ordering as `?`.

## 2. Storage split

- **User-global** (account-bound): profile, styles, preferences, cloud skills, memory
- **Project-scoped** (nearest equivalent to repo-scoped): project instructions + project knowledge
- **Ephemeral**: code-execution sandbox
- **Per-artifact persistent**: artifact key-value store
- **No machine-local tier**

## 3. Disk locations

None on the user's machine — defining trait vs Claude Code/Cowork. All surfaces are server/account-side;
uploads are transient. The only filesystem is a server-side Linux container (`/home/claude`,
`/mnt/user-data/…`), not Windows/macOS/Linux client paths.

## 4. Artifact mapping

| Artifact type | Support |
|---|---|
| Instruction docs | **Native** — as UI fields (profile, project instructions), not files |
| Skills / slash commands | **Native** — cloud, account-bound, description-match |
| Subagents | **Unsupported** |
| Hooks | **Unsupported** |
| MCP servers | **Native** — via Connectors (OAuth-managed, not user-configured) |
| Output styles | **Native** — Styles (UI) |
| Settings / permissions | **Native** — UI toggles |
| Plugins / bundles | **Unsupported** |
| AGENTS.md / CLAUDE.md as files | **Emulated** — placed in project knowledge, read as content, not as an instruction file |

## 5. Cross-compatibility

- **Reads `AGENTS.md`:** only if placed in project knowledge — treated as text content, not as a
  native instruction file. Does not auto-load from a repo.
- **Preferred cross-harness position:** prose instructions in the project instructions field map to
  other chat UIs' custom-instructions. MCP/Connectors map to other harnesses' MCP configs.
- **Capability-contract degradation:** takes the conversational / degraded branch — no user
  filesystem, no persistent shell. Skills that check for filesystem/shell and fall back to
  "describe what to run and paste back the output" work correctly here.

## 6. Composition mechanics

Layering only — profile + project instructions + style + preferences are stacked by the system.
No `applyTo`/path-scoping, no `@import`/include, no explicit merge directives. Skills carry
frontmatter (name/description); instruction surfaces are plain prose.

## 7. Activation + load model

| Surface | Load model |
|---|---|
| Profile / project instructions / styles / preferences | Auto, every turn |
| Project knowledge | Retrieved into context (within a project) |
| Skills | Description-match (model-invoked, not every turn) |
| Memory | Auto-injected when enabled |
| Connectors (MCP) | On-demand tool calls |

Account/project instructions are prefix-cached — per-turn length cost is low after turn 1.

## 8. Validation

Behavioral only — ask the model ("what instructions/style/memory are active?") or observe
behavior. No user-facing diagnostics, `/context`, or logs. This is a real gap vs Claude Code.

## 9. Security / secrets boundary

Secrets must **never** go in any surface — profile, project instructions/knowledge, styles,
preferences, memory, artifacts, or chat. Memory and project knowledge **persist**, so anything
sensitive lingers indefinitely. No env-var/secret-injection mechanism exists. Connector auth is
handled by OAuth tokens managed by the connector — never exposed to the model. Do not hardcode
secrets in sandbox code either.

## 10. Capability limits / notable absences

- No shell or git on the user's machine (only the ephemeral server-side sandbox)
- No background/scheduled tasks (Cowork has these)
- GitHub is read-only from here — no `gh issue create`, no push
- No automatic cross-chat shared state — continuity only via memory / past-chat search
- No hooks, subagents, plugins

---

## Cross-compatibility

| Artifact | Cross-compat position | Notes |
|---|---|---|
| Instruction docs | prose instructions → other chat UIs' custom-instructions | No file-form equivalent |
| MCP | Connectors → other harnesses' `.mcp.json` config | Protocol is cross-vendor; only the config location differs |
| Skills | cloud-only, account-bound | No file-form equivalent consumable by other harnesses |
| AGENTS.md | can be placed in project knowledge as reference text | Not a native load — other harnesses auto-load it |

**Design principle:** write skills to a capability contract, not a harness branch. If shell/filesystem
is unavailable, take the conversational fallback. This harness always takes the fallback branch.

---

## What I need from instruction files

- **Concise** — every byte in project instructions is in context every turn; bloat costs tokens on
  every message
- **Prose, not files** — I load instructions from UI fields, not files in the repo
- **No secrets** — I have no secure injection mechanism; anything written persists
- **Explicit scope** — I don't path-scope instructions; all project instructions apply to all
  conversations in the project
