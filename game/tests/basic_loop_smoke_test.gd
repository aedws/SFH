extends SceneTree

const GAME_SCENE_PATH := "res://game/scenes/game.tscn"
const MAP_GENERATOR_SCENE_PATH := "res://game/features/map_generation/map_generator.tscn"
const MAP_CONFIG_PATH_PATTERN := "res://game/features/map_generation/configs/%s.tres"
const LOOT_CONFIG_PATH_PATTERN := "res://game/features/loot/configs/%s.tres"
const MAP_TIER_IDS := ["small", "medium", "large"]

var game_instance: Node
var frame_count: int = 0


func _init() -> void:
	if not _verify_map_tiers():
		return
	if not await _verify_enemy_stats_modules():
		return

	var game_scene := load(GAME_SCENE_PATH) as PackedScene
	if game_scene == null:
		_fail("Game Scene을 불러오지 못했습니다.")
		return
	if not await _verify_all_tier_entry(game_scene):
		return
	if not await _verify_optional_map_module(game_scene):
		return
	if not await _verify_extraction_flow(game_scene):
		return

	game_instance = game_scene.instantiate()
	root.add_child(game_instance)
	await process_frame
	var setup_overlay := game_instance.get_node("UI/RunSetupOverlay") as Control
	if not setup_overlay.visible or game_instance.get("player") != null:
		_fail("작전 규모 선택 화면이 게임 조립 전에 표시되지 않았습니다.")
		return
	game_instance.call(&"start_run", "small")
	frame_count = 0


func _verify_map_tiers() -> bool:
	var generator_scene := load(MAP_GENERATOR_SCENE_PATH) as PackedScene
	if generator_scene == null:
		_fail("Map Generator Scene을 불러오지 못했습니다.")
		return false

	for tier_id in MAP_TIER_IDS:
		var config = load(MAP_CONFIG_PATH_PATTERN % tier_id)
		var generator := generator_scene.instantiate()
		root.add_child(generator)
		generator.call(&"generate", config, 104729)

		var room_count: int = generator.get("rooms").size()
		var minimum_rooms: int = config.get("minimum_rooms")
		var maximum_rooms: int = config.get("maximum_rooms")
		if room_count < minimum_rooms or room_count > maximum_rooms:
			_fail("%s 맵의 방 수가 범위를 벗어났습니다." % tier_id)
			return false

		var path: PackedVector2Array = generator.call(
			&"get_world_path",
			generator.call(&"get_player_spawn_position"),
			generator.call(&"get_extraction_position")
		)
		if path.is_empty():
			_fail("%s 맵의 시작점과 탈출 지점이 연결되지 않았습니다." % tier_id)
			return false
		if generator.get("obstacle_cells").is_empty():
			_fail("%s 맵에 방해물이 생성되지 않았습니다." % tier_id)
			return false
		var obstacle_kinds: Array = generator.get("obstacle_cells").values()
		if &"wall" not in obstacle_kinds or &"pillar" not in obstacle_kinds:
			_fail("%s 맵에 실내 벽과 기둥 패턴이 모두 생성되지 않았습니다." % tier_id)
			return false
		var loot_config = load(LOOT_CONFIG_PATH_PATTERN % tier_id)
		var loot_positions: PackedVector2Array = generator.call(
			&"get_loot_spawn_positions",
			int(loot_config.get("minimum_cache_count"))
		)
		if loot_positions.size() < int(loot_config.get("minimum_cache_count")):
			_fail("%s 맵에 필요한 파밍 위치를 확보하지 못했습니다." % tier_id)
			return false
		if not is_equal_approx(float(generator.get("cell_size")), 32.0):
			_fail("맵 타일 크기가 32px로 조정되지 않았습니다.")
			return false

		root.remove_child(generator)
		generator.free()

	return true


func _verify_all_tier_entry(game_scene: PackedScene) -> bool:
	var button_names := {
		"small": "SmallMapButton",
		"medium": "MediumMapButton",
		"large": "LargeMapButton",
	}
	for tier_id in MAP_TIER_IDS:
		var tier_game := game_scene.instantiate()
		root.add_child(tier_game)
		await process_frame
		var button := tier_game.get_node(
			"UI/RunSetupOverlay/Center/Panel/Margin/Content/TierButtons/%s" % button_names[tier_id]
		) as Button
		var failure_message := ""
		if button.disabled:
			failure_message = "%s 작전 버튼이 비활성화됐습니다: %s" % [tier_id, button.text]
		else:
			button.pressed.emit()
			await process_frame
			var generator = tier_game.get("map_generator")
			var minimap = tier_game.get("minimap")
			var config = load(MAP_CONFIG_PATH_PATTERN % tier_id)
			if not bool(tier_game.get("run_started")):
				failure_message = "%s 작전이 시작 상태로 전환되지 않았습니다." % tier_id
			elif String(tier_game.get("selected_map_size")) != tier_id:
				failure_message = "%s 작전 선택값이 조립부에 전달되지 않았습니다." % tier_id
			elif tier_game.get("player") == null or generator == null:
				failure_message = "%s 작전의 플레이어 또는 맵이 설치되지 않았습니다." % tier_id
			elif tier_game.get("extraction_zone") == null or minimap == null:
				failure_message = "%s 작전의 탈출 또는 미니맵이 설치되지 않았습니다." % tier_id
			elif generator.get("rooms").size() < int(config.get("minimum_rooms")):
				failure_message = "%s 작전의 최소 방 수를 생성하지 못했습니다." % tier_id
			else:
				var map_view = minimap.get_node("Margin/Content/MapView")
				if map_view.get("map_texture") == null:
					failure_message = "%s 작전의 미니맵 텍스처가 생성되지 않았습니다." % tier_id

		root.remove_child(tier_game)
		tier_game.free()
		await process_frame
		if not failure_message.is_empty():
			_fail("티어 진입 실패: %s" % failure_message)
			return false
	return true


