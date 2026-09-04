class_name WorkshopUnlockService
extends RefCounted

var registry
var recipe_provider


func configure(blueprint_registry, workshop_recipe_provider) -> bool:
	registry = blueprint_registry
	recipe_provider = workshop_recipe_provider
	return (
		registry != null
		and registry.has_method(&"register")
		and registry.has_method(&"is_registered")
		and recipe_provider != null
		and recipe_provider.has_method(&"get_recipes")
		and recipe_provider.has_method(&"has_blueprint")
	)


func register_extracted_blueprints(acquired: Dictionary) -> PackedStringArray:
	var registered := PackedStringArray()
	for raw_id in acquired:
		var blueprint_id := StringName(raw_id)
		if (
			_quantity_of(acquired[raw_id]) > 0
			and bool(recipe_provider.call(&"has_blueprint", blueprint_id))
			and bool(registry.call(&"register", blueprint_id))
		):
			registered.append(String(blueprint_id))
	return registered


func get_candidates() -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	for recipe in recipe_provider.call(&"get_recipes"):
		var blueprint_id := StringName(recipe.get(&"blueprint_id", &""))
		var registered := bool(registry.call(&"is_registered", blueprint_id))
		candidates.append({
			&"recipe_id": StringName(recipe.get(&"recipe_id", &"")),
			&"blueprint_id": blueprint_id,
			&"display_name": String(recipe.get(&"display_name", "제작 항목")),
			&"result_id": StringName(recipe.get(&"result_id", &"")),
			&"registered": registered,
			&"status_label": "재제작 가능" if registered else "도면 반출 필요",
		})
	return candidates


func get_snapshot() -> Dictionary:
	var candidates := get_candidates()
	var registered_count := 0
	for candidate in candidates:
		if bool(candidate.get(&"registered", false)):
			registered_count += 1
	return {
		&"registered_count": registered_count,
		&"candidate_count": candidates.size(),
		&"candidates": candidates,
		&"registered_blueprints": registry.call(&"registered_ids"),
	}


func _quantity_of(value: Variant) -> int:
	if value is Dictionary:
		return maxi(0, int((value as Dictionary).get(&"quantity", 0)))
	if value is int or value is float:
		return maxi(0, int(value))
	return 0
