class_name LootLaunchValidator
extends Node

const POLICY_SCRIPT := preload("res://game/features/loot/loot_value_allocation_policy.gd")

var loot_config_path_pattern := "res://game/features/loot/configs/%s.tres"


func configure(new_loot_config_path_pattern: String) -> bool:
	if new_loot_config_path_pattern.is_empty() or "%s" not in new_loot_config_path_pattern:
		return false
	loot_config_path_pattern = new_loot_config_path_pattern
	return true


func validate_operation_launch(request: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	var tier_id := StringName(request.get(&"tier_id", &""))
	var path := loot_config_path_pattern % tier_id
	if tier_id == &"" or not ResourceLoader.exists(path):
		errors.append("전리품 설정을 찾을 수 없습니다: %s" % path)
		return errors
	var config: Resource = load(path)
	if config == null:
		errors.append("전리품 설정을 불러오지 못했습니다: %s" % path)
		return errors
	if config.has_method(&"validation_errors"):
		for message in config.call(&"validation_errors"):
			errors.append(message)
	if not errors.is_empty():
		return errors
	var random := RandomNumberGenerator.new()
	var runtime_context: Dictionary = request.get(&"runtime_context", {})
	random.seed = int(runtime_context.get(&"map_seed", 0)) ^ int(request.get(&"quote", {}).get(&"entry_cost", 0))
	var policy = POLICY_SCRIPT.new()
	var allocation: Dictionary = policy.call(
		&"allocate", config, int(request.get(&"quote", {}).get(&"entry_cost", 0)), random
	)
	if not bool(allocation.get(&"success", false)):
		errors.append(String(allocation.get(&"reason", "회수 가치 배분 실패")))
		return errors
	var amounts: PackedInt32Array = policy.call(
		&"build_credit_amounts",
		int(allocation.get(&"cache_count", 0)),
		int(allocation.get(&"minimum_cache_credits", 0)),
		int(allocation.get(&"maximum_cache_credits", 0)),
		int(allocation.get(&"target_total_credits", 0)),
		random
	)
	var total := 0
	for amount in amounts:
		total += amount
	if amounts.size() != int(allocation.get(&"cache_count", 0)) or total != int(allocation.get(&"target_total_credits", -1)):
		errors.append("회수 상자 수 또는 총 회수 가치가 계약과 일치하지 않습니다.")
	return errors
