# 02 — Analyse effectiveness of the current skill

Status: needs-triage

## What to build

A written analysis of how well the 2026-07-05 version (`ai-artifacts/skills/shared/documents/mail-to-adoc/`)
actually works, as input for issue 03. Note: the artifacts copy is redacted
(placeholder emails/party names); the unredacted original is `.temp/mail-to-adoc-2026-07-05.zip`
(local-only). Cover:

- **Conversion quality**: run the converter against representative `.eml` samples
  (headers/metadata table, HTML body → AsciiDoc, tables, inline images, attachments,
  umlauts/encoding). Compare output against the expectations in PRD.md and
  `docs/prd/PRD_EDGE_CASES.md`.
- **Known defects**: confirm or refute the four PRD problems on the current code.
- **Test suite**: what `tests/test_mail_to_adoc.py` covers, what it misses
  (edge cases, table conversion, filename tagging, attachment handling).
- **Skill ergonomics**: SKILL.md quality (trigger description, progressive
  disclosure, hardcoded personal data such as `_EMAIL_NAME_MAP`/`_DENNIS_EMAILS`),
  and how invocable the scripts are (PowerShell wrapper vs Python module).
- **Architecture**: how tangled the HTML→AsciiDoc conversion is with mail parsing
  and orchestration — evidence for/against the split proposed in issue 03.

## Acceptance criteria

- [ ] Analysis written to `artifacts/effectiveness-analysis.md` (findings + severity)
- [ ] Each of the four PRD problems marked confirmed / fixed / not reproducible
- [ ] Test coverage gaps listed
- [ ] Coupling assessment done (input for the skill split decision)

## Head start (from issue 01, 2026-07-05)

Issue 01 already surfaced concrete input for this analysis:

- **Test suite is stale in the drop** (was 4/6 red before any change): two tests asserted the old
  `docs/` attachment layout (now fixed to `01_Korrespondenz/Attachments/`), and two reference removed
  functions — `_add_hardbreaks_to_reply_headers` (the `[%hardbreaks]` reply-header output is gone) and
  `_auto_name` (naming refactored to `_adoc_stem` + `_direction_tag`). Those two are **skipped**; this
  issue must decide **intended-removal vs regression** (restore the feature/test, or delete the test).
- **PRD problems** (see PRD Reconciliation): #1 tangled, #2 adoc-only, #3 image-macros — confirmed
  present; #4 spurious table `+` — appears fixed, still needs a real table `.eml` to confirm.
- **Coverage gaps already visible:** no tests for the metadata/table HTML→adoc conversion end-to-end,
  image-vs-link attachment rendering, or the filename tagging beyond the new `_direction_tag` units.

## Blocked by

- [01-incorporate-latest-changes](01-incorporate-latest-changes.md) — analyse the reconciled baseline, not a stale one.
