# PRD — Add the `watch` skill (claude-video) to the repo

Status: needs-triage

Quick capture — iron out in scratch-planning, don't action yet.

## Problem Statement

Import the `watch` skill from the upstream `claude-video` project so Claude can "watch" a video
(URL or local path): download with yt-dlp, extract auto-scaled frames with ffmpeg, pull a transcript
from captions (Whisper API fallback), then reason over frames + transcript to answer questions.

- Upstream repo: https://github.com/bradautomates/claude-video
- Pin commit: `c333c2289e57bf040b32846f18d669e3f8edad9b`
- Author: bradautomates · License: MIT
- Upstream source vendored to [artifacts/watch/](artifacts/watch/) (SKILL.md + `scripts/` Python
  tooling + `scripts/build-skill.sh` + `.codex-plugin/plugin.json`).

## Notes / open questions (for triage, not to action now)

- This is a Python + external-binary skill (yt-dlp, ffmpeg, Whisper API) — a different shape from the
  repo's existing PowerShell/markdown skills. Decide where it lands in the `skills/<group>/` taxonomy
  and how the dual-format deployment (`.claude/commands/`, `copilot/prompts/`) applies, if at all.
- Add upstream-tracking frontmatter (`upstream-author`, `upstream-repo`, `upstream-path`,
  `upstream-commit: c333c22…`) so [[check-updates-detection-scope]] / check-skill-updates picks it up.
- Dependency/runtime story (Python env, yt-dlp/ffmpeg install, Whisper API key) needs a decision.
- Relationship to `import-upstream-skills` (existing batch import flow) — fold in or keep separate?

_Solution: Fill in._
