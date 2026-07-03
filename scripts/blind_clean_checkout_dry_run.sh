#!/usr/bin/env bash
# allow: SIZE_OK - standalone release-gate shell script keeps G0-G8 evidence in one audited executable; split only after release gate is durable.
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage: bash scripts/blind_clean_checkout_dry_run.sh <pinned-ref> <repo-path>

Runs the pre-real-log file-drop evaluator dry run from a fresh clean checkout.
The receipt is written to .omo/evidence/pre-real-log-clean-checkout-receipt.txt
in the original repository containing this script.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -ne 2 ]]; then
  usage
  exit 64
fi

PINNED_REF="$1"
SOURCE_REPO_INPUT="$2"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ORIGINAL_REPO="$(cd "$SCRIPT_DIR/.." && pwd -P)"
SOURCE_REPO="$(cd "$SOURCE_REPO_INPUT" && pwd -P)"
RECEIPT="$ORIGINAL_REPO/.omo/evidence/pre-real-log-clean-checkout-receipt.txt"
WORK_ROOT="${RDF_BLIND_DRY_RUN_WORK_ROOT:-${TMPDIR:-/var/tmp}}"
WORK="$(mktemp -d "$WORK_ROOT/rdf_blind_dryrun.XXXXXX")"
CLONE="$WORK/checkout"
OUTPUTS="$WORK/outputs"
COMMAND_LOG="$WORK/command_transcript.log"
HOME_DIR="$WORK/home"
FAILS=0

mkdir -p "$(dirname "$RECEIPT")" "$OUTPUTS" "$HOME_DIR"
: > "$COMMAND_LOG"
: > "$RECEIPT"

UV_BIN="$(command -v uv || true)"
if [[ -z "$UV_BIN" ]]; then
  {
    echo "created_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "pinned_ref=$PINNED_REF"
    echo "source_repo_path=$SOURCE_REPO"
    echo "original_repo_path=$ORIGINAL_REPO"
    echo "FAIL G0 uv executable not found on PATH"
    echo "DRY_RUN_RESULT=FAIL"
  } | tee "$RECEIPT"
  exit 1
fi

SCRUBBED_PATH="$(dirname "$UV_BIN"):/usr/local/bin:/usr/bin:/bin"

log() {
  printf '%s\n' "$*" | tee -a "$RECEIPT"
}

gate() {
  local gate_id="$1"
  local status="$2"
  local message="$3"
  if [[ "$status" == "PASS" ]]; then
    log "PASS $gate_id $message"
  else
    log "FAIL $gate_id $message"
    FAILS=$((FAILS + 1))
  fi
}

json_value() {
  local json_path="$1"
  local dotted_key="$2"
  python3 - "$json_path" "$dotted_key" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
key = sys.argv[2]
try:
    value = json.loads(path.read_text(encoding="utf-8"))
    for part in key.split("."):
        if isinstance(value, dict):
            value = value.get(part)
        else:
            value = None
            break
    print(json.dumps(value, sort_keys=True))
except Exception:
    print("null")
PY
}

json_equals() {
  local json_path="$1"
  local dotted_key="$2"
  local expected="$3"
  [[ "$(json_value "$json_path" "$dotted_key")" == "$expected" ]]
}

run_in_clone() {
  {
    printf '$'
    printf ' %q' "$@"
    printf '\n'
  } >> "$COMMAND_LOG"
  set +e
  (
    cd "$CLONE"
    env -i \
      PATH="$SCRUBBED_PATH" \
      HOME="$HOME_DIR" \
      LANG="C.UTF-8" \
      LC_ALL="C.UTF-8" \
      UV_CACHE_DIR="$WORK/uv-cache" \
      XDG_CACHE_HOME="$WORK/xdg-cache" \
      "$@"
  ) >> "$COMMAND_LOG" 2>&1
  local rc=$?
  set -e
  echo "rc=$rc" >> "$COMMAND_LOG"
  return "$rc"
}

