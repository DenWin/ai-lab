# PRD — Adapt imported skills to native Claude Code form

Status: ready-for-human

The skills under `skills/` were imported from their claude.ai (chat) versions, organized by intent,
and given upstream provenance. They are **invocable** but still **claude.ai-flavored**. This feature
covers the second pass: making each one behave as a native Claude Code skill.

This is the handoff's "Phase 1 — Skill adaptation" deferred from the organize/provenance/sync session.

## Problem Statement

My skills currently work as slash commands, but their bodies were written for the chat interface:
prose response-guidance, "paste the output back to me" round-trips, no use of shell, `$ARGUMENTS`, or
direct repo/file access. In Claude Code the agent can run commands, read files, and take arguments —
so several skills do more work by hand than they need to, and a couple have carried-over content bugs.

## Solution

For each skill, apply the Claude Code capability contract: where a filesystem/shell is available, take
the full agentic path; otherwise degrade to the conversational path. Concretely — use `!command`
preprocessing and direct tool calls where it removes a manual round-trip, accept `$ARGUMENTS` where the
skill takes an input, set `disable-model-invocation: true` on prompt-only skills, and convert prose
chat-guidance into procedural steps. Fix the known content issues along the way. Do **not** change a
skill's intent or its local customizations — only its mechanics.

## User Stories

1. As a Claude Code user, I want each skill to run correctly when invoked as `/group:name`, so the
   workflow matches my intent without chat-interface assumptions.
2. As a Claude Code user, I want `recon` to generate **and run** the read-only probe itself and read
   the output directly, so I don't have to copy-paste probe output back into the conversation.
3. As a Claude Code user, I want `tdd` and `prototype` to actually run tests / build-and-run the
   prototype via shell, so the red-green loop and the throwaway prototype happen in-tool.
4. As a Claude Code user, I want skills that take an input (e.g. `handoff`'s "what is the next session
   for", an issue reference) to accept it as `$ARGUMENTS`, so I can pass it on the command line.
5. As a Claude Code user, I want prompt-only skills marked `disable-model-invocation: true` where they
   should never auto-trigger, so they only run when I ask.
6. As a Claude Code user, I want `write-a-skill`'s broken resource link fixed, so the skill can open
   its own reference material.
7. As a Claude Code user, I want `check-skill-updates` turned into a committed script with a clean
   entry point, so updating skills is one command rather than pasted snippets.
8. As a Claude Code user, I want each adapted skill verified with `/session:write-a-skill`, so the
   structure and progressive disclosure are sound before I rely on it.

## Implementation Decisions

- **Classification drives effort** (from the handoff):
  - *Conversational — light pass:* `caveman`, `grill-me`, `handoff`, `write-a-skill`. Mostly
    frontmatter (`$ARGUMENTS`, `disable-model-invocation`) and prose→steps tidying.
  - *Agentic — real rethink:* `recon`, `tdd`, `prototype`, `check-skill-updates`. Give them tool
    access: run probes/tests/builds, read repo files, CONTEXT.md, ADRs directly.
- **Capability contract, not harness branching.** Write "if shell/filesystem available → full path;
  else → conversational fallback" rather than "if Claude Code do X". Keeps the skills portable to
  Cowork/claude.ai. (Ref: handoff compatibility-matrix design principle.)
- **Edit the source of truth only.** All edits land in `skills/<group>/<name>/SKILL.md`; re-run
  `scripts/sync-skills.ps1` to regenerate the `.claude/commands` mirror. Never edit the mirror.
- **Preserve intent and local customizations.** Stack rules, the `grill-me`←`grill-with-docs` merge,
  Windows/pwsh substitutions all stay. This pass changes mechanics, not content decisions.
- **`check-skill-updates` rework:** extract the inline PowerShell into `scripts/check-skill-updates.ps1`
  (staleness check + three-way-merge helper), and have the SKILL.md drive it. Keep the path-detection
  already pointed at this repo's `skills/` layout.

## Testing Decisions

- Verify each adapted skill loads and triggers: invoke `/group:name` and confirm the body and any
  `!command` preprocessing resolve, and bundled resources open (after `sync-skills.ps1`).
- For agentic skills, exercise the tool path on a throwaway target (run a trivial probe / a trivial
  failing test / a one-route prototype) and confirm the conversational fallback still reads sensibly
  when shell is unavailable.
- Run `scripts/sync-skills.ps1` after each skill edit and confirm the mirror's resource links resolve.
- Structural review of each via `/session:write-a-skill`.

## Out of Scope

- The **setup/init skill design** decision (monolithic vs self-configuring vs config-in-AGENTS.md vs
  minimal tracker-only) — handoff decision #5. Resolve with a `grill-me` pass in its own session; it
  shapes any future agentic skills but isn't required to adapt the existing eight.
- Adopting **new** authors' skills, or new skills not already in `skills/`.
- The wider `ai-lab` repo scaffold (AGENTS.md, compatibility matrix, instructions/, mcp/, etc.) —
  tracked by the repo-structure handoff, not this feature.

## Scope note — which skills this covers

The eight skills imported in pass 1 live under `skills/`. Of these, the **engineering-origin** ones —
`tdd`, `prototype` (mattpocock `engineering/`), and `grill-me` (the `productivity/grill-me` +
`engineering/grill-with-docs` merge) — are adapted **here** (issues 01, 03, 05). The *additional*
mattpocock engineering/misc skills not yet imported are a separate feature:
`.scratch/import-upstream-skills/`, which feeds its own imports back into this adaptation pass (its
issue 06).

## Further Notes

- Reference material is committed under **`artifacts/`** (`.temp/` is gitignored, so these are the
  only durable copies): the pristine **claude.ai originals** (pre-adaptation baseline);
  **`artifacts/global-prior/`** — the user's prior *global* command-form versions, to mine for local
  customizations worth keeping; and **`artifacts/_merged-grill-with-docs-upstream/`** — the upstream
  `grill-with-docs` that `grill-me` absorbed (its lineage is otherwise untracked).
- Source handoff: `.temp/handoff from claude.ai/HANDOFF-ai-lab-repo-structure.md`, "Step 0 / Phase 1".
- Provenance / origin map: `skills/README.md`. Update workflow: the `/setup:check-skill-updates` skill.
- Carried-over content bugs are listed in this folder's issues and in the provenance doc's
  "Known content issues" section.
- `check-skill-updates`' comparison source is settled (GitHub-remote, multi-repo); only script
  extraction remains — see issue 06.
  <!-- [RE-CONFIRM] claude.ai-origin decision; confirm GitHub-remote/multi-repo still holds before script work. -->

