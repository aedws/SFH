class_name WorkshopService
extends RefCounted

const BLUEPRINT_REGISTRY := preload("res://game/features/p5_hub_progression/blueprint_registry.gd")
const RECIPE_PROVIDER := preload("res://game/features/p5_hub_progression/workshop_recipe_provider.gd")
const UNLOCK_SERVICE := preload("res://game/features/p5_hub_progression/workshop_unlock_service.gd")
const TRANSACTION_SERVICE := preload("res://game/features/p5_hub_progression/workshop_craft_transaction_service.gd")

var profile: Node
var blueprint_registry = BLUEPRINT_REGISTRY.new()
var recipe_provider = RECIPE_PROVIDER.new()
var unlock_service = UNLOCK_SERVICE.new()
var transaction_service = TRANSACTION_SERVICE.new()


func configure(profile_provider: Node, rows: Array[Dictionary], seed: int,
		roll_policy: Resource) -> bool:
	profile = profile_provider
	blueprint_registry = BLUEPRINT_REGISTRY.new()
	recipe_provider = RECIPE_PROVIDER.new()
	unlock_service = UNLOCK_SERVICE.new()
	transaction_service = TRANSACTION_SERVICE.new()
	return (
		is_instance_valid(profile)
		and bool(blueprint_registry.call(&"configure", profile))
		and bool(recipe_provider.call(&"configure", rows))
		and bool(unlock_service.call(&"configure", blueprint_registry, recipe_provider))
		and bool(transaction_service.call(&"configure", profile, roll_policy, seed))
	)


func register_extracted_blueprints(acquired: Dictionary) -> PackedStringArray:
	return unlock_service.call(&"register_extracted_blueprints", acquired)


func get_candidates() -> Array[Dictionary]:
	var candidates: Array[Dictionary] = unlock_service.call(&"get_candidates")
	for candidate in candidates:
		var draft := quote(StringName(candidate.get(&"recipe_id", &"")))
		candidate[&"craftable"] = draft.get(&"craftable", false)
		candidate[&"reason"] = draft.get(&"reason", "제작 불가")
		candidate[&"credit_cost"] = draft.get(&"credit_cost", 0)
		candidate[&"balance_after"] = draft.get(&"balance_after", 0)
		candidate[&"materials"] = draft.get(&"materials", {}).duplicate(true)
		candidate[&"material_preview"] = draft.get(&"material_preview", []).duplicate(true)
		candidate[&"roll_preview"] = draft.get(&"roll_preview", {}).duplicate(true)
	return candidates


func quote(recipe_id: StringName) -> Dictionary:
	var recipe: Dictionary = recipe_provider.call(&"get_recipe", recipe_id)
	if recipe.is_empty():
		return {&"craftable": false, &"reason": "제작법 없음"}
	var blueprint_id := StringName(recipe.get(&"blueprint_id", &""))
	var registration_ready := (
		not bool(recipe.get(&"required_registration", true))
		or bool(blueprint_registry.call(&"is_registered", blueprint_id))
	)
	return transaction_service.call(
		&"quote", recipe, recipe_provider.call(&"get_materials", recipe_id), registration_ready
	)


func craft(recipe_id: StringName, transaction_id: StringName) -> Dictionary:
	var recipe: Dictionary = recipe_provider.call(&"get_recipe", recipe_id)
	if recipe.is_empty():
		return {&"success": false, &"reason": "제작법 없음"}
	var blueprint_id := StringName(recipe.get(&"blueprint_id", &""))
	var registration_ready := (
		not bool(recipe.get(&"required_registration", true))
		or bool(blueprint_registry.call(&"is_registered", blueprint_id))
	)
	return transaction_service.call(
		&"execute", recipe, recipe_provider.call(&"get_materials", recipe_id),
		registration_ready, transaction_id
	)


func get_snapshot() -> Dictionary:
	var result: Dictionary = unlock_service.call(&"get_snapshot")
	result.merge(recipe_provider.call(&"get_snapshot"), true)
	result[&"candidates"] = get_candidates()
	return result
