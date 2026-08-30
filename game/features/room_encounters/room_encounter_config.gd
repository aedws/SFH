class_name RoomEncounterConfig
extends Resource

## 등급별 방 전투 수량과 보상을 데이터로 관리합니다.

@export_category("Small")
@export_range(1, 100, 1) var small_minimum_enemies: int = 6
@export_range(1, 100, 1) var small_maximum_enemies: int = 8
@export_range(1, 100, 1) var small_maximum_encounters: int = 12
@export_range(1, 1000, 1) var small_reward_experience: int = 4

@export_category("Medium")
@export_range(1, 100, 1) var medium_minimum_enemies: int = 8
@export_range(1, 100, 1) var medium_maximum_enemies: int = 11
@export_range(1, 100, 1) var medium_maximum_encounters: int = 18
@export_range(1, 1000, 1) var medium_reward_experience: int = 6

@export_category("Large")
@export_range(1, 100, 1) var large_minimum_enemies: int = 10
@export_range(1, 100, 1) var large_maximum_enemies: int = 14
@export_range(1, 100, 1) var large_maximum_encounters: int = 24
@export_range(1, 1000, 1) var large_reward_experience: int = 8

@export_category("Flow")
@export_range(0.0, 256.0, 4.0) var room_entry_inset: float = 48.0
@export var exclude_start_room: bool = true
@export var exclude_extraction_room: bool = true


func values_for(tier_id: StringName) -> Dictionary:
	match tier_id:
		&"medium":
			return {
				&"minimum_enemies": medium_minimum_enemies,
				&"maximum_enemies": medium_maximum_enemies,
				&"maximum_encounters": medium_maximum_encounters,
				&"reward_experience": medium_reward_experience,
			}
		&"large":
			return {
				&"minimum_enemies": large_minimum_enemies,
				&"maximum_enemies": large_maximum_enemies,
				&"maximum_encounters": large_maximum_encounters,
				&"reward_experience": large_reward_experience,
			}
		_:
			return {
				&"minimum_enemies": small_minimum_enemies,
				&"maximum_enemies": small_maximum_enemies,
				&"maximum_encounters": small_maximum_encounters,
				&"reward_experience": small_reward_experience,
			}


func is_valid() -> bool:
	for tier_id in [&"small", &"medium", &"large"]:
		var values := values_for(tier_id)
		if (
			int(values[&"minimum_enemies"]) <= 0
			or int(values[&"maximum_enemies"]) < int(values[&"minimum_enemies"])
			or int(values[&"maximum_encounters"]) <= 0
			or int(values[&"reward_experience"]) <= 0
		):
			return false
	return room_entry_inset >= 0.0
