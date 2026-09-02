extends SceneTree

const PROFILE_SCENE := preload("res://game/features/persistent_profile/persistent_profile.tscn")
const CONTRACT_SCENE := preload("res://game/features/operation_contract/operation_contract_service.tscn")
const PREFLIGHT_SCENE := preload("res://game/features/operation_launch/operation_launch_preflight_service.tscn")
const LOOT_VALIDATOR_SCENE := preload("res://game/features/operation_launch/loot_launch_validator.tscn")
const EQUIPMENT_SCENE := preload("res://game/features/equipment/equipment_system.tscn")
const INVENTORY_SCENE := preload("res://game/features/inventory/grid_inventory.tscn")
const PLAYER_SCENE := preload("res://game/features/player/player.tscn")
const PROFILE_PATH := "user://sfh_preflight_contract_profile.json"


class SettingContributor extends Node:
	var contributor_id: StringName
	var context_key: StringName
	var cost: int
	var context: Dictionary
	var errors := PackedStringArray()

	func setup(id: StringName, key: StringName, price: int, payload: Dictionary) -> SettingContributor:
		contributor_id = id
		context_key = key
		cost = price
		context = payload
		return self

	func get_operation_setting_contribution() -> Dictionary:
		return {
			&"contributor_id": contributor_id,
			&"context_key": context_key,
			&"additional_entry_cost": cost,
			&"context": context,
			&"validation_errors": errors,
			&"revision": &"test",
		}


