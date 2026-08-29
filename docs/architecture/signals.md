# Signal 규칙

Signal은 모듈 사이의 사건 전달에 사용합니다.

## 이름 규칙

Signal 이름은 이미 발생한 사건처럼 작성합니다.

```gdscript
signal health_changed(current: float, maximum: float)
signal enemy_defeated(enemy_id: StringName)
signal experience_collected(amount: int)
signal buff_selected(buff_id: StringName, stacks: int)
signal run_settled(result: Dictionary)
signal upgrade_completed(result: Dictionary)
```

## 사용 기준

- 직접 반환값이 필요한 호출에는 메서드를 사용합니다.
- 여러 대상이 알아야 하는 사건에는 Signal을 사용합니다.
- 매 프레임 발생하는 이동처럼 빈도가 매우 높은 내부 처리는 같은 기능 안에서 직접 호출합니다.
- 전역 이벤트 버스는 의존성을 숨길 수 있으므로 필요성이 검증되기 전에는 만들지 않습니다.
