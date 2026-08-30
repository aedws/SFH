class_name OperationContractConfig
extends Resource

@export var regions: Array[Dictionary] = []
@export var difficulties: Array[Dictionary] = []


func is_valid() -> bool:
	return _entries_are_valid(regions, &"region_id") and _entries_are_valid(
		difficulties, &"difficulty_id"
	)


func get_region(region_id: StringName) -> Dictionary:
	return _find(regions, &"region_id", region_id)


func get_difficulty(difficulty_id: StringName) -> Dictionary:
	return _find(difficulties, &"difficulty_id", difficulty_id)


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
