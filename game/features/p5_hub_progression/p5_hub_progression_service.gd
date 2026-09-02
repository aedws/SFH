class_name P5HubProgressionService
extends Node

signal snapshot_changed(snapshot: Dictionary)

const SCRIPT_PATHS := {
	&"table": "res://game/features/p5_hub_progression/p5_catalog_table.gd",
	&"utility": "res://game/features/p5_hub_progression/utility_investment_service.gd",
	&"operation_draft": "res://game/features/p5_hub_progression/operation_draft_service.gd",
	&"bankruptcy": "res://game/features/p5_hub_progression/bankruptcy_protection_policy.gd",
	&"shop": "res://game/features/p5_hub_progression/rotating_shop_service.gd",
	&"workshop": "res://game/features/p5_hub_progression/workshop_service.gd",
	&"training": "res://game/features/p5_hub_progression/training_service.gd",
	&"codex": "res://game/features/p5_hub_progression/codex_service.gd",
	&"presenter": "res://game/features/p5_hub_progression/p5_hub_action_presenter.gd",
}

const TABLE_SCHEMAS := {
	&"utility": [["utility_id", "display_name", "utility_type", "run_price", "runtime_enabled"], &"utility_id"],
	&"bankruptcy": [["preset_id", "character_id", "main_weapon_id", "secondary_weapon_id", "skill_ids", "tier_id", "region_id", "difficulty_id", "runtime_enabled"], &"preset_id"],
	&"shop": [["offer_id", "display_name", "quality", "target_id", "quantity", "price", "runtime_enabled"], &"offer_id"],
	&"workshop": [["recipe_id", "blueprint_id", "result_id", "credit_cost", "materials", "runtime_enabled"], &"recipe_id"],
	&"training": [["scenario_id", "display_name", "dummy_mode", "measurement_seconds", "runtime_enabled"], &"scenario_id"],
	&"codex": [["entry_id", "display_name", "source_id", "region_hint", "required_count", "runtime_enabled"], &"entry_id"],
}

var profile: Node
var config: Resource
var _modules: Dictionary = {}
var _presenter
var _configuration_errors := PackedStringArray()


func configure(profile_provider: Node, contract_service: Node, progression_config: Resource,
		seed: int = 0) -> bool:
	_modules.clear()
	_configuration_errors.clear()
	if not is_instance_valid(profile_provider) or progression_config == null or not progression_config.call(&"is_valid"):
		return false
	profile = profile_provider
	config = progression_config
	if not _install_csv_module(&"utility", bool(config.get("utility_enabled")), "utility_csv_path", [profile]): return false
	if bool(config.get("operation_draft_enabled")) and not _install_module(&"operation_draft", [contract_service]): return false
	if not _install_csv_module(&"bankruptcy", bool(config.get("bankruptcy_preset_enabled")), "operation_preset_csv_path", []): return false
	if not _install_csv_module(&"shop", bool(config.get("rotating_shop_enabled")), "shop_offer_csv_path", [profile], [seed, int(config.get("shop_reroll_price")), int(config.get("shop_rotation_slots"))]): return false
	if not _install_csv_module(&"workshop", bool(config.get("workshop_enabled")), "recipe_csv_path", [profile], [seed]): return false
	if not _install_csv_module(&"training", bool(config.get("training_enabled")), "training_scenario_csv_path", []): return false
	if not _install_csv_module(&"codex", bool(config.get("codex_enabled")), "codex_csv_path", [profile]): return false
	_presenter = _new_script_instance(&"presenter")
	if _presenter == null or not bool(_presenter.call(&"configure", self, config)):
		_configuration_errors.append("P5 허브 액션 프레젠터 구성 실패")
		return false
	snapshot_changed.emit(get_snapshot())
	return true


func _install_csv_module(module_id: StringName, enabled: bool, path_property: String,
		leading_arguments: Array, trailing_arguments: Array = []) -> bool:
	if not enabled: return true
	var table_script = _load_script(&"table")
	if table_script == null: return false
	var schema: Array = TABLE_SCHEMAS[module_id]
	var table: Dictionary = table_script.call(&"load_table", String(config.get(path_property)), schema[0], schema[1])
	if not bool(table.get(&"success", false)):
		for error in table.get(&"errors", []): _configuration_errors.append("%s: %s" % [module_id, error])
		return false
	var arguments := leading_arguments.duplicate()
	arguments.append(table.get(&"rows", []))
	arguments.append_array(trailing_arguments)
	return _install_module(module_id, arguments)


func _install_module(module_id: StringName, configure_arguments: Array) -> bool:
	var module = _new_script_instance(module_id)
	if module == null or not bool(module.callv(&"configure", configure_arguments)):
		_configuration_errors.append("하위 모듈 구성 실패: %s" % module_id)
		return false
	_modules[module_id] = module
	return true


