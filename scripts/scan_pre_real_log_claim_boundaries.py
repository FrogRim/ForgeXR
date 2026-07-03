#!/usr/bin/env python3
# noqa: SIZE_OK - single-purpose CLI scanner; phrase/key tables plus bounded context rules stay auditable together.
from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass
import json
from pathlib import Path
import re

JsonValue = None | bool | int | float | str | list["JsonValue"] | dict[str, "JsonValue"]
TEXT_SUFFIXES = {".html", ".md", ".mdx", ".py", ".txt", ".ts", ".tsx"}
STRUCTURED_SUFFIXES = {".json", ".jsonl"}
SKIP_DIRS = {".git", ".mypy_cache", ".next", ".pytest_cache", ".ruff_cache", ".venv", "__pycache__", "node_modules"}
SKIP_PATH_PARTS = {
    ("docs", "archive"),
    ("docs", "buyer"),
    ("docs", "experiments"),
    ("docs", "proof"),
    ("docs", "superpowers"),
}
SKIP_PATHS = {
    ("docs", "developer", "data_schema.md"),
    ("docs", "developer", "debugging_guide.md"),
    ("docs", "developer", "reference_mapping.md"),
    ("docs", "developer", "worklog.md"),
}
POSITIVE_VALUES = {"1", "closed", "enabled", "evaluated", "proven", "ready", "supported", "true", "validated", "yes"}
FORBIDDEN_PHRASES = (
    "deployable policy readiness",
    "external partner data evaluated",
    "general robot intelligence",
    "hardware readiness",
    "hardware validated",
    "live franka support",
    "live franka hardware support",
    "live hardware support",
    "live ros2 bridge readiness",
    "live ros2 dds bridge readiness",
    "live ur rtde support",
    "live ur/rtde support",
    "live ur support",
    "marketplace readiness",
    "physical robot readiness",
    "policy uplift",
    "production certification",
    "production ready",
    "production readiness",
    "real robot data evaluated",
    "real robot ready",
    "real robot success",
    "sim to real proven",
    "sim-to-real proven",
    "visual policy performance",
)
CONTEXT_REQUIRED_PHRASES = {
    "deployable policy readiness",
    "general robot intelligence",
    "policy uplift",
    "sim to real proven",
    "sim-to-real proven",
    "visual policy performance",
}
FORBIDDEN_KEYS = {
    phrase.replace("/", " ").replace("-", " ").replace(" ", "_") for phrase in FORBIDDEN_PHRASES
} | {"hmd_openxr_readiness"}
POSITIVE_CONTEXT_RE = re.compile(
    r"\b(claims?|claimed|completed|enabled|evaluated|guarantees?|has|opened|passed|proven|ready|"
    r"readiness|supported|supports?|validated|verified)\b"
)
NEGATION_RE = re.compile(r"\b(no|not|never|without|does not|do not|is not|are not|isn't|aren't|must not)\b")
LIMITING_CONTEXT_RE = re.compile(
    r"(boundary|cannot|can't|does not|do not|doesn't|experimental|future|instead of claimed|"
    r"limitation|limited|metadata only|metadata-only|must not|no|non-claims?|not|not allowed|not opened|not proven|"
    r"out of scope|post-mvp|request template|roadmap|scope out|separated|stays inside the evidence|unopened|without|"
    r"아니다|않는다|"
    r"않음|없다|금지|넘긴다|미주장|보류|아직|제외|허용되지|주장하지 않는다|claim하지 않는다)"
)
LIMITED_BLOCK_RE = re.compile(
    r"(forbidden claims?|non-claims?|not allowed|허용되지|claim하지 않는다|주장하지 않는다|"
    r"자동 claim하지 않는다|주장하지 않는다)"
)
LIMITED_PYTHON_BLOCK_RE = re.compile(
    r"\b[A-Z0-9_]*(BOUNDARY|CONTEXT_REQUIRED|DISCLAIM|FORBIDDEN|LIMITATION|NON_CLAIM)[A-Z0-9_]*\b"
)
CONTRAST_RE = re.compile(r"\b(but|however|yet|nevertheless|nonetheless|although|though)\b")
CLAUSE_BOUNDARIES = ".!?\n"


