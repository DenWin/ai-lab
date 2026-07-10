#!/usr/bin/env python3
"""Convert a single .msg or .eml file to AsciiDoc format."""

import difflib
import email
import email.policy
import hashlib
import importlib
import re
import sys
from email.utils import getaddresses, parsedate_to_datetime
from html.parser import HTMLParser
from pathlib import Path
from zoneinfo import ZoneInfo

# Project root: scripts/ → mail-to-adoc/ → skills/ → <project-root>/
_PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent.parent

try:
    _LOCAL_TZ = ZoneInfo("Europe/Berlin")
except Exception:
    raise SystemExit("Missing timezone data. Run: pip install tzdata")
_LOG_DIR = _PROJECT_ROOT / ".logs"

#: Dennis's own email addresses — used to determine sent vs. received direction.
#: [REDACTED for public repo — real values in the .temp/ originals]
_DENNIS_EMAILS: frozenset[str] = frozenset(
    {
        "owner@example.com",
        "owner.alt@example.com",
    }
)

#: Maps known email addresses to short party names for filenames.
#: [REDACTED for public repo — real values in the .temp/ originals]
_EMAIL_NAME_MAP: dict[str, str] = {
    "kontakt@lawfirm-a.example": "PartyA",
    "info@lawfirm-b.example": "PartyB",
    "owner@example.com": "Dennis",
    "owner.alt@example.com": "Dennis",
    "family@example.com": "FamilyMember",
}

# ---------------------------------------------------------------------------
# Type aliases — give meaningful names to tuple types that cross boundaries
# ---------------------------------------------------------------------------

AttachmentData = tuple[str, bytes]  # (filename, raw binary content)
AttachmentLink = tuple[str, str, bool]  # (original_name, adoc_link_path, is_image)

# ---------------------------------------------------------------------------
# Module-level constants — defined once here, referenced wherever needed
# ---------------------------------------------------------------------------

#: File extensions rendered as inline image thumbnails in AsciiDoc output.
IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".gif", ".svg", ".webp"}

#: Human-readable labels for MAPI importance integer values (0=Low, 1=Normal, 2=High).
IMPORTANCE_LABELS: dict[int, str] = {0: "Low", 1: "Normal", 2: "High"}

#: Human-readable labels for MAPI sensitivity integer values.
SENSITIVITY_LABELS: dict[int, str] = {
    0: "Normal",
    1: "Personal",
    2: "Private",
    3: "Confidential",
}

#: Maps X-Priority header string codes (used by some mail clients) to readable labels.
X_PRIORITY_LABELS: dict[str, str] = {
    "1": "Highest",
    "2": "High",
    "3": "Normal",
    "4": "Low",
    "5": "Lowest",
}

#: Field names that appear in Outlook quoted-reply header blocks.
QUOTED_HEADER_KEYS = {"from", "sent", "to", "cc", "bcc", "subject", "date"}

#: Matches a single ``*Key:*`` line inside an Outlook reply header block.
REPLY_HEADER_PATTERN = re.compile(r"^\*([^*]+):\*\s*", re.IGNORECASE)


def _log_warning(msg: str) -> None:
    """Print a warning and append it to .logs/mail_to_adoc.log."""
    print(msg)
    try:
        _LOG_DIR.mkdir(parents=True, exist_ok=True)
        log_file = _LOG_DIR / "mail_to_adoc.log"
        from datetime import datetime

        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        with open(log_file, "a", encoding="utf-8") as f:
            f.write(f"[{timestamp}] {msg}\n")
    except OSError:
        pass  # log write failed silently


def _decode_rfc2047(value: str) -> str:
    """Decode RFC 2047 encoded-words in email headers, e.g. =?utf-8?Q?...?="""
    from email.header import decode_header, make_header

    if not value or "=?" not in value:
        return value
    try:
        return str(make_header(decode_header(value)))
    except Exception:
        return value


def _decode_qp_body(text: str) -> str:
    """Decode any residual quoted-printable sequences (=XX) in plain text."""
    import quopri

    if "=" not in text:
        return text
    try:
        return quopri.decodestring(text.encode("ascii", errors="replace")).decode(
            "utf-8", errors="replace"
        )
    except Exception:
        return text


def _get_extract_msg_module():
    """Import extract_msg only when MSG processing is actually needed."""
    try:
        return importlib.import_module("extract_msg")
    except ModuleNotFoundError as exc:
        raise ModuleNotFoundError(
            "Missing optional dependency 'extract-msg'. Install it with: pip install extract-msg"
        ) from exc