func _verify_enemy_stats_modules() -> bool:
	var enemy_scene := load("res://game/features/enemies/enemy.tscn") as PackedScene
	if enemy_scene == null:
		_fail("Enemy Scene을 불러오지 못했습니다.")
		return false
	var enemy := enemy_scene.instantiate()
	root.add_child(enemy)
	await process_frame
	var health = enemy.get_node("HealthComponent")
	var armor = enemy.get_node("ArmorComponent")
	var status_bars := enemy.get_node("StatusBars") as Node2D
	var initial_health := float(health.get("current_value"))
	var initial_armor := float(armor.get("current_value"))
	enemy.call(&"take_damage", 1.0)
	var valid := (
		initial_health > 0.0
		and initial_armor > 0.0
		and is_equal_approx(float(health.get("current_value")), initial_health)
		and float(armor.get("current_value")) < initial_armor
		and status_bars.visible
	)
	root.remove_child(enemy)
	enemy.free()
	if not valid:
		_fail("적 체력·방어력 컴포넌트 또는 상태바가 정상 동작하지 않습니다.")
		return false
	return true


func _verify_optional_map_module(game_scene: PackedScene) -> bool:
	var fallback_game := game_scene.instantiate()
	var fallback_features = fallback_game.get("features").duplicate(true)
	fallback_features.set("map_generation_enabled", false)
	fallback_features.set("map_obstacles_enabled", false)
	fallback_features.set("minimap_enabled", false)
	fallback_features.set("extraction_enabled", false)
	fallback_features.set("run_setup_enabled", false)
	fallback_features.set("loot_enabled", false)
	fallback_game.set("features", fallback_features)
	root.add_child(fallback_game)
	await process_frame

	var fallback_player = fallback_game.get("player")
	var fallback_spawner = fallback_game.get("enemy_spawner")
	var map_label := fallback_game.get_node(
		"UI/HUDMargin/Panel/Margin/Content/TopRow/MapLabel"
	) as Label
	var failure_message := ""
	if fallback_game.get("map_generator") != null:
		failure_message = "비활성화했지만 맵 생성기가 설치됐습니다."
	elif fallback_player == null or fallback_player.global_position != Vector2.ZERO:
		failure_message = "비활성화 폴백의 플레이어 시작 위치가 원점이 아닙니다: %s" % (
			fallback_player.global_position if fallback_player != null else "player=null"
		)
	elif fallback_spawner == null or fallback_spawner.get("map_provider") != null:
		failure_message = "비활성화 폴백의 적 생성기에 맵 제공자가 남아 있습니다."
	elif map_label.visible:
		failure_message = "비활성화했지만 맵 HUD가 표시됩니다."
	elif fallback_game.get("minimap") != null:
		failure_message = "비활성화했지만 미니맵이 설치됐습니다."

	root.remove_child(fallback_game)
	fallback_game.free()

	if not failure_message.is_empty():
		_fail("맵 모듈 비활성화 실패: %s" % failure_message)
		return false

	return true