@dataclass(frozen=True, slots=True)
class ClaimIssue:
    path: str
    rule: str
    match: str
    line: int


def key_forms(key: str) -> tuple[str, ...]:
    return (key, key.replace("_", " "), key.replace("_", "-"))


def is_positive_value(value: JsonValue) -> bool:
    if isinstance(value, bool):
        return value
    if isinstance(value, int | float) and not isinstance(value, bool):
        return value != 0
    if isinstance(value, str):
        return value.strip().lower() in POSITIVE_VALUES
    return False


def normalize_text(text: str) -> str:
    return re.sub(r"\s+", " ", text.lower().replace("_", " "))


def looks_negated(text: str, start: int) -> bool:
    prefix = text[max(0, start - 160) : start]
    boundary = max(prefix.rfind(boundary) for boundary in CLAUSE_BOUNDARIES)
    if boundary >= 0:
        prefix = prefix[boundary + 1 :]
    negations = list(NEGATION_RE.finditer(prefix))
    if not negations:
        return False
    return CONTRAST_RE.search(prefix[negations[-1].end() :]) is None


def has_limited_context(text: str, start: int) -> bool:
    prefix = text[max(0, start - 220) : start]
    limits = list(LIMITING_CONTEXT_RE.finditer(prefix))
    if not limits:
        return False
    between = prefix[limits[-1].end() :]
    return re.search(r"[.!?]", between) is None and CONTRAST_RE.search(between) is None


def bounded_line_context(lines: list[str], line_index: int) -> str:
    start = line_index
    while start > 0 and lines[start - 1].strip() and not normalize_text(lines[start - 1]).endswith((".", "!", "?")):
        start -= 1
    end = line_index + 1
    while end < len(lines) and lines[end - 1].strip() and not normalize_text(lines[end - 1]).endswith((".", "!", "?")):
        if not lines[end].strip():
            break
        end += 1
    return normalize_text(" ".join(lines[start:end]))


def context_limits_phrase(context: str, phrase: str) -> bool:
    normalized = normalize_text(phrase)
    for match in re.finditer(rf"\b{re.escape(normalized)}\b", context):
        limits = list(LIMITING_CONTEXT_RE.finditer(context[: match.start()]))
        between_prefix = context[limits[-1].end() : match.start()] if limits else ""
        if limits and not re.search(r"[.!?]", between_prefix) and CONTRAST_RE.search(between_prefix) is None:
            return True
        next_limit = LIMITING_CONTEXT_RE.search(context[match.end() :])
        between = context[match.end() : match.end() + next_limit.start()] if next_limit else ""
        if next_limit and not re.search(r"[.!?]", between) and CONTRAST_RE.search(between) is None:
            return True
    return False


def has_positive_context(text: str, start: int, end: int) -> bool:
    context = text[max(0, start - 80) : min(len(text), end + 80)]
    if POSITIVE_CONTEXT_RE.search(context):
        return True
    return re.search(r"\bis\s+(true|validated|proven|ready|supported|enabled|closed)\b", context) is not None


