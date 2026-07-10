from __future__ import annotations

import re
import subprocess
import sys
import os
from pathlib import Path
from typing import Iterable

import yaml

REPO_ROOT = Path(__file__).resolve().parents[3]
POLICY_ROOT = REPO_ROOT / "coding-policies"
REPORTS_DIR = Path(
    os.environ.get("REPORTS_DIR", str(REPO_ROOT / ".temp/Reports"))
).expanduser()


def load_yaml(path: Path) -> dict:
    if not path.exists():
        raise FileNotFoundError(f"Missing policy file: {path}")
    with path.open("r", encoding="utf-8") as handle:
        data = yaml.safe_load(handle)
    if not isinstance(data, dict):
        raise ValueError(f"Policy file is not a mapping: {path}")
    return data


def git_ls_files(*patterns: str) -> list[str]:
    cmd = ["git", "ls-files", *patterns]
    result = subprocess.run(
        cmd,
        cwd=REPO_ROOT,
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or "git ls-files failed")
    return [line for line in result.stdout.splitlines() if line.strip()]


def validate_policy_pack(errors: list[str]) -> None:
    usage = load_yaml(POLICY_ROOT / "usage-policy.yaml")
    polyglot = load_yaml(POLICY_ROOT / "polyglot-policy.yaml")

    if "USAGE_POLICY" not in usage:
        errors.append("usage-policy.yaml missing top-level key: USAGE_POLICY")
    if "POLYGLOT_POLICY" not in polyglot:
        errors.append("polyglot-policy.yaml missing top-level key: POLYGLOT_POLICY")

    for relative in (
        "languages/bash-policy.yaml",
        "languages/powershell-policy.yaml",
        "languages/sql-policy.yaml",
        "languages/jvm-policy.yaml",
        "languages/dotnet-policy.yaml",
    ):
        if not (POLICY_ROOT / relative).exists():
            errors.append(f"Missing language policy file: coding-policies/{relative}")


def iter_shell_files() -> Iterable[Path]:
    files = git_ls_files(
        "*.sh",
        ":(exclude).scratch/*/artefacts/**",
        ":(exclude).scratch/*/artifacts/**",
    )
    for rel in files:
        yield REPO_ROOT / rel


def validate_bash_policy(errors: list[str]) -> None:
    for path in iter_shell_files():
        if not path.exists():
            # Local simulation can run in a dirty tree where tracked files were deleted.
            continue
        lines = path.read_text(encoding="utf-8").splitlines()
        for idx, line in enumerate(lines, start=1):
            stripped = line.strip()
            if not stripped or stripped.startswith("#"):
                continue

            if re.search(r"^\s*set\s+-[^\n]*[eu]", line):
                errors.append(
                    f"{path.relative_to(REPO_ROOT)}:{idx}: "
                    "bash-policy no_global_strict_mode violated "
                    "(use explicit rc handling instead of blanket strict mode)"
                )

            if re.search(r"for\s+\w+\s+in\s+\$\(\s*ls\b", line):
                errors.append(
                    f"{path.relative_to(REPO_ROOT)}:{idx}: "
                    "bash-policy no_ls_parsing_loop violated"
                )

            if "`" in line:
                errors.append(
                    f"{path.relative_to(REPO_ROOT)}:{idx}: "
                    "bash-policy no_backticks violated"
                )


def validate_workflow_bash_policy(errors: list[str]) -> None:
    for rel in git_ls_files(".github/workflows/*.yml", ".github/workflows/*.yaml"):
        path = REPO_ROOT / rel
        if not path.exists():
            continue
        lines = path.read_text(encoding="utf-8").splitlines()
        for idx, line in enumerate(lines, start=1):
            if re.search(r"^\s*set\s+-[^\n]*[eu]", line):
                errors.append(
                    f"{path.relative_to(REPO_ROOT)}:{idx}: "
                    "bash-policy no_global_strict_mode violated in workflow run block "
                    "(use explicit rc handling instead of blanket strict mode)"
                )
            if "| tee " in line:
                lookback_start = max(0, idx - 6)
                lookahead_end = min(len(lines), idx + 6)
                before = lines[lookback_start:idx]
                after = lines[idx:lookahead_end]
                has_set_plus_e = any(
                    re.search(r"^\s*set\s+\+e\b", line_text) for line_text in before
                )
                has_pipe_status_check = any(
                    "PIPESTATUS[" in line_text for line_text in after
                )
                if not has_set_plus_e:
                    errors.append(
                        f"{path.relative_to(REPO_ROOT)}:{idx}: "
                        "bash-policy robust_failure_handling violated "
                        "(missing set +e guard before tee pipeline)"
                    )
                if not has_pipe_status_check:
                    errors.append(
                        f"{path.relative_to(REPO_ROOT)}:{idx}: "
                        "bash-policy robust_failure_handling violated "
                        "(missing PIPESTATUS check after tee pipeline)"
                    )


def write_report(errors: list[str]) -> None:
    REPORTS_DIR.mkdir(exist_ok=True)
    report = REPORTS_DIR / "coding-policy-check.txt"
    lines = ["coding policy check"]
    if errors:
        lines.append("status: failed")
        lines.extend(errors)
    else:
        lines.append("status: passed")
        lines.append("validated policy pack and bash policy constraints")
    report.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    errors: list[str] = []
    try:
        validate_policy_pack(errors)
        validate_bash_policy(errors)
        validate_workflow_bash_policy(errors)
    except Exception as exc:  # explicit failure path for CI visibility
        errors.append(str(exc))

    write_report(errors)
    if errors:
        for err in errors:
            print(err)
        return 1

    print("coding policy checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
