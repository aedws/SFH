extends SceneTree

const PROFILE_SCENE := preload("res://game/features/persistent_profile/persistent_profile.tscn")
const CONTRACT_SCENE := preload("res://game/features/operation_contract/operation_contract_service.tscn")
const P5_SCENE := preload("res://game/features/p5_hub_progression/p5_hub_progression_service.tscn")
const P5_CONFIG := preload("res://game/features/p5_hub_progression/configs/default_p5_hub_progression.tres")
const CONTRACT_CONFIG := preload("res://game/features/operation_contract/configs/default_operation_contracts.tres")
const FAILING_PROFILE := preload("res://game/tests/fixtures/failing_transaction_profile.gd")
const PROFILE_PATH := "user://sfh_p7_workshop_transaction.json"

var failures := PackedStringArray()


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	_cleanup_profile()
	var sandbox := Node.new()
	root.add_child(sandbox)
	var session := _create_session(sandbox, PROFILE_SCENE.instantiate(), P5_CONFIG)
	var profile: Node = session.get(&"profile")
	var p5: Node = session.get(&"p5")
	_check(profile != null and p5 != null, "기본 제작 거래 구성")
	if profile != null and p5 != null:
		var locked_quote: Dictionary = p5.call(&"quote_workshop_recipe", &"assault_blueprint_recipe")
		_check(not bool(locked_quote.get(&"craftable", true)) and locked_quote.get(&"reason") == "영구 등록 도면 필요", "미등록 도면 견적 차단")
		p5.call(&"register_extracted_blueprints", {&"assault_rifle_blueprint": 1})
		var before_quote: Dictionary = profile.call(&"get_snapshot")
		var quote: Dictionary = p5.call(&"quote_workshop_recipe", &"assault_blueprint_recipe")
		var after_quote: Dictionary = profile.call(&"get_snapshot")
		var roll_preview: Dictionary = quote.get(&"roll_preview", {})
		_check(before_quote == after_quote, "견적 무차감")
		_check(bool(quote.get(&"craftable", false)) and int(quote.get(&"credit_cost", -1)) == 80, "확정 CSV 비용 견적")
		_check(quote.get(&"materials", {}) == {&"scrap": 2}, "재료 견적")
		_check(int(quote.get(&"balance_after", -1)) == 4920, "제작 후 잔액 선공개")
		_check(
			int(roll_preview.get(&"minimum_affixes", -1)) == 1
			and int(roll_preview.get(&"maximum_affixes", -1)) == 2
			and int(roll_preview.get(&"minimum_sockets", -1)) == 1
			and int(roll_preview.get(&"maximum_sockets", -1)) == 1,
			"옵션 소켓 범위 선공개"
		)
		var candidates: Array = p5.call(&"get_workshop_candidates")
		_check(_candidate_has_quote(candidates, &"assault_blueprint_recipe"), "후보 견적 표시")
		var crafted: Dictionary = p5.call(&"craft_recipe", &"assault_blueprint_recipe", &"atomic-craft-1")
		var after_craft: Dictionary = profile.call(&"get_snapshot")
		var item: Dictionary = crafted.get(&"item", {})
		_check(bool(crafted.get(&"success", false)), "원자 제작 성공")
		_check(int(after_craft.get(&"banked_credits", -1)) == 4920 and int(after_craft.get(&"warehouse", {}).get(&"scrap", -1)) == 6, "비용 재료 1회 차감")
		_check((after_craft.get(&"crafted_items", []) as Array).size() == 1 and &"atomic-craft-1" in after_craft.get(&"processed_transaction_ids", []), "결과 거래 ID 동시 커밋")
		_check((item.get(&"affixes", []) as Array).size() == int(item.get(&"affix_count", -1)) and _unique_affixes(item), "실제 옵션 고유 Roll")
		_check((item.get(&"sockets", []) as Array).size() == int(item.get(&"socket_count", -1)), "실제 빈 소켓 Roll")
		var before_duplicate: Dictionary = after_craft.duplicate(true)
		_check(not bool(p5.call(&"craft_recipe", &"assault_blueprint_recipe", &"atomic-craft-1").get(&"success", true)), "중복 제작 차단")
		_check(before_duplicate == profile.call(&"get_snapshot"), "중복 제작 무변경")
		var before_invalid: Dictionary = profile.call(&"get_snapshot")
		var invalid: Dictionary = profile.call(&"apply_economy_transaction", &"invalid-material", -1, {&"scrap": -999}, {&"instance_id": &"invalid"})
		_check(not bool(invalid.get(&"success", true)) and before_invalid == profile.call(&"get_snapshot"), "원자 검증 실패 무변경")

	for child in sandbox.get_children():
		child.queue_free()
	await process_frame
	var restored := _create_session(sandbox, PROFILE_SCENE.instantiate(), P5_CONFIG)
	var restored_snapshot: Dictionary = restored.get(&"profile").call(&"get_snapshot") if restored.has(&"profile") else {}
	_check((restored_snapshot.get(&"crafted_items", []) as Array).size() == 1 and &"atomic-craft-1" in restored_snapshot.get(&"processed_transaction_ids", []), "재접속 제작 거래 보존")

	var custom_config: Resource = P5_CONFIG.duplicate(true)
	var custom_policy: Resource = custom_config.get("workshop_roll_policy").duplicate(true)
	custom_policy.set("instance_prefix", "custom_roll")
	custom_config.set("workshop_roll_policy", custom_policy)
	var custom_profile := PROFILE_SCENE.instantiate()
	var custom := _create_session(sandbox, custom_profile, custom_config, "")
	if custom.has(&"p5"):
		custom.get(&"p5").call(&"register_extracted_blueprints", {&"assault_rifle_blueprint": 1})
		var custom_item: Dictionary = custom.get(&"p5").call(&"craft_recipe", &"assault_blueprint_recipe", &"custom-policy").get(&"item", {})
		_check(String(custom_item.get(&"instance_id", "")).begins_with("custom_roll_"), "Roll 정책 교체")

	var failed := _create_session(sandbox, FAILING_PROFILE.new(), P5_CONFIG, "")
	if failed.has(&"p5"):
		failed.get(&"p5").call(&"register_extracted_blueprints", {&"assault_rifle_blueprint": 1})
		var failed_before: Dictionary = failed.get(&"profile").call(&"get_snapshot")
		var failed_result: Dictionary = failed.get(&"p5").call(&"craft_recipe", &"assault_blueprint_recipe", &"forced-atomic-failure")
		_check(not bool(failed_result.get(&"success", true)) and failed_before == failed.get(&"profile").call(&"get_snapshot"), "공급자 실패 무변경")

	var storage_failure_profile := PROFILE_SCENE.instantiate()
	sandbox.add_child(storage_failure_profile)
	storage_failure_profile.call(&"configure", "", false, true)
	storage_failure_profile.set("persistence_enabled", true)
	storage_failure_profile.set("storage_error", "강제 저장 실패")
	var storage_before: Dictionary = storage_failure_profile.call(&"get_snapshot")
	var storage_result: Dictionary = storage_failure_profile.call(
		&"apply_economy_transaction", &"storage-failure", -80, {&"scrap": -2},
		{&"instance_id": &"storage-failure-item"}
	)
	_check(not bool(storage_result.get(&"success", true)) and storage_before == storage_failure_profile.call(&"get_snapshot"), "영구 저장 실패 메모리 원복")

	_cleanup_profile()
	if failures.is_empty():
		print("P7_WORKSHOP_TRANSACTION_OK quote_no_mutation visible_cost_material_roll atomic_single_commit duplicate_guard invalid_no_mutation actual_affixes_sockets reconnect replaceable_policy provider_failure storage_failure_rollback")
		quit(0)
	else:
		print("P7_WORKSHOP_TRANSACTION_FAILED: %s" % " / ".join(failures))
		quit(1)


