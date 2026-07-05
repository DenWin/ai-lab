---
name: import-upstream-skill
description: Import a skill from any upstream source into this repo as a first-class, grouped, provenance-tracked skill. Snapshots the source, places it under the right intent group with upstream-* frontmatter, runs the capability-contract adaptation pass, and updates the origin map. Use when user wants to import, vendor, adopt, or pull in a skill from an upstream repo (GitHub, another project) or from a chat/global copy.
---

# Import an Upstream Skill

A repeatable, **source-agnostic** process for bringing an outside skill into this repo. The first
concrete driver was the mattpocock skills repo, but nothing here is specific to it — it works for any
`upstream-repo` (or a local/global copy with no repo).

The single source of truth is `shared/skills/<group>/<name>/SKILL.md` (+ bundled resources). The
`.claude/commands/` copies are a generated mirror — never edit them; rebuild with
`pwsh scripts/sync-skills.ps1`. This skill **imports and adapts**; the sibling
`/setup:check-skill-updates` is what later detects staleness against upstream.

## Process

1. **Snapshot the source.** Capture the upstream `SKILL.md` and every bundled resource verbatim
   before touching them, so the import is reproducible and the pre-adaptation baseline is recorded.
   - GitHub upstream: fetch without cloning —
     `gh api -H 'Accept: application/vnd.github.raw' "repos/<owner>/<repo>/contents/<path>?ref=<commit>"`.
     Pin the **exact commit** you fetched.
   - Local/global copy (chat command, `~/.claude`): copy the file(s) into a scratch `artifacts/` folder.

2. **Pick the intent group.** Place by *what the skill is for*, not the author's folder layout:
   `coding` (writing/changing code) · `planning` (backlog/PRD/issue workflow) · `session`
   (conversational/process skills) · `setup` (repo tooling and skill maintenance). Create a new group
   only when none fit — a new group is a deliberate decision, not a default.

3. **Place it** at `shared/skills/<group>/<name>/SKILL.md` with resources alongside. Use `git mv`-style
   care if you are relocating something already tracked.

4. **Write provenance frontmatter** so `/setup:check-skill-updates` can read the origin directly:
   ```yaml
   upstream-author: <author>
   upstream-repo: https://github.com/<owner>/<repo>
   upstream-path: skills/<author-folder>/<name>/SKILL.md   # path WITHIN the upstream repo
   upstream-commit: <40-char SHA this copy was reconciled to>
   ```
   - `upstream-path` keeps the *author's* folder structure, independent of our intent grouping.
   - **Local fork** (heavily diverged, or a local original that only borrows lineage): record the
     lineage in a comment but **omit `upstream-commit`** so the staleness check skips it. A skill with
     no upstream carries no `upstream-*` fields at all.

5. **Run the adaptation pass** (the capability contract). Where a shell/filesystem is available, take
   the full agentic path; otherwise degrade to a conversational fallback — write "if shell available",
   never "if <harness name>". Concretely: convert bash helpers to pwsh (primary env is Windows/pwsh),
   accept `$ARGUMENTS` where the skill takes input, set `disable-model-invocation: true` on prompt-only
   skills, and turn chat round-trips ("paste the output back to me") into direct tool calls. Preserve
   the author's intent and any local customizations — change mechanics, not decisions. See
   `.scratch/claude-code-skill-adaptation/` for the reference pass.

6. **Verify** the result with `/session:write-a-skill` (structure, description triggers, progressive
   disclosure, references one level deep).

7. **Update the origin map** — add a row to [shared/skills/README.md](../../README.md) (skill, group,
   upstream, notes) so the human-readable summary matches the frontmatter.

8. **Rebuild the mirror:** `pwsh scripts/sync-skills.ps1`, then confirm `/group:name` resolves. If the
   group is new, add its `/.claude/commands/<group>/` mirror path to `.gitignore`.

## Checklist

- [ ] Source snapshotted at a pinned commit (or copied for a local source)
- [ ] Intent group chosen; new group only if truly none fit
- [ ] `upstream-*` frontmatter correct — or fork/local-original rules applied (no dangling `upstream-commit`)
- [ ] Capability-contract adaptation done; bash → pwsh; intent + local customizations preserved
- [ ] Verified via `/session:write-a-skill`
- [ ] `shared/skills/README.md` origin map updated
- [ ] `scripts/sync-skills.ps1` run; `/group:name` resolves