class HTMLToAsciiDoc(HTMLParser):
    """HTML parser that emits AsciiDoc markup for lists, tables, links and inline formatting."""

    def __init__(self):
        super().__init__()

        # Accumulated text fragments that will be joined into the final AsciiDoc string
        self.output_parts: list[str] = []

        # List rendering state — one entry per nesting level to support nested ul/ol
        self.list_depth = 0
        self.list_type_stack: list[str] = []  # 'ul' or 'ol' for each open list
        self.list_item_stack: list[
            list[str]
        ] = []  # text fragments collected for each open <li>

        # Table rendering state
        self.table_depth = 0
        self.current_cell: list[str] | None = None  # None when no <td>/<th> is open
        self.current_row_cells: list[str] = []  # cells accumulated for the current <tr>
        self.table_rows: list[
            list[str]
        ] = []  # all rows accumulated for the current <table>

        # Hyperlink state — href is set on <a>, used while writing inner text, cleared on </a>
        self.open_link_href: str | None = None

    def _write(self, text: str) -> None:
        """Append text to the innermost active context: list item, table cell, or top level."""
        if self.list_item_stack:
            self.list_item_stack[-1].append(text)
        elif self.current_cell is not None:
            self.current_cell.append(text)
        else:
            self.output_parts.append(text)

    def handle_starttag(self, tag, attrs):
        tag = tag.lower()
        attr_dict = dict(attrs)
        if tag == "table":
            self.table_depth += 1
            if self.table_depth == 1:
                self.table_rows = []
        elif tag in ("thead", "tbody", "tfoot", "colgroup", "col"):
            pass
        elif tag == "tr":
            self.current_row_cells = []
        elif tag in ("td", "th"):
            self.current_cell = []
        elif tag in ("ul", "ol"):
            self.list_depth += 1
            self.list_type_stack.append(tag)
        elif tag == "li":
            self.list_item_stack.append([])
        elif tag == "a":
            href = attr_dict.get("href", "")
            if href and not href.startswith(("#", "javascript")):
                self.open_link_href = href
                self._write(f"link:{href}[")
        elif tag in ("b", "strong"):
            self._write("*")
        elif tag in ("i", "em"):
            self._write("_")
        elif tag in ("code", "tt"):
            self._write("`")
        elif tag == "br":
            self._write("\n")

    def handle_endtag(self, tag):
        tag = tag.lower()
        if tag == "table":
            if self.table_depth == 1 and self.table_rows:
                header_row = " ".join(f"|{c}" for c in self.table_rows[0])
                self.output_parts.append(
                    f"\n[%autowidth%header]\n|===\n{header_row}\n\n"
                )
                for row in self.table_rows[1:]:
                    self.output_parts.append("\n".join(f"|{c}" for c in row) + "\n")
                self.output_parts.append("|===\n")
            self.table_rows = []
            self.table_depth = max(0, self.table_depth - 1)
        elif tag in ("thead", "tbody", "tfoot", "colgroup", "col"):
            pass
        elif tag in ("td", "th"):
            if self.current_cell is not None:
                content = "".join(self.current_cell).strip()
                content = re.sub(r"\s+", " ", content)
                content = re.sub(r"\*\*", "", content)  # empty <b> pairs
                content = re.sub(r"__", "", content)  # empty <i> pairs
                content = re.sub(r"``", "", content)  # empty <code> pairs
                self.current_row_cells.append(content)
                self.current_cell = None
        elif tag == "tr":
            if self.table_depth > 0:
                if self.current_row_cells:
                    self.table_rows.append(list(self.current_row_cells))
                self.current_row_cells = []
            else:
                self._write("\n")
        elif tag in ("ul", "ol"):
            self.list_depth = max(0, self.list_depth - 1)
            if self.list_type_stack:
                self.list_type_stack.pop()
            if self.list_depth == 0:
                self._write("\n")
        elif tag == "li":
            if self.list_item_stack:
                content = "".join(self.list_item_stack.pop()).strip()
                content = re.sub(r"\s*\n\s*", " ", content).strip()
                list_type = self.list_type_stack[-1] if self.list_type_stack else "ul"
                marker = "." if list_type == "ol" else "*"
                bullet = marker * self.list_depth
                if content:
                    formatted = f"\n{bullet} {content}"
                    if self.list_item_stack:
                        self.list_item_stack[-1].append(formatted)
                    elif self.current_cell is not None:
                        self.current_cell.append(formatted)
                    else:
                        self.output_parts.append(formatted)
        elif tag == "a":
            if self.open_link_href:
                self._write("]")
                self.open_link_href = None
        elif tag in ("b", "strong"):
            self._write("*")
        elif tag in ("i", "em"):
            self._write("_")
        elif tag in ("code", "tt"):
            self._write("`")
        elif tag in ("p", "div"):
            self._write("\n")

    def handle_data(self, data: str) -> None:
        data = re.sub(
            r"[\u200b\u200c\u200d\ufeff\u00ad]", "", data
        )  # zero-width / soft-hyphen chars
        data = re.sub(
            r"[ \t]*\r?\n[ \t]*", " ", data
        )  # CRLF line-wrapping in HTML source → space
        if data:
            self._write(data)

    def get_text(self) -> str:
        text = "".join(self.output_parts)
        # Remove empty inline markup pairs left by empty <b>/<i>/<code> spans
        text = re.sub(r"\*\*", "", text)
        text = re.sub(r"__", "", text)
        text = re.sub(r"``", "", text)
        return text


def strip_html(html: str) -> str:
    """Remove non-content HTML and convert the remainder to AsciiDoc markup."""
    html = re.sub(r"<style[^>]*>.*?</style>", "", html, flags=re.IGNORECASE | re.DOTALL)
    html = re.sub(
        r"<script[^>]*>.*?</script>", "", html, flags=re.IGNORECASE | re.DOTALL
    )
    html = re.sub(r"<!--.*?-->", "", html, flags=re.DOTALL)
    html = re.sub(r"<o:p[^>]*>.*?</o:p>", "", html, flags=re.IGNORECASE | re.DOTALL)
    html = re.sub(
        r"<!\[if[^\]]*\]>.*?<!\[endif\]>", "", html, flags=re.IGNORECASE | re.DOTALL
    )
    parser = HTMLToAsciiDoc()
    parser.feed(html)
    return parser.get_text()


def normalize_body(body: str) -> str:
    """Clean up raw email body text for AsciiDoc output."""
    body = body.replace("\x00", "").replace("\xa0", " ")
    body = re.sub(r"(?m)^_+$", "---", body)  # underline-only lines → horizontal rule
    lines = [line.strip() if line.strip() else "" for line in body.splitlines()]
    body = re.sub(r"\n{2,}", "\n\n", "\n".join(lines)).strip()
    return body


def _load_blocklist(script_dir: Path) -> set[str]:
    """Load MD5 checksums from attachment-blocklist.txt next to the skills folder."""
    blocklist_path = script_dir.parent / "attachment-blocklist.txt"
    if not blocklist_path.exists():
        return set()
    checksums = set()
    for line in blocklist_path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        checksums.add(
            line.split()[0]
        )  # first token is the checksum; remainder is an optional comment
    return checksums