class RejectingValidator extends Node:
	func validate_operation_launch(_request: Dictionary) -> PackedStringArray:
		return PackedStringArray(["강제 검증 실패"])


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	var manifest: Resource = load("res://game/core/feature_manifest.tres").duplicate(true)
	if &"operation_launch_preflight" not in manifest.call(&"enabled_module_ids"):
		return _fail("사전검증 모듈이 활성 모듈 목록에 없습니다.")
	manifest.set("operation_launch_preflight_enabled", false)
	if &"operation_launch_preflight" in manifest.call(&"enabled_module_ids"):
		return _fail("사전검증 모듈을 독립적으로 끌 수 없습니다.")
	manifest.set("operation_launch_preflight_enabled", true)
	manifest.set("operation_contracts_enabled", false)
	if not manifest.call(&"validation_errors").has("operation_launch_preflight는 operation_contracts 모듈이 필요합니다."):
		return _fail("사전검증 모듈의 작전 계약 의존성이 검증되지 않습니다.")
	if FileAccess.file_exists(PROFILE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE_PATH))
	var host := Node.new()
	root.add_child(host)
	var profile := PROFILE_SCENE.instantiate()
	var contract := CONTRACT_SCENE.instantiate()
	var preflight := PREFLIGHT_SCENE.instantiate()
	var loot_validator := LOOT_VALIDATOR_SCENE.instantiate()
	host.add_child(profile)
	host.add_child(contract)
	host.add_child(preflight)
	host.add_child(loot_validator)
	if not bool(profile.call(&"configure", PROFILE_PATH, true)):
		return _fail("프로필 구성 실패")
	profile.call(&"reset_profile", true)
	if not bool(contract.call(
		&"configure", profile,
		load("res://game/features/operation_contract/configs/default_operation_contracts.tres")
	)):
		return _fail("작전 계약 구성 실패")
	if not bool(preflight.call(&"configure", contract, profile)):
		return _fail("작전 사전검증 구성 실패")
	var character := SettingContributor.new().setup(
		&"character", &"", 25, {&"character_id": &"future_agent"}
	)
	var future_setting := SettingContributor.new().setup(
		&"future_socket_policy", &"future_socket_policy", 75,
		{&"socket_count": 4, &"mode": &"experimental"}
	)
	host.add_child(character)
	host.add_child(future_setting)
	if (
		not bool(preflight.call(&"register_contributor", &"character", character))
		or not bool(preflight.call(&"register_contributor", &"future_socket_policy", future_setting))
		or not bool(loot_validator.call(&"configure", "res://game/features/loot/configs/%s.tres"))
		or not bool(preflight.call(&"register_validator", &"loot", loot_validator))
	):
		return _fail("기여자 또는 전리품 검증기 등록 실패")
	var credits_before := int(profile.call(&"get_snapshot").get(&"banked_credits", 0))
	var tier := load("res://game/features/map_generation/configs/small.tres")
	var plan: Dictionary = preflight.call(&"create_plan", tier, {}, {&"map_seed": 9001})
	var context: Dictionary = plan.get(&"investment_context", {})
	if (
		not bool(plan.get(&"success", false))
		or not bool(preflight.call(&"validate_plan", plan))
		or int(context.get(&"additional_entry_cost", -1)) != 100
		or context.get(&"character_id", &"") != &"future_agent"
		or int(context.get(&"future_socket_policy", {}).get(&"socket_count", 0)) != 4
		or int(plan.get(&"quote", {}).get(&"entry_cost", 0)) != 200
	):
		return _fail("확장 기여자 계획 집계 실패: %s" % plan)
	if int(profile.call(&"get_snapshot").get(&"banked_credits", 0)) != credits_before:
		return _fail("사전검증 단계에서 크레딧이 차감됐습니다.")
	var tampered := plan.duplicate(true)
	tampered[&"investment_context"][&"additional_entry_cost"] = 999
	if bool(preflight.call(&"validate_plan", tampered)):
		return _fail("변조된 불변 계획이 허용됐습니다.")
	var unsafe_setting := SettingContributor.new().setup(
		&"unsafe_setting", &"unsafe_setting", 0, {&"runtime_node": host}
	)
	host.add_child(unsafe_setting)
	preflight.call(&"register_contributor", &"unsafe_setting", unsafe_setting)
	var unsafe_plan: Dictionary = preflight.call(&"create_plan", tier, {}, {&"map_seed": 90015})
	if bool(unsafe_plan.get(&"success", true)) or "복사 가능한 값" not in String(unsafe_plan.get(&"reason", "")):
		return _fail("런타임 Object가 설정 스냅샷에 포함됐습니다: %s" % unsafe_plan)
	preflight.call(&"unregister_contributor", &"unsafe_setting")
	var rejecting := RejectingValidator.new()
	host.add_child(rejecting)
	preflight.call(&"register_validator", &"forced_failure", rejecting)
	var rejected: Dictionary = preflight.call(&"create_plan", tier, {}, {&"map_seed": 9002})
	if bool(rejected.get(&"success", true)) or "강제 검증 실패" not in String(rejected.get(&"reason", "")):
		return _fail("검증기 실패가 결제 전 계획을 차단하지 못했습니다: %s" % rejected)
	if int(profile.call(&"get_snapshot").get(&"banked_credits", 0)) != credits_before:
		return _fail("거절된 계획에서 크레딧이 차감됐습니다.")
	preflight.call(&"unregister_validator", &"forced_failure")
	if not _verify_equipment_and_inventory_validation(host):
		return
	if not _verify_free_loot_contract():
		return
	root.remove_child(host)
	host.free()
	if FileAccess.file_exists(PROFILE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE_PATH))
	print("OPERATION_PREFLIGHT_OK generic_contributors immutable_plan no_debit_before_validation validator_rejection equipment_module_part_revalidation inventory_overlap_rejection future_setting_extension free_loot_contract")
	quit(0)


