# UR RTDE-style file-drop 요청서

`Profile id`:

```text
ur_rtde_csv_v0
```

현재 RDF alpha model:

```text
robot_family=universal_robots
robot_model=ur10e
dof=6
action_semantics=target_q_command
state_semantics=actual_q_state
```

## 요청 파일

```text
metadata.json
rtde_output.csv
```

## 요청 metadata

```json
{
  "profile_id": "ur_rtde_csv_v0",
  "robot_family": "universal_robots",
  "robot_model": "ur10e",
  "dof": 6,
  "joint_names": [
    "shoulder_pan_joint",
    "shoulder_lift_joint",
    "elbow_joint",
    "wrist_1_joint",
    "wrist_2_joint",
    "wrist_3_joint"
  ],
  "units": {
    "joint_position": "rad",
    "tcp_position": "m",
    "tcp_rotation": "rotation_vector_rad"
  },
  "action_semantics": "target_q_command",
  "state_semantics": "actual_q_state"
}
```

## 요청 CSV column

```text
timestamp
joint_names
actual_q
target_q
actual_TCP_pose
target_TCP_pose
actual_TCP_speed
robot_mode
safety_status
```

`joint_names`, `actual_q`, `target_q`, TCP pose, TCP speed는 CSV cell 안에서
JSON array string으로 제공해야 한다.

## Clean data 기대 조건

```text
timestamp는 finite 값이고 strictly monotonic이어야 한다.
timestamp gap은 profile threshold 안에 있어야 한다.
joint 순서는 metadata.joint_names와 정확히 일치해야 한다.
actual_q와 target_q는 6D radian vector여야 한다.
TCP position 단위는 millimeter가 아니라 meter여야 한다.
TCP rotation은 rotation-vector radian이어야 한다.
clean training-eligible row에서는 robot_mode == RUNNING이어야 한다.
clean training-eligible row에서는 safety_status == NORMAL이어야 한다.
target_q는 command/action이고 actual_q는 state여야 한다.
```

## 예상 rejection 예시

```text
actual_q 누락
joint dimension 불일치
joint 순서 뒤바뀜
degree/radian 단위 혼동
millimeter/meter TCP 단위 혼동
non-monotonic timestamp
큰 timestamp gap
protective stop 또는 running 상태가 아닌 robot_mode
threshold를 초과한 target/actual lag
조작된 task_success field
지원 evidence와 맞지 않는 external claim metadata
```