def _as_adoc_link(path: Path) -> str:
    """Return an AsciiDoc link path relative to 01_Korrespondenz/{year}/{mm}/.

    adoc files live two levels deep inside 01_Korrespondenz/, so attachments
    stored at 01_Korrespondenz/Attachments/ are reached with '../../Attachments/'.
    """
    try:
        relative = path.relative_to(_PROJECT_ROOT / "01_Korrespondenz")
        return f"../../{relative.as_posix()}".replace(" ", "%20")
    except ValueError:
        try:
            relative = path.relative_to(_PROJECT_ROOT)
            return f"../../../{relative.as_posix()}".replace(" ", "%20")
        except ValueError:
            return path.as_posix().replace(" ", "%20")


def _find_existing_by_checksum(directory: Path, checksum: str) -> Path | None:
    """Return the first file in directory whose MD5 matches checksum."""
    if not directory.exists():
        return None
    for candidate_file in sorted(directory.iterdir()):
        if candidate_file.is_file():
            try:
                if hashlib.md5(candidate_file.read_bytes()).hexdigest() == checksum:
                    return candidate_file
            except OSError:
                pass
    return None


def _write_unique_file(
    directory: Path, filename: str, data: bytes, date_prefix: str
) -> Path:
    """Write file to directory, adding date prefix and numeric suffix on collisions."""
    directory.mkdir(parents=True, exist_ok=True)
    safe_name = Path(filename).name
    stem, suffix = Path(safe_name).stem, Path(safe_name).suffix
    new_name = f"{date_prefix}-{stem}{suffix}" if date_prefix else safe_name
    dest = directory / new_name
    counter = 1
    while dest.exists():
        if date_prefix:
            dest = directory / f"{date_prefix}-{stem}-{counter}{suffix}"
        else:
            dest = directory / f"{stem}-{counter}{suffix}"
        counter += 1
    dest.write_bytes(data)
    return dest


def _clean_filename(subject: str) -> str:
    """Clean subject for filesystem use: 'AW: Foo' → 'AW_ Foo'.

    Also strips em-dashes so they don't clash with the filename delimiter ' — '.
    """
    clean = re.sub(r":\s*", "_ ", subject or "")
    clean = clean.replace("—", "-").replace("–", "-")
    return re.sub(r'[\\/*?"<>|\x00]', "_", clean).strip()


# Filename component separator — visible, rarely appears in subjects.
_STEM_SEP = " — "
# Bracket tags appended at the end of the filename stem (replaces the older emoji
# markers ✉/✎𓂃/📎). Order in the stem: '{name} {direction}{[CC] if cc-only}{[+] if attachments}'.
_DIR_RECEIVED = "[FROM]"  # mail Dennis received
_DIR_SENT = "[TO]"  # mail Dennis sent
_CC_FLAG = "[CC]"  # received mail where Dennis was only in Cc (not To)
_ATT_FLAG = "[+]"  # mail has attachments


def _adoc_stem(mail_date, subject: str) -> str:
    """Return the base stem for .adoc files: 'YYYYMMDD_HHmm — <subject>'."""
    local = mail_date.astimezone(_LOCAL_TZ) if mail_date else None
    prefix = local.strftime("%Y%m%d_%H%M") if local else "00000000_0000"
    return f"{prefix}{_STEM_SEP}{_clean_filename(subject)}"


def _dennis_in(field: str) -> bool:
    """True if any of Dennis's own addresses appears in a header field value."""
    if not field:
        return False
    cands = re.findall(r"<([^>]+)>", field) or re.findall(r"[\w.+-]+@[\w.-]+", field)
    return any(a.strip().lower() in _DENNIS_EMAILS for a in cands)


def _meta_field(adoc: str, label: str) -> str:
    """Extract a metadata-table field value by label, inline or bulleted.

    Handles both the inline form '|Label |value' and the multi-recipient bullet
    form '|Label a|' followed by '* addr' lines. Returns "" when not found.
    """
    lines = adoc.splitlines()
    row = re.compile(rf"^\|{re.escape(label)}\s*(a)?\|(.*)$")
    for i, ln in enumerate(lines):
        m = row.match(ln)
        if not m:
            continue
        if m.group(1) == "a":  # bulleted list continues on the following '* ' lines
            vals = []
            for nxt in lines[i + 1 :]:
                s = nxt.strip()
                if s.startswith("* "):
                    vals.append(s[2:])
                else:
                    break
            return ", ".join(vals)
        return m.group(2).strip()
    return ""


def _direction_tag(
    from_v: str, to_v: str, has_att: bool = False, cc_only: bool = False
) -> str:
    """Return a '{name} {tags}' direction tag for use in filenames.

    Tags are bracket markers appended at the end of the stem: '[TO]' (Dennis sent),
    '[FROM]' (Dennis received), '[CC]' (received, Dennis was only in Cc — appended
    right after '[FROM]'), and '[+]' (has attachments — always last). Inspects
    From/To header values extracted from the adoc metadata table; uses _DENNIS_EMAILS
    to detect sent mail and _EMAIL_NAME_MAP for party names.
    """

    def _extract_addr(field: str) -> str:
        m = re.search(r"<([^>]+)>", field)
        return (m.group(1) if m else field).strip().lower()

    def _name_for(field: str) -> str:
        for addr in re.findall(r"<([^>]+)>", field) or [field]:
            a = addr.lower()
            if a in _EMAIL_NAME_MAP:
                return _EMAIL_NAME_MAP[a]
            for k, v in _EMAIL_NAME_MAP.items():
                if k in a:
                    return v
            if "lawfirm-a" in a:  # [REDACTED party-name fallback]
                return "PartyA"
            if "lawfirm-b" in a:  # [REDACTED party-name fallback]
                return "PartyB"
        return "Unknown"

    _att = _ATT_FLAG if has_att else ""
    from_addr = _extract_addr(from_v)
    if from_addr in _DENNIS_EMAILS:
        others = [
            a for a in re.findall(r"<([^>]+)>", to_v) if a.lower() not in _DENNIS_EMAILS
        ]
        _n = "MultipleRecipients" if len(others) > 1 else _name_for(to_v)
        return f"{_n} {_DIR_SENT}{_att}"
    _cc = _CC_FLAG if cc_only else ""
    return f"{_name_for(from_v)} {_DIR_RECEIVED}{_cc}{_att}"