func _create_session(sandbox: Node, profile: Node, progression_config: Resource,
		storage_path: String = PROFILE_PATH) -> Dictionary:
	var contract := CONTRACT_SCENE.instantiate()
	var p5 := P5_SCENE.instantiate()
	sandbox.add_child(profile)
	sandbox.add_child(contract)
	sandbox.add_child(p5)
	if not bool(profile.call(&"configure", storage_path, not storage_path.is_empty(), true)):
		return {}
	if not bool(contract.call(&"configure", profile, CONTRACT_CONFIG)):
		return {}
	if not bool(p5.call(&"configure", profile, contract, progression_config, 70404)):
		return {}
	return {&"profile": profile, &"contract": contract, &"p5": p5}


func _candidate_has_quote(candidates: Array, recipe_id: StringName) -> bool:
	for candidate in candidates:
		if StringName(candidate.get(&"recipe_id", &"")) == recipe_id:
			return int(candidate.get(&"credit_cost", -1)) == 80 and not candidate.get(&"roll_preview", {}).is_empty()
	return false


func _unique_affixes(item: Dictionary) -> bool:
	var ids: Array[StringName] = []
	for affix in item.get(&"affixes", []):
		var affix_id := StringName(affix.get(&"affix_id", &""))
		if affix_id == &"" or affix_id in ids:
			return false
		ids.append(affix_id)
	return true


func _cleanup_profile() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		var path: String = PROFILE_PATH + String(suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