func _load_script(module_id: StringName):
	var path := String(SCRIPT_PATHS.get(module_id, ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		_configuration_errors.append("하위 모듈 스크립트 없음: %s" % path)
		return null
	return load(path)


func _new_script_instance(module_id: StringName):
	var script = _load_script(module_id)
	return script.new() if script != null else null


func _module(module_id: StringName): return _modules.get(module_id)


func perform_hub_action(action_id: StringName) -> Dictionary:
	return _presenter.call(&"perform", action_id) if _presenter != null else {&"handled": false}


func set_utility_quantity(utility_id: StringName, quantity: int) -> bool:
	var utility = _module(&"utility")
	var success := utility != null and bool(utility.call(&"set_quantity", utility_id, quantity))
	if success: snapshot_changed.emit(get_snapshot())
	return success


func use_utility(utility_id: StringName, condition_id: StringName) -> Dictionary:
	var utility = _module(&"utility")
	var result: Dictionary = utility.call(&"use", utility_id, condition_id) if utility != null else {&"success": false, &"reason": "유틸리티 모듈 꺼짐"}
	snapshot_changed.emit(get_snapshot())
	return result


func get_investment_context() -> Dictionary:
	var utility = _module(&"utility")
	return utility.call(&"get_investment_context") if utility != null else {&"additional_entry_cost": 0, &"utilities": []}


func toggle_utility(utility_id: StringName) -> Dictionary:
	var utility = _module(&"utility")
	if utility == null: return {&"success": false, &"reason": "유틸리티 모듈 꺼짐"}
	var selected: Dictionary = utility.call(&"get_snapshot").get(&"selected", {})
	var next_quantity := 0 if int(selected.get(utility_id, 0)) > 0 else 1
	var success := set_utility_quantity(utility_id, next_quantity)
	return {&"success": success, &"quantity": next_quantity if success else int(selected.get(utility_id, 0))}


func purchase_shop_offer(offer_id: StringName, transaction_id: StringName) -> Dictionary:
	var shop = _module(&"shop")
	var result: Dictionary = shop.call(&"purchase", offer_id, transaction_id) if shop != null else {&"success": false, &"reason": "상점 모듈 꺼짐"}
	snapshot_changed.emit(get_snapshot())
	return result


func reroll_shop(transaction_id: StringName) -> Dictionary:
	var shop = _module(&"shop")
	var result: Dictionary = shop.call(&"refresh", true, transaction_id) if shop != null else {&"success": false, &"reason": "상점 모듈 꺼짐"}
	snapshot_changed.emit(get_snapshot())
	return result


func register_extracted_blueprints(acquired: Dictionary) -> PackedStringArray:
	var workshop = _module(&"workshop")
	return workshop.call(&"register_extracted_blueprints", acquired) if workshop != null else PackedStringArray()


func craft_recipe(recipe_id: StringName, transaction_id: StringName) -> Dictionary:
	var workshop = _module(&"workshop")
	var result: Dictionary = workshop.call(&"craft", recipe_id, transaction_id) if workshop != null else {&"success": false, &"reason": "제작 모듈 꺼짐"}
	snapshot_changed.emit(get_snapshot())
	return result


func start_training(scenario_id: StringName) -> Dictionary:
	var training = _module(&"training")
	var result: Dictionary = training.call(&"start", scenario_id) if training != null else {&"success": false, &"reason": "훈련 모듈 꺼짐"}
	snapshot_changed.emit(get_snapshot())
	return result


func record_training_hit(damage: float, armor_penetration: float, cooldown_seconds: float) -> bool:
	var training = _module(&"training")
	var recorded := training != null and bool(training.call(&"record_hit", damage, armor_penetration, cooldown_seconds))
	if recorded: snapshot_changed.emit(get_snapshot())
	return recorded


func finish_training() -> Dictionary:
	var training = _module(&"training")
	var result: Dictionary = training.call(&"finish") if training != null else {&"success": false, &"reason": "훈련 모듈 꺼짐"}
	snapshot_changed.emit(get_snapshot())
	return result


func get_codex_entry(entry_id: StringName) -> Dictionary:
	var codex = _module(&"codex")
	return codex.call(&"get_entry", entry_id) if codex != null else {}


func create_operation_draft(tier: Resource, penalty: Dictionary, context: Dictionary) -> Dictionary:
	var draft = _module(&"operation_draft")
	return draft.call(&"create_draft", tier, penalty, context) if draft != null else {}


func confirm_operation_draft(draft_id: StringName, tier: Resource, penalty: Dictionary, context: Dictionary) -> Dictionary:
	var draft = _module(&"operation_draft")
	return draft.call(&"confirm_draft", draft_id, tier, penalty, context) if draft != null else {&"success": false}


func begin_run(run_id: StringName) -> bool:
	var utility = _module(&"utility")
	return utility == null or bool(utility.call(&"begin_run", run_id))


func settle_run(extracted: bool, acquired: Dictionary = {}) -> Dictionary:
	var utility = _module(&"utility")
	var workshop = _module(&"workshop")
	var codex = _module(&"codex")
	var result := {&"utility": utility.call(&"settle_run", extracted) if utility != null else {}}
	if extracted:
		result[&"registered_blueprints"] = workshop.call(&"register_extracted_blueprints", acquired) if workshop != null else PackedStringArray()
		result[&"codex_completed"] = codex.call(&"record_extraction", acquired) if codex != null else PackedStringArray()
	snapshot_changed.emit(get_snapshot())
	return result


func refresh_hub() -> Dictionary:
	var shop = _module(&"shop")
	var result: Dictionary = shop.call(&"refresh", false) if shop != null else {&"success": true}
	snapshot_changed.emit(get_snapshot())
	return result


func get_snapshot() -> Dictionary:
	var credits := int(profile.call(&"get_snapshot").get(&"banked_credits", 0)) if profile != null else 0
	var result := {&"configuration_errors": _configuration_errors.duplicate()}
	for module_id in [&"utility", &"operation_draft", &"shop", &"workshop", &"training", &"codex"]:
		var module = _module(module_id)
		result[module_id] = module.call(&"get_snapshot") if module != null else {}
	var bankruptcy = _module(&"bankruptcy")
	result[&"bankruptcy"] = bankruptcy.call(&"get_snapshot", credits) if bankruptcy != null else {}
	return result
