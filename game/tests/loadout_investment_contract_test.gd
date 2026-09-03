extends SceneTree

const GAME_SCENE := preload("res://game/scenes/game.tscn")
const SERVICE_SCENE := preload(
	"res://game/features/loadout_investment/loadout_investment_service.tscn"
)
const CONFIG := preload(
	"res://game/features/loadout_investment/configs/default_loadout_investment.tres"
)
const PROFILE_SCENE := preload(
	"res://game/features/persistent_profile/persistent_profile.tscn"
)


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	if not _verify_manifest_boundary():
		return
	if not await _verify_service_states():
		return
	if not await _verify_player_visible_flow():
		return
	print("LOADOUT_INVESTMENT_E2E_OK owned_locked_run_purchase skill_price_once equipped_weapon_preserved tag_gate hub_module_part_preserved same_weapon_customization no_catalog_override preflight modular_boundary")
	quit(0)


func _verify_manifest_boundary() -> bool:
	var manifest: Resource = load("res://game/core/feature_manifest.tres").duplicate(true)
	if &"loadout_investment" not in manifest.call(&"enabled_module_ids"):
		return _fail("loadout_investment이 활성 모듈 목록에 없습니다.")
	manifest.set("loadout_investment_enabled", false)
	if &"loadout_investment" in manifest.call(&"enabled_module_ids"):
		return _fail("loadout_investment을 독립적으로 끌 수 없습니다.")
	manifest.set("loadout_investment_enabled", true)
	manifest.set("operation_contracts_enabled", false)
	if not manifest.call(&"validation_errors").has("loadout_investment는 operation_contracts 모듈이 필요합니다."):
		return _fail("작전 계약 의존성이 검증되지 않습니다.")
	manifest.set("operation_contracts_enabled", true)
	manifest.set("combat_skills_enabled", false)
	if not manifest.call(&"validation_errors").has("loadout_investment는 equipment·combat_skills 모듈이 필요합니다."):
		return _fail("장비·스킬 의존성이 검증되지 않습니다.")
	return true


func _verify_service_states() -> bool:
	var profile = PROFILE_SCENE.instantiate()
	var service = SERVICE_SCENE.instantiate()
	root.add_child(profile)
	root.add_child(service)
	await process_frame
	profile.call(&"configure", "user://sfh_loadout_investment_unit_profile.json", false)
	if not service.call(&"configure", CONFIG, profile):
		return _fail("확정 Weapon·Skill 투자 CSV를 구성하지 못했습니다.")
	var snapshot: Dictionary = service.call(&"get_snapshot")
	if snapshot.get(&"weapons", {}).get(&"main", {}).get(&"state") != &"owned":
		return _fail("기본 무기가 소유 상태로 표시되지 않습니다: %s" % snapshot)
	service.call(&"select_weapon", &"main", &"pulse_rifle")
	service.call(&"select_skill", 2, &"arc_dash")
	snapshot = service.call(&"get_snapshot")
	if snapshot.get(&"weapons", {}).get(&"main", {}).get(&"state") != &"locked":
		return _fail("미해금 무기 상태가 구분되지 않습니다: %s" % snapshot)
	profile.call(&"unlock", &"region_industrial_district")
	profile.call(&"unlock", &"region_research_complex")
	snapshot = service.call(&"get_snapshot")
	if int(snapshot.get(&"additional_entry_cost", 0)) != 140 or not bool(snapshot.get(&"selection_ready", false)):
		return _fail("런 구매 비용·해금 상태가 올바르지 않습니다: %s" % snapshot)
	if not service.call(&"commit_run_purchase", &"unit-run"):
		return _fail("런 구매 확정에 실패했습니다.")
	if snapshot.get(&"weapons", {}).get(&"main", {}).get(&"state") == &"run_purchased":
		return _fail("구매 확정 전 상태가 구매 완료로 오인됩니다.")
	snapshot = service.call(&"get_snapshot")
	if snapshot.get(&"weapons", {}).get(&"main", {}).get(&"state") != &"run_purchased":
		return _fail("구매 완료 상태가 구분되지 않습니다: %s" % snapshot)
	service.call(&"finish_run")
	root.remove_child(service)
	service.free()
	root.remove_child(profile)
	profile.free()
	return true


