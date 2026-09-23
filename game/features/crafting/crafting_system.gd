class_name CraftingSystem
extends Node

signal item_crafted(result: Dictionary)

var profile: Node
var config: Resource
var random := RandomNumberGenerator.new()
var supply_policy := EquipmentSupplyPolicy.hub_default()


func configure(profile_provider: Node, crafting_config: Resource, seed: int = 0) -> bool:
	if (
		not is_instance_valid(profile_provider)
		or not profile_provider.has_method(&"consume_blueprint")
		or crafting_config == null
		or not crafting_config.call(&"is_valid")
	):
		return false
	profile = profile_provider
	config = crafting_config
	random.seed = seed if seed != 0 else Time.get_ticks_usec()
	return true


func quote(blueprint_id: StringName) -> Dictionary:
	var recipe: Dictionary = config.call(&"get_recipe", blueprint_id) if config != null else {}
	if recipe.is_empty():
		return {&"craftable": false, &"reason": "등록되지 않은 도면"}
	var supply := supply_policy.recipe_preview(recipe)
	if not supply.valid: return {&"craftable": false, &"reason": supply.reason}
	if not supply_policy.affixes_allowed(config.get("affixes")):
		return {&"craftable": false, &"reason": "거점 제작은 기본 수치 옵션만 허용"}
	var profile_snapshot: Dictionary = profile.call(&"get_snapshot")
	var required_materials: Dictionary = recipe.get(&"materials", {})
	var has_materials := true
	for item_id in required_materials:
		if not profile.call(&"has_warehouse_item", item_id, int(required_materials[item_id])):
			has_materials = false
	return {
		&"craftable": (
			int(profile_snapshot.get(&"blueprints", {}).get(blueprint_id, 0)) > 0
			and has_materials
			and profile.call(&"can_spend", int(recipe.get(&"credit_cost", 0)))
		),
		&"recipe": recipe,
		&"supply": supply,
	}


func craft(blueprint_id: StringName) -> Dictionary:
	var craft_quote := quote(blueprint_id)
	if not bool(craft_quote.get(&"craftable", false)):
		return {&"success": false, &"reason": craft_quote.get(&"reason", "재료 또는 크레딧 부족")}
	var recipe: Dictionary = craft_quote[&"recipe"]
	if not profile.call(&"spend", int(recipe.get(&"credit_cost", 0))):
		return {&"success": false, &"reason": "크레딧 부족"}
	if not profile.call(&"consume_blueprint", blueprint_id):
		profile.call(&"add_credits", int(recipe.get(&"credit_cost", 0)))
		return {&"success": false, &"reason": "도면 부족"}
	for item_id in recipe.get(&"materials", {}):
		profile.call(&"take_warehouse_item", item_id, int(recipe[&"materials"][item_id]))
	var rolled_affixes := _roll_affixes(
		int(recipe.get(&"minimum_affixes", 1)),
		int(recipe.get(&"maximum_affixes", 2))
	)
	var item := {
		&"instance_id": "crafted_%d_%d" % [Time.get_ticks_msec(), random.randi()],
		&"definition_id": recipe.get(&"result_id", &""),
		&"display_name": recipe.get(&"display_name", "제작 장비"),
		&"affixes": rolled_affixes,
		&"grade": craft_quote.supply.grade,
		&"supply_source": &"hub",
	}
	var sockets: Array[Dictionary] = []
	for index in random.randi_range(craft_quote.supply.minimum_sockets, craft_quote.supply.maximum_sockets):
		sockets.append({&"slot_index": index, &"state": &"empty"})
	item[&"sockets"] = sockets
	item[&"socket_count"] = sockets.size()
	profile.call(&"add_crafted_item", item)
	var result := {&"success": true, &"item": item, &"affix_count": rolled_affixes.size()}
	item_crafted.emit(result)
	return result


func _roll_affixes(minimum: int, maximum: int) -> Array[Dictionary]:
	var pool: Array = config.get("affixes").duplicate(true)
	var count := mini(pool.size(), random.randi_range(minimum, maximum))
	var result: Array[Dictionary] = []
	for _index in count:
		var total_weight := 0.0
		for entry in pool:
			total_weight += float(entry.get(&"weight", 1.0))
		var roll := random.randf() * total_weight
		var selected_index := 0
		for index in pool.size():
			roll -= float(pool[index].get(&"weight", 1.0))
			if roll <= 0.0:
				selected_index = index
				break
		var selected: Dictionary = pool.pop_at(selected_index)
		var minimum_value := float(selected.get(&"minimum_value", 0.0))
		var maximum_value := float(selected.get(&"maximum_value", minimum_value))
		selected[&"rolled_value"] = snappedf(
			random.randf_range(minimum_value, maximum_value), 0.001
		)
		result.append(selected)
	return result
