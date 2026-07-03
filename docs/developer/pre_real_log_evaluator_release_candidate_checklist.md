# Pre-real-log Evaluator Release Candidate Checklist

상태: review-work blocker closure evidence refreshed; ready for explicit git tag  
candidate tag: `pre-real-log-evaluator-v0`  
범위: pre-real-log local file-drop evaluator alpha의 taggable evidence package  
작성일: 2026-07-02

## Release Candidate Claim

허용 문장:

> Robot Data Forge is ready to evaluate local recorded robot log file-drops through a verifier-backed trust pipeline before receiving real external robot logs.

이 문서는 taggable readiness checklist다. 실제 tag 생성, push, publish는 git
operation이 source of truth이며, 이 문서 자체가 tag 생성을 대체하지 않는다.

## Exact Non-claims

non-claims:
- external partner data evaluated
- real robot data evaluated
- real robot success
- hardware readiness
- live UR/RTDE support
- live Franka support
- live ROS2/DDS bridge readiness
- policy uplift
- production readiness
- marketplace readiness
- production certification

sample corpus와 smoke artifact는 digital-twin rehearsal evidence다. 실제
external/partner log, real robot log, live hardware run, downstream policy result의
증거로 사용하지 않는다.

## Required Receipts From Todos 1-7

| Todo | Gate | Required command / observable | Receipt path | Current result |
|---:|---|---|---|---|
| 1 | dirty-worktree scope | `git status --porcelain=v1 -z` capture + parser over `# scope_table` | `.omo/evidence/task-1-git-status.z`; `.omo/evidence/task-1-pre-real-log-evaluator-product-ready.log` | PASS; 12 captured paths classified as `in_scope`, `out_of_scope_preserve`, or `planning_only` |
| 2 | documented Python runtime | `uv sync --group dev`; `uv run python -c "import h5py,numpy,fastapi; print(h5py.__version__, numpy.__version__)"`; `uv lock --check` | `.omo/evidence/task-2-pre-real-log-evaluator-product-ready.log` | PASS; `h5py 3.16.0`, `numpy 2.4.4`; bare local Python drift recorded as non-gating |
| 3 | trust-core verifier | `uv run pytest -q apps/api/tests/test_verify_rdf_file_drop_evaluator_run.py`; accepted evaluate + `verify --deep-hdf5`; rejected verify; tamper failure | `.omo/evidence/task-3-pre-real-log-evaluator-product-ready.log` | PASS; 19 tests passed; accepted `VERIFIED`; rejected package `VERIFIED` with `passed=false`; tamper `FAILED` |
| 4 | CLI + sample corpus | `uv run pytest -q apps/api/tests/test_mvp5b_file_drop_evaluator_cli.py apps/api/tests/test_mvp5b_file_drop_evaluator_security.py apps/api/tests/test_mvp5b_file_drop_evaluator_corpus.py`; profile list; accepted/rejected/zip/path-traversal/malformed/doctor checks | `.omo/evidence/task-4-pre-real-log-evaluator-product-ready.log` | PASS; 87 tests passed, 1 warning; accepted `passed=true`; rejected `passed=false` and no HDF5 export; unsafe inputs fail closed |
| 5 | blind clean-checkout dry run | `bash scripts/blind_clean_checkout_dry_run.sh <candidate-sha> .omo/evidence/pre-real-log-current-candidate.git`; invalid ref failure path | `.omo/evidence/task-5-pre-real-log-evaluator-product-ready.log`; `.omo/evidence/pre-real-log-clean-checkout-receipt.txt`; `.omo/evidence/ulw-clean-checkout-current-candidate.txt` | PASS on refreshed durable receipt; `source_repo_path` is under `.omo/evidence`, `DRY_RUN_RESULT=PASS`, `FAILS=0`; pinned SHA is recorded in the current receipt |
| 6 | local API bridge + desktop shell | `uv run pytest -q apps/api/tests/test_file_drop_api_bridge.py`; `cd apps/web && npm run lint && npm run build`; `bash scripts/run_pake_file_drop_shell.sh --smoke`; local backend/web smoke | `.omo/evidence/task-6-pre-real-log-evaluator-product-ready.log`; `.omo/evidence/pre-real-log-desktop-shell-smoke.md` | PASS; 15 tests passed; Next.js lint/build passed; Pake wrapper smoke passed; local bridge surfaces CLI/verifier payloads only |
| 7 | partner intake + claim scan | `uv run pytest -q apps/api/tests/test_pre_real_log_claim_boundary_scanner.py`; `uvx ruff check ...`; `uv run python -m compileall ...`; `uv run python scripts/scan_pre_real_log_claim_boundaries.py docs apps/web scripts README.md --json`; seeded positive forbidden claim failure | `.omo/evidence/task-7-pre-real-log-evaluator-product-ready.log` | PASS; scanner report `ok=true`; seeded positive claim fails closed; partner intake request kit files present |

