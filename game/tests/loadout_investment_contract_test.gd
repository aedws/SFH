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

class ExtensionEffect:
	extends CombatSkillEffect
	func activate(_player: Node2D, _context: Dictionary) -> Dictionary:
		return {&"success": true, &"extension_probe": true}


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	if not _verify_manifest_boundary():
		return
	if not await _verify_service_states():
		return
	if not _verify_binding_extension():
		return
	if not await _verify_player_visible_flow():
		return
	print("LOADOUT_INVESTMENT_E2E_OK owned_locked_run_purchase skill_price_once equipped_weapon_preserved tag_gate hub_module_part_preserved same_weapon_customization no_catalog_override preflight modular_boundary remapped_launch physical_skill_input runtime_settings nested_swap_restore save_failure_atomic future_definition")
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
	game.skill_binding_service.reset_defaults()
	if not game.skill_binding_service.assign_skill(&"speed_boost", &"combat_skill_9").success:
		return _fail("스킬 사용자 슬롯 fixture 실패")
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
	if states[2].input_action != &"combat_skill_9":
		return _fail("교체 스킬이 사용자가 지정한 9번 슬롯을 잃었습니다.")
	var binding_ids: Array = game.skill_binding_service.get_entries().map(func(row): return row.skill_id)
	if &"arc_dash" not in binding_ids or &"speed_boost" in binding_ids:
		return _fail("설정 UI가 교체 전 스킬을 표시합니다.")
	if game.operation_tutorial_overlay != null:
		game.operation_tutorial_overlay.dismiss()
	var activated: Array[StringName] = []
	skill_system.skill_activated.connect(func(_slot, id, _result): activated.append(id))
	await _tap(KEY_9)
	if &"arc_dash" not in activated:
		return _fail("실제 사용자 9번 입력으로 교체 스킬이 발동하지 않았습니다.")
	await _tap(KEY_K)
	var keys = game.key_mapping_panel
	if not keys.visible or not keys.skill_binding_buttons.has(&"arc_dash") or keys.skill_binding_buttons.has(&"speed_boost"):
		return _fail("K 화면이 현재 교체 스킬을 표시하지 않습니다.")
	(keys.skill_rows_container.get_parent().get_parent() as TabContainer).current_tab = 1
	await process_frame
	keys.skill_binding_buttons[&"arc_dash"].grab_focus()
	await _tap(KEY_ENTER)
	if game.skill_binding_service.action_for_skill(&"arc_dash") != &"combat_skill_1":
		return _fail("K 스킬 다음 슬롯 버튼의 실제 Enter 입력 실패")
	await _tap(KEY_ESCAPE)
	if paused:
		return _fail("K 닫기 후 전투 일시정지가 남았습니다.")
	if not game.skill_binding_service.assign_skill(&"arc_dash", &"combat_skill_7").success:
		return _fail("실전에서 교체 스킬 키를 바꿀 수 없습니다.")
	equipment.call(&"set_active_weapon_slot", &"secondary")
	states = skill_system.call(&"get_skill_states")
	if bool(states[2].get(&"weapon_tags_ready", true)):
		return _fail("비전격 보조 무기에서 스킬 태그 불일치가 표시되지 않았습니다.")
	equipment.call(&"set_active_weapon_slot", &"main")
	var future: Resource = load("res://game/features/combat_skills/definitions/arc_dash.tres").duplicate(true)
	future.skill_id = &"test_future_effect"
	future.effect = ExtensionEffect.new()
	var invalid: Resource = future.duplicate(true)
	invalid.effect = Resource.new()
	if invalid.is_valid() or bool(skill_system.preview_skill_replacement(2, invalid).get(&"available", false)):
		return _fail("실행 계약 없는 효과를 스킬로 허용했습니다.")
	var future_result: Dictionary = skill_system.replace_skill(2, future)
	if not future_result.success or not game.skill_binding_service.replace_runtime_skill(&"arc_dash", future.skill_id, &"combat_skill_7", future):
		return _fail("Resource 효과 교체 확장 실패")
	var effect_results: Array = []
	skill_system.skill_activated.connect(func(_slot, _id, result): effect_results.append(result))
	await _tap(KEY_7)
	if effect_results.is_empty() or not effect_results.back().get(&"extension_probe", false):
		return _fail("신규 효과가 실제 키 실행기에 연결되지 않았습니다.")
	skill_system.restore_skill_replacement(2, future_result.previous_definition, future_result.previous_cooldown, future_result.previous_resource_state)
	game.skill_binding_service.restore_runtime_skill(future.skill_id, &"arc_dash", &"combat_skill_7")
	game.call(&"_abandon_run_to_start_hub")
	await process_frame
	if game.skill_binding_service.action_for_skill(&"speed_boost") != &"combat_skill_7":
		return _fail("복귀 시 최근 사용자 슬롯을 잃었습니다.")
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


func _tap(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame


func _verify_binding_extension() -> bool:
	var bindings := SkillBindingService.new()
	var base: Resource = load("res://game/features/combat_skills/configs/default_combat_skills.tres").duplicate(true)
	var profile: Resource = load("res://game/features/skill_binding/configs/default_skill_bindings.tres")
	var path := "user://sfh_binding_extension_test.json"
	if not bindings.configure(base, profile, path, null, false):
		return _fail("binding extension setup")
	var arc: Resource = load("res://game/features/combat_skills/definitions/arc_dash.tres").duplicate(true)
	var future: Resource = arc.duplicate(true)
	future.skill_id = &"test_future_skill"
	future.display_name = "시험 확장 스킬"
	if not bindings.replace_runtime_skill(&"speed_boost", &"arc_dash", &"combat_skill_3", arc):
		return _fail("runtime A")
	if not bindings.replace_runtime_skill(&"arc_dash", future.skill_id, &"combat_skill_3", future):
		return _fail("runtime B without central skill-id branch")
	if not bindings.assign_skill(future.skill_id, &"combat_skill_1").success:
		return _fail("runtime collision swap")
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path)).bindings
	if saved.has("arc_dash") or saved.has("test_future_skill") or saved.get("speed_boost") != "combat_skill_1":
		return _fail("temporary IDs persisted instead of permanent slot owner")
	var snapshot := bindings.get_snapshot()
	bindings.storage_path = "user://missing_sfh_binding_directory/test.json"
	var rejected: Dictionary = bindings.assign_skill(future.skill_id, &"combat_skill_9")
	bindings.storage_path = path
	if rejected.success or bindings.get_snapshot() != snapshot:
		return _fail("save failure changed current bindings")
	if not bindings.restore_runtime_skill(future.skill_id, &"arc_dash", &"combat_skill_3") or not bindings.restore_runtime_skill(&"arc_dash", &"speed_boost", &"combat_skill_3"):
		return _fail("nested runtime restore")
	if bindings.action_for_skill(&"speed_boost") != &"combat_skill_1" or bindings.action_for_skill(&"blink") != &"combat_skill_3" or bindings.runtime_replacement_count != 0:
		return _fail("restore clobbered remapped or displaced skill")
	if not bindings.replace_runtime_skill(&"speed_boost", &"arc_dash", &"combat_skill_1", arc) or not bindings.reset_defaults():
		return _fail("reset during runtime swap")
	if bindings.action_for_skill(&"arc_dash") != &"combat_skill_3" or bindings.action_for_skill(&"speed_boost") != &"":
		return _fail("reset resurrected inactive skill")
	bindings.restore_runtime_skill(&"arc_dash", &"speed_boost", &"combat_skill_1")
	bindings.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	return true
