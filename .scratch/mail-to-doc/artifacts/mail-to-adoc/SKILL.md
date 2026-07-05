---
name: mail-to-adoc
description: "Convert .msg or .eml email files to AsciiDoc (.adoc) format. Use when: converting msg to asciidoc, converting eml to asciidoc, turning an outlook email into adoc, converting email file to documentation, saving mail as AsciiDoc. Runs mail_to_adoc.py from the project root."
argument-hint: "path to .msg or .eml file (e.g. mails/my-email.msg or mails/my-email.eml)"
version:beta
---

# Mail to AsciiDoc Converter

Converts a single Outlook `.msg` or standard `.eml` email file into a well-structured AsciiDoc (`.adoc`) document.

## What It Produces

- Document title from the email subject (colons escaped with `&#58;`)
- Metadata table: From, Sent, To, CC
- Body text with normalized blank lines and proper list/table markup
- Quoted reply-chain headers formatted as `[%hardbreaks]` paragraphs
- Attachments extracted to `docs/` with MD5-dedup; images rendered as `image::` gallery thumbnails, other files as `link:` entries
- Blocklisted attachments (by checksum) silently skipped

## Script Location

[scripts/mail_to_adoc.py](./scripts/mail_to_adoc.py)

## Requirements

Requires the `extract-msg` package (for `.msg` files only; `.eml` uses the Python standard library):

```powershell
pip install extract-msg
```

## Blocklist

Add MD5 checksums of attachments to ignore (e.g. Outlook signature images) to:

```
.github/skills/mail-to-adoc/attachment-blocklist.txt
```

One checksum per line; `# comments` are supported.

## Procedure

1. Confirm the file path (absolute or relative to project root).
2. Run the converter:

```powershell
python '.github/skills/mail-to-adoc/scripts/mail_to_adoc.py' '<path-to-file.msg>'
python '.github/skills/mail-to-adoc/scripts/mail_to_adoc.py' '<path-to-file.eml>'

# Or specify output path explicitly:
python '.github/skills/mail-to-adoc/scripts/mail_to_adoc.py' '<path>' '<output.adoc>'
```

3. Open the generated `.adoc` file to review.
4. The source file is automatically moved to `mails/converted/`.

## Notes

- `.msg`: prefers plain-text body, falls back to HTML.
- `.eml`: prefers HTML body (base64-decoded), falls back to plain text.
- Inline images (`cid:` references, Outlook signature images) are skipped.
- Multiple consecutive blank lines are collapsed to one.
