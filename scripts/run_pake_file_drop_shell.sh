#!/usr/bin/env bash
set -euo pipefail

url="http://127.0.0.1:3000/file-drop"
app_name="RDF File Drop Evaluator"
width="1280"
height="860"
min_width="1040"
min_height="720"
smoke="0"

usage() {
  cat <<'USAGE'
Usage: scripts/run_pake_file_drop_shell.sh [--url URL] [--smoke]

Wrap the local RDF file-drop evaluator page with Pake.

Options:
  --url URL    Local evaluator URL. Must be http://127.0.0.1:<port> or http://localhost:<port>, with port 1..65535.
  --smoke      Print the exact Pake command without launching npx.
USAGE
}

is_local_pake_url() {
  python3 - "$1" 2>/dev/null <<'PY'
import sys
from urllib.parse import urlsplit

raw_url = sys.argv[1]

try:
    parsed = urlsplit(raw_url)
    port = parsed.port
except ValueError:
    sys.exit(1)

if parsed.scheme != "http":
    sys.exit(1)
if parsed.hostname not in {"127.0.0.1", "localhost"}:
    sys.exit(1)
if parsed.username is not None or parsed.password is not None:
    sys.exit(1)
if port is None or port < 1:
    sys.exit(1)
PY
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --url)
      url="${2:?missing value for --url}"
      shift 2
      ;;
    --smoke)
      smoke="1"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      printf 'Unsupported argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if ! is_local_pake_url "$url"; then
  printf 'Refusing non-local Pake URL: %s\n' "$url" >&2
  exit 2
fi

command=(
  npx
  pake-cli
  "$url"
  --name "$app_name"
  --width "$width"
  --height "$height"
  --min-width "$min_width"
  --min-height "$min_height"
)

if [[ "$smoke" == "1" ]]; then
  printf 'Pake smoke command:'
  printf ' %q' "${command[@]}"
  printf '\n'
  exit 0
fi

exec "${command[@]}"