## Current Todo 8 Required Checks

이 checklist 자체는 아래 명령으로 다시 검증해야 한다.

```bash
git tag --list | rg '^pre-real-log-evaluator-v0$'
```

예상 해석:

- exit `0`: tag가 이미 존재한다. 이 경우 새 tag를 만들지 말고 기존 tag를 검토한다.
- exit `1` and empty output: tag가 아직 없다. 이것은 정상이며 이 Todo에서 tag를 만들지 않는다.

```bash
uv run python scripts/scan_pre_real_log_claim_boundaries.py docs apps/web scripts README.md docs/developer/pre_real_log_evaluator_release_candidate_checklist.md --json
```

필수 결과:

- exit `0`
- JSON `ok=true`
- `issue_count=0`

Todo 8 실행 당시 결과:

| Check | Invocation | Result | Evidence |
|---|---|---|---|
| tag preflight check | `git tag --list | rg '^pre-real-log-evaluator-v0$'` | exit `1`, stdout empty; Todo 8 시점에는 tag가 아직 없었다. | `.omo/evidence/task-8-pre-real-log-evaluator-product-ready.log` |
| release-scope status | `git status --short` | dirty paths are classified below; no unclassified product files. | `.omo/evidence/task-8-pre-real-log-evaluator-product-ready.log` |
| claim-boundary scanner | `uv run python scripts/scan_pre_real_log_claim_boundaries.py docs apps/web scripts README.md docs/developer/pre_real_log_evaluator_release_candidate_checklist.md --json` | exit `0`; `ok=true`; `issue_count=0`; `scanned_file_count=128`. | `.omo/evidence/task-8-pre-real-log-evaluator-product-ready.log` |
| diff whitespace | `git diff --check -- docs/developer/pre_real_log_evaluator_release_candidate_checklist.md` | exit `0`. | `.omo/evidence/task-8-pre-real-log-evaluator-product-ready.log` |

## Release-scope Git Status Classification

현재 release candidate는 shared dirty worktree에서 준비되었다. 아래 표는
`git status --short`에 보이는 파일을 Todo/evidence/scope로 분류한다. unclassified
product file은 없어야 한다.

