class_name WorkshopService
extends RefCounted

const BLUEPRINT_REGISTRY := preload("res://game/features/p5_hub_progression/blueprint_registry.gd")
const RECIPE_PROVIDER := preload("res://game/features/p5_hub_progression/workshop_recipe_provider.gd")
const UNLOCK_SERVICE := preload("res://game/features/p5_hub_progression/workshop_unlock_service.gd")

var profile: Node
var random := RandomNumberGenerator.new()
var blueprint_registry = BLUEPRINT_REGISTRY.new()
var recipe_provider = RECIPE_PROVIDER.new()
var unlock_service = UNLOCK_SERVICE.new()


func configure(profile_provider: Node, rows: Array[Dictionary], seed: int) -> bool:
	profile = profile_provider
	blueprint_registry = BLUEPRINT_REGISTRY.new()
	recipe_provider = RECIPE_PROVIDER.new()
	unlock_service = UNLOCK_SERVICE.new()
	random.seed = seed if seed != 0 else 50808
	return (
		is_instance_valid(profile)
		and bool(blueprint_registry.call(&"configure", profile))
		and bool(recipe_provider.call(&"configure", rows))
		and bool(unlock_service.call(&"configure", blueprint_registry, recipe_provider))
	)


func register_extracted_blueprints(acquired: Dictionary) -> PackedStringArray:
	return unlock_service.call(&"register_extracted_blueprints", acquired)


func get_candidates() -> Array[Dictionary]:
	return unlock_service.call(&"get_candidates")


func quote(recipe_id: StringName) -> Dictionary:
	var recipe: Dictionary = recipe_provider.call(&"get_recipe", recipe_id)
	if recipe.is_empty():
		return {&"craftable": false, &"reason": "제작법 없음"}
	var blueprint_id := StringName(recipe.get(&"blueprint_id", &""))
	if bool(recipe.get(&"required_registration", true)) and not bool(blueprint_registry.call(&"is_registered", blueprint_id)):
		return {&"craftable": false, &"reason": "영구 등록 도면 필요", &"recipe": recipe}
	var materials := _parse_pairs(String(recipe.get(&"materials", "")))
	var craftable := bool(profile.call(&"can_spend", int(recipe.get(&"credit_cost", 0))))
	for item_id in materials:
		craftable = craftable and bool(profile.call(&"has_warehouse_item", item_id, int(materials[item_id])))
	return {&"craftable": craftable, &"reason": "" if craftable else "재료 또는 크레딧 부족",
		&"recipe": recipe, &"materials": materials}


func craft(recipe_id: StringName, transaction_id: StringName) -> Dictionary:
	var draft := quote(recipe_id)
	if not bool(draft.get(&"craftable", false)):
		return {&"success": false, &"reason": draft.get(&"reason", "제작 불가")}
	if transaction_id == &"" or bool(profile.call(&"has_processed_transaction", transaction_id)):
		return {&"success": false, &"reason": "중복 제작"}
	var recipe: Dictionary = draft[&"recipe"]
	var cost := int(recipe.get(&"credit_cost", 0))
	if not bool(profile.call(&"spend", cost)):
		return {&"success": false, &"reason": "크레딧 부족"}
	var consumed: Dictionary = {}
	for item_id in draft[&"materials"]:
		var quantity := int(draft[&"materials"][item_id])
		if not bool(profile.call(&"take_warehouse_item", item_id, quantity)):
			for rollback_id in consumed:
				profile.call(&"add_warehouse_item", rollback_id, consumed[rollback_id])
			profile.call(&"add_credits", cost)
			return {&"success": false, &"reason": "재료 차감 실패"}
		consumed[item_id] = quantity
	var minimum_affixes := int(recipe.get(&"minimum_affixes", 0))
	var maximum_affixes := maxi(minimum_affixes, int(recipe.get(&"maximum_affixes", minimum_affixes)))
	var minimum_sockets := int(recipe.get(&"minimum_sockets", 0))
	var maximum_sockets := maxi(minimum_sockets, int(recipe.get(&"maximum_sockets", minimum_sockets)))
	var item := {&"instance_id": "p5_%d_%d" % [Time.get_ticks_usec(), random.randi()],
		&"definition_id": recipe.get(&"result_id", &""),
		&"affix_count": random.randi_range(minimum_affixes, maximum_affixes),
		&"socket_count": random.randi_range(minimum_sockets, maximum_sockets),
		&"recipe_id": recipe_id}
	if int(profile.call(&"add_crafted_item", item)) < 0:
		_rollback_consumption(consumed, cost)
		return {&"success": false, &"reason": "제작 결과 지급 실패"}
	if not bool(profile.call(&"mark_transaction_processed", transaction_id)):
		profile.call(&"remove_crafted_item", StringName(item[&"instance_id"]))
		_rollback_consumption(consumed, cost)
		return {&"success": false, &"reason": "제작 거래 기록 실패"}
	return {&"success": true, &"item": item, &"consumed": consumed, &"credit_cost": cost}


func _rollback_consumption(consumed: Dictionary, cost: int) -> void:
	for item_id in consumed:
		profile.call(&"add_warehouse_item", item_id, consumed[item_id])
	profile.call(&"add_credits", cost)


func get_snapshot() -> Dictionary:
	var result: Dictionary = unlock_service.call(&"get_snapshot")
	result.merge(recipe_provider.call(&"get_snapshot"), true)
	return result


func _parse_pairs(text: String) -> Dictionary:
	var result := {}
	for pair in text.split("|", false):
		var parts := pair.split(":", false, 1)
		if parts.size() == 2:
			result[StringName(parts[0].strip_edges())] = maxi(0, parts[1].to_int())
	return result
