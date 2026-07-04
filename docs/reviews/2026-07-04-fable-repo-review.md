# ai-lab — Repo Review

- **Date:** 2026-07-04
- **Reviewer:** Claude Fable 5 (Claude Code, VS Code extension), on request
- **Scope:** whole repo — intent, pros/cons/improvements, plus commentary on every `.scratch/` entry
- **Point-in-time artifact:** this report reflects the repo as of commit `169e9a3` (before the
  fixes it triggered). It is deliberately *not* updated as facts change — the living state is in
  the [backlog](../../.scratch/BACKLOG.md).

**Outcomes** — the review's improvements were captured as five "fable" scratches, and several were
executed the same day:

| Scratch | State after the review session |
|---|---|
| [sync-skills-drift-check](../../.scratch/sync-skills-drift-check/PRD.md) | ✅ done — `-Check` mode + hook |
| [docs-integrity-pass](../../.scratch/docs-integrity-pass/PRD.md) | ✅ done — 4 drift fixes + decay contract |
| [public-repo-compliance](../../.scratch/public-repo-compliance/PRD.md) | ⏳ ready-for-human — attribution + protections done; profile go/no-go open |
| [backlog-hygiene-wip-limit](../../.scratch/backlog-hygiene-wip-limit/PRD.md) | needs-triage |
| [repo-scope-strays](../../.scratch/repo-scope-strays/PRD.md) | needs-triage |

Also executed on the back of the review: `repo-scaffold` completed (root `AGENTS.md` authored).

---

## 1. What the repo is

`ai-lab` is a personal **control plane for AI-assisted work across multiple harnesses**. Four pillars:

1. **Skills as source of truth** — `shared/skills/` holds portable, provenance-tracked skills
   (grouped by intent: coding/planning/session/setup), deployed into Claude Code's
   `.claude/commands/` via `scripts/sync-skills.ps1`. The mirror is a gitignored build artifact.
2. **Harness knowledge base** — `docs/harnesses/` documents each harness *from the inside*
   (self-description via `TEMPLATE.md`): instruction surfaces, precedence, storage tiers,
   capability limits. The "capability contract" (shell available → full path; else conversational
   fallback) is the portability mechanism that lets one skill copy serve all harnesses.
3. **Instructions as versioned artifacts** — `instructions/` +
   `anthropic/claude-ai/instructions/profile.md` treat instruction files as repo-managed source
   with harness-specific live locations, organized by the specificity tiers in
   `docs/repo-layout.adoc` (`shared/` → `<vendor>/` → `<vendor>/<harness>/`, most-specific wins).
4. **A self-hosted tracker** — `.scratch/` is a committed local-markdown issue tracker
   (PRD + issues + ranked `BACKLOG.md`) that manages the lab's own evolution.

The intent in one sentence: *make AI configuration reproducible, portable, and evaluable, the way
code is.*

## 2. Pros

- **The organizing principle is genuinely good.** Specificity keying with most-specific-wins,
  on-demand folder creation (no empty pre-scaffolding), and "repo = source of truth, sync deploys
  outward" is a clean, extensible design. `docs/repo-layout.adoc` states it in under 90 lines.
- **Harness self-description is a novel, high-value idea.** Having each harness document its own
  load mechanics — with `?` over guessing, verification dates, and (in `copilot.md`) per-section
  confidence tables and copy-paste smoke tests — is better epistemic hygiene than most professional
  documentation. The repeatable TEMPLATE prompt makes it scalable to Codex/ChatGPT later.
- **Build-artifact discipline for skills.** The sync script correctly handles the SKILL.md→command
  layout shift including link rewriting, has a non-clobbering `-IfMissing` bootstrap mode wired to
  a SessionStart hook, and the "never edit the mirror" rule is documented consistently.
- **Provenance is taken seriously.** `upstream-*` frontmatter with pinned commits, an origin map in
  `shared/skills/README.md`, explicit fork-vs-downstream decisions (the `setup-pre-commit` case),
  and license/attribution awareness in the import PRD.
