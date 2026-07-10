# PRD Addendum: Edge Cases and Rebuild Test Matrix

## Purpose

Define edge-case behavior required to faithfully recreate the skill.

## Edge Cases

### Input and Path Handling

1. File path does not exist

- Expected: fail fast with explicit file-not-found error.

1. Unsupported extension

- Expected: fail fast and print supported extensions (.msg, .eml).

1. Explicit output path provided

- Expected: use explicit path and skip auto-name for primary file.

1. Source file already in converted folder

- Expected: do not re-move source.

### Date and Naming

1. Missing or unparsable date

- Expected: output name derived from stem only, no date prefix.

1. Source stem already includes date prefix

- Expected: avoid double-prefixing by trimming known date forms.

1. Filename collisions in output dirs

- Expected: append numeric suffix until unique.

### Metadata Normalization

1. Folded headers in .eml (RFC line wrapping)

- Expected: unfolded values appear as single-line fields.

1. Address fields with mixed display-name/email forms

- Expected: parsed, normalized, sorted representation.

1. More than 10 recipients in a field

- Expected: comma-separated single-cell rendering.

### Body Extraction and Cleanup

1. .msg has empty plain text but valid HTML

- Expected: HTML fallback used.

1. .eml has both HTML and plain text

- Expected: HTML chosen.

1. HTML contains style/script/comment/o:p/conditional blocks

- Expected: removed before conversion.

1. Body contains null bytes, NBSP, zero-width chars

- Expected: stripped or normalized.

1. Body has long runs of blank lines

- Expected: collapsed to stable spacing.

1. Reply chain header block in body

- Expected: [%hardbreaks] inserted before each header run.

### Attachment Handling

1. Inline image with filename

- Expected: skipped as inline artifact.

1. Duplicate attachment content with different names

- Expected: dedupe by checksum; link to existing stored file.

1. Blocklisted attachment checksum

- Expected: skipped without writing file.

1. Attachment filename with directory traversal pattern

- Expected: sanitized to basename before writing.

1. Image attachment

- Expected: rendered with image:: thumbnail and click-through link.

1. Non-image attachment

- Expected: rendered as link: entry.

### Nested Mail Attachments

1. Attached .msg or .eml present

- Expected: write to mails/raw, convert nested mail, link to nested .adoc.

1. Nested conversion fails

- Expected: warning logged; parent links to raw nested source.

1. Duplicate nested mail attachment by checksum

- Expected: existing raw file reused.

### Sibling Pair Comparison

1. Input file has sibling counterpart extension

- Expected: both converted; comparison status printed.

1. Outputs differ

- Expected: similarity percentage + bounded diff preview printed.

1. Outputs identical

- Expected: IDENTICAL status printed.

## Rebuild Verification Matrix

| ID    | Scenario                  | Input Fixture                       | Expected Outcome                      |
| ----- | ------------------------- | ----------------------------------- | ------------------------------------- |
| TC-01 | MSG basic conversion      | single .msg                         | .adoc created with metadata/body      |
| TC-02 | EML basic conversion      | single .eml                         | .adoc created with metadata/body      |
| TC-03 | Missing file              | nonexistent path                    | explicit error and non-zero exit      |
| TC-04 | Unsupported ext           | .txt                                | explicit unsupported-type error       |
| TC-05 | Auto-name with date       | dated source                        | output prefixed with YYYYMMDD_HHMM    |
| TC-06 | No date available         | source without parseable date       | stem-based output name                |
| TC-07 | Reply headers             | mail with quoted From/Sent/To block | [%hardbreaks] inserted                |
| TC-08 | HTML sanitization         | mail with style/script/o:p/comment  | noise removed in output               |
| TC-09 | Image attachment          | png attachment                      | image:: entry + stored file           |
| TC-10 | Binary attachment         | pdf attachment                      | link: entry + stored file             |
| TC-11 | Checksum dedupe           | same attachment twice               | second run reuses existing file       |
| TC-12 | Blocklisted hash          | known blocklisted attachment        | skipped write and no link             |
| TC-13 | Nested mail attachment    | attached .eml in parent mail        | saved under mails/raw and converted   |
| TC-14 | Nested conversion failure | malformed nested mail               | warning + raw link fallback           |
| TC-15 | Sibling parity conversion | foo.msg and foo.eml                 | both outputs generated                |
| TC-16 | Sibling diff report       | known differing pair                | DIFFERENT + similarity + diff preview |
| TC-17 | Sibling equal report      | known equivalent pair               | IDENTICAL report                      |
| TC-18 | Source move behavior      | successful conversion               | source moved to converted/            |
| TC-19 | Already converted path    | input inside converted/             | source not moved again                |
| TC-20 | Safe filename handling    | attachment name with ../            | sanitized basename write              |

## Implementation Guidance for Teams

- Use golden-file snapshots for .adoc outputs per fixture.
- Separate parser, normalizer, and I/O orchestration modules.
- Keep checksum and naming behavior deterministic.
- Include at least one multilingual fixture to catch unicode regressions.
