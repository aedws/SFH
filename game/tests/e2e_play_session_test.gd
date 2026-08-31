extends SceneTree

const GAME_SCENE_PATH := "res://game/scenes/game.tscn"
const E2E_PROFILE_PATH := "user://sfh_e2e_profile.json"
const E2E_RANKINGS_PATH := "user://sfh_e2e_rankings.json"
const E2E_META_PATH := "user://sfh_e2e_meta_progression.json"
const E2E_KEY_MAPPING_PATH := "user://sfh_e2e_key_mapping.json"
const UI_STATE_JUDGE_SCRIPT := preload("res://game/tests/support/ui_state_judge.gd")

var game: Node
var ui_state_judge := UI_STATE_JUDGE_SCRIPT.new()
var judged_ui_states := PackedStringArray()


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
	game.set("features", isolated_features)
	root.add_child(game)
	await process_frame
	await process_frame

	if not await _verify_hub_input_session():
		return
	if not await _verify_operation_session():
		return
	if not await _verify_failure_and_return_session():
		return

	paused = false
	print("E2E_PLAY_SESSION_OK ui_state_contracts_%d viewport_bounds modal_exclusivity hud_non_overlap operation_briefing selected_then_launch tactical_hud mission_tracker bottom_combat_cluster glance_hud hub_real_input key_mapping_k_esc u_e_action_split operation_setup combat_hud loot extraction_pause_resume settlement_return death_return" % judged_ui_states.size())
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
		or int(key_panel.call(&"get_snapshot").get(&"binding_row_count", 0)) != 21
	):
		return _fail("실제 K 입력이 전체 Action 키 설정 화면을 열지 못했습니다.")
	if not _judge_ui_state(&"key_mapping_hub", "거점 K 키 설정"):
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
	var summary_text := String((workbench.get("character_summary") as Label).text)
	if "장비 태그 호환" not in summary_text or "활성 스킬" in summary_text:
		return _fail("장비 호환 수치가 실제 활성 스킬 수처럼 오해되는 문구로 표시됩니다.")

	await _tap_key(KEY_E)
	if not workbench.visible or int((workbench.get("tabs") as TabContainer).current_tab) != 1:
		return _fail("열린 U 화면에서 실제 E 입력이 창을 닫지 않고 모듈·파츠 탭으로 전환하지 못했습니다.")
	if not _judge_ui_state(&"modification_hub", "거점 E 모듈·파츠"):
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

	var weapon_before: StringName = equipment.call(&"get_active_weapon_slot")
	await _tap_key(KEY_Q)
	var weapon_after: StringName = equipment.call(&"get_active_weapon_slot")
	if weapon_before == weapon_after:
		return _fail("실제 Q 입력이 거점 무기를 교체하지 못했습니다.")

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
	):
		return _fail("작전 진입 화면이 브리핑·계약·명시적 투입 구조를 제공하지 않습니다.")
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
	var control_hint := game.get("control_hint_label") as Label
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
	):
		return _fail("전투 HUD가 임무 추적기와 하단 시선권으로 구성되지 않았습니다: %s" % hud_snapshot)
	var mission_rect: Rect2 = hud_snapshot.get(&"mission_rect", Rect2())
	var core_rect: Rect2 = hud_snapshot.get(&"core_rect", Rect2())
	if mission_rect.intersects(core_rect) or core_rect.intersects(skills.get_global_rect()):
		return _fail("임무 추적기·생존 정보·스킬 UI가 서로 겹칩니다: %s" % hud_snapshot)
	if (
		"기본기" not in control_hint.text
		or "스킬" not in control_hint.text
		or "K 키 설정" not in control_hint.text
	):
		return _fail("실제 조작 범위와 다른 전투 안내 문구가 표시됩니다.")
	if minimap.get_global_rect().intersects(skills.get_global_rect()):
		return _fail("미니맵과 스킬 HUD가 화면에서 겹칩니다.")
	if not _judge_ui_state(&"combat", "첫 전투 HUD"):
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
	await _tap_key(KEY_F)
	var credit_ledger = game.get("credit_ledger")
	if int(credit_ledger.get("carried_credits")) <= 0:
		return _fail("파밍 오브젝트 앞 실제 F 입력이 휴대 크레딧을 회수하지 못했습니다.")

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
	var remaining_before := float(extraction_state.get(&"defense_remaining_seconds", 0.0))
	player.global_position += Vector2(float(extraction.get("interaction_radius")) + 80.0, 0.0)
	extraction.call(&"advance", 0.5)
	extraction_state = extraction.call(&"get_snapshot")
	if not bool(extraction_state.get(&"defense_paused", false)):
		return _fail("탈출 구역 이탈 시 방어 카운트다운이 일시정지되지 않았습니다.")
	if float(extraction_state.get(&"defense_remaining_seconds", 0.0)) < remaining_before - 0.1:
		return _fail("탈출 구역 밖에서 카운트다운이 소모됩니다.")
	player.global_position = extraction.global_position
	if not extraction.call(&"request_extraction", player):
		return _fail("탈출 구역 복귀 후 방어전을 재개하지 못했습니다.")
	extraction.call(&"advance", remaining_before + 0.5)
	await process_frame
	var result := game.get_node("UI/GameOverOverlay") as Control
	var title := game.get_node("UI/GameOverOverlay/Center/Panel/Margin/Content/EndTitle") as Label
	if not result.visible or title.text != "탈출 성공" or not paused:
		return _fail("탈출 완료 후 성공 정산 화면이 표시되지 않았습니다.")
	if not _judge_ui_state(&"result", "성공 결과"):
		return false
	await _tap_key(KEY_ENTER)
	if game.get("start_hub") == null or bool(game.get("run_started")) or paused:
		return _fail("정산 화면의 실제 Enter 입력이 시작 거점으로 복귀하지 못했습니다.")
	if not _judge_ui_state(&"hub", "성공 정산 후 거점"):
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
	var title := game.get_node("UI/GameOverOverlay/Center/Panel/Margin/Content/EndTitle") as Label
	if not bool(game.get("run_ended")) or title.text != "작전 실패" or not paused:
		return _fail("플레이어 사망 후 실패 정산이 표시되지 않았습니다.")
	if not _judge_ui_state(&"result", "실패 결과"):
		return false
	await _tap_key(KEY_ENTER)
	if game.get("start_hub") == null or bool(game.get("run_started")) or paused:
		return _fail("실패 정산 후 실제 Enter 입력이 시작 거점으로 복귀하지 못했습니다.")
	if not _judge_ui_state(&"hub", "실패 정산 후 거점"):
		return false
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


func _reset_test_profile() -> void:
	_cleanup_test_profile()


func _cleanup_test_profile() -> void:
	for path in [E2E_PROFILE_PATH, E2E_RANKINGS_PATH, E2E_META_PATH, E2E_KEY_MAPPING_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _fail(message: String) -> bool:
	Input.action_release(&"move_right")
	paused = false
	printerr("E2E_PLAY_SESSION_FAILED: %s" % message)
	_cleanup_test_profile()
	quit(1)
	return false
