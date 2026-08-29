class_name MapTierConfig
extends Resource

@export var tier_id: StringName = &"small"
@export var display_name: String = "소형"
@export_range(0, 1000000000, 1) var entry_cost: int = 100
@export_range(1, 100, 1) var minimum_rooms: int = 5
@export_range(1, 100, 1) var maximum_rooms: int = 8
@export var minimum_room_size := Vector2i(6, 5)
@export var maximum_room_size := Vector2i(10, 8)


func is_valid() -> bool:
	return (
		entry_cost >= 0
		and minimum_rooms > 0
		and maximum_rooms >= minimum_rooms
		and minimum_room_size.x >= 3
		and minimum_room_size.y >= 3
		and maximum_room_size.x >= minimum_room_size.x
		and maximum_room_size.y >= minimum_room_size.y
	)
