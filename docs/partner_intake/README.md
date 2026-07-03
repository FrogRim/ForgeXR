# Partner file-drop intake kit

이 문서 세트는 실제 external recorded robot log를 받기 전 상대에게 요청할 file-drop 형식을 정리한다.

현재 RDF alpha가 지원하는 것은 pre-real-log / digital-twin rehearsal profile이다. 이 문서가 존재한다고 해서 external partner data가 이미 평가됐다는 뜻은 아니다.

## 지원 v0 profile

```text
ur_rtde_csv_v0
franka_state_jsonl_v0
ros2_channel_bundle_jsonl_v0
generic_command_state_jsonl_v0
```

각 profile은 명시적으로 선택해야 한다. RDF는 unknown profile을 trusted로 자동 승격하지 않는다.

## Committed sample drop

MVP-5B alpha에는 사용자가 바로 CLI 또는 desktop shell에 넣어볼 수 있는 작은
sample corpus가 포함된다.

```text
docs/partner_intake/sample_drops/
```

현재 포함된 sample:

```text
ur_rtde_csv_v0/accepted_minimal
ur_rtde_csv_v0/rejected_missing_metadata
```

이 sample은 actual external partner log가 아니다. `generated_by_rdf_sim=true`,
`external_partner_data=false`인 digital-twin rehearsal fixture이며, accept path와
reject/no-export path를 재현하기 위한 smoke corpus다.

## 현재 alpha verifier가 검증하는 package 요구사항

MVP-5B alpha verifier가 지금 실제로 검증하는 입력은 digital-twin rehearsal
drop이다. 따라서 현재 `rdf evaluate`로 바로 검증 가능한 metadata는 아래처럼
pre-real-log rehearsal boundary를 유지해야 한다.

```json
{
  "schema_version": "string",
  "profile_id": "string",
  "source_kind": "digital_twin_rehearsal_log",
  "generated_by_rdf_sim": true,
  "external_partner_data": false,
  "robot_family": "string",
  "robot_model": "string",
  "dof": 6,
  "joint_names": ["..."],
  "units": {},
  "action_semantics": "string",
  "state_semantics": "string"
}
```

`external_partner_data=true`는 MVP-5B alpha verifier에서 의도적으로 reject된다.
실제 partner drop은 아래 request contract를 사용해 수령하지만, 아직 이 alpha의
`file_drop_rehearsal_ready` claim을 열지는 않는다.

## 향후 partner request metadata

모든 file-drop은 folder 또는 zip이어야 한다.

실제 partner에게 요청할 공통 metadata는 다음 key를 포함해야 한다. 이 block은
수령 요청서이며, 현재 MVP-5B verifier input contract가 아니다.

```json
{
  "schema_version": "string",
  "profile_id": "string",
  "source_kind": "string",
  "generated_by_rdf_sim": false,
  "external_partner_data": true,
  "robot_family": "string",
  "robot_model": "string",
  "dof": 6,
  "joint_names": ["..."],
  "units": {},
  "action_semantics": "string",
  "state_semantics": "string"
}
```

MVP-5B alpha에서는 generated digital-twin rehearsal evidence만 검증 완료 상태다. 실제 partner drop을 받으면 위 metadata는 provenance attestation으로 취급되며, 물리적 origin을 암호학적으로 증명하지 않는다.

## 필수 intake document

상대에게 함께 요청한다.

```text
source owner / organization
collection date range
collection location type
robot model and controller version
task description
start/end condition
known pauses, resets, safety stops
license or sharing permission
privacy constraints
whether camera/person data is present
whether data can be redistributed in a small verifier package
```

## Intake kit coverage

현재 partner intake kit는 아래 여섯 surface를 포함한다.

| surface | file | 목적 |
|---|---|---|
| UR RTDE CSV | `ur_rtde_file_drop_request.md` | `rtde_output.csv`와 `metadata.json` 요청 형식, joint/TCP/action-state 의미, rejection 예시를 정의한다. |
| Franka JSONL | `franka_file_drop_request.md` | `franka_state.jsonl`, `franka_command.jsonl`, `metadata.json` 요청 형식과 7-DOF state/command 의미를 정의한다. |
| ROS2 channel bundle | `ros2_channel_bundle_file_drop_request.md` | JSONL topic bundle 요청 형식과 `/joint_states`, `/tf`, `/tf_static`, `/command` channel 기대치를 정의한다. |
| Generic command-state | `generic_command_state_file_drop_request.md` | 특정 robot vendor 형식이 없을 때 명시적 command/state vector request contract를 정의한다. |
| Privacy/license/provenance | `data_privacy_license_provenance_checklist.md` | owner, redistribution, license, privacy, provenance limitation 확인 항목을 정의한다. |
| Triage runbook | `file_drop_triage_runbook.md` | 수령 후 원본 보존, profile 선택, preflight/evaluate/verify, evidence 회신 절차를 정의한다. |

이 coverage는 request template와 triage 절차를 뜻한다. live hardware support,
real robot readiness, external partner evaluation 완료, production readiness를
뜻하지 않는다.

## Non-claim

RDF file-drop evaluation은 아래를 자동 claim하지 않는다.

```text
real robot success
physical robot readiness
deployable policy readiness
live UR/RTDE support
live Franka support
live ROS2/DDS bridge readiness
policy uplift
production certification
marketplace readiness
```

## Profile별 file

- [UR RTDE-style 요청서](ur_rtde_file_drop_request.md)
- [Franka-style 요청서](franka_file_drop_request.md)
- [ROS2 channel bundle 요청서](ros2_channel_bundle_file_drop_request.md)
- [Generic command-state 요청서](generic_command_state_file_drop_request.md)
- [Privacy/license/provenance checklist](data_privacy_license_provenance_checklist.md)
- [Triage runbook](file_drop_triage_runbook.md)