def _peek_mail_metadata(mail_path: Path) -> tuple[object | None, str]:
    """Read date and subject from .msg/.eml for naming without full conversion."""
    ext = mail_path.suffix.lower()
    if ext == ".msg":
        extract_msg = _get_extract_msg_module()
        msg = extract_msg.openMsg(str(mail_path))
        try:
            return msg.date, msg.subject or ""
        finally:
            msg.close()
    if ext == ".eml":
        with open(mail_path, "rb") as f:
            peek_msg = email.message_from_binary_file(f, policy=email.policy.compat32)
        subject = _decode_rfc2047(peek_msg.get("Subject") or "")
        date_str = peek_msg.get("Date") or ""
        try:
            mail_date = parsedate_to_datetime(date_str) if date_str else None
            if mail_date:
                mail_date = mail_date.astimezone(_LOCAL_TZ)
        except Exception:
            mail_date = None
        return mail_date, subject
    return None, ""


def _convert_mail_to_adoc_text(mail_path: Path) -> str:
    """Convert .msg/.eml file content to AsciiDoc text."""
    ext = mail_path.suffix.lower()
    if ext == ".msg":
        return msg_to_adoc(mail_path)
    if ext == ".eml":
        return eml_to_adoc(mail_path)
    raise ValueError(f"Unsupported file type '{ext}'. Use .msg or .eml")


def _write_converted_mail(
    mail_path: Path, out_path: Path | None = None
) -> tuple[Path, str]:
    """Convert a mail file and write output; returns output path and AsciiDoc text."""
    mail_date, subject = _peek_mail_metadata(mail_path)
    if out_path is None:
        stem = _adoc_stem(mail_date, subject)
        year = str(mail_date.astimezone(_LOCAL_TZ).year) if mail_date else "unbekannt"
        out_dir = _PROJECT_ROOT / "01_Korrespondenz" / year
        out_dir.mkdir(parents=True, exist_ok=True)
        out_path = out_dir / (stem + ".adoc")
    adoc = _convert_mail_to_adoc_text(mail_path)
    out_path.write_text(adoc.replace("\x00", ""), encoding="utf-8")
    return out_path, adoc


def _report_adoc_comparison(
    path_a: Path, text_a: str, path_b: Path, text_b: str
) -> None:
    """Print a concise comparison report for two generated AsciiDoc outputs."""
    lines_a = text_a.replace("\r\n", "\n").splitlines()
    lines_b = text_b.replace("\r\n", "\n").splitlines()
    if lines_a == lines_b:
        print(f"Vergleich: IDENTISCH ({path_a.name})")
        return

    ratio = difflib.SequenceMatcher(
        None, "\n".join(lines_a), "\n".join(lines_b)
    ).ratio()
    print(
        f"Vergleich: UNTERSCHIEDE ({ratio:.1%} ähnlich) — {path_a.name} vs {path_b.name}"
    )
    diff = list(
        difflib.unified_diff(
            lines_a,
            lines_b,
            fromfile=path_a.name,
            tofile=path_b.name,
            lineterm="",
            n=2,
        )
    )
    if diff:
        print("Diff (erste 40 Zeilen):")
        for line in diff[:40]:
            print(line)


def process_attachments(
    attachments: list[AttachmentData], mail_date, docs_dir: Path, msg_path: Path
) -> list[AttachmentLink]:
    """Deduplicate attachments against docs/ by MD5 checksum."""
    blocklist = _load_blocklist(Path(__file__).resolve().parent)
    date_prefix = mail_date.strftime("%Y%m%d_%H%M") if mail_date else ""
    results = []

    for name, data in attachments:
        if not data:
            continue
        checksum = hashlib.md5(data).hexdigest()
        if checksum in blocklist:
            print(f"  Skipped (blocklisted): {name}")
            continue

        suffix = Path(name).suffix.lower()
        if suffix in {".msg", ".eml"}:
            raw_dir = _PROJECT_ROOT / ".new" / "mails" / "raw"
            existing_raw = _find_existing_by_checksum(raw_dir, checksum)
            if existing_raw:
                source_mail = existing_raw
            else:
                source_mail = _write_unique_file(raw_dir, name, data, date_prefix)
                print(f"  Extracted mail attachment: {source_mail}")
            try:
                nested_out, _ = _write_converted_mail(source_mail)
                print(f"  Converted mail attachment: {nested_out}")
                results.append((name, _as_adoc_link(nested_out), False))
            except Exception as exc:
                print(f"  Warning: Could not convert mail attachment '{name}': {exc}")
                results.append((name, _as_adoc_link(source_mail), False))
            continue

        already_in_docs = _find_existing_by_checksum(docs_dir, checksum)
        is_image = Path(name).suffix.lower() in IMAGE_EXTENSIONS

        if already_in_docs:
            results.append((name, _as_adoc_link(already_in_docs), is_image))
        else:
            dest = _write_unique_file(docs_dir, name, data, date_prefix)
            print(f"  Extracted: {dest}")
            results.append((name, _as_adoc_link(dest), is_image))

    return results


def _split_addresses(addr_str: str) -> list[str]:
    """Parse an address header into individual address strings, sorted alphabetically."""
    parsed = getaddresses([addr_str])
    result = []
    for name, addr in parsed:
        name = name.strip().strip('"')
        if name and addr:
            result.append(addr if name.lower() == addr.lower() else f"{name} <{addr}>")
        elif addr:
            result.append(addr)
        elif name:
            result.append(name)
    return sorted(result, key=str.lower)


def _addr_table_row(label: str, addr_str: str) -> str:
    """Format an address field as an AsciiDoc table row."""
    if not addr_str:
        return ""
    addrs = _split_addresses(addr_str)
    if not addrs:
        return f"|{label} |{addr_str}"
    if len(addrs) == 1:
        return f"|{label} |{addrs[0]}"
    if len(addrs) > 10:
        return f"|{label} |" + ", ".join(addrs)
    return f"|{label} a|" + "\n".join(f"* {a}" for a in addrs)