| status | path | classification | reason |
|---|---|---|---|
| `M` | `AGENTS.md` | `out_of_scope_preserve` | init-deep generated root guidance change; release candidate checklist가 소유하지 않는다. |
| `M` | `apps/api/app/routers/file_drop.py` | `todo_6_release_scope` | local API bridge display-only surface hardening. |
| `M` | `apps/api/tests/test_file_drop_api_bridge.py` | `todo_6_release_scope` | API bridge regression coverage. |
| `M` | `apps/api/tests/test_mvp5b_file_drop_evaluator_cli.py` | `todo_4_release_scope` | CLI evaluator regression coverage. |
| `M` | `apps/api/tests/test_mvp5b_file_drop_evaluator_corpus.py` | `todo_4_release_scope` | committed sample corpus regression coverage. |
| `M` | `apps/api/tests/test_mvp5b_file_drop_evaluator_security.py` | `todo_4_release_scope` | malformed/unsafe input fail-closed coverage. |
| `M` | `apps/web/app/file-drop/page.tsx` | `todo_6_release_scope` | desktop/web shell displays CLI/verifier evidence only. |
| `M` | `docs/desktop/pake_file_drop_evaluator_alpha.md` | `todo_6_release_scope` | local Pake shell smoke/run documentation. |
| `M` | `docs/developer/worklog.md` | `developer_doc_shared` | repo policy worklog; preserve existing entries and append narrowly. |
| `M` | `docs/partner_intake/README.md` | `todo_7_release_scope` | partner intake overview and sample corpus boundary. |
| `M` | `docs/partner_intake/data_privacy_license_provenance_checklist.md` | `todo_7_release_scope` | privacy/license/provenance request checklist. |
| `M` | `docs/partner_intake/file_drop_triage_runbook.md` | `todo_7_release_scope` | intake triage runbook. |
| `M` | `docs/partner_intake/franka_file_drop_request.md` | `todo_7_release_scope` | Franka request template. |
| `M` | `docs/partner_intake/generic_command_state_file_drop_request.md` | `todo_7_release_scope` | generic command-state request template. |
| `M` | `docs/partner_intake/ros2_channel_bundle_file_drop_request.md` | `todo_7_release_scope` | ROS2 channel bundle request template. |
| `M` | `docs/partner_intake/ur_rtde_file_drop_request.md` | `todo_7_release_scope` | UR RTDE request template. |
| `M` | `scripts/rdf_file_drop_evaluator.py` | `todo_4_release_scope` | CLI evaluator fail-closed behavior. |
| `??` | `.omo/` | `planning_and_evidence` | plan/evidence tree; `.omo/boulder.json`, `.omo/start-work/ledger.jsonl`, and plan checkboxes are not edited by Todo 8. |
| `??` | `apps/api/AGENTS.md` | `out_of_scope_preserve` | init-deep scoped guidance. |
| `??` | `apps/api/tests/test_pre_real_log_claim_boundary_scanner.py` | `todo_7_release_scope` | claim-boundary scanner regression test. |
| `??` | `apps/web/AGENTS.md` | `out_of_scope_preserve` | init-deep scoped guidance. |
| `??` | `docs/AGENTS.md` | `out_of_scope_preserve` | init-deep scoped documentation guidance. |
| `??` | `docs/developer/blind_clean_checkout_dry_run_protocol.md` | `todo_5_release_scope` | blind clean-checkout protocol. |
| `??` | `docs/developer/pre_real_log_evaluator_release_candidate_checklist.md` | `todo_8_release_scope` | this release-candidate checklist. |
| `??` | `docs/partner_intake/sample_drops/` | `todo_4_release_scope` | committed digital-twin sample corpus. |
| `??` | `packages/shared/AGENTS.md` | `out_of_scope_preserve` | init-deep scoped guidance. |
| `??` | `scripts/AGENTS.md` | `out_of_scope_preserve` | init-deep scoped guidance. |
| `??` | `scripts/blind_clean_checkout_dry_run.sh` | `todo_5_release_scope` | executable blind clean-checkout dry-run gate. |
| `??` | `scripts/run_pake_file_drop_shell.sh` | `todo_6_release_scope` | executable local Pake wrapper. |
| `??` | `scripts/scan_pre_real_log_claim_boundaries.py` | `todo_7_release_scope` | executable claim-boundary scanner. |

release-scope rule:

- `todo_*_release_scope` files may be committed in the ordered release commits after final review.
- `out_of_scope_preserve` files must not be silently folded into the release commit unless the user explicitly chooses to include generated AGENTS guidance.
- `.omo/` evidence may be retained as local receipt material, but planning state files are not product release files.
- `Handoff.md`는 repo handoff policy에 따라 갱신했지만 `.gitignore` 대상이라 `git status --short` release-scope table에는 나타나지 않는다.

## Tag Instruction

아래 명령은 release branch가 main에 merge된 뒤 explicit release action으로 실행한다.
tag 존재 여부와 대상 commit은 git이 source of truth다.

```bash
git tag -a pre-real-log-evaluator-v0 -m "<Lore-style tag message>"
```

tag message에는 최소한 아래 내용을 포함한다.

- `Constraint:` pre-real-log local file-drop evaluator only; no external/real/hardware/live/production/marketplace claims.
- `Tested:` Todo 1-8 receipt paths and final claim-boundary scanner command.
- `Not-tested:` real external partner logs, live hardware runs, downstream policy result.

## Checklist QA

- release checklist location: `docs/developer/pre_real_log_evaluator_release_candidate_checklist.md`
- archive에 두지 않았다.
- candidate tag name은 `pre-real-log-evaluator-v0`이다.
- tag creation command는 future explicit-command instruction으로만 기록했다.
- prior receipt paths는 Todos 1-7 모두 포함한다.
- current dirty files는 release-scope table에서 전부 분류한다.
- no stale proof overclaim: blind dry-run readiness는 final receipt의 `DRY_RUN_RESULT=PASS`, `FAILS=0`만 readiness evidence로 사용한다.
- no temporary candidate overclaim: temporary candidate SHA는 clean-checkout reproducibility proof일 뿐 permanent release tag가 아니다.

## Todo 9 Final All-Gates Verification

Todo 9 transcript:

```text
.omo/evidence/task-9-pre-real-log-evaluator-product-ready.log
```

Final command results:

