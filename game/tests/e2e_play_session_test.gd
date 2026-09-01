extends SceneTree

const GAME_SCENE_PATH := "res://game/scenes/game.tscn"
const E2E_PROFILE_PATH := "user://sfh_e2e_profile.json"
const E2E_RANKINGS_PATH := "user://sfh_e2e_rankings.json"
const E2E_META_PATH := "user://sfh_e2e_meta_progression.json"
const E2E_KEY_MAPPING_PATH := "user://sfh_e2e_key_mapping.json"
const E2E_SKILL_BINDING_PATH := "user://sfh_e2e_skill_bindings.json"
const UI_STATE_JUDGE_SCRIPT := preload("res://game/tests/support/ui_state_judge.gd")
const PLAYER_PERCEPTION_JUDGE_SCRIPT := preload(
	"res://game/tests/support/player_perception_judge.gd"
)
const GAMEPLAY_FLOW_JUDGE_SCRIPT := preload(
	"res://game/tests/support/gameplay_flow_judge.gd"
)

var game: Node
var ui_state_judge := UI_STATE_JUDGE_SCRIPT.new()
var player_perception_judge := PLAYER_PERCEPTION_JUDGE_SCRIPT.new()
var gameplay_flow_judge := GAMEPLAY_FLOW_JUDGE_SCRIPT.new()
var judged_ui_states := PackedStringArray()
var judged_perception_checkpoints := PackedStringArray()
var judged_perception_units := {}
var judged_gameplay_flows := PackedStringArray()


func _init() -> void:
	_reset_test_profile()
	call_deferred(&"_run")


func _run() -> void:
	var game_scene := load(GAME_SCENE_PATH) as PackedScene
	if game_scene == null:
		_fail("게임 장면을 불러오지 못했습니다.")
		return
	game = game_scene.instantiate()
	var isolated_features: Resource = game.get("features").duplicate(true)
	isolated_features.set("persistent_profile_storage_path", E2E_PROFILE_PATH)
	isolated_features.set("conditional_ranking_storage_path", E2E_RANKINGS_PATH)
	isolated_features.set("meta_progression_storage_path", E2E_META_PATH)
	isolated_features.set("key_mapping_storage_path", E2E_KEY_MAPPING_PATH)
	isolated_features.set("skill_binding_storage_path", E2E_SKILL_BINDING_PATH)
	game.set("features", isolated_features)
	root.add_child(game)
	await process_frame
	await process_frame
	var cyberpunk_presentation = game.get("cyberpunk_overlay")
	var cyberpunk_snapshot: Dictionary = (
		cyberpunk_presentation.call(&"get_snapshot") if cyberpunk_presentation != null else {}
	)
	var cyberpunk_screen := (
		cyberpunk_presentation.get_node_or_null("ScreenFX") as Control
		if cyberpunk_presentation != null else null
	)
	if (
		cyberpunk_screen == null
		or cyberpunk_screen.mouse_filter != Control.MOUSE_FILTER_IGNORE
		or cyberpunk_snapshot.get(&"accent_hex", "") != "#02e5e1"
		or cyberpunk_screen.size != get_root().get_visible_rect().size
	):
		_fail("사이버펑크 화면 효과가 입력을 가로채거나 뷰포트를 채우지 못했습니다.")
		return

	if not await _verify_hub_input_session():
		return
	if not await _verify_operation_session():
		return
	if not await _verify_ten_minute_sessions(game_scene):
		return
	if not await _verify_failure_and_return_session():
		return

	paused = false
	print("E2E_WEAPON_PARTS_UI_OK weapon_schematic socket_map viewport_safe")
	print("E2E_CYBERPUNK_THEME_OK viewport_safe input_passthrough accent_02e5e1")
	print("E2E_PLAYER_PERCEPTION_OK checkpoints_%d units_%d orientation choice decision glance action_feedback resource_feedback state_feedback consequence continuity" % [
		judged_perception_checkpoints.size(), judged_perception_units.size(),
	])
	print("E2E_PLAY_SESSION_OK hit_feedback player_hit_camera_trauma module_reference_ui module_4_column_cards module_recommended_sort run_augment_cards_3 run_augment_key_selection ui_state_contracts_%d player_perception_contracts_%d gameplay_flows_%d viewport_bounds modal_exclusivity hud_non_overlap operation_briefing selected_then_launch loot_table_targeting field_loot_compare_cancel_select field_loot_immediate_equip_r_restore field_loot_skill_swap_r_restore session_socket_f_apply_hud_unsocket tactical_hud mission_tracker bottom_combat_cluster glance_hud hub_real_input key_mapping_k_esc u_e_action_split operation_setup combat_hud physical_lmb_attack hit_kill_drop room_entry_lock_clear_credit_boxes early_extraction minimap_expanded_warp medium_large_600s fog_room_corridor_transition fog_doorway_grace skill_action_feedback dash_action_feedback movement_motion_feedback loot_feedback extraction_pause_resume settlement_return death_return" % [
		judged_ui_states.size(), judged_perception_checkpoints.size(), judged_gameplay_flows.size(),
	])
	_cleanup_test_profile()
	quit(0)


