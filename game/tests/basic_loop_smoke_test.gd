extends SceneTree

const GAME_SCENE_PATH := "res://game/scenes/game.tscn"

var game_instance: Node
var frame_count: int = 0


func _init() -> void:
	var game_scene := load(GAME_SCENE_PATH) as PackedScene
	if game_scene == null:
		_fail("Game Scene을 불러오지 못했습니다.")
		return

	game_instance = game_scene.instantiate()
	root.add_child(game_instance)


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
		if progression == null or weapon == null:
			return _fail("전투 또는 성장 모듈이 설치되지 않았습니다.")

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
		print("SMOKE_TEST_OK player enemies weapon experience leveling game_over")
		quit(0)
		return true

	return false


func _fail(message: String) -> bool:
	paused = false
	printerr("SMOKE_TEST_FAILED: %s" % message)
	quit(1)
	return true
