# ai-lab

Source-of-truth repo for AI-assisted-work configuration: portable agent skills, harness
instructions, and the sync tooling that deploys them to each AI harness (Claude Code, claude.ai,
Copilot, Codex, ...).

## Getting started

```powershell
pwsh scripts/setup-repo.ps1
```

This enables git hooks and builds the generated harness mirrors (`.claude/commands/`,
`.agents/skills/`, `.github/skills/`) from the source skills under `ai-artifacts/skills/shared/`.

## Where to look

- [AGENTS.md](AGENTS.md) — operational facts and rules for agents working in this repo
- [CONTEXT.md](CONTEXT.md) — domain language and terminology
- [docs/repo-layout.adoc](docs/repo-layout.adoc) — full folder layout reference
- [coding-policies/](coding-policies/) — cross-language and per-language policy rules enforced in CI

## License

[MIT](LICENSE)
