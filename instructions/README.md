# Instructions

Harness-specific instruction files, keyed by harness (matching `docs/harnesses/`). Each file here is
the **repo copy for editing** — the live version lives in that harness's own location. These are
**not interchangeable**: different harnesses read different files, and overlap between them is
expected, not duplication to be merged.

| File | Harness | Live location | Notes |
|---|---|---|---|
| `claude-ai/profile.md` | claude.ai (web / mobile / Desktop **Chat** tab) | Settings → Instructions for Claude | Account-wide profile — paste the whole file into Settings. Keep it domain-agnostic: PowerShell- or project-specific guidance belongs in the relevant claude.ai project, not here. |

## Not the same file (common confusion)

Owned by [docs/repo-layout.adoc](../docs/repo-layout.adoc) ("Not the same file" section) — not
restated here. Note: an earlier version of this section placed the future Claude Code `CLAUDE.md`
repo copy under `instructions/claude-code/`; the canonical location per the layout doc is
`anthropic/claude-code/instructions/CLAUDE.md`.

See `docs/harnesses/<harness>.md` for each harness's instruction surfaces and load model.

> Remaining instructions-taxonomy questions (which shared content is hoisted into `AGENTS.md`) are
> owned by `.scratch/incorporate-global-claude-setup/` (repo-scaffold itself is done).