| Gate | Invocation | Result | Evidence |
|---|---|---|---|
| targeted pytest | `uv run pytest -q apps/api/tests/test_mvp5b_file_drop_evaluator_cli.py apps/api/tests/test_mvp5b_file_drop_evaluator_security.py apps/api/tests/test_mvp5b_file_drop_evaluator_corpus.py apps/api/tests/test_verify_rdf_file_drop_evaluator_run.py apps/api/tests/test_file_drop_api_bridge.py apps/api/tests/test_mvp5a_pre_frozen_verifier_regressions.py apps/api/tests/test_pre_real_log_claim_boundary_scanner.py` | exit `0`; `140 passed`, `1 warning` from duplicate zip member security fixture. | `.omo/evidence/task-9-pre-real-log-evaluator-product-ready.log` |
| compileall | `uv run python -m compileall -q apps/api/app apps/api/tests scripts` | exit `0`. | `.omo/evidence/task-9-pre-real-log-evaluator-product-ready.log` |
| ruff | `uvx ruff check scripts apps/api` | exit `0`; `All checks passed!`. | `.omo/evidence/task-9-pre-real-log-evaluator-product-ready.log` |
| web lint/build | `cd apps/web && npm run lint && npm run build` | exit `0`; ESLint and Next.js production build passed. | `.omo/evidence/task-9-pre-real-log-evaluator-product-ready.log` |
| blind clean-checkout rerun | `bash scripts/blind_clean_checkout_dry_run.sh <current-candidate-sha> .omo/evidence/pre-real-log-current-candidate.git` | exit `0`; `source_repo_path` under `.omo/evidence`; `DRY_RUN_RESULT=PASS`; `FAILS=0`; current pinned SHA recorded in receipt. | `.omo/evidence/ulw-clean-checkout-current-candidate.txt`; `.omo/evidence/pre-real-log-clean-checkout-receipt.txt` |
| claim-boundary scanner | `uv run python scripts/scan_pre_real_log_claim_boundaries.py docs apps/web scripts README.md docs/developer/pre_real_log_evaluator_release_candidate_checklist.md --json` | exit `0`; `ok=true`; `issue_count=0`; `scanned_file_count=128`. | `.omo/evidence/task-9-pre-real-log-evaluator-product-ready.log` |
| tag preflight | `git tag --list | rg '^pre-real-log-evaluator-v0$'` | exit `1`; Todo 9 시점에는 expected absence였다. | `.omo/evidence/task-9-pre-real-log-evaluator-product-ready.log` |

Final interpretation:

```text
FINAL_FAILS=0
allowed_claim=Robot Data Forge is ready to evaluate local recorded robot log file-drops through a verifier-backed trust pipeline before receiving real external robot logs.
```

Claim-boundary QA non-claims:

non-claims:
- external partner data evaluated
- real robot data evaluated
- real robot success
- hardware readiness
- live UR/RTDE support
- live Franka support
- live ROS2/DDS bridge readiness
- policy uplift
- production readiness
- marketplace readiness
- production certification

Code-review / slop / manual QA artifact sections:

```text
Review-work blocker closure did edit the Pake wrapper and focused regression
test. The wrapper now parses the URL and requires loopback hostname, no userinfo,
and explicit port `1..65535`.

Prior Todo 3-8 code-review, slop, gate-review, and manual-QA receipts remain
the product-surface review artifacts. The refreshed clean-checkout proof is the
durable `.omo/evidence/pre-real-log-current-candidate.git` dry run plus the
final claim-boundary scan transcript.
```

## Review-Work Blocker Closure Update

| Blocker | Evidence | Current result |
|---|---|---|
| Pake userinfo bypass | `.omo/evidence/ulw-pake-loopback-green.txt`; `.omo/evidence/ulw-pake-userinfo-reject-green.txt`; `.omo/evidence/ulw-pake-regression-tests.txt` | PASS; valid loopback URLs still smoke, userinfo bypass and port `0` fail closed before Pake launch |
| stale clean-checkout proof | `.omo/evidence/pre-real-log-current-candidate.git`; `.omo/evidence/pre-real-log-clean-checkout-receipt.txt`; `.omo/evidence/ulw-clean-checkout-current-candidate.txt` | PASS; current receipt is generated from a durable bare candidate repo under `.omo/evidence`, not from `/var/tmp` |
| release boundary | `.omo/evidence/ulw-release-boundary.txt` | ULW blocker-closure 시점에는 no commit, tag, push, publish, external/real/hardware/live/production/marketplace/policy-uplift claim was opened. 이후 release action은 git history와 tag가 source of truth다. |
