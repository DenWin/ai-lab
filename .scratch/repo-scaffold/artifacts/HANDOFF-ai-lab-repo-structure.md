# Handoff — Create `ai-lab` initial repo structure

**Next session focus:** two sequential tasks — (1) adapt the existing skill set for Claude Code
before the repo exists, then (2) scaffold the `ai-lab` repo and place everything. Run in
**Claude Code** (not claude.ai web — write access requires local `git`/`gh` auth).

Do NOT conflate with the evaluate-source skill + harness build; that is a separate pending
handoff (`HANDOFF-eval-skill-harness.md`, same output folder).

---

## Requirements (settled — don't re-derive)

**Repo name:** `ai-lab`

**Scope:** all AI-related work, multi-vendor and multi-harness:

- Vendors: Anthropic, OpenAI, Google, xAI, … (extensible)
- Harnesses: claude.ai, Cowork, Claude Code, Claude CLI, Codex, Copilot, … (extensible)
  (Copilot is a multi-vendor _harness_ — miscategorised as a "platform" in the original ask.)
- Artifact types: instruction docs (incl. `rules/`), skills, subagents, hooks, MCP servers,
  output styles, settings, plugins (bundles). (Original list named only the first four.)

**Goals (in priority order):**

1. One repo as the single home — version-controlled, reachable from all tools.
2. Cross-vendor reuse: artifacts portable or adaptable across vendors
   (e.g. ask OpenAI to build something analogous to a Claude skill, or vice versa).
3. **Cross-compatibility preferred** — use the broadest-compatible filename/format where one
   exists: `AGENTS.md` over `CLAUDE.md` or `copilot-instructions.md`; and MCP over a
   vendor-specific artifact where a capability could be either (MCP is the one cross-vendor type).
4. Living documentation: a reference updated over time, tracking what each harness/artifact type
   supports and where cross-compatible positions exist.

---

## Step 0 — Skill adaptation (do this before the repo exists)

**Why first:** the skills currently available are claude.ai-flavored — designed for the chat
interface, project knowledge, prose instructions. Claude Code skills are a different format and
context. Placing unadapted claude.ai skills into the repo would put the wrong artifact in.

**What the user will provide at the start of the session:**