func _verify_hub_input_session() -> bool:
	var hub = game.get("start_hub")
	var player = game.get("player") as Node2D
	var inventory = game.get("inventory_window") as Control
	var workbench = game.get("equipment_workbench") as Control
	var equipment = game.get("equipment_system")
	var hub_hud := game.get_node("UI/StartHubHUD") as Control
	var hub_hint := game.get_node("UI/StartHubHUD/Panel/Margin/Content/Controls") as Label
	var setup := game.get_node("UI/RunSetupOverlay") as Control
	if hub == null or player == null or inventory == null or workbench == null or equipment == null:
		return _fail("거점·플레이어·가방·장비 모듈이 함께 준비되지 않았습니다.")
	if setup.visible or not hub_hud.visible:
		return _fail("첫 화면에서 작전 설정과 거점 HUD의 가시성이 뒤바뀌었습니다.")
	if not _judge_ui_state(&"hub", "첫 거점"):
		return false
	if not _judge_player_perception(&"hub_orientation", "첫 거점 방향 인지"):
		return false
	if "U 장비" not in hub_hint.text or "E 모듈·파츠" not in hub_hint.text:
		return _fail("거점 조작 안내가 U와 E의 서로 다른 역할을 설명하지 않습니다.")
	if "K 키 설정" not in hub_hint.text:
		return _fail("거점 조작 안내가 K 키 설정 진입을 설명하지 않습니다.")

	await _tap_key(KEY_K)
	var key_panel = game.get("key_mapping_panel") as Control
	if (
		key_panel == null
		or not key_panel.visible
		or not paused
		or hub_hud.visible
		or int(key_panel.call(&"get_snapshot").get(&"physical_binding_row_count", 0)) != 23
		or int(key_panel.call(&"get_snapshot").get(&"skill_binding_row_count", 0)) != 3
		or not bool(key_panel.call(&"get_snapshot").get(&"separate_binding_levels", false))
	):
		return _fail("실제 K 입력이 물리 키·스킬 배치를 분리한 입력 설정 화면을 열지 못했습니다.")
	if not _judge_ui_state(&"key_mapping_hub", "거점 K 키 설정"):
		return false
	if not _judge_player_perception(&"key_mapping_comprehension", "키 설정 선택 이해"):
		return false
	await _tap_key(KEY_ESCAPE)
	if key_panel.visible or paused or not hub_hud.visible:
		return _fail("실제 ESC 입력이 키 설정을 닫고 거점 HUD를 복원하지 못했습니다.")
	if not _judge_ui_state(&"hub", "K 종료 후 거점"):
		return false

	await _tap_key(KEY_I)
	if not inventory.visible or not paused or hub_hud.visible:
		return _fail("실제 I 입력이 겹침 없이 가방을 열지 못했습니다.")
	if not _judge_ui_state(&"inventory_hub", "거점 I 가방"):
		return false
	if not _judge_player_perception(&"inventory_comprehension", "가방 공간 이해"):
		return false
	await _tap_key(KEY_ESCAPE)
	if inventory.visible or paused or not hub_hud.visible:
		return _fail("실제 ESC 입력이 가방을 닫고 거점 HUD를 복원하지 못했습니다.")
	if not _judge_ui_state(&"hub", "I 종료 후 거점"):
		return false

	await _tap_key(KEY_U)
	if not workbench.visible or int((workbench.get("tabs") as TabContainer).current_tab) != 0:
		return _fail("실제 U 입력이 캐릭터 장비 탭을 열지 못했습니다.")
	if not _judge_ui_state(&"equipment_hub", "거점 U 장비"):
		return false
	if not _judge_player_perception(&"equipment_comprehension", "장비 슬롯 이해"):
		return false
	var summary_text := String((workbench.get("character_summary") as Label).text)
	if "장비 태그 호환" not in summary_text or "활성 스킬" in summary_text:
		return _fail("장비 호환 수치가 실제 활성 스킬 수처럼 오해되는 문구로 표시됩니다.")

	await _tap_key(KEY_E)
	if not workbench.visible or int((workbench.get("tabs") as TabContainer).current_tab) != 1:
		return _fail("열린 U 화면에서 실제 E 입력이 창을 닫지 않고 모듈·파츠 탭으로 전환하지 못했습니다.")
	var module_ui: Dictionary = workbench.call(&"get_density_snapshot")
	if (
		int(module_ui.get(&"modification_columns", 0)) != 4
		or int(module_ui.get(&"module_inventory_metadata_card_count", 0)) < 1
		or not bool(module_ui.get(&"module_effect_summary_visible", false))
		or module_ui.get(&"modification_sort", &"") != &"compatibility"
		or not bool(module_ui.get(&"weapon_parts_board_visible", false))
		or int(module_ui.get(&"weapon_parts_socket_count", 0)) != 3
		or module_ui.get(&"weapon_parts_minor_tag", &"") != &"rifle"
	):
		return _fail("E 모듈 화면이 적용 수치·4열 카드·추천 정렬·총기 소켓 도식을 함께 표시하지 못했습니다.")
	if not _judge_ui_state(&"modification_hub", "거점 E 모듈·파츠"):
		return false
	if not _judge_player_perception(&"modification_comprehension", "모듈·파츠 선택 이해"):
		return false
	await _tap_key(KEY_U)
	if not workbench.visible or int((workbench.get("tabs") as TabContainer).current_tab) != 0:
		return _fail("열린 E 화면에서 실제 U 입력이 장비 탭으로 돌아오지 못했습니다.")
	if not _judge_ui_state(&"equipment_hub", "거점 U 탭 복귀"):
		return false
	await _tap_key(KEY_ESCAPE)
	if workbench.visible or paused:
		return _fail("실제 ESC 입력이 장비 화면을 닫지 못했습니다.")
	if not _judge_ui_state(&"hub", "U 종료 후 거점"):
		return false

	var weapon_feedback_before := hub_hint.text
	var weapon_before: StringName = equipment.call(&"get_active_weapon_slot")
	await _tap_key(KEY_Q)
	var weapon_after: StringName = equipment.call(&"get_active_weapon_slot")
	if weapon_before == weapon_after:
		return _fail("실제 Q 입력이 거점 무기를 교체하지 못했습니다.")
	if not _judge_player_perception(&"weapon_switch_feedback", "거점 무기 교체 피드백", {
		&"before_text": weapon_feedback_before,
		&"after_text": hub_hint.text,
		&"after_phrases": ["현재"],
	}):
		return false

	var gate_position: Vector2 = hub.call(&"get_operation_position")
	Input.action_press(&"move_right")
	var reached_gate := false
	for _frame in range(480):
		await physics_frame
		if player.global_position.distance_to(gate_position) <= float(hub.get("interaction_radius")) * 0.8:
			reached_gate = true
			break
	Input.action_release(&"move_right")
	if not reached_gate:
		return _fail("실제 지속 이동 입력으로 거점 작전 게이트까지 이동하지 못했습니다.")
	await physics_frame
	await physics_frame
	await _tap_key(KEY_F)
	if not setup.visible or not paused or hub_hud.visible:
		return _fail("게이트의 실제 F 입력이 겹침 없이 작전 설정을 열지 못했습니다.")
	if not _judge_ui_state(&"run_setup", "작전 설정"):
		return false
	var setup_snapshot: Dictionary = game.get("operation_setup_presenter").call(&"get_snapshot")
	if (
		not bool(setup_snapshot.get(&"installed", false))
		or not bool(setup_snapshot.get(&"launch_visible", false))
		or not bool(setup_snapshot.get(&"layout_fits", false))
		or "폐허 도시" not in String(setup_snapshot.get(&"mission_title", ""))
		or "소모품" not in String(setup_snapshot.get(&"selection_summary", ""))
		or "TARGET LOOT" not in String(setup_snapshot.get(&"target_farming_summary", ""))
	):
		return _fail("작전 진입 화면이 브리핑·계약·명시적 투입 구조를 제공하지 않습니다.")
	if not _judge_player_perception(&"operation_decision", "작전 위험·비용 결정 이해"):
		return false
	if not _judge_player_perception(&"target_farming_decision", "지역·난이도 타겟 파밍 이해"):
		return false
	var loot_provider = game.get("loot_table_provider")
	var contract = game.get("operation_contract_service")
	if loot_provider == null or contract == null:
		return _fail("타겟 파밍 제공자 또는 작전 계약이 준비되지 않았습니다.")
	var contract_snapshot: Dictionary = contract.call(&"get_snapshot")
	var loot_context := {
		&"region_id": contract_snapshot.get(&"selected_region_id", &"ruined_city"),
		&"difficulty_id": contract_snapshot.get(&"selected_difficulty_id", &"standard"),
		&"map_size": &"small", &"source_type": &"any",
		&"high_grade_drop_multiplier": 1.0, &"boss_available": true,
	}
	var first_roll: Dictionary = loot_provider.call(&"roll_drop", loot_context, 9137, 4)
	if not _judge_gameplay_flow(&"loot_table_targeting", "지역·난이도 타겟 파밍", {
		&"briefing": loot_provider.call(&"get_briefing", loot_context),
		&"first_roll": first_roll,
		&"repeated_roll": loot_provider.call(&"roll_drop", loot_context, 9137, 4),
		&"selected_region_id": loot_context[&"region_id"],
	}):
		return false
	return true


