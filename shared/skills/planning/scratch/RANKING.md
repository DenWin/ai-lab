# .scratch Ranking — Formula & Tiebreakers

## Score formula

```
Score = P × I × E
```

| Axis | Value | Numeric |
|------|-------|---------|
| **P** (priority) | high | 3 |
| | medium | 2 |
| | low | 1 |
| **I** (importance) | high | 3 |
| | medium | 2 |
| | low | 1 |
| **E** (effort, **inverted** — less effort ranks higher) | 4h | 7 |
| | 1day | 6 |
| | 2days | 5 |
| | 1week | 4 |
| | 2weeks | 3 |
| | 1month | 2 |
| | 2months | 1 |

Score range: 3 (low / low / 2months) — 63 (high / high / 4h).
Higher score = higher in the backlog.

## Tiebreakers (equal score, applied in order)

1. Less effort (lower E_label wins — quick wins first)
2. Higher importance
3. Higher priority
4. Alphabetical by feature slug

## Escalation rule (used by `/planning:scratch-plan`)

When a feature's rank should be raised:
- If `importance < high` → raise importance one level.
- If `importance = high` → raise priority one level instead (if `priority < high`).

This prevents phantom "super-high" rankings by routing excess urgency into priority.

## Example

| Feature | P | I | E | Score |
|---------|---|---|---|-------|
| auth-refactor | high (3) | high (3) | 1week (4) | 36 |
| fix-flaky-test | medium (2) | high (3) | 4h (7) | 42 |
| docs-overhaul | low (1) | medium (2) | 2months (1) | 2 |

Ranked: fix-flaky-test (42) > auth-refactor (36) > docs-overhaul (2).
