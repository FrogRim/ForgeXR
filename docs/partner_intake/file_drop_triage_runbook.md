# File-drop triage runbook

이 runbook은 recorded robot log folder 또는 zip을 받은 뒤 첫 1시간 동안의
triage 절차를 정의한다.

## 1. 원본 파일 보존

```bash
mkdir -p /tmp/rdf_partner_drop/original
cp -a /path/from/partner/. /tmp/rdf_partner_drop/original/
```

original hash를 기록하기 전에는 source file 이름을 바꾸지 않는다.

## 2. Profile 명시 선택

지원 profile list를 먼저 확인한다.

```bash
uv run python scripts/rdf_file_drop_evaluator.py profiles list --json
```

맞는 profile이 없으면 중단한다. trusted profile을 자동 탐지하지 않는다.

## 3. Preflight

```bash
uv run python scripts/rdf_file_drop_evaluator.py preflight \
  /tmp/rdf_partner_drop/original \
  --profile <profile_id> \
  --json
```

preflight가 실패하면 result와 rejection reason을 보존한다. partner가 correction을
확인하기 전에는 source file을 통과시키기 위해 수정하지 않는다.

## 4. Evaluate 실행

```bash
uv run python scripts/rdf_file_drop_evaluator.py evaluate \
  /tmp/rdf_partner_drop/original \
  --profile <profile_id> \
  --out artifacts/rdf_file_drop_evaluator/<run_id> \
  --json
```

rejected run도 유용한 evidence다. raw evidence와 structured rejection reason은
보존하되 training eligible로 승격하면 안 된다.

## 5. Verify 실행

```bash
uv run python scripts/rdf_file_drop_evaluator.py verify \
  artifacts/rdf_file_drop_evaluator/<run_id> \
  --deep-hdf5 \
  --json
```

verifier result가 local source of truth다. buyer report, UI state, cached summary로
verifier result를 override하지 않는다.

## 6. Buyer report 확인

아래 report를 연다.

```text
artifacts/rdf_file_drop_evaluator/<run_id>/reports/buyer_report.html
```

report에는 필요한 경우 non-claim과 rejection reason이 포함되어야 한다.

## 7. Evidence와 함께 escalation

file-drop이 실패하면 partner에게 아래 정보를 보낸다.

```text
profile_id used
command run
exit code
rejection reasons
missing files or fields
unit/dimension/timestamp mismatch evidence
privacy/license blockers if present
```

structured evidence 없이 넓은 의미의 "data bad" 메시지를 보내지 않는다.

## 8. Stop condition

아래 조건이면 중단한다.

```text
profile is unknown
source license is unclear
privacy status is unclear
metadata claims external origin but owner/permission is absent
data requires live robot control to interpret
data requires live ROS2/DDS runtime to parse
source rows cannot support action/state semantics
HDF5 export would erase embodiment-specific semantics
```
