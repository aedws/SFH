class_name P5HubProgressionService
extends Node

signal snapshot_changed(snapshot: Dictionary)

const TABLE := preload("res://game/features/p5_hub_progression/p5_catalog_table.gd")
const UTILITY := preload("res://game/features/p5_hub_progression/utility_investment_service.gd")
const DRAFT := preload("res://game/features/p5_hub_progression/operation_draft_service.gd")
const BANKRUPTCY := preload("res://game/features/p5_hub_progression/bankruptcy_protection_policy.gd")
const SHOP := preload("res://game/features/p5_hub_progression/rotating_shop_service.gd")
const WORKSHOP := preload("res://game/features/p5_hub_progression/workshop_service.gd")
const TRAINING := preload("res://game/features/p5_hub_progression/training_service.gd")
const CODEX := preload("res://game/features/p5_hub_progression/codex_service.gd")

var profile: Node
var config: Resource
var utility
var operation_draft
var bankruptcy
var shop
var workshop
var training
var codex


func configure(profile_provider: Node, contract_service: Node, progression_config: Resource,
		seed: int = 0) -> bool:
	if not is_instance_valid(profile_provider) or progression_config == null or not progression_config.call(&"is_valid"):
		return false
	profile = profile_provider
	config = progression_config
	if bool(config.get("utility_enabled")):
		utility = UTILITY.new()
		if not utility.call(&"configure", profile, TABLE.load_rows(config.get("utility_csv_path"))): return false
	if bool(config.get("operation_draft_enabled")):
		operation_draft = DRAFT.new()
		if not operation_draft.call(&"configure", contract_service): return false
	if bool(config.get("bankruptcy_preset_enabled")):
		bankruptcy = BANKRUPTCY.new()
		if not bankruptcy.call(&"configure", TABLE.load_rows(config.get("operation_preset_csv_path"))): return false
	if bool(config.get("rotating_shop_enabled")):
		shop = SHOP.new()
		if not shop.call(&"configure", profile, TABLE.load_rows(config.get("shop_offer_csv_path")), seed,
			int(config.get("shop_reroll_price")), int(config.get("shop_rotation_slots"))): return false
	if bool(config.get("workshop_enabled")):
		workshop = WORKSHOP.new()
		if not workshop.call(&"configure", profile, TABLE.load_rows(config.get("recipe_csv_path")), seed): return false
	if bool(config.get("training_enabled")):
		training = TRAINING.new()
		if not training.call(&"configure", TABLE.load_rows(config.get("training_scenario_csv_path"))): return false
	if bool(config.get("codex_enabled")):
		codex = CODEX.new()
		if not codex.call(&"configure", profile, TABLE.load_rows(config.get("codex_csv_path"))): return false
	snapshot_changed.emit(get_snapshot())
	return true


func get_investment_context() -> Dictionary:
	return utility.call(&"get_investment_context") if utility != null else {&"additional_entry_cost": 0, &"utilities": []}


func toggle_utility(utility_id: StringName) -> Dictionary:
	if utility == null:
		return {&"success": false, &"reason": "유틸리티 모듈 꺼짐"}
	var selected: Dictionary = utility.call(&"get_snapshot").get(&"selected", {})
	var next_quantity := 0 if int(selected.get(utility_id, 0)) > 0 else 1
	var success: bool = utility.call(&"set_quantity", utility_id, next_quantity)
	snapshot_changed.emit(get_snapshot())
	return {&"success": success, &"quantity": next_quantity if success else int(selected.get(utility_id, 0))}


func purchase_shop_offer(offer_id: StringName, transaction_id: StringName) -> Dictionary:
	var result: Dictionary = shop.call(&"purchase", offer_id, transaction_id) if shop != null else {&"success": false, &"reason": "상점 모듈 꺼짐"}
	snapshot_changed.emit(get_snapshot())
	return result


func reroll_shop(transaction_id: StringName) -> Dictionary:
	var result: Dictionary = shop.call(&"refresh", true, transaction_id) if shop != null else {&"success": false, &"reason": "상점 모듈 꺼짐"}
	snapshot_changed.emit(get_snapshot())
	return result


func craft_recipe(recipe_id: StringName, transaction_id: StringName) -> Dictionary:
	var result: Dictionary = workshop.call(&"craft", recipe_id, transaction_id) if workshop != null else {&"success": false, &"reason": "제작 모듈 꺼짐"}
	snapshot_changed.emit(get_snapshot())
	return result


func start_training(scenario_id: StringName) -> Dictionary:
	var result: Dictionary = training.call(&"start", scenario_id) if training != null else {&"success": false, &"reason": "훈련 모듈 꺼짐"}
	snapshot_changed.emit(get_snapshot())
	return result


func finish_training() -> Dictionary:
	var result: Dictionary = training.call(&"finish") if training != null else {&"success": false, &"reason": "훈련 모듈 꺼짐"}
	snapshot_changed.emit(get_snapshot())
	return result


func create_operation_draft(tier: Resource, penalty: Dictionary, context: Dictionary) -> Dictionary:
	return operation_draft.call(&"create_draft", tier, penalty, context) if operation_draft != null else {}


func confirm_operation_draft(draft_id: StringName, tier: Resource, penalty: Dictionary, context: Dictionary) -> Dictionary:
	return operation_draft.call(&"confirm_draft", draft_id, tier, penalty, context) if operation_draft != null else {&"success": false}


func begin_run(run_id: StringName) -> bool:
	return utility == null or bool(utility.call(&"begin_run", run_id))


func settle_run(extracted: bool, acquired: Dictionary = {}) -> Dictionary:
	var result := {&"utility": utility.call(&"settle_run", extracted) if utility != null else {}}
	if extracted:
		result[&"registered_blueprints"] = workshop.call(&"register_extracted_blueprints", acquired) if workshop != null else PackedStringArray()
		result[&"codex_completed"] = codex.call(&"record_extraction", acquired) if codex != null else PackedStringArray()
	snapshot_changed.emit(get_snapshot())
	return result


func refresh_hub() -> Dictionary:
	var result: Dictionary = shop.call(&"refresh", false) if shop != null else {&"success": true}
	snapshot_changed.emit(get_snapshot())
	return result


func get_snapshot() -> Dictionary:
	var credits := int(profile.call(&"get_snapshot").get(&"banked_credits", 0)) if profile != null else 0
	return {&"utility": utility.call(&"get_snapshot") if utility != null else {},
		&"operation_draft": operation_draft.call(&"get_snapshot") if operation_draft != null else {},
		&"bankruptcy": bankruptcy.call(&"get_snapshot", credits) if bankruptcy != null else {},
		&"shop": shop.call(&"get_snapshot") if shop != null else {},
		&"workshop": workshop.call(&"get_snapshot") if workshop != null else {},
		&"training": training.call(&"get_snapshot") if training != null else {},
		&"codex": codex.call(&"get_snapshot") if codex != null else {}}
