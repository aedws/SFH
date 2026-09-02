extends SceneTree

const GAME_SCENE_PATH := "res://game/scenes/game.tscn"
const TIERS := [&"small", &"medium", &"large"]
const DIFFICULTIES := [&"standard", &"veteran", &"nightmare"]


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	var game_scene := load(GAME_SCENE_PATH) as PackedScene
	if game_scene == null:
		_fail("게임 장면을 불러오지 못했습니다.")
		return
	var verified := 0
	for tier_id in TIERS:
		for difficulty_id in DIFFICULTIES:
			var game := game_scene.instantiate()
			var features: Resource = game.get("features").duplicate(true)
			var suffix := "%s_%s" % [tier_id, difficulty_id]
			features.set("map_seed", 4040600 + verified)
			features.set("persistent_profile_storage_path", "user://sfh_combo_%s_profile.json" % suffix)
			features.set("conditional_ranking_storage_path", "user://sfh_combo_%s_rankings.json" % suffix)
			features.set("meta_progression_storage_path", "user://sfh_combo_%s_meta.json" % suffix)
			features.set("key_mapping_storage_path", "user://sfh_combo_%s_keys.json" % suffix)
			features.set("skill_binding_storage_path", "user://sfh_combo_%s_skills.json" % suffix)
			features.set("presentation_settings_storage_path", "user://sfh_combo_%s_presentation.json" % suffix)
			game.set("features", features)
			root.add_child(game)
			await process_frame
			await process_frame
			var profile = game.get("persistent_profile")
			var contracts = game.get("operation_contract_service")
			var failure := ""
			if profile == null or contracts == null:
				failure = "프로필 또는 작전 계약 서비스가 없습니다."
			else:
				profile.call(&"reset_profile", true)
				if not contracts.call(&"select_difficulty", difficulty_id):
					failure = "난이도 선택이 거부됐습니다."
				else:
					var hub = game.get("start_hub")
					var player = game.get("player") as Node2D
					if hub == null or player == null:
						failure = "기본 거점 진입 경로가 준비되지 않았습니다."
					else:
						player.global_position = hub.call(&"get_operation_position")
						if not hub.call(&"request_operation", player):
							failure = "거점 게이트가 작전 설정을 열지 못했습니다."
						else:
							var tier_button: Button = {
								&"small": game.get("small_map_button"),
								&"medium": game.get("medium_map_button"),
								&"large": game.get("large_map_button"),
							}.get(tier_id)
							var presenter = game.get("operation_setup_presenter")
							if tier_button == null or presenter == null:
								failure = "작전 규모 카드 또는 단계 설정기가 없습니다."
							else:
								tier_button.pressed.emit()
								presenter.call(&"step_relative", 1)
								presenter.call(&"step_relative", 1)
								var wizard: Dictionary = presenter.call(&"get_snapshot")
								if not bool(wizard.get(&"launch_on_confirmation", false)):
									failure = "3단계 작전 설정이 최종 투입 상태에 도달하지 못했습니다."
								else:
									(game.get("operation_launch_button") as Button).pressed.emit()
									await process_frame
				if failure.is_empty():
					var active: Dictionary = game.get("active_contract")
					if (
						not bool(game.get("run_started"))
						or game.get("start_hub") != null
						or game.get("player") == null
						or game.get("map_generator") == null
					):
						failure = "전투 조립 뒤 거점 또는 필수 런타임 상태가 잘못됐습니다."
					elif StringName(active.get(&"tier_id", &"")) != tier_id:
						failure = "선택 맵 등급이 active_contract에 유지되지 않았습니다."
					elif StringName(active.get(&"difficulty_id", &"")) != difficulty_id:
						failure = "선택 난이도가 active_contract에 유지되지 않았습니다."
					elif game.get("operation_tutorial_overlay") == null:
						failure = "첫 투입 현장 튜토리얼이 설치되지 않았습니다."
					else:
						verified += 1
						game.call(&"_return_to_start_hub")
						await process_frame
						if game.get("start_hub") == null or bool(game.get("run_started")):
							failure = "작전 종료 뒤 거점 복귀 상태가 잘못됐습니다."
			root.remove_child(game)
			game.free()
			await process_frame
			_cleanup_paths(features)
			if not failure.is_empty():
				_fail("%s/%s 조합 실패: %s" % [tier_id, difficulty_id, failure])
				return
	var routes_verified := await _verify_initial_routes(game_scene)
	if routes_verified != 4:
		return
	if not await _verify_repeat_without_loot_settlement(game_scene):
		return
	if not await _verify_tutorial_optional(game_scene):
		return
	print("OPERATION_COMBINATION_OK combinations_%d tiers_3 difficulties_3 launch_assemble_return entry_routes_4 wizard_steps_3 tutorial_steps_4 tutorial_optional settlement_optional_repeat" % verified)
	quit(0)


