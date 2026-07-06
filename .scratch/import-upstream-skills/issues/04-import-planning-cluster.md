# 04 — Import the planning cluster (to-issues, to-prd, triage)

Status: ready-for-agent

## What to build

Import these from Matt's `engineering/` into `skills/planning/` with `upstream-*` provenance,
copying resources (triage's AGENT-BRIEF, OUT-OF-SCOPE) verbatim, then `scripts/sync-skills.ps1`.
Wire them to read tracker + label config from wherever issue 02 lands, defaulting to this repo's
local-markdown `.scratch/` tracker.

## Acceptance criteria

- [ ] `to-issues`, `to-prd`, `triage` under `skills/planning/<name>/` with `upstream-*` frontmatter
- [ ] triage resources present
- [ ] Skills reference the centralized config (issue 02), not a per-skill copy
- [ ] Default tracker = local-markdown `.scratch/`; `sync-skills.ps1` run; `/planning:*` resolve
- [ ] `/setup:check-skill-updates` shows them `UP-TO-DATE`

## Tracker-contract prerequisites (from `understand-scratch-skill` §3a)

The compatibility analysis in
[`understand-scratch-skill/PRD.md` §3a](../../understand-scratch-skill/PRD.md) compared these three
upstream artifacts against `scratch`'s `LAYOUT.md`. The storage contract already matches; these are
the concrete gaps to close so the imported skills work against `.scratch/`:

- [ ] **Add a `## Comments` convention to `LAYOUT.md`.** `triage` posts triage-notes / agent-brief
      comments and `to-issues`/`to-prd` "publish to the tracker" by appending there — `LAYOUT.md`
      defines no comments section today (`issue-tracker-local.md` already assumes `## Comments`).
- [ ] **Reconcile the status vocabulary.** `triage`'s state roles add `needs-info` (absent from
      `LAYOUT.md`) plus a `bug`/`enhancement` **category** dimension `scratch` has no equivalent for;
      `LAYOUT.md` has `in-progress`/`done` that `triage` lacks (it closes issues instead). Decide:
      extend `LAYOUT.md`'s enum (add `needs-info`) or map roles via the triage-label config, and
      settle how the `bug`/`enhancement` category applies on a feature/PRD tracker.
- [ ] **`to-issues` output must add the `Status:` line** `LAYOUT.md` requires (its upstream template
      omits it); its optional `## Parent` link is harmless to keep.
- [ ] **Drop the `/setup-matt-pocock-skills` handshake:** the skills should read `.scratch/`
      conventions from `LAYOUT.md` directly (single owner) plus a small triage-label map, not a
      monolithic setup skill (issue 07 decision).

## Blocked by

- 01 (planning group), 02 (config distribution)
