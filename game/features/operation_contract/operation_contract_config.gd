class_name OperationContractConfig
extends Resource

@export var regions: Array[Dictionary] = []
@export var difficulties: Array[Dictionary] = []
@export var ten_level_difficulty := false
var difficulty_rows: Array[Dictionary] = []
@export_range(0, 1000000, 1) var boss_guarantee_minimum_cost: int = 600
@export var bankruptcy_protection_enabled: bool = true
@export var free_tier_id: StringName = &"small"
@export var free_region_id: StringName = &"ruined_city"
@export var free_difficulty_id: StringName = &"standard"


func is_valid() -> bool:
	return _entries_are_valid(regions, &"region_id") and _entries_are_valid(
		get_difficulties(), &"difficulty_id"
	)


func get_region(region_id: StringName) -> Dictionary:
	return _find(regions, &"region_id", region_id)


func get_difficulty(difficulty_id: StringName) -> Dictionary:
	return _find(get_difficulties(), &"difficulty_id", difficulty_id)

func get_difficulties() -> Array[Dictionary]:
	if not ten_level_difficulty: return difficulties.duplicate(true)
	if difficulty_rows.is_empty(): difficulty_rows=preload("res://game/features/operation_contract/difficulty_catalog.gd").new().get_rows()
	return difficulty_rows.duplicate(true)

func set_difficulty_rows(rows: Array[Dictionary]) -> void:
	difficulty_rows=rows.duplicate(true)


func get_region_drop_table(region_id: StringName) -> Array[Dictionary]:
	var region := get_region(region_id)
	return (region.get(&"drop_table", []) as Array[Dictionary]).duplicate(true)


func _entries_are_valid(entries: Array[Dictionary], id_key: StringName) -> bool:
	var ids := {}
	for entry in entries:
		var entry_id := StringName(entry.get(id_key, &""))
		if entry_id == &"" or ids.has(entry_id):
			return false
		ids[entry_id] = true
	return not entries.is_empty()


func _find(entries: Array[Dictionary], id_key: StringName, target_id: StringName) -> Dictionary:
	for entry in entries:
		if StringName(entry.get(id_key, &"")) == target_id:
			return entry.duplicate(true)
	return {}