1. Their claude.ai skill folder names (the set built in claude.ai Projects).
2. The mattpocock original folder names (from `github.com/mattpocock/skills` — already cloned
   and inspected; full tree is in this session's context).

From those two inventories, generate Claude Code adaptations that are **the user's own** —
their naming, their conventions, their needs. Not branded as mattpocock's.

**Key format differences to handle in adaptation:**

| Aspect             | claude.ai skill                        | Claude Code skill                                             |
| ------------------ | -------------------------------------- | ------------------------------------------------------------- |
| Trigger mechanism  | Description match in project knowledge | `/skill-name` slash command or description match              |
| Shell access       | None                                   | `!command` syntax injects shell output into context at load   |
| Parameterization   | N/A                                    | `$ARGUMENTS` substitution                                     |
| Invocation flags   | N/A                                    | `disable-model-invocation: true` (prompt-only, no model call) |
| Typical body shape | Prose response-guidance for chat model | Procedural steps with bash ops where needed                   |
| Context references | Relies on project knowledge files      | Can read repo files, CONTEXT.md, ADRs directly                |

Not all skills need all of this — conversational skills (grill-me, handoff, write-a-skill) adapt
with minimal change; agentic skills (to-issues, to-prd, tdd, recon) need real rethinking for
Claude Code's tool access.

**The setup-skill design question (open — confirm with user before building):**
Matt's pattern: one monolithic `/setup-matt-pocock-skills` that front-loads tracker config,
labels, and domain-doc layout. User is questioning this split. Options:

- Keep a setup/init skill (leaner, user's own, not Matt's branding) — explicit one-time run.
- Self-configuring skills: each skill that needs tracker/context discovers it or degrades gracefully.
- Fold configuration into `AGENTS.md` / `CONTEXT.md` and skills just read it.
- Hybrid: minimal `init` for the tracker (which `gh issue create` vs `.scratch/`), nothing else.

Do NOT pre-answer this — run `grill-me` on the design before building the setup skill.
The decision affects every agentic skill in the set.

**Ownership note:** the user wants this skill set to be theirs. Rename folders, drop mattpocock
references, align naming with their own conventions. The skills were a starting point, not a brand.

## Proposed structure (provisional — reconcile with decisions #6 and #7 before scaffolding)

> ⚠ This tree predates the taxonomy (#6) and artifact-type/packaging (#7) decisions. The artifact
> _folders_ are settled (all eight types need a home); the _keying_ (`<vendor>/<harness>/` nesting)
> and whether folders sit top-level vs nested inside plugin bundles are OPEN — don't commit until
> #6/#7 are resolved.

```
ai-lab/
├── AGENTS.md                 # root cross-compatible instructions (Claude Code, Codex; ref for others)
├── docs/
│   ├── compatibility-matrix.md   # the living doc (name per #6 — "platform" is deprecated)
│   └── harnesses/                # per-harness detail pages
│       ├── claude-ai.md
│       ├── claude-code.md
│       └── cowork.md
├── instructions/
│   ├── global/               # account-wide / cross-vendor (e.g. profile)
│   └── <vendor>/<harness>/   # specific overrides — keying per #6
├── ai-artifacts/
│   ├── skills/               # <vendor>/<harness>/ OR nested in plugin bundles — per #6/#7
│   ├── agents/               # subagents
│   ├── hooks/                # hook scripts / hooks.json
│   ├── mcp-config/           # MCP server defs (.mcp.json)
│   ├── output-styles/        # reusable output styles
│   ├── prompts/              # reusable prompt packs
│   ├── instructions/         # harness instruction surfaces
│   └── plugins/              # plugin packaging
└── eval/
    └── INSTRUCTION-EVAL.md
```

**Design rationale:**

- `AGENTS.md` at root is the broadest-compatible entrypoint; harness/vendor-specific files
  (`CLAUDE.md`, `copilot-instructions.md`) live under `ai-artifacts/instructions/`, keyed per #6.
- The living doc maps (harness × artifact type) with vendor as a tag — not "platform × harness".
  Start minimal; grow as knowledge grows.
- If plugins win (#7), `ai-artifacts/skills/`, `ai-artifacts/agents/`, `ai-artifacts/hooks/`, `mcp/`, `ai-artifacts/output-styles/` nest inside
  `plugins/<name>/` rather than at top level.
- `eval/` holds `INSTRUCTION-EVAL.md` (built) + the pending harness (separate handoff).
- `instructions/global/` holds the account-wide profile copy (source of truth stays Settings →
  Instructions for Claude; repo copy is the edit base).

**Open design decisions for next session (don't pre-answer — confirm with user):**

1. Tracker: GitHub Issues (default, uses `gh issue create`) vs local-markdown
   (`.scratch/` files, zero-auth). Set during whatever init approach #5 lands on — not necessarily
   a `/setup-matt-pocock-skills` call (that skill is itself under redesign).
2. Depth of `docs/harnesses/`: start with a full page per harness, or a single matrix table only
   and grow detail pages lazily?
3. PowerShell-Skripte project-specific files (`02-project-instructions.md`, `CLAUDE.md`,
   `POWERSHELL.md`, `powershell.yml`) — these belong to a specific claude.ai project, not
   the global repo. Options: (a) move under `ai-artifacts/instructions/` keyed per #6 (e.g.
   `…/anthropic/projects/pwsh/`); (b) leave them in the claude.ai project only; (c) both. Confirm.
4. `ai-artifacts/skills/shared/` concept: define what makes a skill "shared" — a skill whose _intent_ is
   cross-vendor (logic documented once, adapted per harness), or one whose _file format_ runs on
   multiple harnesses unchanged? (Ties to the capability-contract principle below.)
5. Setup/init skill shape: monolithic setup skill (Matt's pattern) vs self-configuring vs
   config-in-AGENTS.md vs minimal tracker-only init. Resolve in Step 0 grill-me before
   building any agentic skill.
6. Terminology alignment: the matrix taxonomy below settles on **harness** (primary) + **vendor**
   (tag), with **model** excluded. The structure proposal and Requirements still say "platform"
   (and list Copilot as one — it's a harness). When scaffolding, decide the folder keys
   accordingly: e.g. `ai-artifacts/instructions/<vendor>/<harness>/`, `ai-artifacts/skills/<vendor>/<harness>/`, and rename
   `docs/platforms/` → `docs/harnesses/`. Don't silently keep "platform" — it's the ambiguity
   this session flagged. This includes the living doc's own filename: rename `platform-matrix.md`
   → e.g. `compatibility-matrix.md` or `harness-matrix.md`.
7. Packaging: loose artifact folders (`ai-artifacts/skills/`, `ai-artifacts/agents/`, `ai-artifacts/hooks/`, `mcp/`, `ai-artifacts/output-styles/`,
  `ai-artifacts/mcp-config/`, `ai-artifacts/plugins/`) vs Claude Code **plugin bundles** (`.claude-plugin/plugin.json` wrapping them).
   Plugins are the native share/install unit and compose cleanly; loose folders are simpler but
   not directly installable. Regardless of choice, the structure currently has no home for MCP
   defs, output styles, or settings — add them.

---

## Existing artifacts to place in the repo

All are in the session output folder or `/home/claude/files_extracted/`. Destination paths below
assume the #6 keying (`<vendor>/<harness>/`) and will shift if #6/#7 land differently (e.g. nested
in plugin bundles) — treat them as illustrative, not committed.

| File                                                                                                         | Proposed destination                                         | Notes                                                                                                                              |
| ------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------- |
| `01-profile-instructions.md`                                                                                 | `instructions/global/profile.md`                             | Repo copy for editing; live version is Settings → Instructions for Claude                                                          |
| `01-profile-instructions - PriorVersion.md`                                                                  | only as a reference                                          | the prior version of 01-profile-instructions.md                                                                                    |
| `INSTRUCTION-EVAL.md`                                                                                        | `eval/INSTRUCTION-EVAL.md`                                   | Built this session; final                                                                                                          |
| `SKILL.md` (powershell-reference, in `mnt/`)                                                                 | `skills/anthropic/claude-code/powershell-reference/SKILL.md` | claude.ai version — needs Claude Code adaptation in Step 0                                                                         |
| `skills/powershell-ci/SKILL.md` + `powershell.yml`                                                           | `skills/anthropic/claude-code/powershell-ci/`                | claude.ai version — needs Claude Code adaptation in Step 0                                                                         |
| All existing skills (grill-me, handoff, write-a-skill, recon, tdd, prototype, caveman, to-issues, to-prd, …) | `skills/anthropic/claude-code/<name>/` after adaptation      | **claude.ai-only until Step 0 runs.** User provides folder names; adaptations generated then. Place in repo only after adaptation. |
| `02-project-instructions.md`, `CLAUDE.md`, `POWERSHELL.md`, `powershell.yml`                                 | TBD — confirm open decision #3 above                         | Project-specific; don't assume they go in global repo                                                                              |
| `HANDOFF-eval-skill-harness.md`                                                                              | `eval/.scratch/` or issue                                    | Pending build; separate session                                                                                                    |

---

## First steps for next session (in order)

### Phase 1 — Skill adaptation (before the repo exists)

1. User provides: (a) their claude.ai skill folder names, (b) mattpocock original folder names.
2. Run `grill-me` on the setup/init skill design question (decision #5) — resolve before
   building any agentic skill. This decision shapes every skill that follows.
3. For each skill in the combined inventory: classify (conversational → light adapt;
   agentic → rethink for Claude Code), then generate the Claude Code version under the
   user's own naming convention. Verify with `write-a-skill`.
4. Output: a set of Claude Code SKILL.md files ready to commit, with the user's naming,
   no mattpocock branding.

### Phase 2 — Repo scaffold

5. `git init` + `gh repo create ai-lab --public` (or `--private`) — confirm visibility.
6. Resolve the tracker decision (GitHub Issues vs local-markdown `.scratch/`) — replaces
   the `/setup-matt-pocock-skills` call; decide based on outcome of decision #5.
7. Scaffold the directory structure (confirm proposal in this doc first — run `grill-me`
   if user wants an adversarial pass).
8. Place existing non-skill files (profile, INSTRUCTION-EVAL, project files) per the
   artifact inventory above.
9. Place the adapted Claude Code skills from Phase 1 into `ai-artifacts/skills/`.
10. Author `AGENTS.md` root stub and the living compatibility-matrix draft (filename per #6).
11. Initial commit + push.
12. (Optional) In claude.ai: Settings → Connectors → GitHub Integration → connect + add
    `ai-lab` to the relevant project for read-only file sync.

---

## `platform-matrix.md` — taxonomy + harness self-descriptions

### Taxonomy: harness is the primary key (don't use "platform")

The matrix is a _load-mechanics + capabilities lookup_, not a feature catalogue. For each
(harness × artifact type) it answers: where the artifact lives, how it loads, what capabilities
that environment exposes, whether a cross-compatible position exists. Skills and instruction docs
are _authored against this table_.

Three axes, only one of which is the key:

- **Harness** — the surface/product you work through (claude.ai, Claude Code, Cowork, ChatGPT,
  Codex, Copilot, …). **Primary key** — it determines load mechanics + capabilities.
- **Vendor** — who makes the model(s) (Anthropic, OpenAI, Google, xAI). A **tag**, not a parent
  category: a harness is single-vendor (claude.ai → Anthropic) or multi-vendor (Copilot → many).
  Matters only for which native instruction-file format applies and for cross-vendor porting.
- **Model** (Opus 4.8 / GPT-x.y / Grok / …) — **excluded.** Selectable per session, changeable
  mid-session; never changes load mechanics. Model-sensitivity (fidelity, context budget) is an
  authoring + cross-model-eval concern, not a matrix cell. Do NOT add a model axis — pure
  complexity with no load-mechanic payoff.

Why not "platform": it conflates vendor and harness. Copilot is the proof — one harness running
Anthropic, OpenAI, Google, and xAI models behind one instruction file. Vendor can't sit above
harness.

**Capabilities axis (the load-bearing column set):** per harness — file access (none / ephemeral
sandbox / local-granted / local-full), shell, network, persistent storage/memory. This is what
makes a "robust, works-with-or-without-storage" skill possible.

**Design principle:** write skills to a **capability contract, not a harness branch.** Not "if
Claude Code do X, if Desktop do Y" (brittle). Instead: "if filesystem/shell available → full path;
else → degrade to conversational." The matrix is the capability lookup; the skill reads the
contract. Future-proof: a new harness is a new row, not a skill rewrite.

### Artifact / config types (the second key — original list was incomplete)

The "artifact type" axis needs a fuller vocabulary. Claude Code (richest harness) authors all of:

| Type                                                | Where (Claude Code)                    | Cross-harness?                                                                 |
| --------------------------------------------------- | -------------------------------------- | ------------------------------------------------------------------------------ |
| Instruction docs (+ `rules/` path-scoped fragments) | `CLAUDE.md`, `AGENTS.md`, `rules/`     | most harnesses, varying files                                                  |
| Skills (slash commands now unified in)              | `skills/<name>/SKILL.md`               | Claude family; others vary                                                     |
| Subagents                                           | `agents/*.md`                          | Claude Code                                                                    |
| Hooks                                               | `hooks.json` / `settings.json`         | Claude Code                                                                    |
| Output styles                                       | `ai-artifacts/output-styles/`                       | Claude Code                                                                    |
| **MCP servers**                                     | `.mcp.json`, `~/.claude.json`          | **cross-vendor (open protocol)** — Codex, Cursor, etc.; config location varies |
| Settings / permissions                              | `settings.json`, `settings.local.json` | Claude Code                                                                    |
| Plugins (bundle wrapping all the above)             | `.claude-plugin/plugin.json`           | Claude Code                                                                    |

- **MCP is the only natively cross-vendor type** (open protocol) — strong cross-compat position;
  only config location differs per harness. Give it its own matrix rows per harness.
- **Plugin = Claude Code's native packaging unit** — one folder bundling skills/agents/hooks/
  commands/mcp/output-styles. Forces the repo packaging decision (#7).
- Slash commands are no longer a separate type — unified into skills (2026).
- The original structure proposal has **no home** for MCP defs, output styles, or settings — fix
  when scaffolding.

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

---

## Suggested skills

- `grill-me` — (a) adversarial pass on the setup/init skill design before building it;
  (b) adversarial pass on the repo structure before committing.
- `write-a-skill` — for generating each Claude Code skill adaptation in Phase 1.
- `recon` — verify environment before Phase 2 (`git` version, `gh` auth, existing repos,
  Claude Code skill path conventions).
- _(No `/setup-matt-pocock-skills` — that skill is the subject of redesign in decision #5,
  not a dependency to run first.)_

---

## Sensitive info

None. Do not hardcode API keys; if the harness or any script needs them, read from env vars.
