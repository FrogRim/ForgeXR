from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
SCANNER = ROOT / "scripts" / "scan_pre_real_log_claim_boundaries.py"


def run_scanner(*paths: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(SCANNER), *(str(path) for path in paths), "--json"],
        cwd=ROOT,
        check=False,
        text=True,
        capture_output=True,
    )


def test_scanner_fails_when_positive_real_robot_success_is_present(tmp_path: Path) -> None:
    claim_file = tmp_path / "positive.md"
    claim_file.write_text("real robot success\n", encoding="utf-8")

    result = run_scanner(tmp_path)

    assert result.returncode == 1
    payload = json.loads(result.stdout)
    assert payload["ok"] is False
    assert payload["issue_count"] == 1
    assert payload["issues"][0]["rule"] == "positive_forbidden_phrase"


def test_scanner_fails_for_python_claim_when_directory_is_scanned(tmp_path: Path) -> None:
    claim_file = tmp_path / "claim.py"
    claim_file.write_text('CLAIM = "real robot success"\n', encoding="utf-8")

    result = run_scanner(tmp_path)

    assert result.returncode == 1
    payload = json.loads(result.stdout)
    assert payload["issues"][0]["path"] == "claim.py"
    assert payload["issues"][0]["match"] == "real robot success"


def test_scanner_fails_for_python_claim_when_file_is_scanned_directly(tmp_path: Path) -> None:
    claim_file = tmp_path / "claim.py"
    claim_file.write_text('CLAIM = "real robot success"\n', encoding="utf-8")

    result = run_scanner(claim_file)

    assert result.returncode == 1
    payload = json.loads(result.stdout)
    assert payload["issues"][0]["path"] == "claim.py"
    assert payload["issues"][0]["match"] == "real robot success"


def test_scanner_fails_when_negated_clause_pivots_to_positive_claim(tmp_path: Path) -> None:
    claim_file = tmp_path / "contrast.md"
    claim_file.write_text("RDF does not claim hardware readiness, but real robot success is proven.\n", encoding="utf-8")

    result = run_scanner(tmp_path)

    assert result.returncode == 1
    payload = json.loads(result.stdout)
    assert payload["ok"] is False
    assert payload["issues"][0]["match"] == "real robot success"


def test_scanner_fails_when_limited_claim_is_followed_by_separate_positive_claim(tmp_path: Path) -> None:
    claim_file = tmp_path / "separate.md"
    claim_file.write_text("Do not claim hardware readiness.\n\nreal robot success is proven.\n", encoding="utf-8")

    result = run_scanner(tmp_path)

    assert result.returncode == 1
    payload = json.loads(result.stdout)
    assert payload["issues"][0]["match"] == "real robot success"


def test_scanner_fails_when_same_line_negated_sentence_precedes_positive_claim(tmp_path: Path) -> None:
    claim_file = tmp_path / "same_line_sentence_boundary.md"
    claim_file.write_text("Do not claim hardware readiness. real robot success is proven.\n", encoding="utf-8")

    result = run_scanner(tmp_path)

    assert result.returncode == 1
    payload = json.loads(result.stdout)
    assert payload["issues"][0]["match"] == "real robot success"


def test_scanner_fails_when_positive_claim_precedes_unrelated_limiter(tmp_path: Path) -> None:
    claim_file = tmp_path / "positive_then_limiter.md"
    claim_file.write_text(
        "real robot success is proven. This is not production readiness.\n",
        encoding="utf-8",
    )

    result = run_scanner(tmp_path)

    assert result.returncode == 1
    payload = json.loads(result.stdout)
    assert payload["issues"][0]["match"] == "real robot success"


def test_scanner_allows_negated_and_limited_claims(tmp_path: Path) -> None:
    claim_file = tmp_path / "limited.md"
    claim_file.write_text(
        "\n".join(
            [
                "No real robot success claim is opened here.",
                "This is not production readiness evidence.",
                "The UR RTDE request template is metadata-only and not live UR/RTDE support.",
            ]
        ),
        encoding="utf-8",
    )

    result = run_scanner(tmp_path)

    assert result.returncode == 0
    payload = json.loads(result.stdout)
    assert payload["ok"] is True
    assert payload["issue_count"] == 0


