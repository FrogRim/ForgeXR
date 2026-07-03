from __future__ import annotations

import subprocess
from pathlib import Path
from typing import Final

import pytest


REPO_ROOT: Final = Path(__file__).resolve().parents[3]
SCRIPT: Final = REPO_ROOT / "scripts" / "run_pake_file_drop_shell.sh"


def run_shell(url: str) -> subprocess.CompletedProcess[str]:
    command = ["bash", str(SCRIPT), "--url", url, "--smoke"]
    return subprocess.run(command, check=False, capture_output=True, text=True)


@pytest.mark.parametrize(
    "url",
    [
        "http://127.0.0.1:3000/file-drop",
        "http://localhost:3000/file-drop",
    ],
)
def test_pake_file_drop_shell_accepts_explicit_local_http_urls(url: str) -> None:
    result = run_shell(url)

    assert result.returncode == 0
    assert "Pake smoke command:" in result.stdout
    assert url in result.stdout
    assert result.stderr == ""


@pytest.mark.parametrize(
    "url",
    [
        "http://127.0.0.1:3000@evil.example/file-drop",
        "http://localhost:3000@evil.example/file-drop",
        "http://evil.example:3000/file-drop",
        "https://127.0.0.1:3000/file-drop",
        "http://127.0.0.1/file-drop",
        "http://127.0.0.1:abc/file-drop",
        "http://127.0.0.1:0/file-drop",
        "not a url",
    ],
)
def test_pake_file_drop_shell_rejects_non_local_or_malformed_urls(url: str) -> None:
    result = run_shell(url)

    assert result.returncode != 0
    assert result.stdout == ""
    assert result.stderr == f"Refusing non-local Pake URL: {url}\n"
