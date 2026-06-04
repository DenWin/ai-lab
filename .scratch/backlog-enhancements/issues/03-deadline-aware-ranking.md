# 03 — Deadline-aware ranking (NEEDS GRILLING)

Status: ready-for-human

Run `/session:grill-me` on this decision tree before building — the user flagged it as unfinished.

## The idea

Feed the due date into ranking by modifying **priority** before `Score = P × I × E` is computed.
Priority = urgency, so deadline pressure → priority is consistent with the existing escalation rule
in `RANKING.md`.

User's draft rule:
- If no `due` set at `scratch-plan` time → assume **today + 4 weeks** for ranking only; do **not**
  persist it.
- If `business_days(today → due) < effort_person_days × 2` **and** `updated` > 7 days ago →
  raise priority one level, capped at high.

Effort → person-days mapping (from `RANKING.md` buckets): 4h≈0.5, 1day=1, 2days=2, 1week=5,
2weeks=10, 1month=20, 2months=40.

## Open edge cases to grill

- **Overdue** (`due < today`): jump straight to high rather than one step? Probably yes.
- **Infeasible** (runway can't fit the effort even now, already high): surface a "deadline at risk"
  warning instead of escalating into the void.
- **Business-days definition:** SETTLED — Mon–Fri, public holidays treated as non-existent (no
  holiday list). Just count weekdays between today and `due`.
  <!-- [RE-CONFIRM] confirm the no-holiday-list simplification still holds when you grill this tree. -->

- **The ×2 buffer:** rationale (calendar runway should be ≥ 2× raw effort). Configurable or fixed?
- **Interaction with the existing escalation rule** (`RANKING.md`: raise importance unless high, then
  priority). Deadline pressure raises *priority directly* — confirm these compose without
  double-counting.
- **Repeated runs:** the rule must be idempotent — re-running `scratch-plan` shouldn't ratchet
  priority up every time. Escalation is computed from current `due`/`effort`/`updated`, not applied
  cumulatively.
- **Recurrence interaction:** a re-opened recurring feature gets a fresh `due` and fresh `updated`,
  so it won't immediately trip the staleness arm — confirm that's the intent.

## Acceptance criteria

- [ ] grill-me pass done; decision tree finalized with edge cases resolved
- [ ] `RANKING.md` documents the deadline rule and the ephemeral-default behavior
- [ ] `scratch-plan` applies it idempotently as a pre-processing step on priority
- [ ] Assumed default due date never written back to a PRD
- [ ] Overdue / infeasible cases produce a visible warning, not silent behavior

## Blocked by

- 01 (`due` / `updated` fields must exist)