- **Unusual epistemic maturity in the PRDs.** The `[RE-CONFIRM]` annotations on decisions inherited
  from stale chat sessions ("resolved then ≠ frozen now"), the hypothesis gate in
  `agents-md-folder-guides` ("test the premise before building; if it fails → wontfix"), and the
  validity protocol in `eval-skill-harness` (subject ≠ evaluator, A/B common-mode, N-trials
  pass rates instead of binary) are patterns many teams never develop.
- **The feedback loop closes.** Observed model failures (`quick-script-over-engineering`) become
  scratches, which feed instructions, which are meant to be tested by the planned eval harness.
  That is the right architecture for instruction engineering.

## 3. Cons

- **The meta-system is outgrowing the work it tracks.** 22 scratches, 13 of them `needs-triage`
  with TBD ranking; the backlog header a month stale; recent commits mostly "added more scratches."
  Meanwhile several *new* scratches propose more process (approval gates, immutability, funnel
  stages, stable IDs, recurrence). The risk is concrete: the lab becomes a backlog about its own
  backlog. Capture is working; planning and completion are not keeping pace — and the tool built
  exactly for this (`/planning:scratch-plan`) isn't being run.
- **The two most load-bearing files don't exist.** *(fixed same day: `AGENTS.md` authored)*
  `AGENTS.md` was called "the cross-harness anchor" in three docs — and was absent. No `CLAUDE.md`
  either, so every Claude Code session started blind to the repo's own conventions. Ironic for a
  repo whose subject is instruction management, and cheap to fix.
- **Status and facts are duplicated, and drifting.** *(fixed same day: docs-integrity-pass)*
  Status lives in both PRD `Status:` lines and BACKLOG rows. "Not the same file" existed
  near-verbatim in two places — and the copies contradicted each other on the future CLAUDE.md
  path. The skills README lacked the `planning` group and used pre-migration paths. A resolved
  git-init blocker was still marked blocking.
- **The repo is public with hardening unranked.** *(largely fixed same day: THIRD-PARTY/ added,
  secret scanning + push protection + Dependabot enabled)* Vendored upstream skill copies were
  committed without the license attribution the import PRD itself required "before publishing" —
  publishing had already happened. The personal behavioral profile is public; that should be a
  conscious decision (still open).
- **Stray content dilutes the repo's identity.** `VSCode_Extsion/` (note the typo) is a shipped
  VS Code extension at the root of an AI-configuration repo with no README tying it in;
  `mail-to-doc` rides in the tracker as a general software project. Neither is wrong — the scope
  widening is silent (open: `repo-scope-strays`).
- **Silent-staleness risks in the sync chain.** *(fixed same day: `-Check` mode)* `-IfMissing`
  never refreshes an edited skill, and it's the mode the hook runs — the failure mode was the
  default path. Harness docs describe fast-moving products with a single "verified 2026-06" stamp
  and no re-verification trigger *(fixed: decay contract in TEMPLATE.md)*.
- **Minor:** `.claudeignore` (`.claude*`, `.git*`) hides the synced commands, local settings, and
  `.gitignore` from Claude's file tools — presumably deliberate token hygiene, but an agent asked
  to debug sync or repo hygiene can't Read the very files involved (shell still works).

## 4. Improvements (as recommended at review time, priority order)

1. **Write `AGENTS.md` (+ minimal `CLAUDE.md`) as stubs now** — don't wait for the
   profile/CLAUDE.md reconciliation; iterate the hoist later. *(done — AGENTS.md)*
2. **Run a triage sweep and impose a WIP rule** — `/planning:scratch-plan` over the TBD items;
   "one process/meta feature in progress at a time"; re-plan trigger (needs-triage > 5 or monthly).
3. **Consolidate the process-rule cluster** — `gated-work-prd-issue-approval` +
   `scratch-immutability-appendix` + the capture rules in `claude-md-planning-defaults` are three
   views of one workflow spec. Start with soft enforcement before building PreToolUse hooks.
4. **Close the public-repo gap** — THIRD-PARTY attribution, secret scanning, push protection,
   branch protection decision. *(done except branch protection + profile go/no-go)*