capture_in_clone() {
  local output_path="$1"
  shift
  {
    printf '$'
    printf ' %q' "$@"
    printf ' > %q\n' "$output_path"
  } >> "$COMMAND_LOG"
  set +e
  (
    cd "$CLONE"
    env -i \
      PATH="$SCRUBBED_PATH" \
      HOME="$HOME_DIR" \
      LANG="C.UTF-8" \
      LC_ALL="C.UTF-8" \
      UV_CACHE_DIR="$WORK/uv-cache" \
      XDG_CACHE_HOME="$WORK/xdg-cache" \
      "$@"
  ) > "$output_path" 2>> "$COMMAND_LOG"
  local rc=$?
  set -e
  echo "rc=$rc output=$output_path" >> "$COMMAND_LOG"
  return "$rc"
}

capture_shell_in_clone() {
  local output_path="$1"
  local shell_script="$2"
  echo '$ bash -c <script> > '"$output_path" >> "$COMMAND_LOG"
  set +e
  (
    cd "$CLONE"
    env -i \
      PATH="$SCRUBBED_PATH" \
      HOME="$HOME_DIR" \
      LANG="C.UTF-8" \
      LC_ALL="C.UTF-8" \
      UV_CACHE_DIR="$WORK/uv-cache" \
      XDG_CACHE_HOME="$WORK/xdg-cache" \
      bash -c "$shell_script"
  ) > "$output_path" 2>> "$COMMAND_LOG"
  local rc=$?
  set -e
  echo "rc=$rc output=$output_path" >> "$COMMAND_LOG"
  return "$rc"
}

original_status_snapshot() {
  local exclude_args=(-- . ':!.omo/evidence/pre-real-log-clean-checkout-receipt.txt')
  if [[ -n "${RDF_BLIND_DRY_RUN_ALLOWED_ORIGINAL_WRITE:-}" ]]; then
    IFS=':' read -r -a extra_allowed <<< "$RDF_BLIND_DRY_RUN_ALLOWED_ORIGINAL_WRITE"
    for rel_path in "${extra_allowed[@]}"; do
      [[ -n "$rel_path" ]] && exclude_args+=(":!$rel_path")
    done
  fi
  git -C "$ORIGINAL_REPO" status --porcelain=v1 -uall "${exclude_args[@]}" | sha256sum | awk '{print $1}'
}

record_json_path() {
  local label="$1"
  local path="$2"
  local sha
  sha="$(sha256sum "$path" | awk '{print $1}')"
  log "$label=$path sha256=$sha"
}

log "created_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
log "script_path=$SCRIPT_DIR/blind_clean_checkout_dry_run.sh"
log "pinned_ref=$PINNED_REF"
log "source_repo_path=$SOURCE_REPO"
log "original_repo_path=$ORIGINAL_REPO"
log "work_dir=$WORK"
log "clone_path=$CLONE"
log "receipt_path=$RECEIPT"
log "scrubbed_path=$SCRUBBED_PATH"
log "env_policy=env -i with PYTHONPATH and RDF_FILE_DROP_EVALUATOR_ARTIFACT_ROOT unset; UV_CACHE_DIR and XDG_CACHE_HOME under work_dir"

ORIGINAL_STATUS_BEFORE="$(original_status_snapshot)"

set +e
git clone --quiet "$SOURCE_REPO" "$CLONE" >> "$COMMAND_LOG" 2>&1
CLONE_RC=$?
set -e
if [[ "$CLONE_RC" -ne 0 ]]; then
  gate "G1-clone" "FAIL" "git clone failed rc=$CLONE_RC"
  log "DRY_RUN_RESULT=FAIL"
  log "command_transcript=$COMMAND_LOG"
  exit "$FAILS"
fi
gate "G1-clone" "PASS" "candidate cloned outside original repo"

set +e
if git -C "$CLONE" rev-parse --verify --quiet "$PINNED_REF^{commit}" >/dev/null 2>> "$COMMAND_LOG"; then
  git -C "$CLONE" checkout --quiet --detach "$PINNED_REF" >> "$COMMAND_LOG" 2>&1
  CHECKOUT_RC=$?
