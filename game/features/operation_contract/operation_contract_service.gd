class_name OperationContractService
extends Node

signal contract_changed(snapshot: Dictionary)
signal operation_invested(contract: Dictionary)

var profile: Node
var config: Resource
var selected_region_id: StringName = &"ruined_city"
var selected_difficulty_id: StringName = &"standard"
var active_contract: Dictionary = {}


func configure(profile_provider: Node, contract_config: Resource) -> bool:
	if (
		not is_instance_valid(profile_provider)
		or not profile_provider.has_method(&"spend")
		or contract_config == null
		or not contract_config.has_method(&"is_valid")
		or not contract_config.call(&"is_valid")
	):
		return false
	profile = profile_provider
	config = contract_config
	contract_changed.emit(get_snapshot())
	return true


func select_region(region_id: StringName) -> bool:
	var region: Dictionary = config.call(&"get_region", region_id)
	if region.is_empty():
		return false
	var unlock_id := StringName(region.get(&"unlock_id", &""))
	if unlock_id != &"" and not profile.call(&"is_unlocked", unlock_id):
		return false
	selected_region_id = region_id
	contract_changed.emit(get_snapshot())
	return true


func select_difficulty(difficulty_id: StringName) -> bool:
	if config.call(&"get_difficulty", difficulty_id).is_empty():
		return false
	selected_difficulty_id = difficulty_id
	contract_changed.emit(get_snapshot())
	return true


func cycle_region(direction: int = 1) -> Dictionary:
	var entries: Array = config.get("regions")
	var current_index := _find_index(entries, &"region_id", selected_region_id)
	for offset in range(1, entries.size() + 1):
		var index := posmod(current_index + offset * signi(direction), entries.size())
		if select_region(StringName(entries[index].get(&"region_id", &""))):
			return get_snapshot()
	return get_snapshot()


func cycle_difficulty(direction: int = 1) -> Dictionary:
	var entries: Array = config.get("difficulties")
	var current_index := _find_index(entries, &"difficulty_id", selected_difficulty_id)
	var index := posmod(current_index + signi(direction), entries.size())
	select_difficulty(StringName(entries[index].get(&"difficulty_id", &"")))
	return get_snapshot()


func quote(tier_config: Resource, penalty_snapshot: Dictionary = {}) -> Dictionary:
	if tier_config == null:
		return {}
	var region: Dictionary = config.call(&"get_region", selected_region_id)
	var difficulty: Dictionary = config.call(&"get_difficulty", selected_difficulty_id)
	var base_cost := int(tier_config.get("entry_cost"))
	var entry_cost := ceili(
		float(base_cost)
		* float(region.get(&"entry_cost_multiplier", 1.0))
		* float(difficulty.get(&"entry_cost_multiplier", 1.0))
	)
	return {
		&"region_id": selected_region_id,
		&"region_name": region.get(&"display_name", selected_region_id),
		&"difficulty_id": selected_difficulty_id,
		&"difficulty_name": difficulty.get(&"display_name", selected_difficulty_id),
		&"tier_id": tier_config.get("tier_id"),
		&"entry_cost": entry_cost,
		&"reward_multiplier": (
			float(region.get(&"reward_multiplier", 1.0))
			* float(difficulty.get(&"reward_multiplier", 1.0))
			* float(penalty_snapshot.get(&"reward_multiplier", 1.0))
		),
		&"enemy_modifiers": _combined_enemy_modifiers(
			difficulty.get(&"enemy_modifiers", {}),
			penalty_snapshot.get(&"enemy_modifiers", {})
		),
		&"blueprint_drop_multiplier": float(region.get(&"blueprint_drop_multiplier", 1.0)),
		&"penalty_ids": penalty_snapshot.get(&"selected_ids", []),
		&"ranking_condition_key": "%s|%s|%s|%s" % [
			selected_region_id,
			selected_difficulty_id,
			tier_config.get("tier_id"),
			",".join(PackedStringArray(penalty_snapshot.get(&"selected_ids", []))),
		],
	}


func invest(tier_config: Resource, penalty_snapshot: Dictionary = {}) -> Dictionary:
	var contract := quote(tier_config, penalty_snapshot)
	if contract.is_empty() or not profile.call(&"spend", int(contract[&"entry_cost"])):
		return {&"success": false, &"reason": "투입 크레딧 부족", &"quote": contract}
	active_contract = contract.duplicate(true)
	active_contract[&"success"] = true
	operation_invested.emit(active_contract.duplicate(true))
	return active_contract.duplicate(true)


func clear_active_contract() -> void:
	active_contract.clear()


func get_snapshot() -> Dictionary:
	var region: Dictionary = config.call(&"get_region", selected_region_id) if config != null else {}
	var difficulty: Dictionary = (
		config.call(&"get_difficulty", selected_difficulty_id) if config != null else {}
	)
	return {
		&"selected_region_id": selected_region_id,
		&"selected_region_name": region.get(&"display_name", selected_region_id),
		&"selected_difficulty_id": selected_difficulty_id,
		&"selected_difficulty_name": difficulty.get(&"display_name", selected_difficulty_id),
		&"active_contract": active_contract.duplicate(true),
	}


func _find_index(entries: Array, id_key: StringName, target_id: StringName) -> int:
	for index in entries.size():
		if StringName(entries[index].get(id_key, &"")) == target_id:
			return index
	return 0


func _combined_enemy_modifiers(first: Dictionary, second: Dictionary) -> Dictionary:
	var result := {
		&"health_multiplier": 1.0,
		&"armor_multiplier": 1.0,
		&"damage_multiplier": 1.0,
		&"speed_multiplier": 1.0,
	}
	for source in [first, second]:
		for key in result:
			result[key] = float(result[key]) * float(source.get(key, 1.0))
	return result
