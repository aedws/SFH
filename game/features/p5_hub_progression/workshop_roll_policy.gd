class_name WorkshopRollPolicy
extends Resource

@export var instance_prefix := "p7_crafted"
@export_range(1, 1000000, 1) var seed_stride := 7049
@export_range(0, 16, 1) var maximum_socket_limit := 8
@export var affix_pool: Array[Dictionary] = []
@export var supply_policy: EquipmentSupplyPolicy = EquipmentSupplyPolicy.hub_default()

func get_supply_policy() -> EquipmentSupplyPolicy:
	return supply_policy


func is_valid() -> bool:
	if instance_prefix.is_empty() or seed_stride <= 0 or affix_pool.is_empty():
		return false
	var ids: Array[StringName] = []
	for affix in affix_pool:
		var affix_id := StringName(affix.get(&"affix_id", &""))
		if (
			affix_id == &""
			or affix_id in ids
			or StringName(affix.get(&"stat_id", &"")) == &""
			or float(affix.get(&"weight", 0.0)) <= 0.0
			or float(affix.get(&"minimum_value", 0.0)) > float(affix.get(&"maximum_value", 0.0))
		):
			return false
		ids.append(affix_id)
	return true


func describe(recipe: Dictionary) -> Dictionary:
	var supply := supply_policy.recipe_preview(recipe) if supply_policy != null else {&"valid": false}
	var minimum_affixes := int(recipe.get(&"minimum_affixes", 0))
	var maximum_affixes := int(recipe.get(&"maximum_affixes", minimum_affixes))
	var minimum_sockets := int(recipe.get(&"minimum_sockets", 0))
	var maximum_sockets := int(recipe.get(&"maximum_sockets", minimum_sockets))
	var valid := (
		is_valid()
		and bool(supply.get(&"valid", false))
		and supply_policy.affixes_allowed(affix_pool)
		and StringName(recipe.get(&"result_id", &"")) != &""
		and minimum_affixes >= 0
		and maximum_affixes >= minimum_affixes
		and maximum_affixes <= affix_pool.size()
		and minimum_sockets >= 0
		and maximum_sockets >= minimum_sockets
		and maximum_sockets <= maximum_socket_limit
	)
	return {
		&"valid": valid,
		&"minimum_affixes": minimum_affixes,
		&"maximum_affixes": maximum_affixes,
		&"minimum_sockets": supply.get(&"minimum_sockets", minimum_sockets),
		&"maximum_sockets": supply.get(&"maximum_sockets", maximum_sockets),
		&"grade": supply.get(&"grade", 1),
		&"supply_policy": supply.get(&"supply_policy", ""),
		&"reason": supply.get(&"reason", "공급 정책 오류"),
		&"affix_pool_size": affix_pool.size(),
		&"source_status": String(recipe.get(&"source_status", "provisional")),
	}


func roll(recipe: Dictionary, recipe_id: StringName, transaction_id: StringName,
		session_seed: int) -> Dictionary:
	var preview := describe(recipe)
	if not bool(preview.get(&"valid", false)) or transaction_id == &"":
		return {}
	var random := RandomNumberGenerator.new()
	var stable_hash := absi(String("%s|%s" % [recipe_id, transaction_id]).hash())
	random.seed = (session_seed if session_seed != 0 else 70404) + stable_hash * seed_stride
	var affix_count := random.randi_range(
		int(preview[&"minimum_affixes"]), int(preview[&"maximum_affixes"])
	)
	var socket_count := random.randi_range(
		int(preview[&"minimum_sockets"]), int(preview[&"maximum_sockets"])
	)
	var sockets: Array[Dictionary] = []
	for index in socket_count:
		sockets.append({&"slot_index": index, &"state": &"empty"})
	return {
		&"instance_id": StringName("%s_%d" % [instance_prefix, stable_hash]),
		&"grade": preview.get(&"grade", 1),
		&"supply_source": &"hub",
		&"definition_id": StringName(recipe.get(&"result_id", &"")),
		&"display_name": String(recipe.get(&"display_name", "제작 장비")),
		&"recipe_id": recipe_id,
		&"affixes": _roll_affixes(affix_count, random),
		&"affix_count": affix_count,
		&"sockets": sockets,
		&"socket_count": socket_count,
		&"roll_seed": random.seed,
		&"source_status": preview.get(&"source_status", "provisional"),
	}


func _roll_affixes(count: int, random: RandomNumberGenerator) -> Array[Dictionary]:
	var pool := affix_pool.duplicate(true)
	var result: Array[Dictionary] = []
	for _index in mini(count, pool.size()):
		var total_weight := 0.0
		for candidate in pool:
			total_weight += float(candidate.get(&"weight", 1.0))
		var roll_value := random.randf() * total_weight
		var selected_index := 0
		for index in pool.size():
			roll_value -= float(pool[index].get(&"weight", 1.0))
			if roll_value <= 0.0:
				selected_index = index
				break
		var selected: Dictionary = pool.pop_at(selected_index)
		var minimum_value := float(selected.get(&"minimum_value", 0.0))
		var maximum_value := float(selected.get(&"maximum_value", minimum_value))
		result.append({
			&"affix_id": StringName(selected.get(&"affix_id", &"")),
			&"display_name": String(selected.get(&"display_name", "옵션")),
			&"stat_id": StringName(selected.get(&"stat_id", &"")),
			&"rolled_value": snappedf(random.randf_range(minimum_value, maximum_value), 0.001),
		})
	return result
