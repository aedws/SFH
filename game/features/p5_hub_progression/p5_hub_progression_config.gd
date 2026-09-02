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


func is_valid() -> bool:
	for path in [utility_csv_path, operation_preset_csv_path, shop_offer_csv_path,
		recipe_csv_path, training_scenario_csv_path, codex_csv_path]:
		if path.is_empty() or not FileAccess.file_exists(path):
			return false
	return shop_reroll_price >= 0 and shop_rotation_slots > 0
