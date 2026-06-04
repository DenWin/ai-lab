# Instructions

Harness-specific instruction files, keyed by harness (matching `docs/harnesses/`). Each file here is
the **repo copy for editing** — the live version lives in that harness's own location. These are
**not interchangeable**: different harnesses read different files, and overlap between them is
expected, not duplication to be merged.

| File | Harness | Live location | Notes |
|---|---|---|---|
| `claude-ai/profile.md` | claude.ai (web / mobile / Desktop **Chat** tab) | Settings → Instructions for Claude | Account-wide profile — paste the whole file into Settings. Keep it domain-agnostic: PowerShell- or project-specific guidance belongs in the relevant claude.ai project, not here. |

## Not the same file (common confusion)

- **`claude-ai/profile.md`** — the claude.ai account profile. Read by the Chat harness only.
- **`~/.claude/CLAUDE.md`** — Claude Code's global instructions. Different harness, different file.
  Expected to **overlap** with the profile (same behavioral preferences) but authored and loaded
  separately. Not yet mirrored here; would live under `instructions/claude-code/` if added.
- **`AGENTS.md`** (repo root, when created) — the cross-harness shared layer read by Claude Code,
  Codex, and Copilot. The place for anything that should be identical across harnesses.

See `docs/harnesses/<harness>.md` for each harness's instruction surfaces and load model.

> The instructions taxonomy (vendor tag, additional harnesses, whether shared content is hoisted
> into `AGENTS.md`) is finalized as part of the repo-scaffold work — see the repo-structure handoff.
