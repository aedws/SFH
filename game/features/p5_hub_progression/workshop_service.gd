class_name WorkshopService
extends RefCounted

var profile: Node
var recipes: Array[Dictionary] = []
var random := RandomNumberGenerator.new()


func configure(profile_provider: Node, rows: Array[Dictionary], seed: int) -> bool:
	profile = profile_provider
	recipes = rows.duplicate(true)
	random.seed = seed if seed != 0 else 50808
	return is_instance_valid(profile) and not recipes.is_empty()


func register_extracted_blueprints(acquired: Dictionary) -> PackedStringArray:
	var registered := PackedStringArray()
	for recipe in recipes:
		var blueprint_id := StringName(recipe.get(&"blueprint_id", &""))
		if _quantity_of(acquired.get(blueprint_id, 0)) > 0 and bool(profile.call(&"register_blueprint", blueprint_id)):
			registered.append(String(blueprint_id))
	return registered


func _quantity_of(value: Variant) -> int:
	if value is Dictionary:
		return maxi(0, int((value as Dictionary).get(&"quantity", 0)))
	if value is int or value is float:
		return maxi(0, int(value))
	return 0


func quote(recipe_id: StringName) -> Dictionary:
	var recipe := _find(recipe_id)
	if recipe.is_empty():
		return {&"craftable": false, &"reason": "제작법 없음"}
	var blueprint_id := StringName(recipe.get(&"blueprint_id", &""))
	if bool(recipe.get(&"required_registration", true)) and not bool(profile.call(&"is_blueprint_registered", blueprint_id)):
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
	profile.call(&"add_crafted_item", item)
	profile.call(&"mark_transaction_processed", transaction_id)
	return {&"success": true, &"item": item, &"consumed": consumed, &"credit_cost": cost}


func get_snapshot() -> Dictionary:
	return {&"recipe_count": recipes.size(), &"registered_blueprints": profile.call(&"get_snapshot").get(&"registered_blueprint_ids", [])}


func _find(recipe_id: StringName) -> Dictionary:
	for recipe in recipes:
		if StringName(recipe.get(&"recipe_id", &"")) == recipe_id:
			return recipe
	return {}


func _parse_pairs(text: String) -> Dictionary:
	var result := {}
	for pair in text.split("|", false):
		var parts := pair.split(":", false, 1)
		if parts.size() == 2:
			result[StringName(parts[0].strip_edges())] = maxi(0, parts[1].to_int())
	return result