func _verify_extraction_flow(game_scene: PackedScene) -> bool:
	var extraction_game := game_scene.instantiate()
	root.add_child(extraction_game)
	await process_frame

	var setup_overlay := extraction_game.get_node("UI/RunSetupOverlay") as Control
	if not setup_overlay.visible:
		_fail("첫 실행 작전 규모 선택 화면이 표시되지 않았습니다.")
		return false

	extraction_game.call(&"start_run", "small")
	await process_frame
	var extraction_player = extraction_game.get("player")
	var extraction_zone = extraction_game.get("extraction_zone")
	var credit_ledger = extraction_game.get("credit_ledger")
	var loot_spawner = extraction_game.get("loot_spawner")
	var failure_message := ""
	if extraction_player == null or extraction_zone == null or credit_ledger == null or loot_spawner == null:
		failure_message = "플레이어, 탈출, 크레딧 또는 파밍 모듈이 설치되지 않았습니다."
	elif not _has_f_interaction_binding():
		failure_message = "interact 입력에 F 키가 할당되지 않았습니다."
	else:
		var loot_caches: Array[Node] = []
		for child in extraction_game.get_node("World/Pickups").get_children():
			if child.has_method(&"request_loot"):
				loot_caches.append(child)
		if loot_caches.is_empty():
			failure_message = "랜덤 1회성 파밍 오브젝트가 생성되지 않았습니다."
		else:
			var cache := loot_caches[0] as Node2D
			extraction_player.global_position = cache.global_position
			if not cache.call(&"request_loot", extraction_player):
				failure_message = "파밍 오브젝트에서 크레딧을 획득하지 못했습니다."
			elif cache.call(&"request_loot", extraction_player):
				failure_message = "1회성 파밍 오브젝트를 두 번 획득할 수 있습니다."
			elif int(credit_ledger.get("carried_credits")) <= 0:
				failure_message = "획득한 크레딧이 휴대 원장에 기록되지 않았습니다."

	if failure_message.is_empty():
		extraction_player.global_position = extraction_zone.global_position
		if not extraction_zone.call(&"request_extraction", extraction_player):
			failure_message = "탈출 지점에서 상호작용 요청이 거부됐습니다."
		elif not bool(extraction_game.get("run_ended")):
			failure_message = "탈출 성공 후 작전이 종료되지 않았습니다."
		elif int(credit_ledger.get("secured_credits")) <= 0:
			failure_message = "탈출 성공 후 크레딧이 회수 처리되지 않았습니다."
		elif String(extraction_game.get_node("UI/GameOverOverlay/Center/Panel/Margin/Content/EndTitle").text) != "탈출 성공":
			failure_message = "탈출 성공 결과 화면이 표시되지 않았습니다."

	paused = false
	root.remove_child(extraction_game)
	extraction_game.free()
	if not failure_message.is_empty():
		_fail("탈출 흐름 실패: %s" % failure_message)
		return false
	return true


func _has_f_interaction_binding() -> bool:
	if not InputMap.has_action(&"interact"):
		return false
	for event in InputMap.action_get_events(&"interact"):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			if key_event.keycode == KEY_F or key_event.physical_keycode == KEY_F:
				return true
	return false


func _process(_delta: float) -> bool:
	frame_count += 1

	if frame_count == 120:
		var player := get_first_node_in_group(&"player")
		var enemies := get_nodes_in_group(&"enemies")
		if player == null:
			return _fail("player 그룹이 비어 있습니다.")
		if enemies.is_empty():
			return _fail("적이 생성되지 않았습니다.")

		var progression = game_instance.get("progression_system")
		var weapon = game_instance.get("auto_weapon")
		var map_generator = game_instance.get("map_generator")
		var extraction_zone = game_instance.get("extraction_zone")
		if progression == null or weapon == null or map_generator == null or extraction_zone == null:
			return _fail("맵, 탈출, 전투 또는 성장 모듈이 설치되지 않았습니다.")
		var small_config = load(MAP_CONFIG_PATH_PATTERN % "small")
		if map_generator.get("rooms").size() < int(small_config.get("minimum_rooms")):
			return _fail("소형 맵의 최소 방 수를 생성하지 못했습니다.")
		if map_generator.get("obstacle_cells").is_empty():
			return _fail("소형 맵에 방해물이 생성되지 않았습니다.")
		if not map_generator.call(&"is_walkable_world_position", player.global_position):
			return _fail("플레이어가 걸을 수 없는 위치에 생성됐습니다.")
		var health_label := game_instance.get_node(
			"UI/HUDMargin/Panel/Margin/Content/HealthRow/HealthLabel"
		) as Label
		var health_bar := game_instance.get_node(
			"UI/HUDMargin/Panel/Margin/Content/HealthRow/HealthBar"
		) as ProgressBar
		if "%" not in health_label.text or health_bar.custom_minimum_size.y < 26.0:
			return _fail("플레이어 체력 HUD의 수치 또는 가독성 스타일이 적용되지 않았습니다.")

		enemies[0].call(&"take_damage", 9999.0)
		progression.call(&"gain_experience", 5)

	if frame_count == 125:
		if int(game_instance.get("defeated_enemies")) < 1:
			return _fail("적 처치 이벤트가 Game에 전달되지 않았습니다.")
		if game_instance.get_node("World/Pickups").get_child_count() < 1:
			return _fail("경험치 픽업이 생성되지 않았습니다.")

		var progression = game_instance.get("progression_system")
		if int(progression.get("level")) < 2:
			return _fail("레벨 증가가 적용되지 않았습니다.")

		var player := get_first_node_in_group(&"player")
		player.call(&"take_damage", 9999.0)

	if frame_count == 130:
		var overlay := game_instance.get_node("UI/GameOverOverlay") as Control
		if not paused or not overlay.visible:
			return _fail("게임오버 상태가 적용되지 않았습니다.")

		paused = false
		print("SMOKE_TEST_OK run_setup tier_entry map minimap realistic_obstacles loot credits map_optional player health_ui enemies armor status_bars pathfinding weapon experience leveling extraction_f game_over")
		quit(0)
		return true

	return false


func _fail(message: String) -> bool:
	paused = false
	printerr("SMOKE_TEST_FAILED: %s" % message)
	quit(1)
	return true
