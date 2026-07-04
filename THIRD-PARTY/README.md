# Third-party notices

This repo redistributes adapted copies and verbatim snapshots of upstream work. Each upstream's
license is preserved here; per-skill provenance (`upstream-*` frontmatter) records the exact
source path and pinned commit. The human-readable origin map is
[shared/skills/README.md](../shared/skills/README.md).

| Upstream | License | Pinned commit | Where used in this repo |
|---|---|---|---|
| [mattpocock/skills](https://github.com/mattpocock/skills) | [MIT](mattpocock-skills.LICENSE) | `aaf2453fbdfe7a15c07f11d861224f34ab4b53cb` | Adapted skills under `shared/skills/` (tdd, prototype, caveman, grill-me, handoff, write-a-skill); verbatim snapshots under `.scratch/import-upstream-skills/artifacts/` and `.scratch/claude-code-skill-adaptation/artifacts/` |
| [bradautomates/claude-video](https://github.com/bradautomates/claude-video) | [MIT](bradautomates-claude-video.LICENSE) | `c333c2289e57bf040b32846f18d669e3f8edad9b` | Verbatim snapshot under `.scratch/add-watch-skill/artifacts/watch/` (not yet adapted) |

When vendoring a new upstream, add its license file here (`<owner>-<repo>.LICENSE`) and a row to
this table in the same commit that lands the vendored content.
