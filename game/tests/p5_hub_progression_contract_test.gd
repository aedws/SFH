extends SceneTree

const PROFILE_SCENE := preload("res://game/features/persistent_profile/persistent_profile.tscn")
const CONTRACT_SCENE := preload("res://game/features/operation_contract/operation_contract_service.tscn")
const P5_SCENE := preload("res://game/features/p5_hub_progression/p5_hub_progression_service.tscn")
const FAILING_TRANSACTION_PROFILE := preload("res://game/tests/fixtures/failing_transaction_profile.gd")
const PROFILE_PATH := "user://sfh_p5_contract_profile.json"

var failures := PackedStringArray()


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	if FileAccess.file_exists(PROFILE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE_PATH))
	var sandbox := Node.new()
	root.add_child(sandbox)
	var profile := PROFILE_SCENE.instantiate()
	var contract := CONTRACT_SCENE.instantiate()
	var p5 := P5_SCENE.instantiate()
	sandbox.add_child(profile)
	sandbox.add_child(contract)
	sandbox.add_child(p5)
	_check(profile.call(&"configure", PROFILE_PATH, true), "프로필 구성")
	_check(contract.call(&"configure", profile, load("res://game/features/operation_contract/configs/default_operation_contracts.tres")), "계약 구성")
	_check(p5.call(&"configure", profile, contract, load("res://game/features/p5_hub_progression/configs/default_p5_hub_progression.tres"), 50510), "P5 구성")
	var initial: Dictionary = p5.call(&"get_snapshot")
	_check(int(initial.get(&"utility", {}).get(&"catalog_count", 0)) == 5, "유틸리티 5종")
	_check(int(initial.get(&"shop", {}).get(&"quality_count", 0)) == 3, "상점 3품질")
	_check(int(initial.get(&"training", {}).get(&"scenario_count", 0)) == 2, "훈련 2종")
	_check(int(initial.get(&"codex", {}).get(&"entry_count", 0)) == 6, "도감 6종")
	_check(int(initial.get(&"workshop", {}).get(&"candidate_count", 0)) == 3, "제작 후보 3종")
	_check(_verify_web_payload_fallback(profile, contract, sandbox), "Web 내장 P5 CSV 6종 폴백")

	_check(p5.call(&"set_utility_quantity", &"field_medkit", 1), "회복 유틸 선택")
	var utility_context: Dictionary = p5.call(&"get_investment_context")
	_check(int(utility_context.get(&"additional_entry_cost", 0)) == 30, "유틸 투입 비용")
	var tier := load("res://game/features/map_generation/configs/small.tres")
	var draft: Dictionary = p5.call(&"create_operation_draft", tier, {}, utility_context)
	_check(int(draft.get(&"quote", {}).get(&"break_even_recovery_credits", -1)) >= 0, "손익분기점 견적")
	var before_confirm := int(profile.call(&"get_snapshot").get(&"banked_credits", 0))
	var confirmed: Dictionary = p5.call(&"confirm_operation_draft", draft.get(&"draft_id", &""), tier, {}, utility_context)
	_check(bool(confirmed.get(&"success", false)), "작전 초안 단일 확정")
	_check(before_confirm - int(profile.call(&"get_snapshot").get(&"banked_credits", 0)) == int(confirmed.get(&"entry_cost", 0)), "원자적 단일 차감")
	var duplicate: Dictionary = p5.call(&"confirm_operation_draft", draft.get(&"draft_id", &""), tier, {}, utility_context)
	_check(not bool(duplicate.get(&"success", false)), "작전 중복 확정 차단")
	var rotation_before_run := int(p5.call(&"get_shop_snapshot").get(&"rotation_index", -1))
	var offers_before_run: Array = p5.call(&"get_shop_snapshot").get(&"offers", [])
	_check(p5.call(&"begin_run", &"p5-run-1"), "런 유틸리티 시작")
	_check(not bool(p5.call(&"use_utility", &"field_medkit", &"enemies_nearby").get(&"success", false)), "유틸 사용 조건 차단")
	_check(bool(p5.call(&"use_utility", &"field_medkit", &"health_below_max").get(&"success", false)), "유틸 런 사용")
	var utility_settlement: Dictionary = p5.call(&"settle_run", false, {})
	_check((utility_settlement.get(&"utility", {}).get(&"persistent_grant", {}) as Dictionary).is_empty(), "사망 유틸 영구 지급 없음")
	var rotation_after_run: Dictionary = p5.call(&"get_shop_snapshot")
	_check(
		int(rotation_after_run.get(&"rotation_index", -1)) == rotation_before_run + 1
		and rotation_after_run.get(&"last_refresh_reason", &"") == &"run_return",
		"런 종료 복귀 회전"
	)
	_check(
		int(rotation_after_run.get(&"last_changed_count", 0)) > 0
		and rotation_after_run.get(&"offers", []) != offers_before_run,
		"복귀 매물 체감 교체"
	)
	p5.call(&"refresh_hub")
	_check(int(p5.call(&"get_shop_snapshot").get(&"rotation_index", -1)) == rotation_before_run + 1, "복귀 신호 중복 회전 없음")
	_check(p5.call(&"begin_run", &"p5-run-cancel"), "취소 런 시작")
	_check(p5.call(&"cancel_run"), "조립 실패 런 취소")
	p5.call(&"refresh_hub")
	_check(int(p5.call(&"get_shop_snapshot").get(&"rotation_index", -1)) == rotation_before_run + 1, "취소 런 상점 유지")
	contract.call(&"clear_active_contract")

	var shop_snapshot: Dictionary = p5.call(&"get_snapshot").get(&"shop", {})
	var first_offer: Dictionary = (shop_snapshot.get(&"offers", []) as Array)[0]
	var credits_before_shop := int(profile.call(&"get_snapshot").get(&"banked_credits", 0))
	var purchase: Dictionary = p5.call(&"purchase_shop_offer", first_offer.get(&"offer_id", &""), &"shop-buy-1")
	_check(bool(purchase.get(&"success", false)), "회전 상점 구매")
	var credits_after_shop := int(profile.call(&"get_snapshot").get(&"banked_credits", 0))
	_check(credits_before_shop - credits_after_shop == int(first_offer.get(&"price", 0)), "상점 1회 차감")
	p5.call(&"purchase_shop_offer", first_offer.get(&"offer_id", &""), &"shop-buy-1")
	_check(int(profile.call(&"get_snapshot").get(&"banked_credits", 0)) == credits_after_shop, "상점 중복 차감 없음")
	var reroll_before := credits_after_shop
	_check(bool(p5.call(&"reroll_shop", &"shop-reroll-1").get(&"success", false)), "유료 재굴림")
	var reroll_after := int(profile.call(&"get_snapshot").get(&"banked_credits", 0))
	p5.call(&"reroll_shop", &"shop-reroll-1")
	_check(reroll_before - reroll_after == 25 and int(profile.call(&"get_snapshot").get(&"banked_credits", 0)) == reroll_after, "재굴림 중복 차감 없음")

	var registered: PackedStringArray = p5.call(&"register_extracted_blueprints", {&"assault_rifle_blueprint": 1})
	_check(registered.has("assault_rifle_blueprint"), "탈출 도면 영구 등록")
	_check(int(p5.call(&"get_snapshot").get(&"workshop", {}).get(&"registered_count", 0)) == 1, "등록 도면 후보 표시")
	var craft: Dictionary = p5.call(&"craft_recipe", &"assault_blueprint_recipe", &"craft-1")
	_check(bool(craft.get(&"success", false)), "등록 도면 제작")
	_check(int(craft.get(&"item", {}).get(&"affix_count", 0)) >= 1, "랜덤 옵션 생성")
	_check(not bool(p5.call(&"craft_recipe", &"assault_blueprint_recipe", &"craft-1").get(&"success", false)), "제작 중복 차단")

	_check(bool(p5.call(&"start_training", &"single_target").get(&"success", false)), "무료 훈련 시작")
	p5.call(&"record_training_hit", 100.0, 0.25, 1.2)
	p5.call(&"record_training_hit", 140.0, 0.30, 1.0)
	var telemetry: Dictionary = p5.call(&"finish_training")
	_check(bool(telemetry.get(&"success", false)) and int(telemetry.get(&"hit_count", 0)) == 2, "훈련 텔레메트리")
	_check(bool(telemetry.get(&"restored_loadout", false)), "훈련 종료 로드아웃 원복")

	var completed: PackedStringArray = p5.call(&"settle_run", true, {&"arc_rune": 3}).get(&"codex_completed", PackedStringArray())
	_check(completed.has("codex_arc"), "도감 탈출 누적 완료")
	_check(String(p5.call(&"get_codex_entry", &"codex_arc").get(&"region_hint", "")) == "ruined_city", "도감 지역 힌트")

	var reloaded := PROFILE_SCENE.instantiate()
	sandbox.add_child(reloaded)
	reloaded.call(&"configure", PROFILE_PATH, true)
	var reloaded_snapshot: Dictionary = reloaded.call(&"get_snapshot")
	_check(&"assault_rifle_blueprint" in (reloaded_snapshot.get(&"registered_blueprint_ids", []) as Array), "도면 재접속 유지")
	_check(int(reloaded_snapshot.get(&"codex_progress", {}).get(&"codex_arc", 0)) == 3, "도감 재접속 유지")
	_check(&"shop-buy-1" in (reloaded_snapshot.get(&"processed_transaction_ids", []) as Array), "상점 거래 ID 재접속 유지")
	var remaining := int(profile.call(&"get_snapshot").get(&"banked_credits", 0))
	profile.call(&"spend", remaining)
	_check(bool(p5.call(&"get_snapshot").get(&"bankruptcy", {}).get(&"repeatable_free_sortie", false)), "파산 무료 프리셋 반복 가능")

	var optional_config = load("res://game/features/p5_hub_progression/configs/default_p5_hub_progression.tres").duplicate(true)
	for property_name in ["utility_enabled", "operation_draft_enabled", "bankruptcy_preset_enabled", "rotating_shop_enabled", "workshop_enabled", "training_enabled", "codex_enabled"]:
		optional_config.set(property_name, false)
	for path_property in ["utility_csv_path", "operation_preset_csv_path", "shop_offer_csv_path", "recipe_csv_path", "training_scenario_csv_path", "codex_csv_path"]:
		optional_config.set(path_property, "res://removed/%s.csv" % path_property)
	var optional_p5 := P5_SCENE.instantiate()
	sandbox.add_child(optional_p5)
	_check(optional_p5.call(&"configure", profile, contract, optional_config, 1), "P5 하위 모듈 전부 제거 가능")
	var optional_snapshot: Dictionary = optional_p5.call(&"get_snapshot")
	_check((optional_snapshot.get(&"shop", {}) as Dictionary).is_empty() and (optional_snapshot.get(&"codex", {}) as Dictionary).is_empty(), "제거 모듈 상태 미설치")

	var malformed_path := "user://p5_malformed_utility.csv"
	var malformed := FileAccess.open(malformed_path, FileAccess.WRITE)
	malformed.store_string("utility_id,display_name,runtime_enabled\n설명,설명,설명\nduplicate,첫째,true\nduplicate,둘째,true\n")
	malformed.close()
	var malformed_config = load("res://game/features/p5_hub_progression/configs/default_p5_hub_progression.tres").duplicate(true)
	for property_name in ["operation_draft_enabled", "bankruptcy_preset_enabled", "rotating_shop_enabled", "workshop_enabled", "training_enabled", "codex_enabled"]:
		malformed_config.set(property_name, false)
	malformed_config.set("utility_csv_path", malformed_path)
	var malformed_payload: Resource = malformed_config.get("utility_csv_payload").duplicate(true)
	malformed_payload.set("source_path", malformed_path)
	malformed_config.set("utility_csv_payload", malformed_payload)
	var malformed_p5 := P5_SCENE.instantiate()
	sandbox.add_child(malformed_p5)
	_check(not bool(malformed_p5.call(&"configure", profile, contract, malformed_config, 1)), "CSV 필수 열·중복 ID 차단")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(malformed_path))

	var failing_profile := FAILING_TRANSACTION_PROFILE.new()
	var failing_contract := CONTRACT_SCENE.instantiate()
	var failing_p5 := P5_SCENE.instantiate()
	sandbox.add_child(failing_profile)
	sandbox.add_child(failing_contract)
	sandbox.add_child(failing_p5)
	failing_profile.call(&"configure", "", false)
	failing_contract.call(&"configure", failing_profile, load("res://game/features/operation_contract/configs/default_operation_contracts.tres"))
	_check(failing_p5.call(&"configure", failing_profile, failing_contract, load("res://game/features/p5_hub_progression/configs/default_p5_hub_progression.tres"), 50510), "실패 거래 P5 구성")
	failing_p5.call(&"register_extracted_blueprints", {&"assault_rifle_blueprint": 1})
	var before_failed_craft: Dictionary = failing_profile.call(&"get_snapshot")
	var failed_craft: Dictionary = failing_p5.call(&"craft_recipe", &"assault_blueprint_recipe", &"forced-craft-failure")
	var after_failed_craft: Dictionary = failing_profile.call(&"get_snapshot")
	_check(not bool(failed_craft.get(&"success", false)), "제작 거래 기록 실패 노출")
	_check(before_failed_craft.get(&"banked_credits") == after_failed_craft.get(&"banked_credits") and before_failed_craft.get(&"warehouse") == after_failed_craft.get(&"warehouse") and before_failed_craft.get(&"crafted_items") == after_failed_craft.get(&"crafted_items"), "제작 실패 원자적 롤백")
	var failed_shop_snapshot: Dictionary = failing_p5.call(&"get_snapshot").get(&"shop", {})
	var failed_offer: Dictionary = (failed_shop_snapshot.get(&"offers", []) as Array)[0]
	var before_failed_shop: Dictionary = failing_profile.call(&"get_snapshot")
	var failed_shop: Dictionary = failing_p5.call(&"purchase_shop_offer", failed_offer.get(&"offer_id", &""), &"forced-shop-failure")
	var after_failed_shop: Dictionary = failing_profile.call(&"get_snapshot")
	_check(not bool(failed_shop.get(&"success", false)), "상점 거래 기록 실패 노출")
	_check(before_failed_shop.get(&"banked_credits") == after_failed_shop.get(&"banked_credits") and before_failed_shop.get(&"warehouse") == after_failed_shop.get(&"warehouse"), "상점 실패 원자적 롤백")

	if FileAccess.file_exists(PROFILE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE_PATH))
	if failures.is_empty():
		print("P5_HUB_PROGRESSION_OK web_payload_fallback_6 utility_draft_atomic bankruptcy_repeat shop_quality_rotation_no_double_debit run_return_rotation_cancel_guard workshop_blueprint_registry_provider_unlock_persistence_affix_socket training_telemetry_restore codex_progress_hint_persistence optional_submodules shop_transaction_persistence schema_rejection workshop_transaction_atomic")
		quit(0)
	else:
		print("P5_HUB_PROGRESSION_FAILED: %s" % " / ".join(failures))
		quit(1)


