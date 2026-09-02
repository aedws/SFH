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
@export_range(0, 10000, 1) var shop_reroll_price := 25
@export_range(1, 8, 1) var shop_rotation_slots := 3
@export var default_recipe_id: StringName = &"assault_blueprint_recipe"
@export var default_utility_id: StringName = &"field_medkit"
@export var default_training_scenario_id: StringName = &"single_target"


func is_valid() -> bool:
	var conditional_paths := [
		[utility_enabled, utility_csv_path],
		[bankruptcy_preset_enabled, operation_preset_csv_path],
		[rotating_shop_enabled, shop_offer_csv_path],
		[workshop_enabled, recipe_csv_path],
		[training_enabled, training_scenario_csv_path],
		[codex_enabled, codex_csv_path],
	]
	for pair in conditional_paths:
		if bool(pair[0]) and (String(pair[1]).is_empty() or not FileAccess.file_exists(String(pair[1]))):
			return false
	return (
		shop_reroll_price >= 0
		and shop_rotation_slots > 0
		and (not workshop_enabled or default_recipe_id != &"")
		and (not utility_enabled or default_utility_id != &"")
		and (not training_enabled or default_training_scenario_id != &"")
	)
