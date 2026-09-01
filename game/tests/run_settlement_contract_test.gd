extends SceneTree

const PROFILE_PATH := "user://sfh_run_settlement_test_profile.json"
const LIFECYCLE_SCENE := preload(
	"res://game/features/loot_lifecycle/loot_lifecycle_service.tscn"
)
const PROFILE_SCENE := preload(
	"res://game/features/persistent_profile/persistent_profile.tscn"
)
const SETTLEMENT_SCENE := preload(
	"res://game/features/run_settlement/run_settlement_service.tscn"
)


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	_cleanup()
	var lifecycle = LIFECYCLE_SCENE.instantiate()
	var profile = PROFILE_SCENE.instantiate()
	var settlement = SETTLEMENT_SCENE.instantiate()
	root.add_child(lifecycle)
	root.add_child(profile)
	root.add_child(settlement)
	await process_frame
	var lifecycle_config: Resource = load(
		"res://game/features/loot_lifecycle/configs/default_loot_lifecycle.tres"
	).duplicate(true)
	lifecycle_config.set("source_mode", 0)
	if not lifecycle.call(&"configure", lifecycle_config):
		_fail("확정 Item 생명 주기를 불러오지 못했습니다.")
		return
	profile.call(&"configure", PROFILE_PATH, true)
	profile.call(&"reset_profile", true)
	if not settlement.call(
		&"configure", lifecycle, profile,
		load("res://game/features/operation_results/configs/default_operation_results.tres")
	):
		_fail("런 정산 서비스를 구성하지 못했습니다.")
		return
	var acquired := {
		&"arc_rune": {&"quantity": 2},
		&"capacitor_core": {&"quantity": 1},
		&"phase_artifact": {&"quantity": 1},
		&"tactical_vest_blueprint": {&"quantity": 1},
		&"ballistic_core_item": {&"quantity": 2},
		&"pulse_rifle": {&"quantity": 1},
	}
	var before: Dictionary = profile.call(&"get_snapshot")
	var success: Dictionary = settlement.call(&"settle", &"success-001", acquired, true)
	var after_success: Dictionary = profile.call(&"get_snapshot")
	if (
		not bool(success.get(&"success", false))
		or int(success.get(&"converted_credits", 0)) != 450
		or int(after_success.get(&"banked_credits", 0)) != int(before.get(&"banked_credits", 0)) + 450
		or int((after_success.get(&"warehouse", {}) as Dictionary).get(&"ballistic_core_item", 0)) != 2
		or int((after_success.get(&"blueprints", {}) as Dictionary).get(&"tactical_vest_blueprint", 0)) != 1
		or &"buy_tactical_vest" not in (after_success.get(&"unlocked_shop_offer_ids", []) as Array)
		or int((success.get(&"expired_items", {}) as Dictionary).get(&"pulse_rifle", 0)) != 1
		or not (success.get(&"lost_items", {}) as Dictionary).is_empty()
	):
		_fail("탈출 자동 환전·창고 보관·영구 해금 결과가 올바르지 않습니다: %s" % success)
		return
	var duplicate: Dictionary = settlement.call(&"settle", &"success-001", acquired, true)
	var after_duplicate: Dictionary = profile.call(&"get_snapshot")
	if (
		not bool(duplicate.get(&"duplicate_ignored", false))
		or int(after_duplicate.get(&"banked_credits", 0)) != int(after_success.get(&"banked_credits", 0))
		or int((after_duplicate.get(&"warehouse", {}) as Dictionary).get(&"ballistic_core_item", 0)) != 2
	):
		_fail("동일 run_id 중복 정산이 자산을 다시 지급했습니다.")
		return
	var failure: Dictionary = settlement.call(&"settle", &"failure-001", acquired, false)
	var after_failure: Dictionary = profile.call(&"get_snapshot")
	if (
		bool(failure.get(&"extracted", true))
		or (failure.get(&"lost_items", {}) as Dictionary).size() != acquired.size()
		or not (failure.get(&"expired_items", {}) as Dictionary).is_empty()
		or int(after_failure.get(&"banked_credits", 0)) != int(after_success.get(&"banked_credits", 0))
		or int((after_failure.get(&"warehouse", {}) as Dictionary).get(&"ballistic_core_item", 0)) != 2
		or int(settlement.call(&"get_snapshot").get(&"processed_run_count", 0)) != 2
	):
		_fail("사망 전리품 소실 또는 정산 이력 계약이 올바르지 않습니다: %s" % failure)
		return
	_cleanup()
	print("RUN_SETTLEMENT_OK auto_convert_450 permanent_unlock warehouse run_only_expiry death_loss idempotent_run_id")
	quit(0)


func _cleanup() -> void:
	if FileAccess.file_exists(PROFILE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE_PATH))


func _fail(message: String) -> void:
	_cleanup()
	push_error(message)
	quit(1)