_POSTPROCESS_LONG_LINE = 80  # lines longer than this are QP-wrapped paragraphs
_POSTPROCESS_LIST_PREFIXES = ("* ", "** ", "*** ", ". ", ".. ", "... ", "- ")


def _postprocess_body(body: str) -> str:
    """Apply post-processing to the plain-text body before writing to adoc.

    1. Unwrap Microsoft SafeLinks URLs — replaces the safelinks wrapper with
       the real URL extracted from the ``url=`` query parameter.
    2. Preserve intentional line breaks with `` +`` (hard line-break in AsciiDoc).
       Rules for when to add `` +`` to a line:
       - Both current and next line are non-blank.
       - Line does not already end with `` +``.
       - Line is NOT an AsciiDoc list item (``* ``, ``- ``, etc.) — adding `` +``
         inside a list corrupts the list structure.
       - Line is ≤ 80 chars — longer lines are Quoted-Printable soft-wrapped
         paragraphs that should flow as prose, not be hard-split.
    """
    from urllib.parse import urlparse, parse_qs, unquote as _unquote

    # ── 1. SafeLinks ──────────────────────────────────────────────────────────
    def _unwrap(m: re.Match) -> str:
        raw = m.group("url")
        if "safelinks.protection.outlook.com" not in raw:
            return m.group(0)
        try:
            qs = parse_qs(urlparse(raw).query)
            real = qs.get("url", [None])[0]
            if real:
                return f"link:{_unquote(real).replace(' ', '%20')}[{m.group('disp')}]"
        except Exception:
            pass
        return m.group(0)

    body = re.sub(
        r"link:(?P<url>https?://[^\[]+)\[(?P<disp>[^\]]*)\]",
        _unwrap,
        body,
    )

    # ── 2. Horizontal rule before quoted-reply headers ────────────────────────
    # Outlook/Thunderbird reply headers (*Von:* / *From:*) are preceded by a
    # thin rule in the rendered email.  Insert AsciiDoc ''' before them.
    _REPLY_START = re.compile(r"^\*(Von|From|De|Van):\*", re.IGNORECASE)
    # All recognised reply-header field names (German + English).
    _REPLY_HDR_KEYS = frozenset(
        {
            "from",
            "sent",
            "to",
            "cc",
            "bcc",
            "subject",
            "date",
            "von",
            "gesendet",
            "an",
            "betreff",
            "datum",
        }
    )

    def _is_reply_hdr(line: str) -> bool:
        m = re.match(r"^\*([^*]+):\*", line.strip(), re.IGNORECASE)
        return bool(m and m.group(1).strip().lower() in _REPLY_HDR_KEYS)

    lines = body.split("\n")
    out_hr: list[str] = []
    for line in lines:
        if _REPLY_START.match(line.lstrip()):
            prev = out_hr[-1].strip() if out_hr else ""
            if prev:
                out_hr.append("")
            out_hr.append("'''")
            out_hr.append("")
        out_hr.append(line)
    body = "\n".join(out_hr)

    # ── 3. Hard line-breaks for intentional short lines ───────────────────────
    # Rules (in order of priority):
    #   • AsciiDoc structural lines ([…], ''', ==…) → never add ' +'
    #   • Reply-header lines (*Von:*, *From:*, …)   → always add ' +' (even if long)
    #   • List items                                 → never add ' +'
    #   • Lines > LONG threshold                     → never add ' +' (QP-wrapped prose)
    #   • Everything else that is followed by non-blank → add ' +'
    def _is_structural(line: str) -> bool:
        s = line.strip()
        return (
            s.startswith("[") or s in ("'''", "---", "***", "___") or s.startswith("=")
        )

    lines = body.split("\n")
    out = []
    for idx, line in enumerate(lines):
        raw = line.rstrip()
        next_line = lines[idx + 1] if idx + 1 < len(lines) else ""
        if (
            raw
            and next_line.strip()
            and not raw.endswith(" +")
            and not _is_structural(raw)
            and not any(raw.lstrip().startswith(p) for p in _POSTPROCESS_LIST_PREFIXES)
            and (_is_reply_hdr(raw) or len(raw) <= _POSTPROCESS_LONG_LINE)
        ):
            out.append(raw + " +")
        else:
            out.append(line)
    return "\n".join(out)


def _decode_thread_index(raw: str) -> str:
    """Decode a Thread-Index header into 'short-id (depth N)' form.

    Thread-Index is a base64-encoded binary blob:
      bytes 0:     header byte (0x01)
      bytes 1–5:   FILETIME timestamp of thread creation
      bytes 6–21:  16-byte thread GUID — stable across the whole thread
      bytes 22+:   one 5-byte block per reply (timestamp offset)
    Depth 0 = root message (no replies in chain yet).
    """
    import base64 as _b64

    raw = raw.strip()
    if not raw:
        return ""
    try:
        data = _b64.b64decode(raw + "==")
        if len(data) < 22:
            return raw  # malformed — show as-is
        depth = (len(data) - 22) // 5
        # Stable short ID: base64 of the 16-byte GUID (bytes 6–21), no padding
        short_id = _b64.b64encode(data[6:22]).decode("ascii").rstrip("=")
        return short_id if depth == 0 else f"{short_id} (Index: {depth})"
    except Exception:
        return raw


