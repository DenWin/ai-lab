# Changelog

One line per version. `metadata.version` tracks the skill; `data-tpl` tracks
the rendered markup and moves only when a register built from an older
template would be wrong.

## 2.33.0

- the template's own example rows now pass the checks: known headings, a Goal or
  Problem beside every Fix, and a `data-closed` on the closed example
- `closedRowsAreTrimmed` had a mutation it could never reject - one extra closed
  row is inside the window the check allows. It now fills the window

## 2.32.0

- rows can declare `data-choices="A|B"` and get one button per choice instead of
  agree/disagree; a recommendation cell ending in `?` is now rejected
- `promote` emits ADRs only - the ledger shape is gone, `--shape` defaults to
  `adr`, and `DECISIONS.md` is a container for ADRs rather than a second format
- `REFERENCE.md` named `tr.done` for closed-row dimming; the classes are
  `tr.resolved` and `tr.superseded`
- `data-tpl` 10 -> 11

## 2.31.0

- the archive is `control-register-closed.md` again, not `closed.md`: it leaves
  the session folder and has to be identifiable outside it

## 2.30.0

- `DECISIONS.md` split into `docs/adr/0001..0006`, one ADR per file, in the
  Status / Context / Decision / Consequences / Alternatives shape

## 2.29.0

- `register.js promote --shape ledger|adr`; the destination is given, not assumed
- `register.js archive` defaults to `closed.md` beside the register it belongs to

## 2.28.0

- `register.js promote`: copy a chosen row into a decisions file as a draft
  entry. Archiving stays automatic and disposable; promotion is neither

## 2.27.0

- `register.js edit`: revise a row in place, ID and marker unchanged

## 2.26.0

- `register.js archive`: closed rows past the newest 15 move to a markdown
  archive, detail included, append-only
- `register.js`: row patterns now allow attributes after `class`, so a closed
  row is actually matched
- `checks.js`: the batch-order assertion moved into `register.js` - the file
  cannot tell one closing batch from three

## 2.25.0 — data-tpl 10

- `scripts/register.js`: add, close, block, archive, check. Builds rows, runs
  the checks after every change, restores the file when they fail
- closed rows carry `data-closed`, the order in which they closed
- `checks.js`: `closedIndexIsWellFormed`, `closedRowsAreTrimmed`

## 2.24.0 — data-tpl 9

- new action `review`: delivered agent work becomes a task for the reader,
  with `accepted` / `rejected` verdicts. Replaces the `delivered` state
- `checks.js`: `reviewRowsCarryWhatIsReviewed`

## 2.23.0 — data-tpl 8

- `delivered` state on an agent row: `accepted` / `rejected` verdict buttons,
  so output that has landed can be closed from the outbox
- `checks.js`: `deliveredRowsShowEvidence`

## 2.22.0

- `tests/mutations.js`: one mutation per check, each asserted to make that
  check fail; checks that cannot be mutated are listed with a reason
- `checks.js`: `detailFixHasAGoalOrProblem`, `detailHeadingsAreKnown`
- `DECISIONS.md` and this file

## 2.21.0

- `checks.js`: `openRowsAreNotBlockedByClosedRows` - a blocker whose target has
  closed is satisfied and must be cleared

## 2.20.0 — data-tpl 7

- page script renamed and split; `apply()` became `applyFilters()` over five
  named functions
- `window.__cb` publishes `RANK`, `STATUS`, `VERDICTS` and the pure helpers
- `checks.js` reads them instead of keeping its own copies

## 2.19.0

- renamed throughout: control panel → control register
- `checks.js`: five differential checks against the previous register

## 2.18.0

- renamed throughout: control block → control panel
- the outbox is no longer called "the panel" anywhere

## 2.17.0

- `verify.js` split into `checks.js` (the checks), `verify.js` (the CLI) and
  `verify.test.js` (`node:test`, one test per check, a fresh DOM for each)

## 2.16.0 — data-tpl 6

- more space between the header row and the filter row

## 2.15.0 — data-tpl 5

- first gap between the header row and the filter row

## 2.14.0 — data-tpl 4

- `#top`: sticky header holding title, outbox and filter row
- the outbox left the floating layer; `#obspace` and its sync script removed

## 2.13.0 — data-tpl 3

- outbox width `clamp(20rem, 33vw, 50vw)`; `#obspace` reserved its strip

## 2.12.0 — data-tpl 2

- outbox width 50vw; `pointer-events: none` while empty
