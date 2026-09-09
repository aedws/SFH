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
	config = contract_config.duplicate(true)
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
	var entries: Array = config.call(&"get_difficulties")
	var current_index := _find_index(entries, &"difficulty_id", selected_difficulty_id)
	var index := posmod(current_index + signi(direction), entries.size())
	select_difficulty(StringName(entries[index].get(&"difficulty_id", &"")))
	return get_snapshot()


func quote(
	tier_config: Resource,
	penalty_snapshot: Dictionary = {},
	investment_context: Dictionary = {}
) -> Dictionary:
	if tier_config == null:
		return {}
	var region: Dictionary = config.call(&"get_region", selected_region_id)
	var difficulty: Dictionary = config.call(&"get_difficulty", selected_difficulty_id)
	var base_cost := int(tier_config.get("entry_cost"))
	var base_entry_cost := ceili(
		float(base_cost)
		* float(region.get(&"entry_cost_multiplier", 1.0))
		* float(difficulty.get(&"entry_cost_multiplier", 1.0))
	)
	var additional_entry_cost := maxi(0, int(investment_context.get(&"additional_entry_cost", 0)))
	var entry_cost := base_entry_cost + additional_entry_cost
	var bankruptcy_protection := (
		bool(config.get("bankruptcy_protection_enabled"))
		and StringName(tier_config.get("tier_id")) == StringName(config.get("free_tier_id"))
		and selected_region_id == StringName(config.get("free_region_id"))
		and selected_difficulty_id == StringName(config.get("free_difficulty_id"))
		and additional_entry_cost == 0
		and not bool(profile.call(&"can_spend", entry_cost))
	)
	if bankruptcy_protection:
		entry_cost = 0
	var boss_guaranteed := (
		entry_cost >= int(config.get("boss_guarantee_minimum_cost"))
		or bool(region.get(&"boss_guaranteed", false))
		or bool(difficulty.get(&"boss_guaranteed", false))
	)
	var penalty_score := int(penalty_snapshot.get(&"penalty_score", 0))
	return {
		&"region_id": selected_region_id,
		&"region_name": region.get(&"display_name", selected_region_id),
		&"difficulty_id": selected_difficulty_id,
		&"difficulty_name": difficulty.get(&"display_name", selected_difficulty_id),
		&"difficulty_level": difficulty.get(&"level",1),
		&"map_geometry": difficulty.get(&"map_geometry",{}).duplicate(true),
		&"loot_difficulty_id": difficulty.get(&"loot_band",selected_difficulty_id),
		&"tier_id": tier_config.get("tier_id"),
		&"entry_cost": entry_cost,
		&"base_entry_cost": base_entry_cost,
		&"additional_entry_cost": additional_entry_cost,
		&"investment_context": investment_context.duplicate(true),
		&"bankruptcy_protection": bankruptcy_protection,
		&"boss_spawn_guaranteed": boss_guaranteed,
		&"high_grade_drop_multiplier": (
			float(region.get(&"high_grade_drop_multiplier", 1.0))
			* float(difficulty.get(&"high_grade_drop_multiplier", 1.0))
			* (1.0 + float(entry_cost) / 1500.0)
		),
		&"region_drop_table": config.call(&"get_region_drop_table", selected_region_id),
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
		&"penalty_score": penalty_score,
		&"player_modifiers": penalty_snapshot.get(&"player_modifiers", {}),
		&"world_modifiers": penalty_snapshot.get(&"world_modifiers", {}),
		&"ranking_condition_key": "%s|%s|%s" % [
			selected_region_id,
			selected_difficulty_id,
			tier_config.get("tier_id"),
		],
	}


func invest(
	tier_config: Resource,
	penalty_snapshot: Dictionary = {},
	investment_context: Dictionary = {}
) -> Dictionary:
	var contract := quote(tier_config, penalty_snapshot, investment_context)
	if contract.is_empty() or not profile.call(&"spend", int(contract[&"entry_cost"])):
		return {&"success": false, &"reason": "투입 크레딧 부족", &"quote": contract}
	active_contract = contract.duplicate(true)
	active_contract[&"success"] = true
	operation_invested.emit(active_contract.duplicate(true))
	return active_contract.duplicate(true)


func clear_active_contract() -> void:
	active_contract.clear()

func set_difficulty_rows(rows: Array[Dictionary]) -> void:
	if config == null: return
	config.call(&"set_difficulty_rows",rows)
	contract_changed.emit(get_snapshot())


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