def _build_adoc(
    subject: str,
    sender: str,
    to: str,
    cc: str,
    date: str,
    attachment_links: list,
    body: str,
    *,
    reply_to: str = "",
    bcc: str = "",
    importance: str = "",
    sensitivity: str = "",
    categories: str = "",
    thread_topic: str = "",
    thread_index: str = "",
) -> str:
    """Assemble the final AsciiDoc document from extracted mail fields."""
    subject_escaped = subject.replace(": ", "&#58; ")
    lines = [
        f"= {subject_escaped}",
        "",
        "[%autowidth]",
        "|===",
        f"|From |{sender}",
        f"|Sent |{date}",
    ]
    to_row = _addr_table_row("To  ", to)
    if to_row:
        lines.append(to_row)
    if reply_to and reply_to != sender:
        row = _addr_table_row("Reply-To", reply_to)
        if row:
            lines.append(row)
    cc_row = _addr_table_row("CC  ", cc)
    if cc_row:
        lines.append(cc_row)
    bcc_row = _addr_table_row("BCC ", bcc)
    if bcc_row:
        lines.append(bcc_row)
    if importance and importance.lower() != "normal":
        lines.append(f"|Importance |{importance}")
    if sensitivity and sensitivity.lower() != "normal":
        lines.append(f"|Sensitivity |{sensitivity}")
    if categories:
        lines.append(f"|Categories |{categories}")
    if thread_topic and thread_topic != subject:
        lines.append(f"|Thread-Topic |{thread_topic}")
    if thread_index:
        lines.append(f"|Thread |{_decode_thread_index(thread_index)}")
    lines += ["|===", ""]
    if attachment_links:
        lines += ["[NOTE]", "====", "*Attachments:*", ""]
        for orig_name, link_path, is_image in attachment_links:
            if is_image:
                lines.append(
                    f'image::{link_path}[{orig_name}, 120, link="{link_path}"]'
                )
            else:
                lines.append(f"* link:{link_path}[{orig_name}]")
        lines += ["", "====", ""]
    lines.append(_postprocess_body(body))
    return "\n".join(lines)


def _decode_msg_html(html_bytes: bytes) -> str:
    """Decode .msg HTML body detecting charset from meta tag; fallback: cp1252."""
    m = re.search(rb'charset=["\']?([^"\'>\s;]+)', html_bytes, re.IGNORECASE)
    charset = m.group(1).decode("ascii", "replace") if m else "cp1252"
    try:
        return html_bytes.decode(charset, errors="replace")
    except LookupError:
        return html_bytes.decode("cp1252", errors="replace")


def msg_to_adoc(msg_path: Path) -> str:
    """Convert a .msg Outlook file to an AsciiDoc string."""
    extract_msg = _get_extract_msg_module()
    msg = extract_msg.openMsg(str(msg_path))
    try:
        subject = (msg.subject or "(No Subject)").replace("\x00", "").strip()
        sender = msg.sender or ""
        to = re.sub(r"[ \t]+", " ", (msg.to or "")).replace("; ", ", ")
        cc = re.sub(r"[ \t]+", " ", (msg.cc or "")).replace("; ", ", ")
        _date_local = msg.date.astimezone(_LOCAL_TZ) if msg.date else None
        date = str(_date_local) if _date_local else ""
        # Prefer HTML (has charset) → fallback plain text
        html_bytes = msg.htmlBody
        if html_bytes:
            html = (
                _decode_msg_html(html_bytes)
                if isinstance(html_bytes, bytes)
                else html_bytes
            )
            body = strip_html(html)
        else:
            body = msg.body or ""
        body = normalize_body(body)
        raw_attachments = []
        for att in msg.attachments:
            if getattr(att, "isInline", False):
                continue
            name = re.sub(
                r"\s+",
                " ",
                (att.longFilename or att.shortFilename or "").replace("\x00", ""),
            ).strip()
            if not name:
                continue
            raw_attachments.append((name, getattr(att, "data", None) or b""))
        mail_date = msg.date
        if mail_date is not None:
            # extract_msg may return a timezone-naive UTC datetime; convert to local.
            import datetime as _dt

            if mail_date.tzinfo is None:
                mail_date = mail_date.replace(tzinfo=_dt.timezone.utc)
            mail_date = mail_date.astimezone(_LOCAL_TZ)
        reply_to = re.sub(r"[ \t]+", " ", getattr(msg, "reply_to", "") or "")
        bcc = re.sub(r"[ \t]+", " ", getattr(msg, "bcc", "") or "")
        raw_imp = getattr(msg, "importanceText", None) or getattr(
            msg, "importance", None
        )
        importance = (
            IMPORTANCE_LABELS.get(raw_imp, "")
            if isinstance(raw_imp, int)
            else str(raw_imp).capitalize()
            if raw_imp
            else ""
        )
        raw_sens = getattr(msg, "sensitivityText", None) or getattr(
            msg, "sensitivity", None
        )
        sensitivity = (
            SENSITIVITY_LABELS.get(raw_sens, "")
            if isinstance(raw_sens, int)
            else str(raw_sens).capitalize()
            if raw_sens
            else ""
        )
        categories = ", ".join(str(c) for c in (getattr(msg, "categories", None) or []))
        thread_topic = (getattr(msg, "threadTopic", None) or "").strip()
        thread_index = (getattr(msg, "threadIndex", None) or "").strip()
    finally:
        msg.close()
    docs_dir = _PROJECT_ROOT / "01_Korrespondenz" / "Attachments"
    attachment_links = process_attachments(
        raw_attachments, mail_date, docs_dir, msg_path
    )
    return _build_adoc(
        subject,
        sender,
        to,
        cc,
        date,
        attachment_links,
        body,
        reply_to=reply_to,
        bcc=bcc,
        importance=importance,
        sensitivity=sensitivity,
        categories=categories,
        thread_topic=thread_topic,
        thread_index=thread_index,
    )


def _unfold_header(value: str) -> str:
    """Remove RFC 2822 line-folding."""
    return re.sub(r"\r?\n[ \t]+", " ", value).strip()