func _verify_equipment_and_inventory_validation(host: Node) -> bool:
	var player := PLAYER_SCENE.instantiate()
	var equipment := EQUIPMENT_SCENE.instantiate()
	var inventory := INVENTORY_SCENE.instantiate()
	host.add_child(player)
	host.add_child(equipment)
	host.add_child(inventory)
	if not bool(equipment.call(
		&"configure", load("res://game/features/equipment/loadouts/default_loadout.tres"),
		player, true, true, true
	)):
		return _fail("장비 검증 샌드박스 구성 실패")
	if not bool(inventory.call(
		&"configure", load("res://game/features/inventory/catalogs/default_inventory.tres")
	)):
		return _fail("가방 검증 샌드박스 구성 실패")
	var module_definition := load("res://game/features/equipment/definitions/modules/ballistic_core.tres")
	var part_definition := load("res://game/features/equipment/definitions/parts/rifle_scope.tres")
	if (
		not bool(equipment.call(&"install_module", &"main", &"preflight_module", module_definition))
		or not bool(equipment.call(&"install_part", &"main", part_definition))
	):
		return _fail("검증용 모듈·파츠 장착 실패")
	var equipment_state: Dictionary = equipment.call(&"export_runtime_state")
	var request := {
		&"runtime_context": {&"equipment_state": equipment_state},
		&"investment_context": {&"loadout_investment": {
			&"weapon_paths": {&"main": "res://game/features/equipment/definitions/weapons/pulse_rifle.tres"},
		}},
	}
	var equipment_errors: PackedStringArray = equipment.call(&"validate_operation_launch", request)
	if not equipment_errors.is_empty():
		return _fail("유효한 모듈·파츠 상태 또는 작전 총기 교체가 거부됐습니다: %s" % " / ".join(equipment_errors))
	var invalid_equipment := equipment_state.duplicate(true)
	var invalid_main := (invalid_equipment[&"equipment_states"][&"main"] as EquipmentItemState)
	invalid_main.installed_parts.append(part_definition)
	if invalid_main.installed_parts.size() != 2:
		return _fail("중복 파츠 검증 상태를 만들지 못했습니다: %d" % invalid_main.installed_parts.size())
	if invalid_main.validation_errors().is_empty():
		return _fail("장비 상태 자체가 중복 파츠를 감지하지 못했습니다.")
	var invalid_request := request.duplicate(true)
	invalid_request[&"runtime_context"] = {&"equipment_state": invalid_equipment}
	var invalid_equipment_errors: PackedStringArray = equipment.call(&"validate_operation_launch", invalid_request)
	if invalid_equipment_errors.is_empty():
		var direct_errors: PackedStringArray = equipment.call(&"validate_runtime_state", invalid_equipment)
		return _fail("중복 파츠 소켓 상태를 사전검증이 허용했습니다: direct=%s" % direct_errors)
	var inventory_state: Dictionary = inventory.call(&"export_runtime_state")
	var ids := (inventory_state[&"placements"] as Dictionary).keys()
	if ids.size() < 2:
		return _fail("가방 중첩 검증용 아이템이 부족합니다.")
	inventory_state[&"placements"][ids[1]] = inventory_state[&"placements"][ids[0]]
	if (inventory.call(&"validate_runtime_state", inventory_state) as PackedStringArray).is_empty():
		return _fail("겹친 가방 상태를 사전검증이 허용했습니다.")
	return true


func _verify_free_loot_contract() -> bool:
	var policy = load("res://game/features/loot/loot_value_allocation_policy.gd").new()
	var config := load("res://game/features/loot/configs/small.tres")
	var random := RandomNumberGenerator.new()
	random.seed = 1
	var allocation: Dictionary = policy.call(&"allocate", config, 0, random)
	return _check(
		bool(allocation.get(&"success", false))
		and int(allocation.get(&"minimum_total_credits", -1)) == int(allocation.get(&"target_total_credits", -2))
		and int(allocation.get(&"maximum_total_credits", -1)) == int(allocation.get(&"target_total_credits", -2)),
		"0원 작전의 최소·최대·목표 회수 가치 계약이 일치하지 않습니다."
	)


func _check(condition: bool, message: String) -> bool:
	if not condition:
		return _fail(message)
	return true


func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