else
  git -C "$CLONE" fetch --quiet origin "$PINNED_REF" >> "$COMMAND_LOG" 2>&1
  FETCH_RC=$?
  if [[ "$FETCH_RC" -eq 0 ]]; then
    git -C "$CLONE" checkout --quiet --detach FETCH_HEAD >> "$COMMAND_LOG" 2>&1
    CHECKOUT_RC=$?
  else
    CHECKOUT_RC=$FETCH_RC
  fi
fi
set -e

if [[ "$CHECKOUT_RC" -ne 0 ]]; then
  gate "G0-ref" "FAIL" "candidate ref checkout failed before readiness claim rc=$CHECKOUT_RC"
  log "DRY_RUN_RESULT=FAIL"
  log "command_transcript=$COMMAND_LOG"
  exit "$FAILS"
fi

HEAD_SHA="$(git -C "$CLONE" rev-parse HEAD)"
LOCK_SHA="$(sha256sum "$CLONE/uv.lock" | awk '{print $1}')"
log "pinned_sha=$HEAD_SHA"
log "uv_lock_sha256=$LOCK_SHA"
gate "G0-ref" "PASS" "pinned ref resolved to $HEAD_SHA"

if [[ -z "$(git -C "$CLONE" status --porcelain=v1 -uall)" ]]; then
  gate "G1-clean-tree" "PASS" "clean checkout status is empty"
else
  gate "G1-clean-tree" "FAIL" "checkout has dirty status"
fi