func _verify_initial_routes(game_scene: PackedScene) -> int:
	var route_cases := [
		{&"hub": true, &"setup": true, &"expected": &"hub"},
		{&"hub": false, &"setup": true, &"expected": &"setup"},
		{&"hub": true, &"setup": false, &"expected": &"operation"},
		{&"hub": false, &"setup": false, &"expected": &"operation"},
	]
	var verified := 0
	for index in route_cases.size():
		var route: Dictionary = route_cases[index]
		var game := game_scene.instantiate()
		var features: Resource = game.get("features").duplicate(true)
		features.set("start_hub_enabled", bool(route[&"hub"]))
		features.set("run_setup_enabled", bool(route[&"setup"]))
		features.set("map_seed", 5050600 + index)
		features.set("persistent_profile_storage_path", "user://sfh_route_%d_profile.json" % index)
		features.set("conditional_ranking_storage_path", "user://sfh_route_%d_rankings.json" % index)
		features.set("meta_progression_storage_path", "user://sfh_route_%d_meta.json" % index)
		features.set("key_mapping_storage_path", "user://sfh_route_%d_keys.json" % index)
		features.set("skill_binding_storage_path", "user://sfh_route_%d_skills.json" % index)
		features.set("presentation_settings_storage_path", "user://sfh_route_%d_presentation.json" % index)
		game.set("features", features)
		root.add_child(game)
		await process_frame
		await process_frame
		var expected: StringName = route[&"expected"]
		var valid := false
		match expected:
			&"hub":
				valid = game.get("start_hub") != null and not bool(game.get("run_started"))
			&"setup":
				valid = game.get_node("UI/RunSetupOverlay").visible and not bool(game.get("run_started"))
			&"operation":
				valid = bool(game.get("run_started")) and game.get("map_generator") != null and game.get("player") != null
		if not valid:
			root.remove_child(game)
			game.free()
			_cleanup_paths(features)
			_fail("초기 진입 경로 %d가 %s 상태로 연결되지 않았습니다." % [index, expected])
			return verified
		verified += 1
		root.remove_child(game)
		game.free()
		await process_frame
		_cleanup_paths(features)
	return verified


func _verify_repeat_without_loot_settlement(game_scene: PackedScene) -> bool:
	var game := game_scene.instantiate()
	var features: Resource = game.get("features").duplicate(true)
	features.set("run_settlement_enabled", false)
	features.set("map_seed", 6060700)
	features.set("persistent_profile_storage_path", "user://sfh_repeat_profile.json")
	features.set("conditional_ranking_storage_path", "user://sfh_repeat_rankings.json")
	features.set("meta_progression_storage_path", "user://sfh_repeat_meta.json")
	features.set("key_mapping_storage_path", "user://sfh_repeat_keys.json")
	features.set("skill_binding_storage_path", "user://sfh_repeat_skills.json")
	features.set("presentation_settings_storage_path", "user://sfh_repeat_presentation.json")
	game.set("features", features)
	root.add_child(game)
	await process_frame
	await process_frame
	(game.get("persistent_profile")).call(&"reset_profile", true)
	for run_index in 2:
		if not game.call(&"start_run", "small"):
			root.remove_child(game)
			game.free()
			_cleanup_paths(features)
			_fail("전리품 정산 비활성 반복 투입 %d회차가 차단됐습니다." % (run_index + 1))
			return false
		await process_frame
		game.call(&"_settle_run_loot", false)
		game.call(&"_return_to_start_hub")
		await process_frame
	root.remove_child(game)
	game.free()
	await process_frame
	_cleanup_paths(features)
	return true


func _verify_tutorial_optional(game_scene: PackedScene) -> bool:
	var game := game_scene.instantiate()
	var features: Resource = game.get("features").duplicate(true)
	features.set("operation_tutorial_enabled", false)
	features.set("persistent_profile_storage_path", "user://sfh_tutorial_optional_profile.json")
	features.set("conditional_ranking_storage_path", "user://sfh_tutorial_optional_rankings.json")
	features.set("meta_progression_storage_path", "user://sfh_tutorial_optional_meta.json")
	features.set("key_mapping_storage_path", "user://sfh_tutorial_optional_keys.json")
	features.set("skill_binding_storage_path", "user://sfh_tutorial_optional_skills.json")
	features.set("presentation_settings_storage_path", "user://sfh_tutorial_optional_presentation.json")
	game.set("features", features)
	root.add_child(game)
	await process_frame
	var valid: bool = (
		game.get("operation_tutorial_overlay") == null
		and bool(game.call(&"start_run", "small"))
	)
	root.remove_child(game)
	game.free()
	await process_frame
	_cleanup_paths(features)
	if not valid:
		_fail("작전 튜토리얼을 제거한 구성에서 핵심 작전이 독립 실행되지 않았습니다.")
	return valid


func _cleanup_paths(features: Resource) -> void:
	for property_name in [
		"persistent_profile_storage_path", "conditional_ranking_storage_path",
		"meta_progression_storage_path", "key_mapping_storage_path",
		"skill_binding_storage_path", "presentation_settings_storage_path",
	]:
		var path := String(features.get(property_name))
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