func _verify_operation_session() -> bool:
	var setup := game.get_node("UI/RunSetupOverlay") as Control
	var small_button := game.get("small_map_button") as Button
	var launch_button := game.get("operation_launch_button") as Button
	if small_button == null or small_button.disabled:
		return _fail("소형 작전 카드가 실제 선택 가능한 상태가 아닙니다.")
	small_button.pressed.emit()
	await process_frame
	if not setup.visible or not paused or bool(game.get("run_started")):
		return _fail("작전 규모 선택이 확인 없이 즉시 전투를 시작했습니다.")
	if launch_button == null or not launch_button.visible or launch_button.disabled:
		return _fail("선택 계약을 확정하는 작전 투입 버튼이 준비되지 않았습니다.")
	launch_button.pressed.emit()
	await process_frame
	if setup.visible or paused or not bool(game.get("run_started")):
		return _fail("작전 투입 확정 후 전투 세션으로 전환되지 않았습니다.")

	var player = game.get("player") as Node2D
	var minimap = game.get("minimap") as Control
	var skills = game.get("combat_skill_hud") as Control
	var dash = game.get("dash_cooldown_hud") as Control
	if player == null or minimap == null or skills == null or dash == null:
		return _fail("전투 HUD·미니맵·대시 UI가 함께 설치되지 않았습니다.")
	if not minimap.visible or not skills.visible or not dash.visible:
		return _fail("전투 HUD의 필수 자원·쿨타임 정보가 보이지 않습니다.")
	var hud_snapshot: Dictionary = game.get("combat_hud_presenter").call(
		&"get_snapshot", game.get_node("UI/HUDMargin")
	)
	if (
		not bool(hud_snapshot.get(&"installed", false))
		or not bool(hud_snapshot.get(&"mission_tracker", false))
		or not bool(hud_snapshot.get(&"bottom_cluster", false))
		or not bool(hud_snapshot.get(&"runtime_clustered", false))
		or not bool(hud_snapshot.get(&"details_side_by_side", false))
		or not bool(hud_snapshot.get(&"loadout_split", false))
		or not bool(hud_snapshot.get(&"responsive", false))
		or int(hud_snapshot.get(&"icon_count", 0)) < 16
		or int(hud_snapshot.get(&"action_count", 0)) < 8
		or not bool(hud_snapshot.get(&"low_obstruction", false))
		or bool(hud_snapshot.get(&"details_persistent", true))
		or float(hud_snapshot.get(&"persistent_area_ratio", 1.0)) > 0.16
	):
		return _fail("전투 HUD가 아이콘 기반 반응형 시선권으로 구성되지 않았습니다: %s" % hud_snapshot)
	var mission_rect: Rect2 = hud_snapshot.get(&"mission_rect", Rect2())
	var core_rect: Rect2 = hud_snapshot.get(&"core_rect", Rect2())
	if mission_rect.intersects(core_rect) or core_rect.intersects(skills.get_global_rect()):
		return _fail("임무 추적기·생존 정보·스킬 UI가 서로 겹칩니다: %s" % hud_snapshot)
	if minimap.get_global_rect().intersects(skills.get_global_rect()):
		return _fail("미니맵과 스킬 HUD가 화면에서 겹칩니다.")
	var minimap_snapshot: Dictionary = minimap.call(&"get_layout_snapshot")
	if (
		not bool(minimap_snapshot.get(&"low_obstruction", false))
		or bool(minimap_snapshot.get(&"header_visible", true))
		or not bool(minimap_snapshot.get(&"full_map_preserved", false))
		or float(minimap_snapshot.get(&"background_alpha", 1.0)) > 0.7
	):
		return _fail("미니맵이 전체 지도는 유지하면서 장식 점유를 줄이지 못했습니다: %s" % minimap_snapshot)
	if not _judge_ui_state(&"combat", "첫 전투 HUD"):
		return false
	if not _judge_player_perception(&"combat_glance", "전투 시선 정보 이해"):
		return false
	if not await _verify_combat_action_feedback(player, skills, dash):
		return false
	if not await _verify_primary_attack_resolution(player):
		return false
	if not await _verify_room_encounter_resolution(player):
		return false
	if not await _verify_expanded_map_warp(player):
		return false
	if not await _verify_run_augment_choice():
		return false

	await _tap_key(KEY_I)
	var inventory = game.get("inventory_window") as Control
	if inventory == null or not inventory.visible or not paused:
		return _fail("전투 세션에서 실제 I 입력으로 가방을 확인할 수 없습니다.")
	if not _judge_ui_state(&"inventory_combat", "전투 I 가방"):
		return false
	await _tap_key(KEY_ESCAPE)
	if not _judge_ui_state(&"combat", "전투 I 종료"):
		return false
	await _tap_key(KEY_U)
	var workbench = game.get("equipment_workbench") as Control
	if workbench == null or not workbench.visible:
		return _fail("전투 세션에서 실제 U 입력으로 장비를 확인할 수 없습니다.")
	if not _judge_ui_state(&"equipment_combat", "전투 U 장비"):
		return false
	await _tap_key(KEY_E)
	if not workbench.visible or int((workbench.get("tabs") as TabContainer).current_tab) != 1:
		return _fail("전투 세션에서도 E가 모듈·파츠 탭을 안정적으로 열지 못했습니다.")
	if not _judge_ui_state(&"modification_combat", "전투 E 모듈·파츠"):
		return false
	await _tap_key(KEY_ESCAPE)
	if not _judge_ui_state(&"combat", "전투 U/E 종료"):
		return false
	if not _judge_player_perception(&"combat_context_restored", "모달 종료 후 전투 복원", {
		&"expected_context": &"combat",
		&"actual_context": &"combat" if not paused else &"paused",
	}):
		return false

	var loot_cache: Node2D
	for child in game.get_node("World/Pickups").get_children():
		if child.has_method(&"request_loot"):
			loot_cache = child as Node2D
			break
	if loot_cache == null:
		return _fail("실제 작전에 회수 가능한 파밍 오브젝트가 없습니다.")
	player.global_position = loot_cache.global_position
	await physics_frame
	await physics_frame
	# Headless physics does not always emit a fresh Area2D body_entered after teleporting.
	# Keep the interaction handler under test while making the nearby actor explicit.
	loot_cache.set("nearby_player", player)
	var credit_ledger = game.get("credit_ledger")
	var credits_before := int(credit_ledger.get("carried_credits"))
	var credit_text_before := String((game.get("credit_label") as Label).text)
	await _tap_key(KEY_F)
	var credits_after := int(credit_ledger.get("carried_credits"))
	if credits_after <= 0:
		return _fail("파밍 오브젝트 앞 실제 F 입력이 휴대 크레딧을 회수하지 못했습니다.")
	if not _judge_player_perception(&"loot_feedback", "자원 회수 수치 피드백", {
		&"before_text": credit_text_before,
		&"after_text": String((game.get("credit_label") as Label).text),
		&"after_phrases": ["CR"],
		&"before_value": credits_before,
		&"after_value": credits_after,
		&"value_direction": &"increase",
	}):
		return false

	var extraction = game.get("extraction_zone") as Node2D
	player.global_position = extraction.global_position
	game.set("elapsed_time", float(game.get("extraction_unlock_seconds")))
	game.call(&"_process", 0.0)
	await physics_frame
	await physics_frame
	extraction.set("nearby_player", player)
	await _tap_key(KEY_F)
	var extraction_state: Dictionary = extraction.call(&"get_snapshot")
	if not bool(extraction_state.get(&"defense_active", false)):
		return _fail("탈출 지점의 실제 F 입력이 카운트다운 방어전을 시작하지 못했습니다.")
	if not _judge_player_perception(&"extraction_start_feedback", "탈출 방어 시작 인지"):
		return false
	var remaining_before := float(extraction_state.get(&"defense_remaining_seconds", 0.0))
	player.global_position += Vector2(float(extraction.get("interaction_radius")) + 80.0, 0.0)
	extraction.call(&"advance", 0.5)
	extraction_state = extraction.call(&"get_snapshot")
	if not bool(extraction_state.get(&"defense_paused", false)):
		return _fail("탈출 구역 이탈 시 방어 카운트다운이 일시정지되지 않았습니다.")
	if float(extraction_state.get(&"defense_remaining_seconds", 0.0)) < remaining_before - 0.1:
		return _fail("탈출 구역 밖에서 카운트다운이 소모됩니다.")
	if not _judge_player_perception(&"extraction_pause_feedback", "탈출 이탈 일시정지 인지"):
		return false
	player.global_position = extraction.global_position
	if not extraction.call(&"request_extraction", player):
		return _fail("탈출 구역 복귀 후 방어전을 재개하지 못했습니다.")
	if not _judge_player_perception(&"extraction_resume_feedback", "탈출 복귀 재개 인지"):
		return false
	extraction.call(&"advance", remaining_before + 0.5)
	await process_frame
	var result := game.get_node("UI/GameOverOverlay") as Control
	var title := game.get_node("UI/GameOverOverlay/Center/Panel/Margin/Content/EndTitle") as Label
	if not result.visible or title.text != "탈출 성공" or not paused:
		return _fail("탈출 완료 후 성공 정산 화면이 표시되지 않았습니다.")
	if not _judge_ui_state(&"result", "성공 결과"):
		return false
	if not _judge_player_perception(&"success_consequence", "탈출 성공 결과 이해"):
		return false
	await _tap_key(KEY_ENTER)
	if game.get("start_hub") == null or bool(game.get("run_started")) or paused:
		return _fail("정산 화면의 실제 Enter 입력이 시작 거점으로 복귀하지 못했습니다.")
	var restored_equipment = game.get("equipment_system")
	var restored_main = restored_equipment.call(&"get_equipment_state", &"main")
	if (
		restored_main == null
		or restored_main.definition.weapon_id != &"assault_rifle"
		or restored_equipment.call(&"get_summary").get(&"active_weapon_id", &"") != &"service_pistol"
	):
		return _fail("현장 즉시 장착 뒤 거점 복귀가 원래 주무기·활성 슬롯을 복구하지 못했습니다.")
	if not _judge_ui_state(&"hub", "성공 정산 후 거점"):
		return false
	if not _judge_player_perception(&"hub_context_restored", "성공 후 거점 복원", {
		&"expected_context": &"hub",
		&"actual_context": &"hub" if not bool(game.get("run_started")) else &"combat",
	}):
		return false
	return true


