class_name PenaltySystem
extends Node

signal selection_changed(snapshot: Dictionary)

var config: Resource
var selected_ids: Array[StringName] = []


func configure(penalty_config: Resource) -> bool:
	if penalty_config == null or not penalty_config.call(&"is_valid"):
		return false
	config = penalty_config
	selected_ids.clear()
	return true


func toggle(modifier_id: StringName) -> bool:
	if config.call(&"get_modifier", modifier_id).is_empty():
		return false
	if modifier_id in selected_ids:
		selected_ids.erase(modifier_id)
	elif selected_ids.size() < int(config.get("maximum_selected")):
		selected_ids.append(modifier_id)
	else:
		return false
	selection_changed.emit(get_snapshot())
	return true


func cycle_single() -> Dictionary:
	var entries: Array = config.get("modifiers")
	var next_index := 0
	if not selected_ids.is_empty():
		for index in entries.size():
			if StringName(entries[index].get(&"modifier_id", &"")) == selected_ids[0]:
				next_index = index + 1
				break
	selected_ids.clear()
	if next_index < entries.size():
		selected_ids.append(StringName(entries[next_index].get(&"modifier_id", &"")))
	selection_changed.emit(get_snapshot())
	return get_snapshot()


func get_snapshot() -> Dictionary:
	var reward_multiplier := 1.0
	var enemy_modifiers := {
		&"health_multiplier": 1.0, &"armor_multiplier": 1.0,
		&"damage_multiplier": 1.0, &"speed_multiplier": 1.0,
	}
	var names := PackedStringArray()
	var penalty_score := 0
	var player_modifiers := {&"recovery_multiplier": 1.0}
	var world_modifiers := {&"vision_multiplier": 1.0, &"extraction_duration_multiplier": 1.0}
	for modifier_id in selected_ids:
		var modifier: Dictionary = config.call(&"get_modifier", modifier_id)
		names.append(String(modifier.get(&"display_name", modifier_id)))
		reward_multiplier *= float(modifier.get(&"reward_multiplier", 1.0))
		penalty_score += int(modifier.get(&"penalty_score", 0))
		var source: Dictionary = modifier.get(&"enemy_modifiers", {})
		for key in enemy_modifiers:
			enemy_modifiers[key] = float(enemy_modifiers[key]) * float(source.get(key, 1.0))
		var player_source: Dictionary = modifier.get(&"player_modifiers", {})
		for key in player_modifiers:
			player_modifiers[key] = float(player_modifiers[key]) * float(player_source.get(key, 1.0))
		var world_source: Dictionary = modifier.get(&"world_modifiers", {})
		for key in world_modifiers:
			world_modifiers[key] = float(world_modifiers[key]) * float(world_source.get(key, 1.0))
	return {
		&"selected_ids": selected_ids.duplicate(),
		&"display_names": names,
		&"reward_multiplier": reward_multiplier,
		&"enemy_modifiers": enemy_modifiers,
		&"penalty_score": penalty_score,
		&"player_modifiers": player_modifiers,
		&"world_modifiers": world_modifiers,
	}