def eml_to_adoc(eml_path: Path) -> str:
    """Convert a .eml file to AsciiDoc using Python's built-in email module."""
    with open(eml_path, "rb") as f:
        msg = email.message_from_binary_file(f, policy=email.policy.compat32)
    subject = _decode_rfc2047(_unfold_header(msg.get("Subject") or "(No Subject)"))
    sender = _decode_rfc2047(_unfold_header(msg.get("From") or ""))
    to = _decode_rfc2047(_unfold_header(msg.get("To") or ""))
    cc = _decode_rfc2047(_unfold_header(msg.get("CC") or msg.get("Cc") or ""))
    date_str = msg.get("Date") or ""
    mail_date = None
    date = date_str
    if date_str:
        try:
            mail_date = parsedate_to_datetime(date_str)
            mail_date = mail_date.astimezone(_LOCAL_TZ)
            date = str(mail_date)
        except Exception:
            pass
    html_body: str | None = None
    plain_body: str | None = None
    raw_attachments: list[tuple[str, bytes]] = []
    for part in msg.walk():
        content_type = part.get_content_type()
        disposition = part.get("Content-Disposition") or ""
        filename = _decode_rfc2047(part.get_filename() or "")
        if "attachment" in disposition.lower() and filename:
            data = part.get_payload(decode=True) or b""
            name = re.sub(r"\s+", " ", filename.replace("\x00", "")).strip()
            if name and isinstance(data, (bytes, bytearray)):
                raw_attachments.append((name, bytes(data)))
            continue
        if "inline" in disposition.lower() and filename:
            continue
        if content_type == "text/html" and html_body is None:
            payload = part.get_payload(decode=True)
            if isinstance(payload, (bytes, bytearray)) and payload:
                html_body = bytes(payload).decode(
                    part.get_content_charset() or "utf-8", errors="replace"
                )
        elif content_type == "text/plain" and plain_body is None:
            payload = part.get_payload(decode=True)
            if isinstance(payload, (bytes, bytearray)) and payload:
                raw_plain = bytes(payload).decode(
                    part.get_content_charset() or "utf-8", errors="replace"
                )
                # Some clients embed QP-encoded text without declaring CTE
                plain_body = (
                    _decode_qp_body(raw_plain)
                    if "=3D" in raw_plain or "=C3" in raw_plain
                    else raw_plain
                )
    body = (
        normalize_body(strip_html(html_body))
        if html_body
        else (normalize_body(plain_body) if plain_body else "")
    )
    reply_to = _unfold_header(msg.get("Reply-To") or "")
    bcc = _unfold_header(msg.get("BCC") or msg.get("Bcc") or "")
    imp_hdr = msg.get("Importance") or msg.get("X-Priority") or ""
    importance = X_PRIORITY_LABELS.get(imp_hdr.strip(), imp_hdr.strip().capitalize())
    sensitivity = _unfold_header(msg.get("Sensitivity") or "").capitalize()
    categories = _unfold_header(msg.get("Keywords") or "")
    thread_topic = _decode_rfc2047(_unfold_header(msg.get("Thread-Topic") or ""))
    thread_index = _unfold_header(msg.get("Thread-Index") or "")
    docs_dir = _PROJECT_ROOT / "01_Korrespondenz" / "Attachments"
    attachment_links = process_attachments(
        raw_attachments, mail_date, docs_dir, eml_path
    )
    return _build_adoc(
        subject,
        sender,
        to,
        cc,
        date,
        attachment_links,
        body,
        reply_to=reply_to,
        bcc=bcc,
        importance=importance,
        sensitivity=sensitivity,
        categories=categories,
        thread_topic=thread_topic,
        thread_index=thread_index,
    )


