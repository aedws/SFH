extends SceneTree

const PROFILE_SCENE := preload("res://game/features/persistent_profile/persistent_profile.tscn")
const CONTRACT_SCENE := preload("res://game/features/operation_contract/operation_contract_service.tscn")
const P5_SCENE := preload("res://game/features/p5_hub_progression/p5_hub_progression_service.tscn")
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

	var utility = p5.get("utility")
	_check(utility.call(&"set_quantity", &"field_medkit", 1), "회복 유틸 선택")
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
	_check(p5.call(&"begin_run", &"p5-run-1"), "런 유틸리티 시작")
	_check(not bool(utility.call(&"use", &"field_medkit", &"enemies_nearby").get(&"success", false)), "유틸 사용 조건 차단")
	_check(bool(utility.call(&"use", &"field_medkit", &"health_below_max").get(&"success", false)), "유틸 런 사용")
	var utility_settlement: Dictionary = p5.call(&"settle_run", false, {})
	_check((utility_settlement.get(&"utility", {}).get(&"persistent_grant", {}) as Dictionary).is_empty(), "사망 유틸 영구 지급 없음")
	contract.call(&"clear_active_contract")

	var shop = p5.get("shop")
	var shop_snapshot: Dictionary = shop.call(&"get_snapshot")
	var first_offer: Dictionary = (shop_snapshot.get(&"offers", []) as Array)[0]
	var credits_before_shop := int(profile.call(&"get_snapshot").get(&"banked_credits", 0))
	var purchase: Dictionary = shop.call(&"purchase", first_offer.get(&"offer_id", &""), &"shop-buy-1")
	_check(bool(purchase.get(&"success", false)), "회전 상점 구매")
	var credits_after_shop := int(profile.call(&"get_snapshot").get(&"banked_credits", 0))
	_check(credits_before_shop - credits_after_shop == int(first_offer.get(&"price", 0)), "상점 1회 차감")
	shop.call(&"purchase", first_offer.get(&"offer_id", &""), &"shop-buy-1")
	_check(int(profile.call(&"get_snapshot").get(&"banked_credits", 0)) == credits_after_shop, "상점 중복 차감 없음")
	var reroll_before := credits_after_shop
	_check(bool(shop.call(&"refresh", true, &"shop-reroll-1").get(&"success", false)), "유료 재굴림")
	var reroll_after := int(profile.call(&"get_snapshot").get(&"banked_credits", 0))
	shop.call(&"refresh", true, &"shop-reroll-1")
	_check(reroll_before - reroll_after == 25 and int(profile.call(&"get_snapshot").get(&"banked_credits", 0)) == reroll_after, "재굴림 중복 차감 없음")

	var workshop = p5.get("workshop")
	var registered: PackedStringArray = workshop.call(&"register_extracted_blueprints", {&"assault_blueprint": 1})
	_check(registered.has("assault_blueprint"), "탈출 도면 영구 등록")
	var craft: Dictionary = workshop.call(&"craft", &"assault_blueprint_recipe", &"craft-1")
	_check(bool(craft.get(&"success", false)), "등록 도면 제작")
	_check(int(craft.get(&"item", {}).get(&"affix_count", 0)) >= 1, "랜덤 옵션 생성")
	_check(not bool(workshop.call(&"craft", &"assault_blueprint_recipe", &"craft-1").get(&"success", false)), "제작 중복 차단")

	var training = p5.get("training")
	_check(bool(training.call(&"start", &"single_target").get(&"success", false)), "무료 훈련 시작")
	training.call(&"record_hit", 100.0, 0.25, 1.2)
	training.call(&"record_hit", 140.0, 0.30, 1.0)
	var telemetry: Dictionary = training.call(&"finish")
	_check(bool(telemetry.get(&"success", false)) and int(telemetry.get(&"hit_count", 0)) == 2, "훈련 텔레메트리")
	_check(bool(telemetry.get(&"restored_loadout", false)), "훈련 종료 로드아웃 원복")

	var codex = p5.get("codex")
	var completed: PackedStringArray = codex.call(&"record_extraction", {&"arc_rune": 3})
	_check(completed.has("codex_arc"), "도감 탈출 누적 완료")
	_check(String(codex.call(&"get_entry", &"codex_arc").get(&"region_hint", "")) == "ruined_district", "도감 지역 힌트")

	var reloaded := PROFILE_SCENE.instantiate()
	sandbox.add_child(reloaded)
	reloaded.call(&"configure", PROFILE_PATH, true)
	var reloaded_snapshot: Dictionary = reloaded.call(&"get_snapshot")
	_check(&"assault_blueprint" in (reloaded_snapshot.get(&"registered_blueprint_ids", []) as Array), "도면 재접속 유지")
	_check(int(reloaded_snapshot.get(&"codex_progress", {}).get(&"codex_arc", 0)) == 3, "도감 재접속 유지")
	_check(&"shop-buy-1" in (reloaded_snapshot.get(&"processed_transaction_ids", []) as Array), "상점 거래 ID 재접속 유지")
	var remaining := int(profile.call(&"get_snapshot").get(&"banked_credits", 0))
	profile.call(&"spend", remaining)
	_check(bool(p5.call(&"get_snapshot").get(&"bankruptcy", {}).get(&"repeatable_free_sortie", false)), "파산 무료 프리셋 반복 가능")

	var optional_config = load("res://game/features/p5_hub_progression/configs/default_p5_hub_progression.tres").duplicate(true)
	for property_name in ["utility_enabled", "operation_draft_enabled", "bankruptcy_preset_enabled", "rotating_shop_enabled", "workshop_enabled", "training_enabled", "codex_enabled"]:
		optional_config.set(property_name, false)
	var optional_p5 := P5_SCENE.instantiate()
	sandbox.add_child(optional_p5)
	_check(optional_p5.call(&"configure", profile, contract, optional_config, 1), "P5 하위 모듈 전부 제거 가능")
	var optional_snapshot: Dictionary = optional_p5.call(&"get_snapshot")
	_check((optional_snapshot.get(&"shop", {}) as Dictionary).is_empty() and (optional_snapshot.get(&"codex", {}) as Dictionary).is_empty(), "제거 모듈 상태 미설치")

	if FileAccess.file_exists(PROFILE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE_PATH))
	if failures.is_empty():
		print("P5_HUB_PROGRESSION_OK utility_draft_atomic bankruptcy_repeat shop_quality_rotation_no_double_debit workshop_blueprint_persistence_affix_socket training_telemetry_restore codex_progress_hint_persistence optional_submodules shop_transaction_persistence")
		quit(0)
	else:
		print("P5_HUB_PROGRESSION_FAILED: %s" % " / ".join(failures))
		quit(1)


func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
