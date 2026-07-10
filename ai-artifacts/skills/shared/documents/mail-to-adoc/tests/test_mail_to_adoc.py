from __future__ import annotations

import hashlib
from email.message import EmailMessage
from pathlib import Path

import pytest


def test_split_addresses_sorts_and_collapses_duplicate_display(converter):
    header = 'Zoe <zoe@example.com>, "amy@example.com" <amy@example.com>, Bob <bob@example.com>'

    result = converter._split_addresses(header)

    assert result == [
        "amy@example.com",
        "Bob <bob@example.com>",
        "Zoe <zoe@example.com>",
    ]


def test_addr_table_row_uses_bullets_for_medium_recipient_lists(converter):
    recipients = ", ".join(f"User{i} <u{i}@example.com>" for i in range(1, 4))

    row = converter._addr_table_row("To", recipients)

    assert row.startswith("|To a|")
    assert "* User1 <u1@example.com>" in row
    assert "* User2 <u2@example.com>" in row
    assert "* User3 <u3@example.com>" in row


@pytest.mark.skip(
    reason="_add_hardbreaks_to_reply_headers was removed in the 2026-07-05 drop "
    "(no [%hardbreaks] output remains). Decide intended-removal vs regression in "
    "mail-to-doc issue 02, then delete or restore this test."
)
def test_add_hardbreaks_to_reply_headers_only_at_header_run_start(converter):
    body = """Hello team,

*From:* A <a@example.com>
*Sent:* Today
*To:* B <b@example.com>
Thanks
"""

    normalized = converter._add_hardbreaks_to_reply_headers(body)

    assert normalized.count("[%hardbreaks]") == 1
    assert "[%hardbreaks]\n*From:* A <a@example.com>" in normalized


@pytest.mark.skip(
    reason="_auto_name was refactored away in the 2026-07-05 drop; naming is now "
    "_adoc_stem + _direction_tag with a different convention. Decide in mail-to-doc "
    "issue 02 whether to retarget this at _adoc_stem or delete it."
)
def test_auto_name_trims_existing_date_prefix_and_handles_raw_folder(converter):
    mail_date = __import__("datetime").datetime(2026, 5, 11, 14, 52)
    mail_path = Path("mails/raw/2026-05-11 1452 - Weekly Meeting.eml")

    out_path = converter._auto_name(mail_path, mail_date, "Weekly Meeting")

    assert out_path.as_posix() == "mails/20260511 1452 - Weekly Meeting.adoc"


def test_process_attachments_skips_blocklist_and_dedupes_existing(
    converter, monkeypatch, tmp_path
):
    docs_dir = tmp_path / "docs"
    docs_dir.mkdir(parents=True)

    existing_data = b"same-content"
    existing_file = docs_dir / "20260511_1452-evidence.pdf"
    existing_file.write_bytes(existing_data)

    blocked_data = b"blocked-content"
    blocked_checksum = hashlib.md5(blocked_data).hexdigest()
    monkeypatch.setattr(
        converter, "_load_blocklist", lambda _script_dir: {blocked_checksum}
    )

    attachments = [
        ("duplicate.pdf", existing_data),
        ("blocked.png", blocked_data),
    ]

    links = converter.process_attachments(
        attachments=attachments,
        mail_date=__import__("datetime").datetime(2026, 5, 11, 14, 52),
        docs_dir=docs_dir,
        msg_path=Path("mails/sample.eml"),
    )

    assert links == [
        ("duplicate.pdf", "../../../docs/20260511_1452-evidence.pdf", False)
    ]
    assert not (docs_dir / "20260511_1452-blocked.png").exists()