5. **De-duplicate facts; single owner per fact.** *(done; rule codified in AGENTS.md)*
6. **Add a `-Check` drift mode to sync-skills.ps1.** *(done)*
7. **Give harness docs a decay contract.** *(done)*
8. **Decide the strays consciously** — declare incubation or evict. *(open)*

## 5. Scratch-by-scratch commentary

**Meta/process cluster** — `gated-work-prd-issue-approval`, `scratch-immutability-appendix`,
`claude-md-planning-defaults`, `backlog-enhancements`, `understand-scratch-skill`:
Consolidate, start soft. The immutability rule as written ("do not act upon *any* prompt") would
deadlock even scratch creation — the PRD spots this itself, which is the sign it needs the grill-me
pass before anything else in the cluster. `understand-scratch-skill` is a 30-minute
read-the-source task, not a feature — fold it into the triage sweep.

**Skills pipeline** — `import-upstream-skills`, `claude-code-skill-adaptation`,
`check-updates-detection-scope`, `fetch-latest-claude-skills`, `add-watch-skill`:
The first two are the best-formed PRDs in the repo — ship them before capturing more imports.
`check-updates-detection-scope` is cheap with a crisp acceptance criterion; fold into
`add-watch-skill` triage since watch is its named test case. `fetch-latest-claude-skills` may be
ill-posed: claude.ai skills aren't distributed through a pollable channel — the "upstream" is your
own chat sessions; reframe as a documented export procedure or close wontfix. `add-watch-skill`'s
real question is the dependency story (Python + yt-dlp + ffmpeg + API key) — a new artifact class;
worth a small ADR because the answer applies to every future tool-bearing skill.

**Instructions/profile cluster** — `repo-scaffold`, `incorporate-global-claude-setup`,
`profile-improvement`, `evaluate-temp-ai-config`, `harness-docs`, `agents-md-folder-guides`:
The ordering constraint the PRDs state (profile and CLAUDE.md stabilize → then hoist overlap to
AGENTS.md) is right, but don't let it block the *stub* AGENTS.md. `evaluate-temp-ai-config` is
mostly subsumed by `incorporate-global-claude-setup` plus one decision (does a PowerShell reference
doc belong in the repo?) — consider merging. For `agents-md-folder-guides`' hypothesis analysis:
per `copilot.md`, Copilot reads *only the root* AGENTS.md, so nested folder guides help Claude
Code/Codex only — that halves the payoff side. `harness-docs`' "Claude's outside view, marked for
inside confirmation" pattern is the right way to avoid blocking on sessions not yet run.

**Quality/eval cluster** — `eval-skill-harness`, `testing-methodologies-foundation`,
`quick-script-over-engineering`:
`eval-skill-harness` is the most ambitious and most valuable long-term; build Tier 1
(deterministic regression probes) alone first and run it against the profile — a weekend-sized
slice that pays off immediately. Ready-made synergy: `quick-script-over-engineering` is the
perfect first probe pack ("quick script for X" → assert no `[CmdletBinding()]`/`#Requires`
scaffolding). On that scratch's root-cause question: the profile says "for trivial asks, scale
down effort — not the rules" while §8 mandates rigor — the itemized rules outweigh the one-line
scale-down clause, so "quick" loses. The fix is an explicit mode switch (trigger words beat
abstract effort-scaling clauses). `testing-methodologies-foundation` is in good shape; its
issue-01 git-init blocker was stale *(since fixed)*.

**Housekeeping** — `global-gitignore`, `harden-github-repo`, `mail-to-doc`:
`global-gitignore` is under an hour including wiring docs — just do it. `harden-github-repo`: the
open question was answered (remote exists, public) — rank it high; free wins pulled forward via
`public-repo-compliance`. `mail-to-doc` is a fine, tightly-scoped PRD; its only issue is the scope
question of whether non-lab projects live in this tracker.

## Bottom line

The architecture and the thinking are strong — better than most team-run repos. The gap is
entirely in **execution flow**: excellent machinery for capturing and reasoning about work, a
growing deficit in finishing it. One stub AGENTS.md/CLAUDE.md, one triage sweep, one WIP limit,
and the public-repo hardening convert more value than any new process feature in the backlog.
