# Franka-style file-drop 요청서

`Profile id`:

```text
franka_state_jsonl_v0
```

현재 RDF alpha model:

```text
robot_family=franka
robot_model=panda
dof=7
action_semantics=q_d_command
state_semantics=q_actual_state
```

## 요청 파일

```text
metadata.json
franka_state.jsonl
franka_command.jsonl
```

## 요청 metadata

```json
{
  "profile_id": "franka_state_jsonl_v0",
  "robot_family": "franka",
  "robot_model": "panda",
  "dof": 7,
  "joint_names": [
    "panda_joint1",
    "panda_joint2",
    "panda_joint3",
    "panda_joint4",
    "panda_joint5",
    "panda_joint6",
    "panda_joint7"
  ],
  "units": {
    "joint_position": "rad"
  },
  "action_semantics": "q_d_command",
  "state_semantics": "q_actual_state"
}
```

## 요청 JSONL field

`franka_state.jsonl` row:

```text
timestamp
q
O_T_EE
robot_mode
```

`franka_command.jsonl` row:

```text
timestamp
q_d
O_T_EE_d
```

`q`와 `q_d`는 7D vector여야 한다. `O_T_EE`와 `O_T_EE_d`는 16-number
transform이어야 한다.

## Clean data 기대 조건

```text
timestamp는 finite 값이고 strictly monotonic이어야 한다.
state row와 command row는 row count와 timestamp 기준으로 정렬되어야 한다.
q는 actual state여야 한다.
q_d는 commanded target/action이어야 한다.
O_T_EE는 plausible rigid transform이어야 한다.
command semantics가 요구하면 O_T_EE_d가 있어야 한다.
clean training-eligible row에서는 robot_mode == move여야 한다.
```

## 예상 rejection 예시

```text
state 또는 command file 누락
DOF 불일치
non-finite q 또는 q_d
state와 command 사이의 timestamp drift
O_T_EE 누락 또는 malformed O_T_EE
non-rigid transform
clean motion state가 아닌 robot mode
action semantics 누락
조작된 task_success field
```
