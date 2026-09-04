class_name P5HubProgressionConfig
extends Resource

@export var utility_enabled := true
@export var operation_draft_enabled := true
@export var bankruptcy_preset_enabled := true
@export var rotating_shop_enabled := true
@export var workshop_enabled := true
@export var training_enabled := true
@export var codex_enabled := true
@export var utility_csv_path := "res://game/features/p5_hub_progression/data/utility.csv"
@export var operation_preset_csv_path := "res://game/features/p5_hub_progression/data/operation_preset.csv"
@export var shop_offer_csv_path := "res://game/features/p5_hub_progression/data/shop_offer.csv"
@export var recipe_csv_path := "res://game/features/p5_hub_progression/data/recipe.csv"
@export var training_scenario_csv_path := "res://game/features/p5_hub_progression/data/training_scenario.csv"
@export var codex_csv_path := "res://game/features/p5_hub_progression/data/codex.csv"
@export var utility_csv_payload: Resource
@export var operation_preset_csv_payload: Resource
@export var shop_offer_csv_payload: Resource
@export var shop_quality_catalog: Resource
@export var shop_rotation_policy: Resource
@export var recipe_csv_payload: Resource
@export var training_scenario_csv_payload: Resource
@export var codex_csv_payload: Resource
@export_range(0, 10000, 1) var shop_reroll_price := 25
@export_range(1, 8, 1) var shop_rotation_slots := 3
@export var default_recipe_id: StringName = &"assault_blueprint_recipe"
@export var default_utility_id: StringName = &"field_medkit"
@export var default_training_scenario_id: StringName = &"single_target"


func is_valid() -> bool:
	if (
		rotating_shop_enabled
		and (
			shop_quality_catalog == null
			or not shop_quality_catalog.has_method(&"is_valid")
			or not bool(shop_quality_catalog.call(&"is_valid"))
			or shop_rotation_policy == null
			or not shop_rotation_policy.has_method(&"is_valid")
			or not bool(shop_rotation_policy.call(&"is_valid"))
		)
	):
		return false
	var csv_contracts := [
		[utility_enabled, utility_csv_path, utility_csv_payload],
		[bankruptcy_preset_enabled, operation_preset_csv_path, operation_preset_csv_payload],
		[rotating_shop_enabled, shop_offer_csv_path, shop_offer_csv_payload],
		[workshop_enabled, recipe_csv_path, recipe_csv_payload],
		[training_enabled, training_scenario_csv_path, training_scenario_csv_payload],
		[codex_enabled, codex_csv_path, codex_csv_payload],
	]
	for contract in csv_contracts:
		if not bool(contract[0]):
			continue
		var path := String(contract[1])
		var payload: Resource = contract[2]
		if path.is_empty():
			return false
		var has_source_file := FileAccess.file_exists(path)
		var has_matching_payload := (
			payload != null
			and payload.has_method(&"is_valid_for")
			and bool(payload.call(&"is_valid_for", path))
		)
		if not has_source_file and not has_matching_payload:
			return false
	return (
		shop_reroll_price >= 0
		and shop_rotation_slots > 0
		and (not workshop_enabled or default_recipe_id != &"")
		and (not utility_enabled or default_utility_id != &"")
		and (not training_enabled or default_training_scenario_id != &"")
	)
