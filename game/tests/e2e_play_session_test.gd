extends SceneTree

const GAME_SCENE_PATH := "res://game/scenes/game.tscn"
const E2E_PROFILE_PATH := "user://sfh_e2e_profile.json"
const E2E_RANKINGS_PATH := "user://sfh_e2e_rankings.json"
const E2E_META_PATH := "user://sfh_e2e_meta_progression.json"

var game: Node


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
	print("E2E_PLAY_SESSION_OK hub_real_input u_e_action_split operation_setup combat_hud loot extraction_pause_resume settlement_return death_return")
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
	if "U 장비" not in hub_hint.text or "E 모듈·파츠" not in hub_hint.text:
		return _fail("거점 조작 안내가 U와 E의 서로 다른 역할을 설명하지 않습니다.")

	await _tap_key(KEY_I)
	if not inventory.visible or not paused or hub_hud.visible:
		return _fail("실제 I 입력이 겹침 없이 가방을 열지 못했습니다.")
	await _tap_key(KEY_ESCAPE)
	if inventory.visible or paused or not hub_hud.visible:
		return _fail("실제 ESC 입력이 가방을 닫고 거점 HUD를 복원하지 못했습니다.")

	await _tap_key(KEY_U)
	if not workbench.visible or int((workbench.get("tabs") as TabContainer).current_tab) != 0:
		return _fail("실제 U 입력이 캐릭터 장비 탭을 열지 못했습니다.")
	var summary_text := String((workbench.get("character_summary") as Label).text)
	if "장비 태그 호환" not in summary_text or "활성 스킬" in summary_text:
		return _fail("장비 호환 수치가 실제 활성 스킬 수처럼 오해되는 문구로 표시됩니다.")

	await _tap_key(KEY_E)
	if not workbench.visible or int((workbench.get("tabs") as TabContainer).current_tab) != 1:
		return _fail("열린 U 화면에서 실제 E 입력이 창을 닫지 않고 모듈·파츠 탭으로 전환하지 못했습니다.")
	await _tap_key(KEY_U)
	if not workbench.visible or int((workbench.get("tabs") as TabContainer).current_tab) != 0:
		return _fail("열린 E 화면에서 실제 U 입력이 장비 탭으로 돌아오지 못했습니다.")
	await _tap_key(KEY_ESCAPE)
	if workbench.visible or paused:
		return _fail("실제 ESC 입력이 장비 화면을 닫지 못했습니다.")

	var weapon_before: StringName = equipment.call(&"get_active_weapon_slot")
	await _tap_key(KEY_Q)
	var weapon_after: StringName = equipment.call(&"get_active_weapon_slot")
	if weapon_before == weapon_after:
		return _fail("실제 Q 입력이 거점 무기를 교체하지 못했습니다.")

	var gate_position: Vector2 = hub.call(&"get_operation_position")
	Input.action_press(&"ui_right")
	var reached_gate := false
	for _frame in range(480):
		await physics_frame
		if player.global_position.distance_to(gate_position) <= float(hub.get("interaction_radius")) * 0.8:
			reached_gate = true
			break
	Input.action_release(&"ui_right")
	if not reached_gate:
		return _fail("실제 지속 이동 입력으로 거점 작전 게이트까지 이동하지 못했습니다.")
	await physics_frame
	await physics_frame
	await _tap_key(KEY_F)
	if not setup.visible or not paused or hub_hud.visible:
		return _fail("게이트의 실제 F 입력이 겹침 없이 작전 설정을 열지 못했습니다.")
	return true


func _verify_operation_session() -> bool:
	var setup := game.get_node("UI/RunSetupOverlay") as Control
	var small_button := game.get_node(
		"UI/RunSetupOverlay/Center/Panel/Margin/Content/TierButtons/SmallMapButton"
	) as Button
	if small_button == null or small_button.disabled:
		return _fail("소형 작전 카드가 실제 선택 가능한 상태가 아닙니다.")
	small_button.pressed.emit()
	await process_frame
	await process_frame
	if setup.visible or paused or not bool(game.get("run_started")):
		return _fail("소형 작전 카드 선택 후 전투 세션으로 전환되지 않았습니다.")

	var player = game.get("player") as Node2D
	var minimap = game.get("minimap") as Control
	var skills = game.get("combat_skill_hud") as Control
	var dash = game.get("dash_cooldown_hud") as Control
	var control_hint := game.get_node("UI/HUDMargin/Panel/Margin/Content/FooterRow/Hint") as Label
	if player == null or minimap == null or skills == null or dash == null:
		return _fail("전투 HUD·미니맵·대시 UI가 함께 설치되지 않았습니다.")
	if not minimap.visible or not skills.visible or not dash.visible:
		return _fail("전투 HUD의 필수 자원·쿨타임 정보가 보이지 않습니다.")
	if "LMB 기본기" not in control_hint.text or "1~9 스킬" not in control_hint.text:
		return _fail("실제 조작 범위와 다른 전투 안내 문구가 표시됩니다.")
	if minimap.get_global_rect().intersects(skills.get_global_rect()):
		return _fail("미니맵과 스킬 HUD가 화면에서 겹칩니다.")

	await _tap_key(KEY_I)
	var inventory = game.get("inventory_window") as Control
	if inventory == null or not inventory.visible or not paused:
		return _fail("전투 세션에서 실제 I 입력으로 가방을 확인할 수 없습니다.")
	await _tap_key(KEY_ESCAPE)
	await _tap_key(KEY_U)
	var workbench = game.get("equipment_workbench") as Control
	if workbench == null or not workbench.visible:
		return _fail("전투 세션에서 실제 U 입력으로 장비를 확인할 수 없습니다.")
	await _tap_key(KEY_E)
	if not workbench.visible or int((workbench.get("tabs") as TabContainer).current_tab) != 1:
		return _fail("전투 세션에서도 E가 모듈·파츠 탭을 안정적으로 열지 못했습니다.")
	await _tap_key(KEY_ESCAPE)

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
	await _tap_key(KEY_ENTER)
	if game.get("start_hub") == null or bool(game.get("run_started")) or paused:
		return _fail("정산 화면의 실제 Enter 입력이 시작 거점으로 복귀하지 못했습니다.")
	return true


func _verify_failure_and_return_session() -> bool:
	if not game.call(&"start_run", "small"):
		return _fail("성공 정산 후 두 번째 작전을 시작할 수 없습니다.")
	await process_frame
	var player = game.get("player")
	player.call(&"take_damage", 999999.0)
	await process_frame
	var title := game.get_node("UI/GameOverOverlay/Center/Panel/Margin/Content/EndTitle") as Label
	if not bool(game.get("run_ended")) or title.text != "작전 실패" or not paused:
		return _fail("플레이어 사망 후 실패 정산이 표시되지 않았습니다.")
	await _tap_key(KEY_ENTER)
	if game.get("start_hub") == null or bool(game.get("run_started")) or paused:
		return _fail("실패 정산 후 실제 Enter 입력이 시작 거점으로 복귀하지 못했습니다.")
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
	for path in [E2E_PROFILE_PATH, E2E_RANKINGS_PATH, E2E_META_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _fail(message: String) -> bool:
	Input.action_release(&"ui_right")
	paused = false
	printerr("E2E_PLAY_SESSION_FAILED: %s" % message)
	_cleanup_test_profile()
	quit(1)
	return false
