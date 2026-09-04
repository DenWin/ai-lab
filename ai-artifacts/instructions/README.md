# Instructions

Harness-specific instruction files, keyed as `ai-artifacts/instructions/<vendor>/<harness>/` (matching
`docs/harnesses/`). Each file here is the **repo copy for editing** — the live version lives in that
harness's own location. These are **not interchangeable**: different harnesses read different files,
and overlap between them is expected, not duplication to be merged.

This folder is intentionally broader than the old name suggested: it holds claude.ai profile
instructions, project instructions, global `CLAUDE.md` copies, Copilot/Codex instruction surfaces,
and equivalent base instruction documents for other AI agents.

Current tracked file:

- `anthropic/claude-ai/profile.md` (claude.ai Chat tab). Live location: Settings → Instructions for Claude.

## Deploying a repo copy

These files often carry OKF frontmatter (`docs/okf-adoption.md`) for repo-side cataloging — revision,
status, sources. That frontmatter is metadata about the file, not content to deploy. Where the live
surface is unstructured prose with no frontmatter parser of its own (e.g. a claude.ai settings field),
deploying means copying the body **below** the closing `---`, never the frontmatter block itself.
Pasting the block turns catalog metadata into live behavioral prompt text and silently consumes the
harness's instruction payload on every turn. See `docs/okf-adoption.md` § "Deploy-time stripping".

## Not the same file (common confusion)

Owned by [docs/repo-layout.adoc](../../docs/repo-layout.adoc) ("Not the same file" section) — not
restated here. Note: earlier versions placed the future Claude Code `CLAUDE.md` repo copy under
`ai-artifacts/instructions/claude-code/` or `ai-artifacts/instructions/anthropic/claude-code/`; the canonical artifact-first
location is now `ai-artifacts/instructions/anthropic/claude-code/CLAUDE.md`.

See `docs/harnesses/<harness>.md` for each harness's instruction surfaces and load model.

> Remaining instructions-taxonomy questions (which shared content is hoisted into `AGENTS.md`) are
> owned by `.scratch/incorporate-global-claude-setup/` (repo-scaffold itself is done).