func _verify_run_augment_choice() -> bool:
	var selector = game.get("run_buff_selector") as Control
	var run_buffs = game.get("run_buff_system")
	if selector == null or run_buffs == null:
		return _fail("내부 증강 선택 UI 또는 런 버프 규칙 모듈이 없습니다.")
	var choices: Array[Dictionary] = run_buffs.call(&"prepare_choices", 2, 3)
	if choices.size() != 3 or not selector.call(&"open_choices", 2, choices):
		return _fail("런 레벨업이 비교 가능한 증강 카드 3장을 열지 못했습니다.")
	await process_frame
	await process_frame
	var snapshot: Dictionary = selector.call(&"get_snapshot")
	var card_snapshots: Array = snapshot.get(&"card_snapshots", [])
	if (
		int(snapshot.get(&"visible_card_count", 0)) != 3
		or int(snapshot.get(&"focused_index", -1)) != 0
		or not bool(snapshot.get(&"cards_inside_viewport", false))
		or card_snapshots.size() != 3
	):
		return _fail("증강 카드가 3열·첫 포커스·화면 경계 계약을 지키지 못했습니다: %s" % snapshot)
	var titles := PackedStringArray()
	var categories := PackedStringArray()
	for card_snapshot_variant in card_snapshots:
		var card_snapshot: Dictionary = card_snapshot_variant
		var title := String(card_snapshot.get(&"title", ""))
		var description := String(card_snapshot.get(&"description", ""))
		if title.is_empty() or description.is_empty() or String(card_snapshot.get(&"icon_code", "")).is_empty():
			return _fail("증강 카드가 이름·효과·식별 코드를 함께 제시하지 않습니다: %s" % card_snapshot)
		titles.append(title)
		categories.append(String(card_snapshot.get(&"category", "")))
	if titles.size() != 3 or categories.size() != 3:
		return _fail("증강 비교 정보가 세 카드에 분리되지 않았습니다.")
	if not _judge_ui_state(&"run_buff_choice", "내부 증강 3장 선택"):
		return false
	if not _judge_player_perception(&"run_buff_choice_comprehension", "증강 비교·작전 한정 이해"):
		return false
	var selected_before := int(run_buffs.call(&"selected_buff_count"))
	await _tap_key(KEY_2)
	if int(run_buffs.call(&"selected_buff_count")) != selected_before + 1:
		return _fail("실제 2 입력으로 두 번째 증강이 런 상태에 적용되지 않았습니다.")
	var chained_choices := 0
	while selector.visible:
		chained_choices += 1
		if chained_choices > 16:
			return _fail("연속 레벨업 증강 선택이 16회를 넘어서도 종료되지 않습니다.")
		await _tap_key(KEY_1)
	await process_frame
	var pending_levels: Array = game.get("pending_buff_levels")
	if selector.visible or not pending_levels.is_empty() or paused:
		return _fail("대기 중인 연속 증강을 모두 선택한 뒤 전투가 재개되지 않았습니다.")
	if not _judge_ui_state(&"combat", "증강 선택 후 전투 복원"):
		return false
	return true


func _verify_failure_and_return_session() -> bool:
	if not game.call(&"start_run", "small"):
		return _fail("성공 정산 후 두 번째 작전을 시작할 수 없습니다.")
	await process_frame
	if not _judge_ui_state(&"combat", "실패 검증용 두 번째 전투"):
		return false
	var player = game.get("player")
	player.call(&"take_damage", 999999.0)
	await process_frame
	var hit_feedback = game.get("hit_feedback_director")
	var feedback_snapshot: Dictionary = (
		hit_feedback.call(&"get_snapshot") if hit_feedback != null else {}
	)
	if (
		hit_feedback == null
		or int(feedback_snapshot.get(&"total_player_hits", 0)) < 1
		or int(feedback_snapshot.get(&"active_impacts", 0)) < 1
		or float(feedback_snapshot.get(&"trauma", 0.0)) <= 0.0
	):
		return _fail("실제 플레이어 피격이 충격 VFX와 카메라 반응으로 연결되지 않았습니다.")
	var title := game.get_node("UI/GameOverOverlay/Center/Panel/Margin/Content/EndTitle") as Label
	if not bool(game.get("run_ended")) or title.text != "작전 실패" or not paused:
		return _fail("플레이어 사망 후 실패 정산이 표시되지 않았습니다.")
	if not _judge_ui_state(&"result", "실패 결과"):
		return false
	if not _judge_player_perception(&"failure_consequence", "사망 실패 결과 이해"):
		return false
	await _tap_key(KEY_ENTER)
	if game.get("start_hub") == null or bool(game.get("run_started")) or paused:
		return _fail("실패 정산 후 실제 Enter 입력이 시작 거점으로 복귀하지 못했습니다.")
	if not _judge_ui_state(&"hub", "실패 정산 후 거점"):
		return false
	if not _judge_player_perception(&"hub_context_restored", "실패 후 거점 복원", {
		&"expected_context": &"hub",
		&"actual_context": &"hub" if not bool(game.get("run_started")) else &"combat",
	}):
		return false
	return true


