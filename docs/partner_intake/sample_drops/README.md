# RDF file-drop sample corpus v0

이 디렉토리는 MVP-5B `rdf_file_drop_evaluator.py`와 local desktop shell을
직접 시험할 수 있게 만든 작은 committed sample corpus다.

중요한 claim boundary:

- 이 샘플은 실제 external partner robot log가 아니다.
- 이 샘플은 real robot data evaluation evidence가 아니다.
- 이 샘플은 live UR/RTDE, Franka, ROS2/DDS, hardware readiness, policy
  uplift, production readiness를 주장하지 않는다.
- `accepted_minimal`은 evaluator happy path smoke용이다.
- `rejected_missing_metadata`는 evaluator reject path와 no-export gate smoke용이다.

## Sample 구성

```text
docs/partner_intake/sample_drops/
  ur_rtde_csv_v0/
    accepted_minimal/
      metadata.json
      rtde_output.csv
    rejected_missing_metadata/
      rtde_output.csv
```

`accepted_minimal`은 deterministic digital-twin rehearsal fixture에서 생성한
UR RTDE-style command/state drop이다. `rejected_missing_metadata`는 같은 source
rows에서 `metadata.json`을 제거한 negative sample이다.

## CLI smoke 실행

repository root에서 실행한다.

```bash
uv run python scripts/rdf_file_drop_evaluator.py evaluate \
  docs/partner_intake/sample_drops/ur_rtde_csv_v0/accepted_minimal \
  --profile ur_rtde_csv_v0 \
  --out artifacts/rdf_file_drop_evaluator/sample-accepted \
  --force \
  --json

uv run python scripts/rdf_file_drop_evaluator.py verify \
  artifacts/rdf_file_drop_evaluator/sample-accepted \
  --deep-hdf5 \
  --json
```

Reject path는 아래 명령으로 확인한다.

```bash
uv run python scripts/rdf_file_drop_evaluator.py evaluate \
  docs/partner_intake/sample_drops/ur_rtde_csv_v0/rejected_missing_metadata \
  --profile ur_rtde_csv_v0 \
  --out artifacts/rdf_file_drop_evaluator/sample-rejected \
  --force \
  --json

uv run python scripts/rdf_file_drop_evaluator.py verify \
  artifacts/rdf_file_drop_evaluator/sample-rejected \
  --json
```

예상 결과:

- accepted sample: `passed=true`, HDF5 export가 존재하고 verifier는 `VERIFIED`.
- rejected sample: `passed=false`, HDF5 export가 없고 verifier는 `VERIFIED`와
  `passed=false`.