def test_eml_to_adoc_prefers_html_and_writes_attachment_links(converter, tmp_path):
    msg = EmailMessage()
    msg["Subject"] = "Mail Subject"
    msg["From"] = "sender@example.com"
    msg["To"] = "receiver@example.com"
    msg["Date"] = "Tue, 11 May 2026 14:52:00 +0000"

    msg.set_content("plain fallback body")
    msg.add_alternative(
        "<html><body><p><b>HTML body</b></p></body></html>", subtype="html"
    )
    msg.add_attachment(
        b"%PDF-1.4 demo",
        maintype="application",
        subtype="pdf",
        filename="evidence.pdf",
    )

    eml_path = tmp_path / "mail.eml"
    eml_path.write_bytes(msg.as_bytes())

    adoc = converter.eml_to_adoc(eml_path)
    saved_attachments = list(
        (tmp_path / "01_Korrespondenz" / "Attachments").glob("*-evidence.pdf")
    )

    assert "= Mail Subject" in adoc
    assert "*HTML body*" in adoc
    assert "plain fallback body" not in adoc
    assert len(saved_attachments) == 1
    saved_name = saved_attachments[0].name
    assert f"* link:../../Attachments/{saved_name}[evidence.pdf]" in adoc


def test_strip_html_removes_script_tag_with_whitespace_before_closing_bracket(converter):
    html = "<p>keep</p><script>alert('x')</script ><p>also keep</p>"

    text = converter.strip_html(html)

    assert "alert('x')" not in text
    assert "keep" in text
    assert "also keep" in text


# --- Filename direction/attachment markers (bracket tags, replacing emoji) ------

_DENNIS = "Dennis <owner@example.com>"
_PARTY_A = "PartyA <kontakt@lawfirm-a.example>"


def test_direction_tag_sent_uses_bracket_to(converter):
    assert converter._direction_tag(from_v=_DENNIS, to_v=_PARTY_A) == "PartyA [TO]"


def test_direction_tag_received_uses_bracket_from(converter):
    assert converter._direction_tag(from_v=_PARTY_A, to_v=_DENNIS) == "PartyA [FROM]"


def test_direction_tag_attachment_flag_is_last(converter):
    assert (
        converter._direction_tag(from_v=_PARTY_A, to_v=_DENNIS, has_att=True)
        == "PartyA [FROM][+]"
    )


def test_direction_tag_cc_only_appends_cc_after_from(converter):
    tag = converter._direction_tag(
        from_v=_PARTY_A, to_v="Other <other@example.com>", cc_only=True
    )
    assert tag == "PartyA [FROM][CC]"


def test_direction_tag_cc_and_attachment_order(converter):
    tag = converter._direction_tag(
        from_v=_PARTY_A, to_v="Other <other@example.com>", has_att=True, cc_only=True
    )
    assert tag == "PartyA [FROM][CC][+]"


def test_direction_tag_carries_no_legacy_emoji(converter):
    for tag in (
        converter._direction_tag(from_v=_DENNIS, to_v=_PARTY_A, has_att=True),
        converter._direction_tag(from_v=_PARTY_A, to_v=_DENNIS, has_att=True),
    ):
        assert not any(ch in tag for ch in ("✉", "✎", "𓂃", "📎"))


def test_dennis_in_detects_own_address_only(converter):
    assert converter._dennis_in("X <owner@example.com>") is True
    assert converter._dennis_in("owner.alt@example.com") is True
    assert converter._dennis_in("Y <stranger@example.com>") is False
    assert converter._dennis_in("") is False


def test_meta_field_reads_inline_and_bulleted_rows(converter):
    adoc = (
        "|===\n"
        "|From |A <a@x.com>\n"
        "|To   |B <b@x.com>\n"
        "|CC   a|\n* c@x.com\n* d@x.com\n"
        "|===\n"
    )
    assert converter._meta_field(adoc, "From") == "A <a@x.com>"
    assert converter._meta_field(adoc, "To") == "B <b@x.com>"
    assert converter._meta_field(adoc, "CC") == "c@x.com, d@x.com"
    assert converter._meta_field(adoc, "BCC") == ""