func _verify_combat_action_feedback(player: Node2D, skills: Control, dash: Control) -> bool:
	var skill_before: Dictionary = skills.call(&"get_snapshot")
	var skill_before_states: Array = skill_before.get(&"states", [])
	if skill_before_states.is_empty():
		return _fail("전투 스킬 HUD에 실제 발동 가능한 슬롯이 없습니다.")
	var energy_before := float((skill_before_states[0] as Dictionary).get(&"energy_current", 0.0))
	var blink_position_before := player.global_position
	await _tap_key(KEY_1)
	await physics_frame
	await process_frame
	var skill_after: Dictionary = skills.call(&"get_snapshot")
	var skill_after_states: Array = skill_after.get(&"states", [])
	if skill_after_states.is_empty():
		return _fail("스킬 발동 후 HUD 상태가 사라졌습니다.")
	var blink_state: Dictionary = skill_after_states[0]
	var energy_after := float(blink_state.get(&"energy_current", energy_before))
	var blink_distance := blink_position_before.distance_to(player.global_position)
	if float(blink_state.get(&"cooldown_remaining", 0.0)) <= 0.0:
		return _fail("실제 1 입력 뒤 점멸 쿨타임이 시작되지 않았습니다.")
	if not _judge_player_perception(&"skill_activation_feedback", "점멸 이동·에너지·쿨타임 인지", {
		&"before_value": energy_before,
		&"after_value": energy_after,
		&"value_direction": &"decrease",
		&"world_delta": blink_distance,
		&"minimum_world_delta": 24.0,
	}):
		return false

	var dash_before: Dictionary = dash.call(&"get_snapshot")
	var dash_before_remaining := float(
		(dash_before.get(&"movement", {}) as Dictionary).get(&"dash_cooldown_remaining", 0.0)
	)
	Input.action_press(&"move_left")
	await physics_frame
	await _press_key_for_physics(KEY_SPACE)
	for _frame in range(6):
		await physics_frame
	Input.action_release(&"move_left")
	await process_frame
	var dash_after: Dictionary = dash.call(&"get_snapshot")
	var dash_after_remaining := float(
		(dash_after.get(&"movement", {}) as Dictionary).get(&"dash_cooldown_remaining", 0.0)
	)
	if dash_after_remaining <= 0.0:
		return _fail("실제 Space 입력 뒤 대시 쿨타임이 시작되지 않았습니다.")
	if String(dash_after.get(&"status", "READY")) == "READY":
		return _fail("실제 대시 뒤 HUD가 READY 상태에서 바뀌지 않았습니다.")
	var movement_feedback := player.get_node_or_null("MovementFeedback")
	if movement_feedback == null:
		return _fail("실제 플레이어에 이동 체감 피드백 모듈이 없습니다.")
	var movement_feedback_after: Dictionary = movement_feedback.call(&"get_feedback_snapshot")
	if not _judge_player_perception(&"dash_activation_feedback", "대시 재사용 피드백 인지", {
		&"before_text": String(dash_before.get(&"status", "")),
		&"after_text": String(dash_after.get(&"status", "")),
		&"before_value": dash_before_remaining,
		&"after_value": dash_after_remaining,
		&"value_direction": &"increase",
		&"visual_intensity": float(movement_feedback_after.get(&"visual_intensity", 0.0)),
		&"minimum_visual_intensity": 0.55,
		&"trail_point_count": int(movement_feedback_after.get(&"trail_point_count", 0)),
		&"minimum_trail_points": 2,
		&"camera_lead_pixels": float(movement_feedback_after.get(&"camera_lead_pixels", 0.0)),
		&"minimum_camera_lead_pixels": 8.0,
	}):
		return false
	return true


func _verify_primary_attack_resolution(player: Node2D) -> bool:
	var spawner = game.get("enemy_spawner")
	var weapon = game.get("auto_weapon")
	var hit_feedback = game.get("hit_feedback_director")
	var resources = game.get("combat_resource_system")
	var map_provider = game.get("map_generator")
	if spawner == null or weapon == null or hit_feedback == null or resources == null or map_provider == null:
		return _fail("좌클릭 전투 인과관계를 관측할 필수 모듈이 없습니다.")
	var spawn_position: Vector2 = map_provider.call(
		&"get_enemy_spawn_position", player.global_position, 180.0
	)
	var enemy: Node2D = spawner.call(&"spawn_enemy_at", spawn_position, &"e2e_primary_attack")
	if enemy == null:
		return _fail("좌클릭 전투 검증용 적을 실제 스포너로 생성하지 못했습니다.")
	enemy.global_position = player.global_position + Vector2(180.0, 0.0)
	enemy.set("move_speed", 0.0)
	enemy.set("damage_enabled", false)
	await process_frame

	var weapon_before: Dictionary = weapon.call(&"get_runtime_snapshot")
	var hit_before: Dictionary = hit_feedback.call(&"get_snapshot")
	var resource_before: Dictionary = resources.call(&"get_snapshot")
	var kills_before := int(game.get("defeated_enemies"))
	var target_instance_id := enemy.get_instance_id()
	var pressed_event := InputEventMouseButton.new()
	pressed_event.button_index = MOUSE_BUTTON_LEFT
	pressed_event.button_mask = MOUSE_BUTTON_MASK_LEFT
	pressed_event.pressed = true
	pressed_event.position = get_root().get_visible_rect().size * 0.5
	pressed_event.global_position = pressed_event.position
	Input.parse_input_event(pressed_event)
	for _frame in range(360):
		await physics_frame
		if not is_instance_valid(enemy):
			break
	var released_event := pressed_event.duplicate() as InputEventMouseButton
	released_event.pressed = false
	released_event.button_mask = 0
	Input.parse_input_event(released_event)
	await process_frame
	await process_frame

	var weapon_after: Dictionary = weapon.call(&"get_runtime_snapshot")
	var hit_after: Dictionary = hit_feedback.call(&"get_snapshot")
	var resource_after: Dictionary = resources.call(&"get_snapshot")
	var spawned_before: Dictionary = resource_before.get(&"spawned_pickups", {})
	var spawned_after: Dictionary = resource_after.get(&"spawned_pickups", {})
	var drop_count_before := int(spawned_before.get(&"energy", 0)) + int(spawned_before.get(&"health", 0))
	var drop_count_after := int(spawned_after.get(&"energy", 0)) + int(spawned_after.get(&"health", 0))
	if int(weapon_after.get(&"last_target_instance_id", 0)) != target_instance_id:
		return _fail("실제 좌클릭 공격이 생성한 적을 스마트 타게팅하지 못했습니다.")
	if not _judge_gameplay_flow(&"primary_attack_resolution", "좌클릭→타격→처치→드랍", {
		&"physical_left_mouse": true,
		&"projectiles_before": weapon_before.get(&"total_projectiles_fired", 0),
		&"projectiles_after": weapon_after.get(&"total_projectiles_fired", 0),
		&"hits_before": hit_before.get(&"total_hits", 0),
		&"hits_after": hit_after.get(&"total_hits", 0),
		&"lethal_before": hit_before.get(&"total_lethal_hits", 0),
		&"lethal_after": hit_after.get(&"total_lethal_hits", 0),
		&"kills_before": kills_before,
		&"kills_after": game.get("defeated_enemies"),
		&"drops_before": drop_count_before,
		&"drops_after": drop_count_after,
		&"target_removed": not is_instance_valid(enemy),
	}):
		return false
	return _judge_player_perception(&"primary_attack_feedback", "좌클릭 처치 피드백", {
		&"before_value": kills_before,
		&"after_value": game.get("defeated_enemies"),
		&"value_direction": &"increase",
	})


