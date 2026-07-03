# ROS2 channel-bundle file-drop 요청서

`Profile id`:

```text
ros2_channel_bundle_jsonl_v0
```

현재 RDF alpha model:

```text
robot_family=ros2_simulated_manipulator
robot_model=ur10e_channel_bundle
dof=6
action_semantics=command_topic_target_joint_state
state_semantics=joint_states_topic_actual_state
```

이 profile은 JSONL channel-bundle rehearsal profile이다. live ROS2/DDS bridge
claim도 아니고 MCAP binary parser claim도 아니다.

## 요청 파일

```text
metadata.json
topic_manifest.json
topics/joint_states.jsonl
topics/tf.jsonl
topics/tf_static.jsonl
topics/command.jsonl
```

## 요청 topic

`topic_manifest.json`은 아래 topic을 정확히 나열해야 한다.

```text
/joint_states
/tf
/tf_static
/command
```

## 요청 message field

`topics/joint_states.jsonl`:

```text
timestamp
name
position
```

`topics/tf.jsonl`:

```text
timestamp
parent_frame_id
child_frame_id
translation
```

`topics/tf_static.jsonl`:

```text
parent_frame_id
child_frame_id
```

`topics/command.jsonl`:

```text
timestamp
target_position
frame_id
```

## Clean data 기대 조건

```text
joint_states.name은 expected joint_names와 정확히 일치해야 한다.
joint_states.position은 6D radian이어야 한다.
tf timestamp는 joint state timestamp와 정렬되어야 한다.
command timestamp는 joint state timestamp와 정렬되어야 한다.
tf_static이 있어야 한다.
required frame id에는 world, base_link, tool0가 포함되어야 한다.
base frame은 하나의 trajectory 안에서 drift하면 안 된다.
command target은 action이고 joint_states.position은 state여야 한다.
```

## 예상 rejection 예시

```text
/joint_states 누락
/tf 누락
/tf_static 누락
/command 누락
frame_id 누락
joint name 불일치
dimension 불일치
topic timestamp mismatch
base frame drift
threshold를 초과한 command/state lag
조작된 task_success field
```
