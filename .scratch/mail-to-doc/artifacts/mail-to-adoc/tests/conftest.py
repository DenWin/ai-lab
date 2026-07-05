from __future__ import annotations

import importlib.util
import sys
import types
from pathlib import Path
from typing import Callable

import pytest

SCRIPT_PATH = Path(__file__).resolve().parent.parent / "scripts" / "mail_to_adoc.py"


@pytest.fixture
def converter(monkeypatch, tmp_path):
    """Load the converter module with a stubbed extract_msg dependency."""
    if "extract_msg" not in sys.modules:
        extract_msg_stub = types.ModuleType("extract_msg")

        def _open_msg_stub(*_args, **_kwargs):
            return (_ for _ in ()).throw(
                NotImplementedError("extract_msg is not available in tests")
            )

        open_msg: Callable[..., object] = _open_msg_stub
        setattr(extract_msg_stub, "openMsg", open_msg)
        sys.modules["extract_msg"] = extract_msg_stub

    spec = importlib.util.spec_from_file_location("mail_to_adoc", SCRIPT_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Unable to load converter module from {SCRIPT_PATH}")

    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    monkeypatch.setattr(module, "_PROJECT_ROOT", tmp_path)
    return module