func _verify_room_encounter_resolution(player: Node2D) -> bool:
	var encounters = game.get("room_encounter_system")
	var spawner = game.get("enemy_spawner")
	var generator = game.get("map_generator")
	var progression = game.get("progression_system")
	var credit_ledger = game.get("credit_ledger")
	var fog = game.get("fog_of_war")
	if encounters == null or spawner == null or generator == null or progression == null or credit_ledger == null or fog == null:
		return _fail("방 전투 E2E에 필요한 모듈이 설치되지 않았습니다.")
	var room := {}
	var fallback_room := {}
	for candidate: Dictionary in generator.call(&"get_room_encounter_snapshot"):
		if (
			not bool(candidate.get(&"is_start_room", false))
			and not bool(candidate.get(&"is_extraction_room", false))
			and not (candidate.get(&"doorways", []) as Array).is_empty()
		):
			fallback_room = candidate
			if bool(candidate.get(&"is_four_way", false)):
				room = candidate
				break
	if room.is_empty():
		room = fallback_room
	if room.is_empty():
		return _fail("문 봉쇄가 가능한 일반 방을 생성하지 못했습니다.")
	var test_tier_values: Dictionary = encounters.get("tier_values").duplicate(true)
	test_tier_values[&"maximum_encounters"] = 1
	encounters.set("tier_values", test_tier_values)
	player.global_position = room[&"center"]
	await physics_frame
	await process_frame
	encounters.call(&"_process", 0.0)
	await process_frame
	var active: Dictionary = encounters.call(&"get_snapshot")
	if not _judge_player_perception(&"room_lock_feedback", "방 진입과 문 봉쇄 인지"):
		return false
	var credits_before := int(credit_ledger.call(&"get_snapshot").get(&"carried", 0))
	var room_id := StringName("room_%d" % int(room[&"room_index"]))
	player.global_position = (room[&"world_rect"] as Rect2).position + Vector2(160.0, 160.0)
	await physics_frame
	await physics_frame
	for enemy in spawner.call(&"get_active_targets"):
		if enemy.get_meta(&"room_encounter_id", &"") == room_id:
			enemy.call(&"take_damage", 100000.0, {
				&"source_kind": &"e2e_room_clear",
				&"impact_direction": Vector2.RIGHT,
				&"impact_strength": 1.0,
			})
	for _frame in range(4):
		await process_frame
	encounters.call(&"_process", 0.0)
	await process_frame
	var cleared: Dictionary = encounters.call(&"get_snapshot")
	var visible_status := String((game.get("status_label") as Label).text)
	if int(cleared.get(&"active_room_index", -2)) != -1 or "확보" not in visible_status:
		return _fail("방 섬멸 후 확보 상태가 화면에 유지되지 않습니다: %s / %s" % [
			visible_status, cleared,
		])
	if not _judge_player_perception(&"room_clear_feedback", "방 클리어와 보상 생성 인지"):
		return false
	if not await _verify_field_loot_acquisition(player):
		return false
	var pacing: Dictionary = game.call(&"get_run_pacing_snapshot")
	if (
		not bool(pacing.get(&"extraction_unlocked", false))
		or float(pacing.get(&"elapsed_seconds", INF)) >= float(pacing.get(&"extraction_unlock_seconds", 0.0))
	):
		return _fail("모든 전투 방 확보가 제한 시간 전 탈출을 개방하지 못했습니다: %s" % pacing)
	var rewards: Array = encounters.call(&"get_active_rewards")
	if rewards.is_empty():
		return _fail("방 클리어 후 회수 가능한 실제 보상 노드가 없습니다.")
	var reward := rewards[0] as Node2D
	player.global_position = reward.global_position
	reward.call(&"_on_body_entered", player)
	reward.call(&"request_loot", player)
	await process_frame
	await process_frame
	var collected: Dictionary = encounters.call(&"get_snapshot")
	var credits_after := int(credit_ledger.call(&"get_snapshot").get(&"carried", 0))
	if not _judge_gameplay_flow(&"room_encounter_resolution", "방 진입→봉쇄→클리어→보상", {
		&"active": active,
		&"cleared": cleared,
		&"collected": collected,
		&"credits_before": credits_before,
		&"credits_after": credits_after,
	}):
		return false
	return await _verify_fog_room_corridor_transition(player, generator, fog, room)