func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)


func _verify_web_payload_fallback(profile: Node, contract: Node, sandbox: Node) -> bool:
	var fallback_config = load(
		"res://game/features/p5_hub_progression/configs/default_p5_hub_progression.tres"
	).duplicate(true)
	for stem in [
		"utility", "operation_preset", "shop_offer", "recipe", "training_scenario", "codex",
	]:
		var path_property := "%s_csv_path" % stem
		var payload_property := "%s_csv_payload" % stem
		var missing_path := "res://web-export/%s.csv" % stem
		var payload: Resource = fallback_config.get(payload_property).duplicate(true)
		payload.set("source_path", missing_path)
		fallback_config.set(path_property, missing_path)
		fallback_config.set(payload_property, payload)
	var fallback_p5 := P5_SCENE.instantiate()
	sandbox.add_child(fallback_p5)
	if not bool(fallback_p5.call(&"configure", profile, contract, fallback_config, 50511)):
		return false
	var snapshot: Dictionary = fallback_p5.call(&"get_snapshot")
	return (
		int(snapshot.get(&"utility", {}).get(&"catalog_count", 0)) == 5
		and int(snapshot.get(&"shop", {}).get(&"quality_count", 0)) == 3
		and int(snapshot.get(&"training", {}).get(&"scenario_count", 0)) == 2
		and int(snapshot.get(&"codex", {}).get(&"entry_count", 0)) == 6
	)