def test_scanner_allows_forbidden_claim_list_and_not_yet_evaluated_boundary(tmp_path: Path) -> None:
    claim_file = tmp_path / "boundary.md"
    claim_file.write_text(
        "\n".join(
            [
                "Forbidden claims:",
                "real robot success",
                "hardware readiness",
                "not yet evaluated real robot data",
            ]
        ),
        encoding="utf-8",
    )

    result = run_scanner(tmp_path)

    assert result.returncode == 0
    payload = json.loads(result.stdout)
    assert payload["ok"] is True


def test_scanner_fails_when_structured_forbidden_key_is_positive(tmp_path: Path) -> None:
    claim_file = tmp_path / "claims.json"
    claim_file.write_text(json.dumps({"non_claims": {"hardware_readiness": True}}), encoding="utf-8")

    result = run_scanner(tmp_path)

    assert result.returncode == 1
    payload = json.loads(result.stdout)
    assert payload["issues"][0]["rule"] == "positive_forbidden_key"


def test_scanner_fails_when_valid_json_string_value_contains_positive_claim(tmp_path: Path) -> None:
    claim_file = tmp_path / "claims.json"
    claim_file.write_text(json.dumps({"claim": "real robot success is proven"}), encoding="utf-8")

    result = run_scanner(tmp_path)

    assert result.returncode == 1
    payload = json.loads(result.stdout)
    assert payload["issues"][0]["rule"] == "positive_forbidden_phrase"
    assert payload["issues"][0]["match"] == "real robot success"


def test_scanner_fails_when_valid_jsonl_string_value_contains_positive_claim(tmp_path: Path) -> None:
    claim_file = tmp_path / "claims.jsonl"
    claim_file.write_text(
        json.dumps({"ok": False}) + "\n" + json.dumps({"claim": "real robot success is proven"}) + "\n",
        encoding="utf-8",
    )

    result = run_scanner(tmp_path)

    assert result.returncode == 1
    payload = json.loads(result.stdout)
    assert payload["issues"][0]["rule"] == "positive_forbidden_phrase"
    assert payload["issues"][0]["match"] == "real robot success"


def test_scanner_allows_valid_structured_negated_string_values(tmp_path: Path) -> None:
    json_file = tmp_path / "claims.json"
    json_file.write_text(
        json.dumps({"claim": "No real robot success claim is opened here."}),
        encoding="utf-8",
    )
    jsonl_file = tmp_path / "claims.jsonl"
    jsonl_file.write_text(
        json.dumps({"claim": "This is not production readiness evidence."}) + "\n",
        encoding="utf-8",
    )

    result = run_scanner(tmp_path)

    assert result.returncode == 0
    payload = json.loads(result.stdout)
    assert payload["ok"] is True


def test_scanner_fails_when_malformed_json_contains_positive_claim(tmp_path: Path) -> None:
    claim_file = tmp_path / "claims.json"
    claim_file.write_text('{"claim": "real robot success is proven"\n', encoding="utf-8")

    result = run_scanner(tmp_path)

    assert result.returncode == 1
    payload = json.loads(result.stdout)
    assert payload["issues"][0]["rule"] == "positive_forbidden_phrase"
    assert payload["issues"][0]["match"] == "real robot success"


def test_scanner_fails_when_malformed_jsonl_contains_positive_claim(tmp_path: Path) -> None:
    claim_file = tmp_path / "claims.jsonl"
    claim_file.write_text('{"ok": false}\n{"claim": "real robot success is proven"\n', encoding="utf-8")

    result = run_scanner(tmp_path)

    assert result.returncode == 1
    payload = json.loads(result.stdout)
    assert payload["issues"][0]["rule"] == "positive_forbidden_phrase"
    assert payload["issues"][0]["match"] == "real robot success"
