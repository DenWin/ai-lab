# Mail to AsciiDoc Skill

## Purpose

Convert Outlook .msg and MIME .eml files into normalized AsciiDoc (.adoc) documents suitable for audit and documentation workflows.

## Scope

- Input formats: .msg, .eml
- Output format: .adoc
- Attachment handling: dedupe by checksum, routing by type
- Reply-chain readability: preserve Outlook-style headers with hardbreak formatting

## Key Features

- Supports both .msg and .eml as primary input.
- Auto-generates output filename from mail timestamp and source stem.
- Writes output one level above raw/ when the source file is in a raw folder.
- Preserves metadata in an AsciiDoc table:
  - From
  - Sent
  - To
  - Reply-To
  - CC
  - BCC
  - Importance
  - Sensitivity
  - Categories
- Normalizes address fields:
  - Parses mixed display-name/address formats.
  - Sorts addresses case-insensitively.
  - Uses AsciiDoc bullet cell formatting for medium address lists.
- Body extraction strategy:
  - .msg: prefers plain text, falls back to HTML.
  - .eml: prefers HTML, falls back to plain text.
- HTML to AsciiDoc conversion includes:
  - Links (link:url[text])
  - Lists (ul/ol, including nested lists)
  - Tables (%autowidth%header)
  - Basic inline formatting (bold, italic, code)
- Cleanup/normalization:
  - Removes style/script/comments and Outlook o:p artifacts.
  - Removes zero-width/invisible characters.
  - Collapses excessive blank lines.
  - Adds [%hardbreaks] before quoted reply header blocks.
- Attachment deduplication with MD5 checksums.
- Attachment blocklist support via attachment-blocklist.txt.
- Attachment rendering:
  - Images rendered as image:: thumbnails with clickable links.
  - Non-images rendered as link: entries.
- Special handling for attached mail files (.msg/.eml):
  - Stored in mails/raw (not docs).
  - Converted recursively to .adoc.
  - Parent mail links to the converted nested output where possible.
- Pairwise sibling comparison:
  - If foo.msg and foo.eml both exist, both are converted.
  - Generated outputs are compared.
  - Similarity ratio and unified diff preview are printed.
- Source lifecycle:
  - Converted source file is moved to a converted subfolder.

## Folder Conventions

- Skill root: .github/skills/mail-to-adoc
- Script: .github/skills/mail-to-adoc/scripts/mail_to_adoc.py
- Attachment blocklist: .github/skills/mail-to-adoc/attachment-blocklist.txt
- Project docs target: docs/
- Nested mail attachment target: mails/raw/

## CLI Usage

```powershell
python ".github/skills/mail-to-adoc/scripts/mail_to_adoc.py" "<path-to-file.msg>"
python ".github/skills/mail-to-adoc/scripts/mail_to_adoc.py" "<path-to-file.eml>"
python ".github/skills/mail-to-adoc/scripts/mail_to_adoc.py" "<path-to-mail>" "<output.adoc>"
```

## Dependencies

- Python 3.10+
- extract-msg package for .msg processing

## Known Notes

- extract-msg import resolution depends on environment setup.
- Comparison output is diagnostic and does not block conversion success.
