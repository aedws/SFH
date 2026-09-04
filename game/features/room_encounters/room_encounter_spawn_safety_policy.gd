class_name RoomEncounterSpawnSafetyPolicy
extends Resource

## 방 진입 직후 대규모 스폰의 공정성만 소유하는 교체 가능한 정책입니다.
## 적 수량, AI, 피해 계산에는 관여하지 않습니다.

@export_range(64.0, 1024.0, 8.0) var minimum_player_distance := 288.0
@export_range(0.0, 5.0, 0.1) var contact_damage_grace_seconds := 1.6
@export_range(0.1, 1.0, 0.05) var telegraph_alpha := 0.55


func is_valid() -> bool:
	return (
		minimum_player_distance >= 64.0
		and contact_damage_grace_seconds >= 0.0
		and telegraph_alpha > 0.0
		and telegraph_alpha <= 1.0
	)


func get_snapshot() -> Dictionary:
	return {
		&"minimum_player_distance": minimum_player_distance,
		&"contact_damage_grace_seconds": contact_damage_grace_seconds,
		&"telegraph_alpha": telegraph_alpha,
	}
