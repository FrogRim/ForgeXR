# Generic command-state JSONL file-drop 요청서

`Profile id`:

```text
generic_command_state_jsonl_v0
```

현재 RDF alpha model:

```text
robot_family=generic_manipulator
robot_model=generic_6dof_command_state
dof=6
action_semantics=explicit_command_vector
state_semantics=explicit_state_vector
```

## 요청 파일

```text
metadata.json
command_state.jsonl
```

## 요청 metadata

```json
{
  "profile_id": "generic_command_state_jsonl_v0",
  "robot_family": "generic_manipulator",
  "robot_model": "generic_6dof_command_state",
  "dof": 6,
  "joint_names": ["joint_1", "joint_2", "joint_3", "joint_4", "joint_5", "joint_6"],
  "units": {
    "joint_position": "rad"
  },
  "action_semantics": "explicit_command_vector",
  "state_semantics": "explicit_state_vector"
}
```

## 요청 JSONL field

```text
timestamp
state_timestamp
command_timestamp
state
command
```

`state`와 `command`는 6D finite numeric vector여야 한다.

## Clean data 기대 조건

```text
timestamp는 finite 값이고 strictly monotonic이어야 한다.
command_timestamp는 state_timestamp보다 뒤에 있으면 안 된다.
command/state lag는 threshold 안에 있어야 한다.
state는 observation/state여야 한다.
command는 action/target이어야 한다.
명시적인 future state-only profile이 생기기 전까지 state-only log는 action log가 아니다.
```

## 예상 rejection 예시

```text
command_state.jsonl 누락
state 누락
command 누락
state dimension 불일치
action dimension 불일치
state/action/timestamp 안의 NaN 또는 Inf
future state를 action으로 사용
action semantics 불일치
큰 timestamp gap
하나의 continuous trajectory 안에 reset boundary 포함
조작된 task_success field
placeholder source owner
```
