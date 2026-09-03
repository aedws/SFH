class_name FieldLootSpawnPolicy
extends Resource
## A rotating category guarantee makes a complete run exercise all gear systems.
@export var room_categories := PackedStringArray(["weapon", "armor", "module", "part"])
@export_range(0.0, 1.0) var enemy_drop_chance := 0.12
@export_range(1, 128) var maximum_world_drops := 48
@export_range(1, 8) var boss_drop_count := 2


func room_category(cleared_count: int) -> StringName:
	return StringName(room_categories[posmod(cleared_count, room_categories.size())]) if not room_categories.is_empty() else &""