def scan_text_file(path: Path, root: Path) -> list[ClaimIssue]:
    raw_text = path.read_text(encoding="utf-8", errors="ignore")
    relative = path.relative_to(root).as_posix()
    issues: list[ClaimIssue] = []
    lines = raw_text.splitlines()
    limited_code_block = False
    limited_plain_block = False
    limited_python_block = False
    for line_index, line in enumerate(lines):
        stripped = line.strip()
        if not stripped:
            limited_plain_block = False
            continue
        if path.suffix.lower() == ".py":
            if opens_limited_python_block(stripped):
                limited_python_block = True
                continue
            if limited_python_block and stripped.startswith(("}", ")")):
                limited_python_block = False
                continue
        if stripped.startswith(("cd ", "git ", "rg ", "uv run ", "# status=")):
            continue
        if stripped.startswith("```"):
            if not limited_code_block and previous_lines_open_limited_block(lines, line_index):
                limited_code_block = True
            elif limited_code_block:
                limited_code_block = False
            continue
        text = normalize_text(line)
        bounded_context = bounded_line_context(lines, line_index)
        if text.endswith(":") and LIMITED_BLOCK_RE.search(text):
            limited_plain_block = True
            continue
        list_limited = (
            limited_code_block
            or limited_plain_block
                    or limited_python_block
                    or (path.suffix.lower() == ".py" and python_line_is_false_flag(stripped))
                )
        for phrase in FORBIDDEN_PHRASES:
            normalized = normalize_text(phrase)
            for match in re.finditer(rf"\b{re.escape(normalized)}\b", text):
                limited = (
                    list_limited
                    or looks_negated(text, match.start())
                    or has_limited_context(text, match.start())
                    or context_limits_phrase(bounded_context, phrase)
                )
                positive = phrase not in CONTEXT_REQUIRED_PHRASES or has_positive_context(
                    text, match.start(), match.end()
                )
                identifier_only = path.suffix.lower() == ".py" and python_identifier_mentions_phrase(stripped, phrase)
                guard_check = identifier_only and python_guard_checks_claim_flag(stripped)
                if limited or not positive or guard_check or (phrase in CONTEXT_REQUIRED_PHRASES and identifier_only):
                    continue
                issues.append(
                    ClaimIssue(
                        path=relative,
                        rule="positive_forbidden_phrase",
                        match=phrase,
                        line=line_index + 1,
                    )
                )
    return issues


def previous_lines_open_limited_block(lines: list[str], line_index: int) -> bool:
    for previous in reversed(lines[max(0, line_index - 4) : line_index]):
        normalized = normalize_text(previous)
        if not normalized:
            continue
        return LIMITED_BLOCK_RE.search(normalized) is not None
    return False


def opens_limited_python_block(stripped: str) -> bool:
    return LIMITED_PYTHON_BLOCK_RE.search(stripped) is not None and stripped.endswith(("{", "("))


def python_line_is_false_flag(stripped: str) -> bool:
    return re.search(r"[:=]\s*False\b", stripped) is not None


def python_identifier_mentions_phrase(stripped: str, phrase: str) -> bool:
    lowered = stripped.lower()
    raw_phrase = phrase.lower()
    identifier = phrase.replace("/", " ").replace("-", " ").replace(" ", "_").lower()
    return raw_phrase not in lowered and identifier in lowered


def python_guard_checks_claim_flag(stripped: str) -> bool:
    return stripped.startswith("if ") and re.search(r"\b(is|==)\s+True\b", stripped) is not None


def scan_structured_value(value: JsonValue, path: Path, root: Path, line: int = 1) -> list[ClaimIssue]:
    relative = path.relative_to(root).as_posix()
    issues: list[ClaimIssue] = []
    if isinstance(value, dict):
        for key, item in value.items():
            lowered_key = str(key).strip().lower()
            for forbidden_key in FORBIDDEN_KEYS:
                if lowered_key in key_forms(forbidden_key) and is_positive_value(item):
                    issues.append(
                        ClaimIssue(path=relative, rule="positive_forbidden_key", match=forbidden_key, line=line)
                    )
            issues.extend(scan_structured_value(item, path, root, line))
    elif isinstance(value, list):
        for item in value:
            issues.extend(scan_structured_value(item, path, root, line))
    elif isinstance(value, str):
        issues.extend(scan_malformed_structured_text(path, root, value, line - 1))
    return issues


def scan_malformed_structured_text(path: Path, root: Path, raw_text: str, line_offset: int = 0) -> list[ClaimIssue]:
    relative = path.relative_to(root).as_posix()
    issues: list[ClaimIssue] = []
    for line_index, line in enumerate(raw_text.splitlines()):
        text = normalize_text(line)
        for phrase in FORBIDDEN_PHRASES:
            normalized = normalize_text(phrase)
            for match in re.finditer(rf"\b{re.escape(normalized)}\b", text):
                if looks_negated(text, match.start()) or has_limited_context(text, match.start()):
                    continue
                positive = phrase not in CONTEXT_REQUIRED_PHRASES or has_positive_context(
                    text, match.start(), match.end()
                )
                if positive:
                    issues.append(
                        ClaimIssue(
                            path=relative,
                            rule="positive_forbidden_phrase",
                            match=phrase,
                            line=line_offset + line_index + 1,
                        )
                    )
    return issues