case "$CLONE" in
  "$ORIGINAL_REPO"/*|"$ORIGINAL_REPO")
    gate "G1-path-isolation" "FAIL" "clone path is inside original repo"
    ;;
  *)
    gate "G1-path-isolation" "PASS" "clone path differs from original repo"
    ;;
esac

if run_in_clone "$UV_BIN" sync --group dev; then
  gate "G2a-uv-sync" "PASS" "uv sync --group dev"
else
  gate "G2a-uv-sync" "FAIL" "uv sync --group dev"
fi

if capture_in_clone "$OUTPUTS/import_check.txt" "$UV_BIN" run python -c 'import h5py,numpy,fastapi; print(h5py.__version__, numpy.__version__)'; then
  gate "G2b-imports" "PASS" "h5py/numpy/fastapi import through uv run output=$OUTPUTS/import_check.txt"
else
  gate "G2b-imports" "FAIL" "h5py/numpy/fastapi import through uv run output=$OUTPUTS/import_check.txt"
fi

CLI=( "$UV_BIN" run python scripts/rdf_file_drop_evaluator.py )
ACCEPT_SAMPLE="docs/partner_intake/sample_drops/ur_rtde_csv_v0/accepted_minimal"
REJECT_SAMPLE="docs/partner_intake/sample_drops/ur_rtde_csv_v0/rejected_missing_metadata"
ART_ROOT="artifacts/rdf_file_drop_evaluator/blind-clean-checkout"

if capture_in_clone "$OUTPUTS/doctor.json" "${CLI[@]}" doctor --json && json_equals "$OUTPUTS/doctor.json" ok true; then
  gate "G3-doctor" "PASS" "doctor ok output=$OUTPUTS/doctor.json"
else
  gate "G3-doctor" "FAIL" "doctor ok output=$OUTPUTS/doctor.json"
fi
record_json_path "doctor_json" "$OUTPUTS/doctor.json"

if capture_in_clone "$OUTPUTS/profiles_list.json" "${CLI[@]}" profiles list --json && json_equals "$OUTPUTS/profiles_list.json" ok true && json_equals "$OUTPUTS/profiles_list.json" profile_count 4; then
  gate "G4a-profiles-list" "PASS" "profiles list ok profile_count=4 output=$OUTPUTS/profiles_list.json"
else
  gate "G4a-profiles-list" "FAIL" "profiles list output=$OUTPUTS/profiles_list.json"
fi
record_json_path "profiles_list_json" "$OUTPUTS/profiles_list.json"

if capture_in_clone "$OUTPUTS/profiles_inspect_ur.json" "${CLI[@]}" profiles inspect ur_rtde_csv_v0 --json && json_equals "$OUTPUTS/profiles_inspect_ur.json" ok true; then
  gate "G4b-profiles-inspect" "PASS" "profiles inspect ur_rtde_csv_v0 output=$OUTPUTS/profiles_inspect_ur.json"
else
  gate "G4b-profiles-inspect" "FAIL" "profiles inspect ur_rtde_csv_v0 output=$OUTPUTS/profiles_inspect_ur.json"
fi
record_json_path "profiles_inspect_json" "$OUTPUTS/profiles_inspect_ur.json"

if capture_in_clone "$OUTPUTS/evaluate_accept.json" "${CLI[@]}" evaluate "$ACCEPT_SAMPLE" --profile ur_rtde_csv_v0 --out "$ART_ROOT/accepted" --force --json; then
  EVAL_ACCEPT_RC=0
else
  EVAL_ACCEPT_RC=$?
fi
if [[ "$EVAL_ACCEPT_RC" -eq 0 ]] && json_equals "$OUTPUTS/evaluate_accept.json" passed true; then
  gate "G5a-accepted-evaluate" "PASS" "accepted sample evaluated passed=true output=$OUTPUTS/evaluate_accept.json"
else
  gate "G5a-accepted-evaluate" "FAIL" "accepted sample evaluate rc=$EVAL_ACCEPT_RC output=$OUTPUTS/evaluate_accept.json"
fi
record_json_path "accepted_evaluate_json" "$OUTPUTS/evaluate_accept.json"

if capture_in_clone "$OUTPUTS/verify_accept.json" "${CLI[@]}" verify "$ART_ROOT/accepted" --deep-hdf5 --json; then
  VERIFY_ACCEPT_RC=0
else
  VERIFY_ACCEPT_RC=$?
fi
if [[ "$VERIFY_ACCEPT_RC" -eq 0 ]] && json_equals "$OUTPUTS/verify_accept.json" verdict '"VERIFIED"' && json_equals "$OUTPUTS/verify_accept.json" passed true; then
  gate "G5b-accepted-verify" "PASS" "accepted verifier VERIFIED passed=true output=$OUTPUTS/verify_accept.json"
else
  gate "G5b-accepted-verify" "FAIL" "accepted verifier rc=$VERIFY_ACCEPT_RC output=$OUTPUTS/verify_accept.json"
fi
record_json_path "accepted_verify_json" "$OUTPUTS/verify_accept.json"

if capture_in_clone "$OUTPUTS/evaluate_reject.json" "${CLI[@]}" evaluate "$REJECT_SAMPLE" --profile ur_rtde_csv_v0 --out "$ART_ROOT/rejected" --force --json; then
  EVAL_REJECT_RC=0
else
  EVAL_REJECT_RC=$?
fi
if [[ "$EVAL_REJECT_RC" -eq 2 ]] && json_equals "$OUTPUTS/evaluate_reject.json" passed false; then
  gate "G6a-rejected-evaluate" "PASS" "rejected sample failed closed rc=2 output=$OUTPUTS/evaluate_reject.json"
else
  gate "G6a-rejected-evaluate" "FAIL" "rejected sample rc=$EVAL_REJECT_RC output=$OUTPUTS/evaluate_reject.json"
fi
record_json_path "rejected_evaluate_json" "$OUTPUTS/evaluate_reject.json"

if [[ ! -e "$CLONE/$ART_ROOT/rejected/export" ]]; then
  gate "G6a-rejected-no-export" "PASS" "rejected run has no export directory"
else
  gate "G6a-rejected-no-export" "FAIL" "rejected run unexpectedly has export directory"
fi

if capture_in_clone "$OUTPUTS/verify_reject.json" "${CLI[@]}" verify "$ART_ROOT/rejected" --deep-hdf5 --json; then
  VERIFY_REJECT_RC=0
else
  VERIFY_REJECT_RC=$?
fi
if [[ "$VERIFY_REJECT_RC" -eq 0 ]] && json_equals "$OUTPUTS/verify_reject.json" verdict '"VERIFIED"' && json_equals "$OUTPUTS/verify_reject.json" passed false; then
  gate "G6b-rejected-verify" "PASS" "rejected verifier VERIFIED passed=false output=$OUTPUTS/verify_reject.json"
else
  gate "G6b-rejected-verify" "FAIL" "rejected verifier rc=$VERIFY_REJECT_RC output=$OUTPUTS/verify_reject.json"
fi
record_json_path "rejected_verify_json" "$OUTPUTS/verify_reject.json"

run_in_clone cp -R "$ART_ROOT/accepted" "$ART_ROOT/tampered" || true
capture_shell_in_clone "$OUTPUTS/tamper_mutation.txt" 'set -euo pipefail; first_file="$(find artifacts/rdf_file_drop_evaluator/blind-clean-checkout/tampered/source_drop -type f | sort | head -n 1)"; printf x >> "$first_file"; printf "%s\n" "$first_file"'
if capture_in_clone "$OUTPUTS/verify_tampered.json" "${CLI[@]}" verify "$ART_ROOT/tampered" --deep-hdf5 --json; then
  VERIFY_TAMPER_RC=0
else
  VERIFY_TAMPER_RC=$?
fi
if [[ "$VERIFY_TAMPER_RC" -ne 0 ]] && json_equals "$OUTPUTS/verify_tampered.json" verdict '"FAILED"'; then
  gate "G6c-tamper-reject" "PASS" "tampered accepted package rejected rc=$VERIFY_TAMPER_RC output=$OUTPUTS/verify_tampered.json"
else
  gate "G6c-tamper-reject" "FAIL" "tamper verifier rc=$VERIFY_TAMPER_RC output=$OUTPUTS/verify_tampered.json"
fi
record_json_path "tampered_verify_json" "$OUTPUTS/verify_tampered.json"

if capture_in_clone "$OUTPUTS/make_accept_zip.txt" "$UV_BIN" run python -c 'from pathlib import Path; from zipfile import ZIP_DEFLATED, ZipFile; root = Path("docs/partner_intake/sample_drops/ur_rtde_csv_v0/accepted_minimal"); zip_path = Path("artifacts/rdf_file_drop_evaluator/blind-clean-checkout/accepted_minimal.zip"); zip_path.parent.mkdir(parents=True, exist_ok=True); archive = ZipFile(zip_path, "w", compression=ZIP_DEFLATED); [archive.write(path, path.relative_to(root).as_posix()) for path in sorted(root.rglob("*")) if path.is_file()]; archive.close(); print(zip_path)'; then
  gate "G7a-zip-create" "PASS" "accepted zip created"
else
  gate "G7a-zip-create" "FAIL" "accepted zip creation"
fi

if capture_in_clone "$OUTPUTS/evaluate_zip.json" "${CLI[@]}" evaluate "$ART_ROOT/accepted_minimal.zip" --profile ur_rtde_csv_v0 --out "$ART_ROOT/accepted-zip" --force --json; then
  EVAL_ZIP_RC=0
else
  EVAL_ZIP_RC=$?
fi
if [[ "$EVAL_ZIP_RC" -eq 0 ]] && json_equals "$OUTPUTS/evaluate_zip.json" passed true && json_equals "$OUTPUTS/evaluate_zip.json" input_kind '"zip"'; then
  gate "G7a-zip-evaluate" "PASS" "zip accepted evaluated passed=true output=$OUTPUTS/evaluate_zip.json"
else
  gate "G7a-zip-evaluate" "FAIL" "zip accepted evaluate rc=$EVAL_ZIP_RC output=$OUTPUTS/evaluate_zip.json"
fi
record_json_path "zip_evaluate_json" "$OUTPUTS/evaluate_zip.json"

if capture_in_clone "$OUTPUTS/verify_zip.json" "${CLI[@]}" verify "$ART_ROOT/accepted-zip" --deep-hdf5 --json; then
  VERIFY_ZIP_RC=0
else
  VERIFY_ZIP_RC=$?
fi
if [[ "$VERIFY_ZIP_RC" -eq 0 ]] && json_equals "$OUTPUTS/verify_zip.json" verdict '"VERIFIED"' && json_equals "$OUTPUTS/verify_zip.json" passed true; then
  gate "G7a-zip-verify" "PASS" "zip verifier VERIFIED passed=true output=$OUTPUTS/verify_zip.json"
else
  gate "G7a-zip-verify" "FAIL" "zip verifier rc=$VERIFY_ZIP_RC output=$OUTPUTS/verify_zip.json"
fi
record_json_path "zip_verify_json" "$OUTPUTS/verify_zip.json"

FROZEN_COMMANDS=(
  "scripts/verify_mvp2_package.py docs/proof/mvp2_learning_proven_evidence_package/package_manifest.json"
  "scripts/verify_proof_package.py docs/proof/mvp3a_target_fixture_pose_variant_proof_package/package_manifest.json"
  "scripts/verify_mvp3b_source_adapter_package.py docs/proof/mvp3b_source_adapter_matrix_proof_package/package_manifest.json"
  "scripts/verify_mvp3c_isaac_sim_embodiment_source_package.py docs/proof/mvp3c_isaac_sim_embodiment_source_proof_package/package_manifest.json"
  "scripts/verify_external_robot_data_ingest_package.py docs/proof/external_robot_data_ingest_eval_v0_proof_package/package_manifest.json"
  "scripts/verify_lerobot_public_slice_package.py docs/proof/lerobot_public_aloha_slice_semantic_parity_proof_package/package_manifest.json"
  "scripts/verify_lerobot_public_dataset_matrix_package.py docs/proof/lerobot_public_dataset_matrix_semantic_parity_proof_package/package_manifest.json"
  "scripts/verify_lerobot_public_dataset_matrix_package.py docs/proof/rdf_public_dataset_trustpack_v0_lerobot_matrix_package/package_manifest.json"
  "scripts/verify_mvp5a_pre_file_drop_chaos_rehearsal_package.py docs/proof/mvp5a_pre_digital_twin_file_drop_chaos_rehearsal_package/package_manifest.json --deep-hdf5"
)

frozen_index=0
for frozen_cmd in "${FROZEN_COMMANDS[@]}"; do
  frozen_index=$((frozen_index + 1))
  frozen_output="$OUTPUTS/frozen_${frozen_index}.txt"
  if capture_shell_in_clone "$frozen_output" "$UV_BIN run python $frozen_cmd"; then
    FROZEN_RC=0
  else
    FROZEN_RC=$?
  fi
  frozen_name="$(awk '{print $1}' <<< "$frozen_cmd" | xargs basename)"
  if [[ "$FROZEN_RC" -eq 0 ]] && grep -q "VERDICT: VERIFIED" "$frozen_output"; then
    gate "G7b-frozen-$frozen_index" "PASS" "$frozen_name VERDICT: VERIFIED output=$frozen_output"
  else
    gate "G7b-frozen-$frozen_index" "FAIL" "$frozen_name rc=$FROZEN_RC output=$frozen_output"
  fi
  log "frozen_verifier_${frozen_index}_command=$frozen_cmd"
  log "frozen_verifier_${frozen_index}_output=$frozen_output"
done

case "$CLONE/$ART_ROOT" in
  "$ORIGINAL_REPO"/*|"$ORIGINAL_REPO")
    gate "G8-output-containment" "FAIL" "artifact root resolves inside original repo"
    ;;
  "$CLONE"/*)
    gate "G8-output-containment" "PASS" "artifact root is under clean clone only"
    ;;
  *)
    gate "G8-output-containment" "FAIL" "artifact root is outside clean clone"
    ;;
esac

ORIGINAL_STATUS_AFTER="$(original_status_snapshot)"
if [[ "$ORIGINAL_STATUS_BEFORE" == "$ORIGINAL_STATUS_AFTER" ]]; then
  gate "G8-original-status" "PASS" "original repo status unchanged except allowed evidence paths"
else
  gate "G8-original-status" "FAIL" "original repo status changed outside allowed evidence paths"
fi
log "original_status_before_sha256=$ORIGINAL_STATUS_BEFORE"
log "original_status_after_sha256=$ORIGINAL_STATUS_AFTER"
log "command_transcript=$COMMAND_LOG"

if [[ "$FAILS" -eq 0 ]]; then
  log "DRY_RUN_RESULT=PASS"
else
  log "DRY_RUN_RESULT=FAIL"
fi
log "FAILS=$FAILS"

exit "$FAILS"
