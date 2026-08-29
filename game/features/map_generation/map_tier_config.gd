class_name MapTierConfig
extends Resource

@export var tier_id: StringName = &"small"
@export var display_name: String = "소형"
@export_range(0, 1000000000, 1) var entry_cost: int = 100
@export_range(1, 100, 1) var minimum_rooms: int = 5
@export_range(1, 100, 1) var maximum_rooms: int = 8
@export var minimum_room_size := Vector2i(6, 5)
@export var maximum_room_size := Vector2i(10, 8)
@export_range(0.0, 0.2, 0.001) var obstacle_density: float = 0.02
@export_range(60, 3600, 30) var target_run_duration_seconds: int = 600
@export_range(0, 3600, 30) var extraction_unlock_seconds: int = 600


func is_valid() -> bool:
	return (
		entry_cost >= 0
		and minimum_rooms > 0
		and maximum_rooms >= minimum_rooms
		and minimum_room_size.x >= 3
		and minimum_room_size.y >= 3
		and maximum_room_size.x >= minimum_room_size.x
		and maximum_room_size.y >= minimum_room_size.y
		and obstacle_density >= 0.0
		and obstacle_density <= 0.2
		and target_run_duration_seconds >= 60
		and extraction_unlock_seconds >= 0
		and extraction_unlock_seconds <= target_run_duration_seconds
	)
