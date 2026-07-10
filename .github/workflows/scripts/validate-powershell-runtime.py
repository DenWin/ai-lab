from __future__ import annotations

import re
import subprocess
import sys
import os
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
REPORTS_DIR = Path(
    os.environ.get("REPORTS_DIR", str(REPO_ROOT / ".temp/Reports"))
).expanduser()
WINDOWS_PS_SUFFIX = "-windowsps.ps1"
RUNTIME_POLICY_RE = re.compile(
    r"^\s*#\s*RuntimePolicy:\s*([A-Za-z0-9_-]+)", re.IGNORECASE
)
RUNTIME_JUSTIFICATION_RE = re.compile(
    r"^\s*#\s*RuntimeJustification:\s*(.+)$", re.IGNORECASE
)
REQUIRES_VERSION_RE = re.compile(
    r"^\s*#requires\s+-version\s+([0-9]+(?:\.[0-9]+)?)", re.IGNORECASE
)
REQUIRES_EDITION_RE = re.compile(r"^\s*#requires\s+-psedition\s+(\w+)", re.IGNORECASE)


def git_ls_files(*patterns: str) -> list[str]:
    result = subprocess.run(
        ["git", "ls-files", *patterns],
        cwd=REPO_ROOT,
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or "git ls-files failed")
    return [line for line in result.stdout.splitlines() if line.strip()]


def parse_headers(path: Path) -> tuple[str | None, str | None, str | None, str | None]:
    policy = None
    justification = None
    version = None
    edition = None
    with path.open("r", encoding="utf-8") as handle:
        for _ in range(40):
            line = handle.readline()
            if not line:
                break
            policy_match = RUNTIME_POLICY_RE.match(line)
            if policy_match:
                policy = policy_match.group(1).strip().lower()
            justification_match = RUNTIME_JUSTIFICATION_RE.match(line)
            if justification_match:
                justification = justification_match.group(1).strip()
            version_match = REQUIRES_VERSION_RE.match(line)
            if version_match:
                version = version_match.group(1)
            edition_match = REQUIRES_EDITION_RE.match(line)
            if edition_match:
                edition = edition_match.group(1)
    return policy, justification, version, edition


def version_major(version_text: str) -> int:
    try:
        return int(version_text.split(".")[0])
    except (ValueError, IndexError) as exc:
        raise ValueError(f"invalid version '{version_text}'") from exc


def validate_ps_files(errors: list[str]) -> None:
    files = git_ls_files(
        "*.ps1",
        ":(exclude).scratch/*/artefacts/**",
        ":(exclude).scratch/*/artifacts/**",
    )
    for rel in files:
        path = REPO_ROOT / rel
        if not path.exists():
            continue
        policy, justification, version, edition = parse_headers(path)
        rel_posix = path.relative_to(REPO_ROOT).as_posix()
        is_windows_ps = path.name.lower().endswith(WINDOWS_PS_SUFFIX)

        if policy is None:
            errors.append(
                f"{rel_posix}: missing '# RuntimePolicy: core-first|dual-runtime|desktop-only'"
            )
            continue

        if policy not in {"core-first", "dual-runtime", "desktop-only"}:
            errors.append(
                f"{rel_posix}: invalid RuntimePolicy '{policy}' "
                "(allowed: core-first, dual-runtime, desktop-only)"
            )
            continue

        if policy == "core-first":
            if version is None:
                errors.append(
                    f"{rel_posix}: core-first scripts must declare '#Requires -Version 7.0' or higher"
                )
                continue
            if edition is None:
                errors.append(
                    f"{rel_posix}: core-first scripts must declare '#Requires -PSEdition Core'"
                )
                continue
            major = version_major(version)
            edition_norm = edition.lower()
            if major < 7:
                errors.append(
                    f"{rel_posix}: core-first requires PowerShell {version}; expected 7+"
                )
            if edition_norm != "core":
                errors.append(
                    f"{rel_posix}: core-first scripts must use '#Requires -PSEdition Core'"
                )
            if is_windows_ps:
                errors.append(
                    f"{rel_posix}: core-first scripts must not use the '{WINDOWS_PS_SUFFIX}' override suffix"
                )
            continue

        if policy == "dual-runtime":
            if edition is not None:
                errors.append(
                    f"{rel_posix}: dual-runtime scripts must not set '#Requires -PSEdition ...'"
                )
            if version is not None:
                major = version_major(version)
                if major > 5:
                    errors.append(
                        f"{rel_posix}: dual-runtime '#Requires -Version {version}' blocks Windows PowerShell 5.1"
                    )
            if is_windows_ps:
                errors.append(
                    f"{rel_posix}: dual-runtime scripts must not use the '{WINDOWS_PS_SUFFIX}' suffix"
                )
            continue

        if policy == "desktop-only":
            if not is_windows_ps:
                errors.append(
                    f"{rel_posix}: desktop-only scripts must be named '*{WINDOWS_PS_SUFFIX}'"
                )
            if not justification:
                errors.append(
                    f"{rel_posix}: desktop-only scripts must include '# RuntimeJustification: ...'"
                )
            if version is None:
                errors.append(
                    f"{rel_posix}: desktop-only scripts must declare '#Requires -Version 5.1'"
                )
                continue
            if edition is None:
                errors.append(
                    f"{rel_posix}: desktop-only scripts must declare '#Requires -PSEdition Desktop'"
                )
                continue
            if version != "5.1":
                errors.append(
                    f"{rel_posix}: desktop-only scripts must use '#Requires -Version 5.1'"
                )
            if edition.lower() != "desktop":
                errors.append(
                    f"{rel_posix}: desktop-only scripts must use '#Requires -PSEdition Desktop'"
                )


def write_report(errors: list[str]) -> None:
    REPORTS_DIR.mkdir(exist_ok=True)
    report = REPORTS_DIR / "powershell-runtime-check.txt"
    lines = ["powershell runtime check"]
    if errors:
        lines.append("status: failed")
        lines.extend(errors)
    else:
        lines.append("status: passed")
        lines.append("all PowerShell scripts declare a valid runtime policy")
    report.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    errors: list[str] = []
    try:
        validate_ps_files(errors)
    except Exception as exc:
        errors.append(str(exc))

    write_report(errors)
    if errors:
        for err in errors:
            print(err)
        return 1
    print("PowerShell runtime checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
