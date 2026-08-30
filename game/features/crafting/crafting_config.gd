class_name CraftingConfig
extends Resource

@export var recipes: Array[Dictionary] = []
@export var affixes: Array[Dictionary] = []


func is_valid() -> bool:
	return not recipes.is_empty() and not affixes.is_empty()


func get_recipe(blueprint_id: StringName) -> Dictionary:
	for recipe in recipes:
		if StringName(recipe.get(&"blueprint_id", &"")) == blueprint_id:
			return recipe.duplicate(true)
	return {}
