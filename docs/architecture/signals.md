# Signal 규칙

Signal은 모듈 사이의 사건 전달에 사용합니다.

## 이름 규칙

Signal 이름은 이미 발생한 사건처럼 작성합니다.

```gdscript
signal health_changed(current: float, maximum: float)
signal operation_requested
signal enemy_defeated(enemy_id: StringName)
signal experience_collected(amount: int)
signal buff_selected(buff_id: StringName, stacks: int)
signal run_settled(result: Dictionary)
signal upgrade_completed(result: Dictionary)
signal growth_balance_updated(snapshot: Dictionary, source_label: String)
signal recovery_state_changed(snapshot: Dictionary)
signal reinforcement_dispatched(spawned_count: int, active_count: int, target_count: int)
signal spawn_budget_exhausted(total_spawned: int, maximum_total_spawns: int)
signal encounter_started(room_index: int, enemy_count: int)
signal doors_locked(room_index: int, door_count: int)
signal encounter_cleared(room_index: int)
signal reward_collected(room_index: int, experience_amount: int)
signal skill_states_changed(states: Array[Dictionary])
signal skill_activated(slot_index: int, skill_id: StringName, result: Dictionary)
```

## 사용 기준

- 직접 반환값이 필요한 호출에는 메서드를 사용합니다.
- 여러 대상이 알아야 하는 사건에는 Signal을 사용합니다.
- 매 프레임 발생하는 이동처럼 빈도가 매우 높은 내부 처리는 같은 기능 안에서 직접 호출합니다.
- 전역 이벤트 버스는 의존성을 숨길 수 있으므로 필요성이 검증되기 전에는 만들지 않습니다.