def scan_structured_file(path: Path, root: Path) -> list[ClaimIssue]:
    if path.suffix.lower() == ".json":
        raw_text = path.read_text(encoding="utf-8", errors="ignore")
        try:
            return scan_structured_value(json.loads(raw_text), path, root)
        except json.JSONDecodeError:
            return scan_malformed_structured_text(path, root, raw_text)
    issues: list[ClaimIssue] = []
    for line_number, line in enumerate(path.read_text(encoding="utf-8", errors="ignore").splitlines(), start=1):
        if not line.strip():
            continue
        try:
            issues.extend(scan_structured_value(json.loads(line), path, root, line_number))
        except json.JSONDecodeError:
            issues.extend(scan_malformed_structured_text(path, root, line, line_number - 1))
    return issues


def iter_scannable_files(paths: list[Path]) -> list[Path]:
    files: list[Path] = []
    for input_path in paths:
        if input_path.is_file():
            files.append(input_path)
            continue
        for path in sorted(input_path.rglob("*")):
            if not path.is_file() or any(part in SKIP_DIRS for part in path.parts) or is_skipped_path(path):
                continue
            if path.suffix.lower() in TEXT_SUFFIXES | STRUCTURED_SUFFIXES:
                files.append(path)
    return sorted(set(files))


def is_skipped_path(path: Path) -> bool:
    parts = path.parts
    for skip_path in SKIP_PATHS:
        for index in range(len(parts) - len(skip_path) + 1):
            if tuple(parts[index : index + len(skip_path)]) == skip_path:
                return True
    for skip_parts in SKIP_PATH_PARTS:
        for index in range(len(parts) - len(skip_parts) + 1):
            if tuple(parts[index : index + len(skip_parts)]) == skip_parts:
                return True
    return False


def scan(paths: list[Path], root: Path) -> tuple[list[ClaimIssue], list[str]]:
    issues: list[ClaimIssue] = []
    scanned_paths: list[str] = []
    for path in iter_scannable_files(paths):
        scanned_paths.append(path.relative_to(root).as_posix() if path.is_relative_to(root) else path.as_posix())
        suffix = path.suffix.lower()
        if suffix in TEXT_SUFFIXES:
            issues.extend(scan_text_file(path, root if path.is_relative_to(root) else path.parent))
        elif suffix in STRUCTURED_SUFFIXES:
            issues.extend(scan_structured_file(path, root if path.is_relative_to(root) else path.parent))
    return issues, scanned_paths


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Scan repo text for positive pre-real-log forbidden claims.")
    parser.add_argument("paths", nargs="+", type=Path)
    parser.add_argument("--json", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    root = Path.cwd().resolve()
    paths = [path.resolve() for path in args.paths]
    issues, scanned_paths = scan(paths, root)
    payload = {
        "schema_version": "rdf_pre_real_log_claim_boundary_scan_v0.1.0",
        "ok": not issues,
        "issue_count": len(issues),
        "scanned_file_count": len(scanned_paths),
        "scanned_paths": scanned_paths,
        "rules": {
            "forbidden_key_count": len(FORBIDDEN_KEYS),
            "forbidden_phrase_count": len(FORBIDDEN_PHRASES),
            "negation_aware": True,
            "contrast_pivot_aware": True,
        },
        "issues": [asdict(issue) for issue in issues],
    }
    if args.json:
        print(json.dumps(payload, ensure_ascii=False, sort_keys=True, indent=2))
    else:
        print("pre_real_log_claim_boundary_scan=PASS" if payload["ok"] else "pre_real_log_claim_boundary_scan=FAIL")
        for issue in issues[:12]:
            print(f"{issue.path}:{issue.line}: {issue.rule}: {issue.match}")
    return 0 if payload["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
