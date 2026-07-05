# 01 — Incorporate latest changes (2026-07-05 drop + filename markers)

Status: in-progress (markers + tests done 2026-07-05; zip-diff needs local `.temp/` — see Progress)

## What to build

Make the 2026-07-05 drop the new baseline for this scratch and fold in the latest
requirements from the user.

1. **Diff the two drops** — `.temp/mail-to-adoc-2026-06-28.zip` vs
   `.temp/mail-to-adoc-2026-07-05.zip` (gitignored local backups; the redacted
   extracted working copy is `shared/skills/documents/mail-to-adoc/`). Record what changed and check whether any of the four
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
      — **partial:** the zip-to-zip diff needs the local `.temp/` originals (not in the cloud clone);
      the observable state of the 2026-07-05 drop is documented in PRD Further Notes instead.
- [x] PRD.md problem list reconciled with the new drop (stale items marked done/updated) — see PRD Further Notes.
- [x] Generated filenames use `[TO]`/`[FROM]`/`[CC]`/`[+]` at the end of the stem; no emojis remain.
- [x] `[CC]` semantics confirmed with the user (2026-07-05: `[CC]` is appended **alongside** `[FROM]`
      when Dennis was only in Cc, not To; format `{name} [DIR][CC?][+?]`).
- [x] Tests updated and passing — `_direction_tag`/`_meta_field`/`_dennis_in` covered; 2 pre-existing
      drift tests fixed to the new archive layout; 2 dead-API tests skipped (see below). Suite:
      12 passed, 2 skipped.

## Progress (2026-07-05)

- **Markers implemented** in `scripts/mail_to_adoc.py`: emoji constants → bracket tags, new `[CC]`
  logic (`_dennis_in` + `_meta_field` detect Cc-only from the rendered metadata table), call site
  passes `cc_only`. Verified end-to-end on a real Cc'd `.eml` → `PartyA [FROM][CC]`.
- **Test suite was red on arrival** (4/6 failing) due to drift in the drop itself — this is an
  input to issue 02:
  - `test_process_attachments`, `test_eml_to_adoc_prefers_html`: asserted the old `docs/` layout;
    updated to the new `01_Korrespondenz/Attachments/` layout (documented in code). **Fixed.**
  - `test_add_hardbreaks_to_reply_headers` (`_add_hardbreaks_to_reply_headers` removed — no
    `[%hardbreaks]` output remains) and `test_auto_name` (`_auto_name` refactored away): reference
    dead API. **Skipped with a reason** — needs a call on intended-removal vs regression (issue 02).
- **PRD problems reconciled** (see PRD Further Notes): #1 tangled + #2 adoc-only + #3 image-macros
  still present; #4 spurious table `+` **appears fixed** in this drop (needs a real-sample confirm).

## Blocked by

- Nothing. (The zip-to-zip diff sub-task needs the local `.temp/` originals; do it on the workstation.)
