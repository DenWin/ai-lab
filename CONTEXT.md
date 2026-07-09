# AI Lab

AI Lab is a source-of-truth repo for AI-assisted-work configuration. It organizes shared skills,
instruction surfaces, and harness-specific support artifacts so multiple AI harnesses can work from
one maintained repo.

## Language

### Core context

**AI Lab**:
The repo itself: the maintained source of truth for AI-assisted-work configuration, documentation,
and sync tooling.
*Avoid*: workspace, toolkit, playground

**Harness**:
A concrete AI runtime or product surface that loads instructions, tools, and config in its own
way. Claude Code, claude.ai, Copilot, and Codex are different harnesses.
*Avoid*: model, vendor, agent

**Vendor**:
The platform/provider namespace above a harness, used for folder scoping such as `anthropic/` or
`openai/`.
*Avoid*: harness, runtime

**Artifact type**:
A top-level repo family defined by what something is, not by who uses it. Examples include
`ai-artifacts/skills/`, `ai-artifacts/instructions/`, `ai-artifacts/mcp-config/`,
`ai-artifacts/prompts/`, and `ai-artifacts/plugins/`.
*Avoid*: bucket, misc, catch-all

**Scope tier**:
The level at which an artifact applies: `shared/`, `<vendor>/`, or `<vendor>/<harness>/`.
More-specific tiers override more-general ones.
*Avoid*: environment, layer

### Skill system

**Skill**:
An invocable, task-shaped instruction package with a `SKILL.md` and optional bundled resources.
In this repo, skills are grouped by intent under `ai-artifacts/skills/shared/<group>/<name>/`.
*Avoid*: script, prompt, command

**Source skill**:
The maintained skill definition under `ai-artifacts/skills/shared/` or another scoped source folder. This is the
editable copy.
*Avoid*: mirror, generated skill

**Generated mirror**:
A harness-specific build artifact produced from source skills, such as `.claude/commands/` or
`.agents/skills/`.
*Avoid*: source skill, canonical copy

**Capability contract**:
The rule that a skill should take the full agentic path when shell/filesystem access exists and
degrade to a conversational fallback when it does not.
*Avoid*: harness-specific branch, hardcoded runtime path

**Sync**:
The act of rebuilding generated mirrors from source artifacts, typically via
`pwsh scripts/sync-skills.ps1`.
*Avoid*: deploy, publish

### Planning and work tracking

**Scratch**:
The repo's committed local-markdown work tracker under `.scratch/`, used for PRDs, issues, ranking,
and support artifacts.
*Avoid*: backlog file, temp folder

**PRD**:
Product Requirements Document. In this repo it is the primary planning document for a scratch
feature folder.
*Avoid*: issue, ADR, spec note

**Issue**:
A smaller tracked work item inside a scratch feature, usually under `issues/`.
*Avoid*: PRD, artifact

**Scratch artifact**:
Supporting material stored under `.scratch/<feature>/artifacts/`. It exists to support planning or
analysis, not to be the final deliverable.
*Avoid*: deliverable, permanent home

**Deliverable**:
A finished repo output that belongs in its real artifact-type home, such as `ai-artifacts/skills/`, `docs/`, or
`ai-artifacts/mcp-config/`, rather than inside `.scratch/`.
*Avoid*: scratch artifact, draft input

### Instruction and config surfaces

**Instruction surface**:
A file or location a harness actually reads as instructions. Repo copies are edited here, but the
live loaded copy may exist elsewhere.
*Avoid*: any markdown file, README

**Repo copy**:
A source-controlled editing copy of a harness-owned artifact whose live version is stored outside
the repo.
*Avoid*: live version, generated mirror

**Live version**:
The copy actually loaded by a harness at runtime, such as a profile field, settings location, or
generated mirror.
*Avoid*: repo copy, source file

**MCP**:
Model Context Protocol. In this repo, MCP-related material belongs under `ai-artifacts/mcp-config/` when it is a
durable repo artifact.
*Avoid*: generic tool config, extension

**Output style**:
A reusable asset that shapes how a model formats or frames its responses.
*Avoid*: skill, instruction surface

### Documentation and provenance

**ADR**:
Architecture Decision Record. It captures a hard-to-reverse, context-sensitive decision that would
otherwise be surprising later.
*Avoid*: PRD, issue, meeting note

**OKF**:
Open Knowledge Format. In this repo it is the lightweight metadata/documentation convention used
where no harness-owned format already controls the file.
*Avoid*: frontmatter in general, runtime instruction format

**Origin map**:
The human-readable summary of where skills came from, maintained in `ai-artifacts/skills/shared/README.md`.
*Avoid*: provenance file, metadata file

## Flagged ambiguities

**Artifact vs scratch artifact**:
An artifact in the broad sense is any repo asset. A scratch artifact is specifically supporting
material inside `.scratch/<feature>/artifacts/` and is not the final home of deliverables.

**Instruction vs settings**:
Instructions tell a harness how to behave. Settings configure a harness or tool. They may overlap in
purpose but do not belong in the same artifact-type folder by default.

**Source of truth vs live version**:
The repo is the source of truth for maintained copies, but some live harness-loaded files exist
outside the repo. Source of truth does not mean every runtime file is read from the repo directly.

**Vendor vs harness**:
The vendor is the provider namespace; the harness is the specific runtime/product surface beneath
it. `anthropic/claude-ai/` names both, in that order.

## Example dialogue

Dev: Should this Codex-specific config live in `.scratch/` until we wire it up?

Domain expert: No. If it is a real deliverable, put it in its artifact-type home. For repo config,
that means something like `ai-artifacts/mcp-config/openai/codex/`.

Dev: Then what belongs in `.scratch/`?

Domain expert: The PRD, any follow-up issues, and supporting artifacts used to reason about the
change. `.scratch/` tracks the work; it is not the final home of the output.

Dev: And if I need to adapt a skill for two harnesses?

Domain expert: Edit the source skill first. The generated mirrors are build artifacts, so you sync
them after the source change rather than editing `.claude/commands/` or `.agents/skills/` directly.