func _verify_field_loot_acquisition(player: Node2D) -> bool:
	var service = game.get("field_loot_acquisition_service")
	if service == null:
		return _fail("현장 비교·획득 서비스가 작전 세션에 설치되지 않았습니다.")
	var drops: Array = service.call(&"get_active_drops")
	if drops.is_empty():
		return _fail("방 확보 뒤 접근 가능한 비교 전리품이 생성되지 않았습니다.")
	var drop := drops[0] as Node2D
	player.global_position = drop.global_position
	drop.call(&"_process", 0.0)
	await process_frame
	var approached: Dictionary = service.call(&"get_snapshot")
	if not _judge_player_perception(&"field_loot_comparison", "현장 전리품 비교·보존 결과 이해"):
		return false
	await _tap_key(KEY_ESCAPE)
	var cancelled: Dictionary = service.call(&"get_snapshot")
	player.global_position = drop.global_position + Vector2(220.0, 0.0)
	drop.call(&"_process", 0.0)
	player.global_position = drop.global_position
	drop.call(&"_process", 0.0)
	await process_frame
	await _tap_key(KEY_F)
	await process_frame
	var acquired: Dictionary = service.call(&"get_snapshot")
	if not _judge_gameplay_flow(&"field_loot_acquisition", "드랍→접근→비교→보류→선택", {
		&"approached": approached,
		&"cancelled": cancelled,
		&"acquired": acquired,
	}):
		return false
	var equipment = game.get("equipment_system")
	var before_weapon: StringName = equipment.call(&"get_summary").get(&"active_weapon_id", &"")
	var equip_drop: Node2D = service.call(&"spawn_candidate", player.global_position, {
		&"entry_id": &"e2e_pulse", &"item_id": &"pulse_rifle", &"grade": 3,
		&"quantity": 1, &"source_type": &"room_reward",
	})
	if equip_drop == null:
		return _fail("P4-04A 현장 무기 후보를 생성하지 못했습니다.")
	equip_drop.call(&"_process", 0.0)
	await process_frame
	if not _judge_player_perception(&"field_loot_immediate_equip", "현장 무기 즉시 장착·기존 장비 처리 이해"):
		return false
	var equip_before: Dictionary = service.call(&"get_snapshot")
	await _tap_key(KEY_R)
	await process_frame
	var equip_after: Dictionary = service.call(&"get_snapshot")
	var after_weapon: StringName = equipment.call(&"get_summary").get(&"active_weapon_id", &"")
	if not _judge_gameplay_flow(&"field_loot_immediate_equip", "드랍→R 장착→무기 변화→복구 가능", {
		&"before_weapon": before_weapon,
		&"after_weapon": after_weapon,
		&"before": equip_before,
		&"after": equip_after,
	}):
		return false
	var skill_system = game.get("combat_skill_system")
	var before_skill: StringName = (skill_system.call(&"get_skill_states") as Array)[2].get(&"skill_id", &"")
	var skill_drop: Node2D = service.call(&"spawn_candidate", player.global_position, {
		&"entry_id": &"e2e_arc_dash", &"item_id": &"arc_dash", &"grade": 4,
		&"quantity": 1, &"source_type": &"room_reward",
	})
	if skill_drop == null:
		return _fail("P4-04B 현장 스킬 후보를 생성하지 못했습니다.")
	skill_drop.call(&"_process", 0.0)
	await process_frame
	if not _judge_player_perception(&"field_loot_skill_swap", "현장 스킬·키·자원 교체 이해"):
		return false
	var skill_before: Dictionary = service.call(&"get_snapshot")
	if (
		StringName(skill_before.get(&"focused_item_id", &"")) != &"arc_dash"
		or not bool((skill_before.get(&"panel", {}) as Dictionary).get(&"shows_skill_swap", false))
	):
		return _fail("아크 질주 드랍이 실제 R 입력 대상으로 고정되지 않았습니다: %s" % skill_before)
	await _tap_key(KEY_R)
	await process_frame
	var skill_after: Dictionary = service.call(&"get_snapshot")
	var active_skill_state: Dictionary = (skill_system.call(&"get_skill_states") as Array)[2]
	if not _judge_gameplay_flow(&"field_loot_skill_swap", "드랍→R 스킬 교체→키 유지→런 복구 가능", {
		&"before_skill": before_skill,
		&"after_skill": active_skill_state.get(&"skill_id", &""),
		&"after_action": active_skill_state.get(&"input_action", &""),
		&"before": skill_before,
		&"after": skill_after,
	}):
		return false
	if int(service.call(&"restore_equipment_swaps")) != 2:
		return _fail("현장 무기·스킬 교체 기록을 함께 복구하지 못했습니다.")
	var restored_skill: Dictionary = (skill_system.call(&"get_skill_states") as Array)[2]
	if (
		equipment.call(&"get_summary").get(&"active_weapon_id", &"") != before_weapon
		or restored_skill.get(&"skill_id", &"") != before_skill
	):
		return _fail("거점 복귀 전 무기·스킬 런 상태 복구에 실패했습니다.")
	var sockets = game.get("session_socket_service")
	var socket_hud = game.get("session_socket_hud") as Control
	var weapon = game.get("auto_weapon")
	if sockets == null or socket_hud == null or weapon == null:
		return _fail("P4-05 세션 소켓 E2E에 필요한 서비스·HUD·무기가 없습니다.")
	sockets.call(&"clear_run")
	var damage_before := float(weapon.call(&"get_runtime_snapshot").get(&"damage", 0.0))
	var rune_drop: Node2D = service.call(&"spawn_candidate", player.global_position, {
		&"entry_id": &"e2e_arc_rune", &"item_id": &"arc_rune", &"grade": 3,
		&"quantity": 1, &"source_type": &"room_reward",
	})
	if rune_drop == null:
		return _fail("P4-05 전도 룬 현장 드랍을 생성하지 못했습니다.")
	rune_drop.call(&"_process", 0.0)
	await process_frame
	if not _judge_player_perception(&"session_socket_decision", "런 소켓 장착·작전 한정 이해"):
		return false
	var socket_before: Dictionary = service.call(&"get_snapshot")
	await _tap_key(KEY_F)
	await process_frame
	var socket_after: Dictionary = service.call(&"get_snapshot")
	var damage_after := float(weapon.call(&"get_runtime_snapshot").get(&"damage", 0.0))
	var socket_hud_snapshot: Dictionary = socket_hud.call(&"get_snapshot")
	var slots_row := socket_hud.get_node("%SlotsRow") as HBoxContainer
	var unsocket_success := false
	for child in slots_row.get_children():
		if child is Button and not (child as Button).disabled:
			(child as Button).pressed.emit()
			unsocket_success = true
			break
	await process_frame
	if not _judge_gameplay_flow(&"session_socket_runtime", "드랍→F 런 소켓→효과→HUD 해제", {
		&"before": socket_before,
		&"after": socket_after,
		&"hud": socket_hud_snapshot,
		&"damage_before": damage_before,
		&"damage_after": damage_after,
		&"unsocket_success": unsocket_success,
		&"damage_restored": weapon.call(&"get_runtime_snapshot").get(&"damage", -1.0),
	}):
		return false
	return true


func _verify_expanded_map_warp(player: Node2D) -> bool:
	var minimap = game.get("minimap") as Control
	var room_warp = game.get("room_warp_system")
	var encounters = game.get("room_encounter_system")
	var generator = game.get("map_generator")
	if minimap == null or room_warp == null or encounters == null or generator == null:
		return _fail("M 확장 지도 워프 E2E에 필요한 모듈이 없습니다.")
	await _tap_key(KEY_M)
	await process_frame
	var expanded: Dictionary = minimap.call(&"get_layout_snapshot")
	if (
		not bool(expanded.get(&"expanded", false))
		or expanded.get(&"layout_mode", &"") != &"expanded_interactive"
		or int(expanded.get(&"warp_target_count", 0)) < 2
	):
		return _fail("실제 M 입력이 클릭 가능한 확장 전술 지도를 열지 못했습니다: %s" % expanded)
	var targets: Array = room_warp.call(&"get_warp_targets")
	var chosen := {}
	for target: Dictionary in targets:
		if target.get(&"kind", &"") == &"junction":
			chosen = target
			break
	if chosen.is_empty():
		for target: Dictionary in targets:
			if target.get(&"kind", &"") == &"start":
				chosen = target
				break
	if chosen.is_empty():
		return _fail("확장 지도에 시작·클리어 교차 방 워프 후보가 없습니다.")
	var map_view := minimap.get_node("Margin/Content/MapView") as Control
	map_view.queue_redraw()
	await process_frame
	var rendered_rect: Rect2 = map_view.get("rendered_map_rect")
	var click_position: Vector2 = map_view.call(
		&"_world_to_minimap", chosen.get(&"world_position", Vector2.ZERO), rendered_rect
	)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = click_position
	map_view.call(&"_gui_input", click)
	await process_frame
	if not player.global_position.is_equal_approx(chosen.get(&"world_position", Vector2.ZERO)):
		return _fail("확장 지도 후보 클릭이 플레이어를 해당 방으로 워프하지 못했습니다.")
	if bool(minimap.call(&"is_expanded")):
		return _fail("워프 완료 후 확장 지도가 전투 시야를 다시 열어주지 않았습니다.")
	var rejected_uncleared := false
	for room: Dictionary in generator.call(&"get_room_encounter_snapshot"):
		var room_index := int(room.get(&"room_index", -1))
		if (
			not bool(room.get(&"is_start_room", false))
			and not bool(room.get(&"is_extraction_room", false))
			and not bool(encounters.call(&"is_room_completed", room_index))
		):
			rejected_uncleared = not bool(room_warp.call(&"request_warp", room_index))
			break
	if not rejected_uncleared:
		return _fail("미클리어 일반 방 워프 요청이 차단되지 않았습니다.")
	return true


