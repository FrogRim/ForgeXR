# Blind Clean-Checkout Dry Run Protocol — Pre-Real-Log File-Drop Evaluator

Status: release-gate protocol (MVP-5A/5B). Run this before tagging the
`pre-real-log file-drop evaluator` release candidate.

## Purpose

Prove that the evaluator + verifiers reproduce their verdicts **from nothing but
what is committed at a pinned ref, plus the documented dependency install** — no
dev-machine state, no inherited env, no pre-built `artifacts/`, no cached venv.

This is the single highest-value remaining verification because almost all
residual risk sits on three untested seams:

1. `scripts/rdf_file_drop_evaluator.py` does `sys.path.insert(0, apps/api)` then
   `from app.services.mvp5a_file_drop_rehearsal import ...` — fresh-tree import.
2. `scripts/verify_rdf_file_drop_evaluator_run.py` does `import h5py, numpy` for
   `--deep-hdf5` — dependency presence.
3. The API bridge spawns `sys.executable` with a scrubbed env — interpreter/PATH
   assumptions.

**Coupling note:** this protocol is also what upgrades the trust core from
"90% (tests green on dev machine)" to "95% (verdicts reproduce from a blind
clone)." Do not count trust-core completeness and release readiness as
independent until G7 below passes.

## What "blind" means (isolation controls — all mandatory)

- Clone into a temp dir **outside** the working repo (`mktemp -d`).
- Fresh dependency environment created **inside** the clone (no inherited
  site-packages / no reused `.venv`).
- Scrubbed environment: unset `PYTHONPATH`, unset
  `RDF_FILE_DROP_EVALUATOR_ARTIFACT_ROOT` (so the CLI's in-repo default path is
  exercised), keep only `PATH`/`HOME`/`LANG`.
- Pin an exact ref (release tag or commit SHA). Record it + the `uv.lock` hash in
  the receipt. A dirty or moving ref invalidates the run.
- Never run any command against the original working tree. All artifacts land
  under the temp clone only (verified by G8).
- **Every CLI/verifier call goes through `uv run`** (the documented runtime).
  Bare `python` on a machine with another interpreter (e.g. a system/anaconda
  Python missing the pinned deps) silently rejects valid drops — this was
  observed while validating this protocol and is itself a thing the dry run must
  catch.
- **Do not leave `RDF_FILE_DROP_EVALUATOR_ARTIFACT_ROOT` pointing outside the
  clone.** The CLI `doctor` check `artifact_root_under_repo` fails (and G3 fails)
  if it does. Leave it unset so the in-repo default is exercised.

## Sample-input note

The committed `docs/proof/.../source_drops/golden/<profile>/` drops are **MVP-5A
artifacts and are rejected by the MVP-5B evaluator** — they are not valid accept
inputs. The executable dry run now uses the committed digital-twin sample corpus
under `docs/partner_intake/sample_drops/ur_rtde_csv_v0/`:

- `accepted_minimal/` for accepted folder and zip gates.
- `rejected_missing_metadata/` for rejected no-export gates.

The dry run does not generate a service-writer fixture during G5. A missing
committed sample corpus is a protocol failure because release-candidate
reproducibility must come from the pinned tree, not from an ad hoc generated
input outside it.

## Preconditions

- The ref under test is pushed/reachable (or clone from the local path).
- Documented install command is `uv sync --group dev` (root pins `h5py`,
  `numpy`; `apps/api` pins `fastapi`; dev group adds `httpx`).
- Node available only if G9 (web/bridge) is included.

## Gate checklist (each gate fail-closed; any miss = protocol FAIL)

