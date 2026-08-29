extends SceneTree

const GAME_SCENE_PATH := "res://game/scenes/game.tscn"
const MAP_GENERATOR_SCENE_PATH := "res://game/features/map_generation/map_generator.tscn"
const MAP_CONFIG_PATH_PATTERN := "res://game/features/map_generation/configs/%s.tres"
const MAP_TIER_IDS := ["small", "medium", "large"]

var game_instance: Node
var frame_count: int = 0


func _init() -> void:
	if not _verify_map_tiers():
		return

	var game_scene := load(GAME_SCENE_PATH) as PackedScene
	if game_scene == null:
		_fail("Game Scene을 불러오지 못했습니다.")
		return
	if not await _verify_optional_map_module(game_scene):
		return

	game_instance = game_scene.instantiate()
	root.add_child(game_instance)


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

		root.remove_child(generator)
		generator.free()

	return true


func _verify_optional_map_module(game_scene: PackedScene) -> bool:
	var fallback_game := game_scene.instantiate()
	var fallback_features = fallback_game.get("features").duplicate(true)
	fallback_features.set("map_generation_enabled", false)
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

	root.remove_child(fallback_game)
	fallback_game.free()

	if not failure_message.is_empty():
		_fail("맵 모듈 비활성화 실패: %s" % failure_message)
		return false

	return true


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
		if progression == null or weapon == null or map_generator == null:
			return _fail("맵, 전투 또는 성장 모듈이 설치되지 않았습니다.")
		if map_generator.get("rooms").size() < 5:
			return _fail("소형 맵의 최소 방 수를 생성하지 못했습니다.")
		if not map_generator.call(&"is_walkable_world_position", player.global_position):
			return _fail("플레이어가 걸을 수 없는 위치에 생성됐습니다.")

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
		print("SMOKE_TEST_OK map map_optional player enemies pathfinding weapon experience leveling game_over")
		quit(0)
		return true

	return false


func _fail(message: String) -> bool:
	paused = false
	printerr("SMOKE_TEST_FAILED: %s" % message)
	quit(1)
	return true
