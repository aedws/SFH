class_name RoomEncounterConfig
extends Resource

## 등급별 방 전투 수량과 방 클리어 크레딧 보상을 데이터로 관리합니다.

@export_category("Small")
@export_range(1, 100, 1) var small_minimum_enemies: int = 12
@export_range(1, 100, 1) var small_maximum_enemies: int = 18
@export_range(1, 100, 1) var small_maximum_encounters: int = 12
@export_range(1, 1000, 1) var small_reward_credit_minimum: int = 18
@export_range(1, 1000, 1) var small_reward_credit_maximum: int = 32

@export_category("Medium")
@export_range(1, 100, 1) var medium_minimum_enemies: int = 18
@export_range(1, 100, 1) var medium_maximum_enemies: int = 26
@export_range(1, 100, 1) var medium_maximum_encounters: int = 18
@export_range(1, 1000, 1) var medium_reward_credit_minimum: int = 28
@export_range(1, 1000, 1) var medium_reward_credit_maximum: int = 48

@export_category("Large")
@export_range(1, 100, 1) var large_minimum_enemies: int = 24
@export_range(1, 100, 1) var large_maximum_enemies: int = 34
@export_range(1, 100, 1) var large_maximum_encounters: int = 24
@export_range(1, 1000, 1) var large_reward_credit_minimum: int = 42
@export_range(1, 1000, 1) var large_reward_credit_maximum: int = 70

@export_category("Flow")
@export_range(0.0, 256.0, 4.0) var room_entry_inset: float = 48.0
@export var exclude_start_room: bool = true
@export var exclude_extraction_room: bool = true
@export var spawn_safety_policy: Resource

@export_category("Room clear reward boxes")
@export_range(1, 5, 1) var minimum_reward_boxes: int = 1
@export_range(1, 5, 1) var maximum_reward_boxes: int = 5
@export_range(0, 2, 1) var random_box_variance: int = 1


func values_for(tier_id: StringName) -> Dictionary:
	match tier_id:
		&"medium":
			return {
				&"minimum_enemies": medium_minimum_enemies,
				&"maximum_enemies": medium_maximum_enemies,
				&"maximum_encounters": medium_maximum_encounters,
				&"reward_credit_minimum": medium_reward_credit_minimum,
				&"reward_credit_maximum": medium_reward_credit_maximum,
			}
		&"large":
			return {
				&"minimum_enemies": large_minimum_enemies,
				&"maximum_enemies": large_maximum_enemies,
				&"maximum_encounters": large_maximum_encounters,
				&"reward_credit_minimum": large_reward_credit_minimum,
				&"reward_credit_maximum": large_reward_credit_maximum,
			}
		_:
			return {
				&"minimum_enemies": small_minimum_enemies,
				&"maximum_enemies": small_maximum_enemies,
				&"maximum_encounters": small_maximum_encounters,
				&"reward_credit_minimum": small_reward_credit_minimum,
				&"reward_credit_maximum": small_reward_credit_maximum,
			}


func is_valid() -> bool:
	for tier_id in [&"small", &"medium", &"large"]:
		var values := values_for(tier_id)
		if (
			int(values[&"minimum_enemies"]) <= 0
			or int(values[&"maximum_enemies"]) < int(values[&"minimum_enemies"])
			or int(values[&"maximum_encounters"]) <= 0
			or int(values[&"reward_credit_minimum"]) <= 0
			or int(values[&"reward_credit_maximum"]) < int(values[&"reward_credit_minimum"])
		):
			return false
	return (
		room_entry_inset >= 0.0
		and spawn_safety_policy != null
		and spawn_safety_policy.has_method(&"is_valid")
		and bool(spawn_safety_policy.call(&"is_valid"))
		and minimum_reward_boxes >= 1
		and maximum_reward_boxes >= minimum_reward_boxes
	)
