from __future__ import annotations

import os
import shutil
import subprocess
from pathlib import Path

import pytest

SCRIPT_PATH = (
    Path(__file__).resolve().parent.parent
    / "scripts"
    / "Invoke-LocalWorkflowSimulation.ps1"
)


def _pwsh_executable() -> str:
    pwsh = shutil.which("pwsh")
    if pwsh:
        return pwsh
    pytest.skip("pwsh is required for simulate-workflows tests")


def _write_cmd(path: Path, body: str) -> None:
    path.write_text(body, encoding="utf-8")


def _prepare_fake_toolchain(tmp_path: Path, log_path: Path) -> Path:
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir(parents=True, exist_ok=True)

    _write_cmd(
        bin_dir / "python.cmd",
        "@echo off\r\n" "exit /b 0\r\n",
    )
    _write_cmd(
        bin_dir / "git.cmd",
        "@echo off\r\n" "exit /b 0\r\n",
    )

    return bin_dir


def _prepare_repo_root(tmp_path: Path) -> Path:
    repo_root = tmp_path / "repo"
    (repo_root / ".git").mkdir(parents=True, exist_ok=True)
    runner = (
        repo_root
        / ".github"
        / "workflows"
        / "scripts"
        / "execute-all-workflow-scripts.ps1"
    )
    runner.parent.mkdir(parents=True, exist_ok=True)
    runner.write_text(
        "param([string]$RepoRoot, [switch]$FullScan)\n"
        "$parts = @($PSCommandPath, '-RepoRoot', $RepoRoot)\n"
        "if ($FullScan) { $parts += '-FullScan' }\n"
        "$parts -join ' ' | Out-File -FilePath $env:SIM_LOG -Encoding utf8\n",
        encoding="utf-8",
    )
    return repo_root


def _run_simulation(
    repo_root: Path, env: dict[str, str], *args: str
) -> subprocess.CompletedProcess[str]:
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
        check=False,
        text=True,
        capture_output=True,
        env=env,
    )


def test_default_mode_invokes_workflow_runner_with_full_scan(tmp_path: Path) -> None:
    log_path = tmp_path / "pwsh.log"
    bin_dir = _prepare_fake_toolchain(tmp_path, log_path)
    repo_root = _prepare_repo_root(tmp_path)

    env = os.environ.copy()
    env["SIM_LOG"] = str(log_path)
    env["PATH"] = str(bin_dir) + os.pathsep + env.get("PATH", "")

    result = _run_simulation(repo_root, env)

    assert result.returncode == 0, result.stderr
    logged = log_path.read_text(encoding="utf-8")
    assert (
        str(
            repo_root
            / ".github"
            / "workflows"
            / "scripts"
            / "execute-all-workflow-scripts.ps1"
        )
        in logged
    )
    assert "-RepoRoot" in logged
    assert str(repo_root) in logged
    assert "-FullScan" in logged


def test_use_changed_files_omits_full_scan_flag(tmp_path: Path) -> None:
    log_path = tmp_path / "pwsh.log"
    bin_dir = _prepare_fake_toolchain(tmp_path, log_path)
    repo_root = _prepare_repo_root(tmp_path)

    env = os.environ.copy()
    env["SIM_LOG"] = str(log_path)
    env["PATH"] = str(bin_dir) + os.pathsep + env.get("PATH", "")

    result = _run_simulation(repo_root, env, "-UseChangedFiles")

    assert result.returncode == 0, result.stderr
    logged = log_path.read_text(encoding="utf-8")
    assert (
        str(
            repo_root
            / ".github"
            / "workflows"
            / "scripts"
            / "execute-all-workflow-scripts.ps1"
        )
        in logged
    )
    assert "-RepoRoot" in logged
    assert str(repo_root) in logged
    assert "-FullScan" not in logged
