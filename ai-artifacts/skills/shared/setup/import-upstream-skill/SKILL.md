---
name: import-upstream-skill
version: 1.0.0
description: Import a skill from any upstream source into this repo as a first-class, grouped, provenance-tracked skill. Snapshots the source, places it under the right intent group, writes OKF-style METADATA.md provenance, runs the capability-contract adaptation pass, and updates the origin map. Use when user wants to import, vendor, adopt, or pull in a skill from an upstream repo (GitHub, another project) or from a chat/global copy.
---

# Import an Upstream Skill

A repeatable, **source-agnostic** process for bringing an outside skill into this repo. The first
concrete driver was the mattpocock skills repo, but nothing here is specific to it — it works for any
`upstream-repo` (or a local/global copy with no repo).

The single source of truth is `ai-artifacts/skills/shared/<group>/<name>/SKILL.md` (+ bundled resources). The
`.claude/commands/` copies are a generated mirror — never edit them; rebuild with
`pwsh scripts/sync-skills.ps1`. This skill **imports and adapts**; the sibling
`/setup:check-skill-updates` is what later detects staleness against upstream.

## Process

1. **Snapshot the source.** Capture the upstream `SKILL.md` and every bundled resource verbatim
   before touching them, so the import is reproducible and the pre-adaptation baseline is recorded.
   - GitHub upstream: fetch without cloning —
     `gh api -H 'Accept: application/vnd.github.raw' "repos/<owner>/<repo>/contents/<path>?ref=<commit>"`.
     Pin the fetched upstream checkpoint only in the imported skill's `METADATA.md`.
   - Use `.temp/` for transient downloads or unpacked upstream snapshots. Move only durable,
     redacted, intentionally committed reference material into a scratch `artifacts/` folder.
   - Local/global copy (chat command, `~/.claude`): copy the file(s) into `.temp/` first, then promote
     only the needed committed evidence into `artifacts/`.

2. **Pick the intent group.** Place by *what the skill is for*, not the author's folder layout:
   `coding` (writing/changing code) · `planning` (backlog/PRD/issue workflow) · `session`
   (conversational/process skills) · `setup` (repo tooling and skill maintenance). Create a new group
   only when none fit — a new group is a deliberate decision, not a default.

3. **Place it** at `ai-artifacts/skills/shared/<group>/<name>/SKILL.md` with resources alongside. Runtime
   frontmatter should contain only harness-relevant fields plus `version: <semver>`; start new local
   imports at `version: 1.0.0` unless they are explicitly experimental (`0.x.y`). Use `git mv`-style
   care if you are relocating something already tracked.

4. **Write `METADATA.md`** next to `SKILL.md` so `/setup:check-skill-updates` can read the origin
   without loading provenance into the runtime skill. The file follows OKF v0.1 concept conventions:

   ```yaml
   ---
   type: Agent Skill Metadata
   title: <name>
   description: <one-line summary>
   resource: ./SKILL.md
   tags: [<group>, skill]
   upstream-author: <author>
   upstream-repo: https://github.com/<owner>/<repo>
   upstream-path: skills/<author-folder>/<name>/SKILL.md   # path WITHIN the upstream repo
   upstream-commit: <40-char SHA this copy was reconciled to>
   ---
   ```

   - `upstream-path` keeps the *author's* folder structure, independent of our intent grouping.
   - **Local fork** (heavily diverged, or a local original that only borrows lineage): record the
     lineage in the `METADATA.md` body but **omit `upstream-commit`** so the staleness check skips it.
     A skill with no upstream carries no `upstream-*` fields.

5. **Run the adaptation pass** (the capability contract). Where a shell/filesystem is available, take
   the full agentic path; otherwise degrade to a conversational fallback — write "if shell available",
   never "if <harness name>". Concretely: convert bash helpers to pwsh (primary env is Windows/pwsh),
   accept `$ARGUMENTS` where the skill takes input, set `disable-model-invocation: true` on prompt-only
   skills, and turn chat round-trips ("paste the output back to me") into direct tool calls. Preserve
   the author's intent and any local customizations — change mechanics, not decisions. See
   `.scratch/claude-code-skill-adaptation/` for the reference pass.

6. **Verify** the result with `/session:write-a-skill` (structure, description triggers, progressive
   disclosure, references one level deep).

7. **Update the origin map** — add a row to [ai-artifacts/skills/shared/README.md](../../README.md) (skill, group,
   upstream, notes) so the human-readable summary matches `METADATA.md`.

8. **Rebuild the mirror:** `pwsh scripts/sync-skills.ps1`, then confirm `/group:name` resolves. If the
   group is new, add its `/.claude/commands/<group>/` mirror path to `.gitignore`.

## Checklist

- [ ] Source snapshotted at a pinned upstream checkpoint (or copied for a local source)
- [ ] Intent group chosen; new group only if truly none fit
- [ ] Runtime frontmatter includes valid SemVer `version`
- [ ] `METADATA.md` has OKF `type` frontmatter and correct `upstream-*` fields — or fork/local-original rules applied (no dangling `upstream-commit`)
- [ ] Capability-contract adaptation done; bash → pwsh; intent + local customizations preserved
- [ ] Verified via `/session:write-a-skill`
- [ ] `ai-artifacts/skills/shared/README.md` origin map updated
- [ ] `scripts/sync-skills.ps1` run; `/group:name` resolves
