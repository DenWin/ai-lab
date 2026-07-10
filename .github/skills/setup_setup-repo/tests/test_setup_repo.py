from __future__ import annotations

import shutil
import subprocess
from pathlib import Path

import pytest

SCRIPT_PATH = (
    Path(__file__).resolve().parent.parent / "scripts" / "Invoke-SetupRepo.ps1"
)


def _pwsh_executable() -> str:
    pwsh = shutil.which("pwsh")
    if pwsh:
        return pwsh
    pytest.skip("pwsh is required for setup-repo tests")


def _run_setup_repo(repo_root: Path, *args: str) -> subprocess.CompletedProcess[str]:
    command = [
        _pwsh_executable(),
        "-NoProfile",
        "-File",
        str(SCRIPT_PATH),
        "-RepoRoot",
        str(repo_root),
        *args,
    ]
    return subprocess.run(
        command,
        cwd=repo_root,
        check=False,
        text=True,
        capture_output=True,
    )


def _write_minimal_skill(repo_root: Path, group: str, name: str) -> Path:
    skill_dir = repo_root / "ai-artifacts" / "skills" / "shared" / group / name
    skill_dir.mkdir(parents=True, exist_ok=True)
    (skill_dir / "SKILL.md").write_text(
        """---
name: \"setup-repo\"
description: \"Bootstrap repo\"
version: \"1.0.0\"
---

# Setup Repo

Body.
""",
        encoding="utf-8",
    )
    return skill_dir


def _init_git_repo(path: Path) -> None:
    git = shutil.which("git")
    if not git:
        pytest.skip("git is required for hook setup test")
    subprocess.run([git, "init"], cwd=path, check=True, capture_output=True, text=True)


def test_codex_mirror_uses_group_underscore_name(tmp_path: Path) -> None:
    _write_minimal_skill(tmp_path, "setup", "setup-repo")

    result = _run_setup_repo(tmp_path, "-Target", "Codex", "-SkipHooks")

    assert result.returncode == 0, result.stderr
    mirror_root = tmp_path / ".agents" / "skills"
    assert (mirror_root / "setup_setup-repo" / "SKILL.md").exists()
    assert not (mirror_root / "setup-setup-repo").exists()


def test_copilot_mirror_uses_group_underscore_name(tmp_path: Path) -> None:
    _write_minimal_skill(tmp_path, "setup", "setup-repo")

    result = _run_setup_repo(tmp_path, "-Target", "Copilot", "-SkipHooks")

    assert result.returncode == 0, result.stderr
    mirror_root = tmp_path / ".github" / "skills"
    assert (mirror_root / "setup_setup-repo" / "SKILL.md").exists()
    assert not (mirror_root / "setup-setup-repo").exists()


def test_if_missing_preserves_existing_codex_skill_file(tmp_path: Path) -> None:
    _write_minimal_skill(tmp_path, "setup", "setup-repo")

    first = _run_setup_repo(tmp_path, "-Target", "Codex", "-SkipHooks")
    assert first.returncode == 0, first.stderr

    target_skill = tmp_path / ".agents" / "skills" / "setup_setup-repo" / "SKILL.md"
    target_skill.write_text("sentinel", encoding="utf-8")

    second = _run_setup_repo(tmp_path, "-Target", "Codex", "-SkipHooks", "-IfMissing")

    assert second.returncode == 0, second.stderr
    assert target_skill.read_text(encoding="utf-8") == "sentinel"


def test_hook_setup_configures_git_hooks_path(tmp_path: Path) -> None:
    _write_minimal_skill(tmp_path, "setup", "setup-repo")
    _init_git_repo(tmp_path)

    hooks_dir = tmp_path / ".githooks"
    hooks_dir.mkdir(parents=True, exist_ok=True)
    (hooks_dir / "pre-commit").write_text(
        "#!/usr/bin/env sh\r\necho ok\r\n", encoding="utf-8"
    )

    result = _run_setup_repo(tmp_path, "-SkipSkillSync")

    assert result.returncode == 0, result.stderr
    git = shutil.which("git")
    config = subprocess.run(
        [git, "config", "core.hooksPath"],
        cwd=tmp_path,
        check=True,
        text=True,
        capture_output=True,
    )
    assert config.stdout.strip() == ".githooks"