func _verify_fog_room_corridor_transition(
	player: Node2D,
	generator: Node,
	fog: Node,
	room: Dictionary
) -> bool:
	player.global_position = room[&"center"]
	var enter_seconds := float(fog.get("room_enter_transition_seconds"))
	var exit_seconds := float(fog.get("room_exit_transition_seconds"))
	fog.call(&"_process", enter_seconds + 0.01)
	var room_snapshot: Dictionary = fog.call(&"get_snapshot")
	var corridor_position := _find_corridor_position(generator)
	if corridor_position == Vector2.INF:
		return _fail("방·통로 안개 전환을 확인할 통로 좌표가 없습니다.")
	player.global_position = corridor_position
	var grace_seconds := float(fog.get("doorway_grace_seconds"))
	fog.call(&"_process", grace_seconds * 0.5)
	var grace_snapshot: Dictionary = fog.call(&"get_snapshot")
	fog.call(&"_process", grace_seconds * 0.5 + 0.001)
	fog.call(&"_process", exit_seconds * 0.5)
	var leaving_snapshot: Dictionary = fog.call(&"get_snapshot")
	fog.call(&"_process", exit_seconds)
	var corridor_snapshot: Dictionary = fog.call(&"get_snapshot")
	player.global_position = room[&"center"]
	fog.call(&"_process", enter_seconds * 0.5)
	var entering_snapshot: Dictionary = fog.call(&"get_snapshot")
	fog.call(&"_process", enter_seconds)
	var returned_snapshot: Dictionary = fog.call(&"get_snapshot")
	return _judge_gameplay_flow(&"fog_room_corridor_transition", "방↔통로 전장의 안개", {
		&"room": room_snapshot,
		&"grace": grace_snapshot,
		&"leaving": leaving_snapshot,
		&"corridor": corridor_snapshot,
		&"entering": entering_snapshot,
		&"returned": returned_snapshot,
	})


func _verify_ten_minute_sessions(game_scene: PackedScene) -> bool:
	for tier_id in [&"medium", &"large"]:
		var tier_game := game_scene.instantiate()
		var tier_features: Resource = tier_game.get("features").duplicate(true)
		var suffix := String(tier_id)
		tier_features.set("persistent_profile_storage_path", "user://sfh_e2e_%s_profile.json" % suffix)
		tier_features.set("conditional_ranking_storage_path", "user://sfh_e2e_%s_rankings.json" % suffix)
		tier_features.set("meta_progression_storage_path", "user://sfh_e2e_%s_meta.json" % suffix)
		tier_features.set("key_mapping_storage_path", "user://sfh_e2e_%s_keys.json" % suffix)
		tier_features.set("skill_binding_storage_path", "user://sfh_e2e_%s_skills.json" % suffix)
		tier_game.set("features", tier_features)
		root.add_child(tier_game)
		await process_frame
		if not tier_game.call(&"start_run", String(tier_id)):
			root.remove_child(tier_game)
			tier_game.free()
			return _fail("%s 10분 E2E 세션을 시작하지 못했습니다." % tier_id)
		await process_frame
		var initial: Dictionary = tier_game.call(&"get_run_pacing_snapshot")
		var until_before_unlock := maxf(
			0.0,
			float(initial.get(&"extraction_unlock_seconds", 600.0))
			- float(initial.get(&"elapsed_seconds", 0.0))
			- 1.0
		)
		tier_game.call(&"advance_run_clock", until_before_unlock)
		var before_unlock: Dictionary = tier_game.call(&"get_run_pacing_snapshot")
		tier_game.call(&"advance_run_clock", 1.1)
		var after_unlock: Dictionary = tier_game.call(&"get_run_pacing_snapshot")
		var valid := _judge_gameplay_flow(&"ten_minute_session", "%s 10분 세션" % tier_id, {
			&"before_unlock": before_unlock,
			&"after_unlock": after_unlock,
		})
		root.remove_child(tier_game)
		tier_game.free()
		await process_frame
		_cleanup_tier_profile(suffix)
		if not valid:
			return false
	return true


func _find_corridor_position(generator: Node) -> Vector2:
	var cell_size := float(generator.get("cell_size"))
	for cell in generator.get("floor_cells"):
		var world_position := (Vector2(cell) + Vector2.ONE * 0.5) * cell_size
		var context: Dictionary = generator.call(&"get_visibility_region", world_position)
		if context.get(&"mode", &"room") == &"corridor":
			return world_position
	return Vector2.INF


func _cleanup_tier_profile(suffix: String) -> void:
	for path in [
		"user://sfh_e2e_%s_profile.json" % suffix,
		"user://sfh_e2e_%s_rankings.json" % suffix,
		"user://sfh_e2e_%s_meta.json" % suffix,
		"user://sfh_e2e_%s_keys.json" % suffix,
		"user://sfh_e2e_%s_skills.json" % suffix,
	]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _judge_gameplay_flow(
	flow_id: StringName,
	context: String,
	evidence: Dictionary
) -> bool:
	var result: Dictionary = gameplay_flow_judge.call(&"judge", flow_id, evidence)
	if not bool(result.get(&"success", false)):
		var errors: PackedStringArray = result.get(&"errors", PackedStringArray())
		return _fail("게임플레이 흐름 판정 실패 [%s/%s] · %s" % [
			context, flow_id, " / ".join(errors),
		])
	judged_gameplay_flows.append(flow_id)
	return true


func _judge_player_perception(
	checkpoint_id: StringName,
	context: String,
	evidence: Dictionary = {}
) -> bool:
	var result: Dictionary = player_perception_judge.call(
		&"judge", game, checkpoint_id, evidence
	)
	if not bool(result.get(&"success", false)):
		var errors: PackedStringArray = result.get(&"errors", PackedStringArray())
		return _fail("플레이어 인식 판정 실패 [%s/%s] · %s" % [
			context, checkpoint_id, " / ".join(errors),
		])
	judged_perception_checkpoints.append(checkpoint_id)
	judged_perception_units[result.get(&"perception_unit", &"unknown")] = true
	return true


func _judge_ui_state(state_id: StringName, context: String) -> bool:
	var result: Dictionary = ui_state_judge.call(&"judge", game, state_id)
	if not bool(result.get(&"success", false)):
		var errors: PackedStringArray = result.get(&"errors", PackedStringArray())
		return _fail("UI 상태 판정 실패 [%s/%s] · %s" % [context, state_id, " / ".join(errors)])
	judged_ui_states.append(state_id)
	return true


func _tap_key(keycode: Key) -> void:
	var pressed_event := InputEventKey.new()
	pressed_event.keycode = keycode
	pressed_event.physical_keycode = keycode
	pressed_event.pressed = true
	Input.parse_input_event(pressed_event)
	await process_frame
	var released_event := pressed_event.duplicate() as InputEventKey
	released_event.pressed = false
	Input.parse_input_event(released_event)
	await process_frame


func _press_key_for_physics(keycode: Key, frame_count: int = 1) -> void:
	var pressed_event := InputEventKey.new()
	pressed_event.keycode = keycode
	pressed_event.physical_keycode = keycode
	pressed_event.pressed = true
	Input.parse_input_event(pressed_event)
	for _frame in range(maxi(1, frame_count)):
		await physics_frame
	var released_event := pressed_event.duplicate() as InputEventKey
	released_event.pressed = false
	Input.parse_input_event(released_event)
	await process_frame


func _reset_test_profile() -> void:
	_cleanup_test_profile()


func _cleanup_test_profile() -> void:
	for path in [E2E_PROFILE_PATH, E2E_RANKINGS_PATH, E2E_META_PATH, E2E_KEY_MAPPING_PATH, E2E_SKILL_BINDING_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _fail(message: String) -> bool:
	Input.action_release(&"move_right")
	paused = false
	printerr("E2E_PLAY_SESSION_FAILED: %s" % message)
	_cleanup_test_profile()
	quit(1)
	return false