| Gate | Check | PASS criterion |
|------|-------|----------------|
| G0 | Pin ref + record evidence | exact SHA + `uv.lock` sha256 recorded |
| G1 | Clone + checkout into temp; tree clean | `git status` clean, `HEAD` == pinned SHA |
| G2 | Documented deps only | `uv sync --group dev` succeeds; `uv run python -c "import h5py,numpy,fastapi"` ok |
| G3 | CLI `doctor` | exit 0, `ok=true`, all doctor checks true |
| G4 | `profiles list` / `inspect` | exit 0, `ok=true`, 4 profiles |
| G5a | Committed accept sample path (folder) → evaluate | exit 0, `passed=true`, run package created |
| G5b | Accept path → `verify --deep-hdf5` | exit 0, `verdict=VERIFIED`, `passed=true` |
| G6a | Committed reject sample path → evaluate | exit 2, `passed=false`, `rejection_reasons` non-empty, **no `export/` dir** |
| G6b | Reject path → `verify --deep-hdf5` | exit 0, `verdict=VERIFIED`, `passed=false` (valid rejected package) |
| G6c | Tamper guard | flip one source byte in an accepted package, re-verify → exit 1, `FAILED` |
| G7a | Zip input → evaluate + verify | same verdicts as G5 (zip-slip-safe extraction in clean env) |
| G7b | Frozen verifier reproduction | every frozen verifier prints `VERDICT: VERIFIED` (incl. mvp5a `--deep-hdf5`) |
| G8 | Blindness containment | original repo unmodified; all writes under temp clone |
| G9 | (optional) web/bridge smoke | `npm ci && npm run build` ok; loopback `GET /api/file-drop/profiles` 200 passthrough |

## Runnable script

실행 스크립트는 이제 repo-local 파일
`scripts/blind_clean_checkout_dry_run.sh`가 source of truth다. 예전 embedded
draft는 제거한다. 스크립트는 `set -euo pipefail`로 시작하고, 모든 evaluator /
verifier 호출은 `env -i`로 `PYTHONPATH`와
`RDF_FILE_DROP_EVALUATOR_ARTIFACT_ROOT`를 상속하지 않으며 `uv run`을 통과한다.

기본 실행:

```bash
bash scripts/blind_clean_checkout_dry_run.sh <pinned-ref> <repo-path>
```

현재 공유 worktree처럼 release-scope 변경이 uncommitted이고 commit/tag/stage가
금지된 경우에는 원본 repo history를 바꾸지 말고, repo 밖의 temporary candidate
clone에서 필요한 release-scope 파일만 복사한 뒤 그 temp clone 안에서만 local
commit을 만든다. 그런 다음 위 스크립트를 temp candidate repo path와 그 local
commit SHA로 실행한다. 이 temp commit은 release claim의 영구 history가 아니라
dirty worktree를 실행 target으로 쓰지 않기 위한 검증용 pinned tree다.

스크립트가 기록해야 하는 receipt 필드:

- `pinned_ref`, `pinned_sha`, `uv_lock_sha256`
- `source_repo_path`, `original_repo_path`, `work_dir`, `clone_path`
- G0-G8 `PASS` / `FAIL`
- accepted / rejected / zip `evaluate` JSON 경로
- accepted / rejected / zip / tampered verifier JSON 경로
- frozen verifier command별 output 경로와 `VERDICT: VERIFIED` gate
- original repo status containment hash와 output root containment

실패 경로 smoke:

```bash
! bash scripts/blind_clean_checkout_dry_run.sh refs/does-not-exist "$(pwd)"
```

이 명령은 candidate ref checkout 단계에서 실패해야 하며, receipt에
`DRY_RUN_RESULT=PASS`를 쓰면 안 된다.

## Evidence / receipt

The script writes the durable release-gate receipt to
`.omo/evidence/pre-real-log-clean-checkout-receipt.txt` in the original repo.
Large command outputs and verifier JSON files stay under the script-created
`work_dir` outside the original repo; the receipt records those absolute paths
and their sha256 hashes. The release is gated on `FAILS=0` and
`DRY_RUN_RESULT=PASS`.

## Exit criteria → readiness unlocked

- All gates G0–G8 PASS → blind reproducibility proven; trust core moves 90%→95%
  and the "release 68%" item *clean checkout blind dry run* closes.
- G9 PASS additionally de-risks the desktop/Pake packaged smoke (the bridge +
  web build are confirmed from a clean tree).
- Remaining after a green run: packaged Pake binary smoke, real folder/zip e2e
  *through the desktop shell* (not just CLI), and the final tag/release note.

## Non-claims preserved

A green dry run proves only blind local reproducibility of the digital-twin
rehearsal evaluator. It does not evaluate external partner data, real robot logs,
hardware, live UR/Franka/ROS2, policy uplift, or production readiness.
```
