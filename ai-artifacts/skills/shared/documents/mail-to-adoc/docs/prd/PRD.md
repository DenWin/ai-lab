# Product Requirements Document (PRD)

## Product Name

Mail to AsciiDoc Converter Skill

## Objective

Provide deterministic, high-fidelity conversion of .msg and .eml emails into AsciiDoc for archival, audit, and analysis, including attachment extraction, normalization, and format parity checks.

## Users

- Delivery architects and technical auditors
- Engineers documenting communication artifacts
- Analysts building traceable audit trails from mail sources

## Problem Statement

Email formats vary by client and encoding. .msg and .eml representations of the same message can differ in body decoding and metadata quality. The tool must normalize these differences and preserve critical content in a documentation-friendly format.

## Non-Goals

- Rendering exact visual email layout
- Round-trip reconstruction back to .msg/.eml
- Rich CSS fidelity
- Full MIME client behavior emulation

## Functional Requirements

1. Input acceptance

- The tool shall accept one file path argument to a .msg or .eml source.
- The tool shall optionally accept an explicit output .adoc path.
- The tool shall return a clear error for unsupported extensions.

1. Output naming and placement

- Without explicit output path, output filename shall be auto-derived from date + source stem.
- If source is in a raw directory, output shall be placed in the parent directory.

1. Metadata extraction

- The output shall include mail metadata table fields where available:
  - From, Sent, To, Reply-To, CC, BCC, Importance, Sensitivity, Categories.
- Subject shall be used as document title and colon spacing shall be escaped for AsciiDoc safety.

1. Body extraction and normalization

- .msg conversion shall prefer plain text body, then HTML fallback.
- .eml conversion shall prefer HTML body, then plain text fallback.
- HTML conversion shall support links, lists, tables, line breaks, and basic inline emphasis.
- Body normalization shall remove null bytes, NBSP artifacts, invisible unicode, repeated blank lines, and Outlook-specific noise blocks.
- Quoted header blocks shall be prefixed with [%hardbreaks] for readability.

1. Attachment processing

- All non-inline attachments shall be inspected.
- Attachments shall be deduplicated by MD5 checksum.
- Blocklisted checksums shall be skipped.
- Non-mail attachments shall be saved in docs/ with collision-safe names.
- Image attachments shall be rendered as image:: entries with links.
- Other attachments shall be rendered as link: entries.

1. Nested mail attachment processing

- Attached .msg/.eml files shall not be written to docs/.
- Attached .msg/.eml files shall be written to mails/raw/.
- Nested mail attachments shall be converted recursively to .adoc.
- Parent document attachment list shall link to nested conversion output when available, otherwise to raw source.

1. Sibling parity conversion and comparison

- If counterpart extension exists for the same stem (foo.msg + foo.eml), both shall be converted.
- Tool shall compare generated outputs and print:
  - Identical or Different verdict
  - Similarity ratio when different
  - Limited unified diff preview

1. Source lifecycle

- After successful conversion run, the primary source file shall be moved to a converted subfolder unless already inside converted.

## Quality Attributes

- Deterministic output for identical inputs and environment.
- Safe filename handling (no path traversal writes from attachment names).
- Graceful degradation when partial metadata is missing.
- Readable diagnostics for conversion and comparison outcomes.

## Constraints

- Must run on Windows PowerShell workflows.
- Must use extract-msg for .msg support.
- Must avoid destructive behavior outside expected output directories.

## Acceptance Criteria

1. Given valid .msg input, tool writes .adoc with metadata and body.
2. Given valid .eml input, tool writes .adoc with metadata and body.
3. Given paired .msg/.eml siblings, both outputs exist and comparison is printed.
4. Given image and non-image attachments, output renders image:: and link: entries correctly.
5. Given attached .msg/.eml, files appear in mails/raw and nested .adoc is created.
6. Given duplicate attachments by checksum, no duplicate write occurs.
7. Given blocklisted checksum, attachment is skipped.
8. Given unsupported extension, tool exits with clear error message.

## Suggested Work Breakdown for Reimplementation

1. Implement model and path utilities.
2. Implement HTML-to-AsciiDoc parser.
3. Implement body normalization pipeline.
4. Implement .msg extractor adapter.
5. Implement .eml extractor adapter.
6. Implement attachment processing and dedupe.
7. Implement nested mail routing and recursive conversion.
8. Implement sibling comparison and diff reporting.
9. Implement CLI orchestration and source move policy.
10. Add regression test suite using golden files.
