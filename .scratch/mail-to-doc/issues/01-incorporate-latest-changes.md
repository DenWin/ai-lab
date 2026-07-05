# 01 — Incorporate latest changes (2026-07-05 drop + filename markers)

Status: needs-triage

## What to build

Make the 2026-07-05 drop the new baseline for this scratch and fold in the latest
requirements from the user.

1. **Diff the two drops** — `.temp/mail-to-adoc-2026-06-28.zip` vs
   `.temp/mail-to-adoc-2026-07-05.zip` (gitignored local backups; the redacted
   extracted working copy is `artifacts/mail-to-adoc/`). Record what changed and check whether any of the four
   problems in PRD.md (tangled HTML→AsciiDoc logic, adoc-only output, image macros
   instead of links, spurious `+` after table rows) were already fixed upstream.
   Update PRD.md accordingly.
2. **Replace emoji filename markers with bracket tags.** Verified in the 2026-07-05
   drop (`scripts/mail_to_adoc.py:390-403`): filenames still use `✉` (received),
   `✎𓂃` (sent), and `📎` (has attachments). Replace with `[FROM]`, `[TO]`, `[CC]`,
   and `[+]` (attachments), and keep the tags **at the end of the filename**.
   - Presumed mapping: sent → `[TO]`, received → `[FROM]`, attachments → `[+]`.
   - `[CC]` has no emoji counterpart today — clarify with the user when it applies
     (mail where he is only in CC?) before implementing.
3. Update tests that assert on the old emoji markers.

## Acceptance criteria

- [ ] Diff summary 2026-06-28 → 2026-07-05 documented (in PRD.md Further Notes or an artifacts note)
- [ ] PRD.md problem list reconciled with the new drop (stale items marked done/updated)
- [ ] Generated filenames use `[TO]`/`[FROM]`/`[CC]`/`[+]` at the end of the stem; no emojis remain
- [ ] `[CC]` semantics confirmed with the user
- [ ] Tests updated and passing

## Blocked by

- Nothing.