func _verify_player_visible_flow() -> bool:
	var game = GAME_SCENE.instantiate()
	var features: Resource = game.get("features").duplicate(true)
	var paths := {
		"persistent_profile_storage_path": "user://sfh_loadout_investment_profile.json",
		"conditional_ranking_storage_path": "user://sfh_loadout_investment_rankings.json",
		"meta_progression_storage_path": "user://sfh_loadout_investment_meta.json",
		"key_mapping_storage_path": "user://sfh_loadout_investment_keys.json",
		"skill_binding_storage_path": "user://sfh_loadout_investment_skills.json",
		"presentation_settings_storage_path": "user://sfh_loadout_investment_presentation.json",
	}
	for property_name in paths:
		features.set(property_name, paths[property_name])
	game.set("features", features)
	root.add_child(game)
	await process_frame
	await process_frame
	var profile = game.get("persistent_profile")
	var service = game.get("loadout_investment_service")
	if profile == null or service == null:
		return _fail("게임 조립에서 프로필 또는 런 투자 서비스를 찾지 못했습니다.")
	profile.call(&"reset_profile", true)
	var prepared_equipment = game.get("equipment_system")
	if (
		prepared_equipment == null
		or not bool(prepared_equipment.call(
			&"install_module", &"main", &"launch_ballistic",
			load("res://game/features/equipment/definitions/modules/ballistic_core.tres")
		))
		or not bool(prepared_equipment.call(
			&"install_part", &"main",
			load("res://game/features/equipment/definitions/parts/rifle_scope.tres")
		))
	):
		return _fail("출격 전 모듈·파츠 장착 상태를 만들지 못했습니다.")
	if service.call(&"select_weapon", &"main", &"pulse_rifle"):
		return _fail("로비 장비 보존 모드에서 카탈로그 무기 교체를 허용했습니다.")
	service.call(&"select_skill", 2, &"arc_dash")
	await process_frame
	if not service.call(&"get_investment_context")[&"weapon_paths"].is_empty():
		return _fail("계약에 장비 덮어쓰기 경로가 남아 있습니다.")
	var credits_before := int(profile.call(&"get_snapshot").get(&"banked_credits", 0))
	if game.call(&"start_run", "small"):
		return _fail("미해금 런 장비로 작전에 진입했습니다.")
	if int(profile.call(&"get_snapshot").get(&"banked_credits", 0)) != credits_before:
		return _fail("거절된 작전에서 크레딧이 차감됐습니다.")
	profile.call(&"unlock", &"region_industrial_district")
	profile.call(&"unlock", &"region_research_complex")
	await process_frame
	var tier_config: Resource = load("res://game/features/map_generation/configs/small.tres")
	var base_quote: Dictionary = game.get("operation_contract_service").call(&"quote", tier_config, {}, {})
	var quote: Dictionary = game.get("operation_contract_service").call(
		&"quote", tier_config, {}, game.call(&"_operation_investment_context")
	)
	if int(quote.get(&"entry_cost", 0)) - int(base_quote.get(&"entry_cost", 0)) != 60:
		return _fail("스킬 비용 외에 장착 무기를 다시 청구했습니다: %s" % quote)
	if not game.call(&"start_run", "small"):
		return _fail("해금 후 런 장비 투자 작전에 진입하지 못했습니다.")
	await process_frame
	await process_frame
	var spent := credits_before - int(profile.call(&"get_snapshot").get(&"banked_credits", 0))
	if spent != int(quote.get(&"entry_cost", 0)):
		return _fail("계약 총액이 한 번만 차감되지 않았습니다: %d / %s" % [spent, quote])
	var equipment = game.get("equipment_system")
	var main_weapon: Resource = equipment.call(&"get_weapon", &"main") if equipment != null else null
	if main_weapon == null or main_weapon.get("weapon_id") != &"assault_rifle":
		return _fail("실제 로비 메인 무기가 출격 시 교체됐습니다.")
	var transient_state: EquipmentItemState = equipment.call(&"get_equipment_state", &"main")
	if transient_state.installed_modules.size() != 1 or transient_state.installed_parts.size() != 1:
		return _fail("로비 모듈·파츠가 출격에서 유실됐습니다.")
	var skill_system = game.get("combat_skill_system")
	var states: Array[Dictionary] = skill_system.call(&"get_skill_states") if skill_system != null else []
	if states.size() < 3 or states[2].get(&"skill_id") != &"arc_dash" or not bool(states[2].get(&"weapon_tags_ready", false)):
		return _fail("로비 무기의 태그가 스킬에 적용되지 않았습니다: %s" % [states])
	if not bool(skill_system.call(&"try_activate", 2)):
		return _fail("태그가 일치하는 아크 질주가 발동하지 않았습니다.")
	equipment.call(&"set_active_weapon_slot", &"secondary")
	states = skill_system.call(&"get_skill_states")
	if bool(states[2].get(&"weapon_tags_ready", true)):
		return _fail("비전격 보조 무기에서 스킬 태그 불일치가 표시되지 않았습니다.")
	equipment.call(&"set_active_weapon_slot", &"main")
	game.call(&"_abandon_run_to_start_hub")
	await process_frame
	var hub_equipment = game.get("equipment_system")
	var restored: Resource = hub_equipment.call(&"get_weapon", &"main") if hub_equipment != null else null
	if restored == null or restored.get("weapon_id") != &"assault_rifle":
		return _fail("런 구매 무기가 거점 장비를 영구 덮어썼습니다.")
	var restored_state: EquipmentItemState = hub_equipment.call(&"get_equipment_state", &"main")
	if restored_state.installed_modules.size() != 1 or restored_state.installed_parts.size() != 1:
		return _fail("런 구매 총기 사용 후 거점 모듈·파츠 상태가 복원되지 않았습니다.")
	var after: Dictionary = service.call(&"get_snapshot")
	if after.get(&"active_run_id", &"") != &"" or not after.get(&"equipped_weapons_only", false):
		return _fail("복귀 후 런 구매 상태가 초기화되지 않았습니다: %s" % after)
	service.call(&"select_weapon", &"main", &"assault_rifle")
	service.call(&"select_skill", 2, &"speed_boost")
	if not game.call(&"start_run", "small"):
		return _fail("거점 총기와 동일한 작전 총기로 재투입하지 못했습니다: %s" % game.get("status_label").text)
	await process_frame
	var same_weapon_state: EquipmentItemState = game.get("equipment_system").call(
		&"get_equipment_state", &"main"
	)
	if same_weapon_state.installed_modules.size() != 1 or same_weapon_state.installed_parts.size() != 1:
		return _fail("동일 총기 출격에서 모듈·파츠가 유지되지 않았습니다.")
	game.call(&"_abandon_run_to_start_hub")
	await process_frame
	root.remove_child(game)
	game.free()
	for path in paths.values():
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	return true


func _fail(message: String) -> bool:
	push_error(message)
	quit(1)
	return false