def main():
    global _PROJECT_ROOT, _LOG_DIR
    import json as _json

    # Optional --root <path> override — useful for debug/test runs into a shadow folder.
    args = sys.argv[1:]
    if args and args[0] == "--root":
        if len(args) < 2:
            print("Error: --root requires a path argument")
            sys.exit(1)
        _PROJECT_ROOT = Path(args[1]).resolve()
        _LOG_DIR = _PROJECT_ROOT / ".logs"
        args = args[2:]
    else:
        args = list(args)

    overwrite = False
    if args and args[0] == "--overwrite":
        overwrite = True
        args = args[1:]

    # --json: emit a single JSON object to stdout; all diagnostic prints → stderr
    json_mode = False
    if args and args[0] == "--json":
        json_mode = True
        args = args[1:]

    def _emit(msg: str) -> None:
        if json_mode:
            sys.stderr.write(msg + "\n")
            sys.stderr.flush()
        else:
            print(msg)

    # Result dict populated throughout; serialised to stdout at end when --json.
    _jr: dict = {}

    if not args:
        print(
            "Usage: python mail_to_adoc.py [--root <project-root>] [--overwrite] [--json] <file.msg|.eml>"
        )
        sys.exit(1)

    mail_path = Path(args[0])
    _jr["source"] = str(mail_path.resolve())
    if not mail_path.exists():
        print(f"Error: File not found: {mail_path}")
        sys.exit(1)

    ext = mail_path.suffix.lower()
    if ext not in {".msg", ".eml"}:
        print(f"Error: Unsupported file type '{ext}'. Use .msg or .eml")
        sys.exit(1)

    # ── 1. Metadata & naming ──────────────────────────────────────────────────
    mail_date, subject = _peek_mail_metadata(mail_path)
    local_date = mail_date.astimezone(_LOCAL_TZ) if mail_date else None
    stem = _adoc_stem(mail_date, subject)
    year = str(local_date.year) if local_date else "unbekannt"

    # ── 2. Convert primary into .temp/ ────────────────────────────────────────
    import tempfile as _tempfile

    temp_dir = Path(_tempfile.gettempdir()) / "mail_to_adoc_temp"
    temp_dir.mkdir(parents=True, exist_ok=True)
    temp_primary = temp_dir / (stem + ".adoc")
    _, primary_adoc = _write_converted_mail(mail_path, temp_primary)
    _jr["temp"] = str(temp_primary)
    _emit(f"Temp (primary .{ext[1:]}): {temp_primary.name}")

    # ── 3. Convert counterpart for comparison ─────────────────────────────────
    counterpart_ext = ".eml" if ext == ".msg" else ".msg"
    counterpart = mail_path.with_suffix(counterpart_ext)
    final_adoc = primary_adoc

    if counterpart.exists():
        import tempfile

        tmp_fd, tmp_name = tempfile.mkstemp(
            suffix=f".{counterpart_ext[1:]}.adoc", prefix=stem + "_cmp_"
        )
        import os as _os

        _os.close(tmp_fd)
        temp_cmp = Path(tmp_name)
        _, cmp_adoc = _write_converted_mail(counterpart, temp_cmp)
        _report_adoc_comparison(temp_primary, primary_adoc, temp_cmp, cmp_adoc)

        if ext == ".msg" and cmp_adoc != primary_adoc:
            temp_primary.write_text(cmp_adoc.replace("\x00", ""), encoding="utf-8")
            final_adoc = cmp_adoc
            _emit("  → .eml-Version als final übernommen (bessere Kodierung/TZ)")

        try:
            temp_cmp.unlink()
        except OSError:
            pass
    else:
        _emit(f"Vergleich: kein {counterpart_ext}-Gegenstück gefunden")

    # ── 4. Build full stem with direction tag + attachment flag ──────────────
    _fm = re.search(r"\|From\s*\|(.+)", final_adoc)
    _tm = re.search(r"\|To\s*\|(.+)", final_adoc)
    _from_v = _fm.group(1).strip() if _fm else ""
    _to_v = _tm.group(1).strip() if _tm else ""
    _has_att = "*Attachments:*" in final_adoc
    # Dennis was only CC'd when he appears in the Cc field but not in To.
    _cc_only = _dennis_in(_meta_field(final_adoc, "CC")) and not _dennis_in(
        _meta_field(final_adoc, "To")
    )
    _dtag = _direction_tag(_from_v, _to_v, has_att=_has_att, cc_only=_cc_only)
    month = f"{local_date.month:02d}" if local_date else "00"
    full_stem = f"{stem}{_STEM_SEP}{_dtag}"

    # ── 5. Copy from .temp/ to 01_Korrespondenz/{year}/{month}/ ─────────────
    import shutil as _shutil2

    out_dir = _PROJECT_ROOT / "01_Korrespondenz" / year / month
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / (full_stem + ".adoc")

    if out_path.exists():
        try:
            existing = out_path.read_text(encoding="utf-8")
            identical = existing.replace("\r\n", "\n") == final_adoc.replace(
                "\r\n", "\n"
            )
        except OSError:
            identical = False  # cloud-only file — treat as needing overwrite
        if identical:
            _jr["adoc_status"] = "skipped"
            _emit(f"Übersprungen (identisch): {out_path.name}")
        elif overwrite:
            # copy2 cannot open a cloud-only file for 'wb'; use rename instead:
            # write to a sibling temp file, then rename() over the cloud-only target.
            import os as _os
            import tempfile as _tf

            tmp_fd, tmp_name = _tf.mkstemp(dir=out_dir, prefix=".tmp_")
            _os.close(tmp_fd)
            _shutil2.copy2(str(temp_primary), tmp_name)
            _os.rename(tmp_name, str(out_path))
            _jr["adoc_status"] = "overwritten"
            _emit(f"Überschrieben: {out_path.name}")
        else:
            counter = 1
            while out_path.exists():
                out_path = out_dir / f"{full_stem} ({counter}).adoc"
                counter += 1
            _shutil2.copy2(str(temp_primary), str(out_path))
            _jr["adoc_status"] = "conflict"
            _emit(f"KONFLIKT — gespeichert als: {out_path.name}")
    else:
        _shutil2.copy2(str(temp_primary), str(out_path))
        _jr["adoc_status"] = "written"
        _emit(f"Written: {out_path}")
    _jr["adoc"] = str(out_path)

    # ── 6. Archive / rename source file ──────────────────────────────────────
    import filecmp as _filecmp

    _parts = [p.lower() for p in mail_path.resolve().parts]
    _in_archive = any(
        _parts[i] == "01_korrespondenz"
        and i + 1 < len(_parts)
        and _parts[i + 1] == "original"
        for i in range(len(_parts) - 1)
    )
    archive_ext = mail_path.suffix
    new_src_name = full_stem + archive_ext  # match adoc stem

    if not _in_archive:
        archive_dir = (
            _PROJECT_ROOT / "01_Korrespondenz" / "Original" / f"{year}-{month}"
        )
        archive_dir.mkdir(parents=True, exist_ok=True)
        dest = archive_dir / new_src_name

        if dest.exists():
            if _filecmp.cmp(str(mail_path), str(dest), shallow=False):
                _emit(f"Archiv übersprungen (identisch): {dest.name}")
                _jr["archive"] = str(dest)
                _jr["archive_status"] = "skipped"
                dest = None
            else:
                counter = 1
                while dest.exists():
                    dest = archive_dir / f"{full_stem} ({counter}){archive_ext}"
                    counter += 1

        if dest is not None:
            _shutil2.copy2(str(mail_path), str(dest))
            try:
                mail_path.unlink()
            except OSError:
                pass  # OneDrive FUSE blocks unlink; run Cleanup-ProcessedFiles.ps1 on Windows
            _jr["archive"] = str(dest)
            _jr["archive_status"] = "archived"
            _emit(f"Archiviert: {dest.name}")
    else:
        # Already in archive — rename in-place to match adoc stem
        dest = mail_path.parent / new_src_name
        if dest != mail_path:
            if not dest.exists():
                try:
                    mail_path.rename(dest)
                    _jr["archive"] = str(dest)
                    _jr["archive_status"] = "renamed"
                    _emit(f"Umbenannt: {dest.name}")
                except OSError:
                    pass  # OneDrive FUSE rename may fail
            else:
                _jr["archive"] = str(dest)
                _jr["archive_status"] = "skipped_rename"
                _emit(f"Umbenennung übersprungen (Ziel existiert): {dest.name}")

    if json_mode:
        print(_json.dumps(_jr, ensure_ascii=True))


if __name__ == "__main__":
    main()
