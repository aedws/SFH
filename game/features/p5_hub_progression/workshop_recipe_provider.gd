class_name WorkshopRecipeProvider
extends RefCounted

var recipes: Array[Dictionary] = []
var _by_recipe_id: Dictionary = {}
var _by_blueprint_id: Dictionary = {}


func configure(rows: Array[Dictionary]) -> bool:
	recipes.clear()
	_by_recipe_id.clear()
	_by_blueprint_id.clear()
	for source in rows:
		var recipe := source.duplicate(true)
		var recipe_id := StringName(recipe.get(&"recipe_id", &""))
		var blueprint_id := StringName(recipe.get(&"blueprint_id", &""))
		if recipe_id == &"" or blueprint_id == &"" or _by_recipe_id.has(recipe_id):
			return false
		recipes.append(recipe)
		_by_recipe_id[recipe_id] = recipe
		if not _by_blueprint_id.has(blueprint_id):
			_by_blueprint_id[blueprint_id] = []
		(_by_blueprint_id[blueprint_id] as Array).append(recipe)
	return not recipes.is_empty()


func get_recipe(recipe_id: StringName) -> Dictionary:
	var recipe: Dictionary = _by_recipe_id.get(recipe_id, {})
	return recipe.duplicate(true)


func get_recipes() -> Array[Dictionary]:
	return recipes.duplicate(true)


func get_recipes_for_blueprint(blueprint_id: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for recipe in _by_blueprint_id.get(blueprint_id, []):
		result.append((recipe as Dictionary).duplicate(true))
	return result


func has_blueprint(blueprint_id: StringName) -> bool:
	return blueprint_id != &"" and _by_blueprint_id.has(blueprint_id)


func get_materials(recipe_id: StringName) -> Dictionary:
	var recipe := get_recipe(recipe_id)
	var result := {}
	for pair in String(recipe.get(&"materials", "")).split("|", false):
		var parts := pair.split(":", false, 1)
		if parts.size() == 2:
			result[StringName(parts[0].strip_edges())] = maxi(0, parts[1].to_int())
	return result


func get_snapshot() -> Dictionary:
	return {
		&"recipe_count": recipes.size(),
		&"blueprint_count": _by_blueprint_id.size(),
	}
