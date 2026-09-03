extends SceneTree
var save_test_isolation: RefCounted

const GAME_SCENE_PATH := "res://game/scenes/game.tscn"
const WARMUP_FRAMES := 90
const SAMPLE_FRAMES := 240
const TARGET_FRAME_MS := 16.667
const MAXIMUM_PEAK_FRAME_MS := 33.334
const MAXIMUM_NODE_BUDGET := 6000
const MAXIMUM_ELECTRIC_EFFECTS := 3
const MINIMUM_LARGE_ROOM_HORDE := 24


func _init() -> void:
	save_test_isolation = preload("res://game/tests/support/save_test_isolation.gd").new()
	node_added.connect(save_test_isolation.isolate)
	_run.call_deferred()


func _run() -> void:
	var game_scene := load(GAME_SCENE_PATH) as PackedScene
	if game_scene == null:
		_fail("Game Scene을 불러오지 못했습니다.")
		return
	var game := game_scene.instantiate()
	var features = game.get("features").duplicate(true)
	features.set("run_setup_enabled", false)
	features.set("start_hub_enabled", false)
	features.set("map_size", "large")
	features.set("map_seed", 8675309)
	game.set("features", features)
	root.add_child(game)
	await process_frame
	if not bool(game.get("run_started")):
		_fail("대형 성능 검증 작전을 시작하지 못했습니다.")
		return
	var configured_spawner = game.get("enemy_spawner")
	var room_encounters = game.get("room_encounter_system")
	var generated_map = game.get("map_generator")
	if room_encounters != null and generated_map != null:
		var maximum_room_values: Dictionary = room_encounters.get("tier_values").duplicate(true)
		maximum_room_values[&"minimum_enemies"] = maximum_room_values[&"maximum_enemies"]
		room_encounters.set("tier_values", maximum_room_values)
		for room: Dictionary in generated_map.call(&"get_room_encounter_snapshot"):
			if not bool(room[&"is_start_room"]) and not bool(room[&"is_extraction_room"]):
				room_encounters.call(&"try_start_room", int(room[&"room_index"]))
				break
	for _frame in WARMUP_FRAMES:
		await process_frame

	var wall_frame_total_ms := 0.0
	var wall_frame_peak_ms := 0.0
	var maximum_nodes := 0
	var maximum_electric_effects := 0
	var skill_system = game.get("combat_skill_system")
	if skill_system != null:
		skill_system.call(&"advance", 120.0)
		for slot_index in 3:
			skill_system.call(&"try_activate", slot_index)
	for frame_index in SAMPLE_FRAMES:
		var frame_started_usec := Time.get_ticks_usec()
		await process_frame
		var wall_frame_ms := float(Time.get_ticks_usec() - frame_started_usec) / 1000.0
		wall_frame_total_ms += wall_frame_ms
		wall_frame_peak_ms = maxf(wall_frame_peak_ms, wall_frame_ms)
		maximum_nodes = maxi(
			maximum_nodes,
			int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
		)
		maximum_electric_effects = maxi(
			maximum_electric_effects,
			get_node_count_in_group(&"combat_skill_electric_effect")
		)

	var average_wall_frame_ms := wall_frame_total_ms / float(SAMPLE_FRAMES)
	var spawner = game.get("enemy_spawner")
	var spawner_snapshot: Dictionary = spawner.call(&"get_snapshot") if spawner != null else {}
	var map_generator = game.get("map_generator")
	var map_performance: Dictionary = (
		map_generator.call(&"get_performance_snapshot") if map_generator != null else {}
	)
	var result := {
		&"renderer": "gl_compatibility",
		&"viewport": "1280x720",
		&"map_tier": "large",
		&"sample_frames": SAMPLE_FRAMES,
		&"target_frame_ms": TARGET_FRAME_MS,
		&"maximum_peak_frame_ms": MAXIMUM_PEAK_FRAME_MS,
		&"average_wall_frame_ms": snappedf(average_wall_frame_ms, 0.001),
		&"peak_wall_frame_ms": snappedf(wall_frame_peak_ms, 0.001),
		&"reported_process_ms": snappedf(
			Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, 0.001
		),
		&"reported_physics_ms": snappedf(
			Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0, 0.001
		),
		&"maximum_nodes": maximum_nodes,
		&"maximum_electric_effects": maximum_electric_effects,
		&"collision_shapes": int(map_performance.get(&"collision_shape_count", 0)),
		&"collision_compression_ratio": snappedf(
			float(map_performance.get(&"collision_compression_ratio", 1.0)), 0.001
		),
		&"active_enemy_target": int(spawner_snapshot.get(&"target_active_enemies", 0)),
		&"maximum_total_spawns": int(spawner_snapshot.get(&"maximum_total_spawns", 0)),
		&"active_room_enemies": int(
			room_encounters.call(&"get_snapshot").get(&"active_enemy_count", 0)
			if room_encounters != null else 0
		),
	}
	print("PERFORMANCE_BUDGET_RESULT %s" % JSON.stringify(result))
	if average_wall_frame_ms > TARGET_FRAME_MS:
		_fail("평균 헤드리스 프레임 시간이 60 FPS 예산을 초과했습니다.")
		return
	if wall_frame_peak_ms > MAXIMUM_PEAK_FRAME_MS:
		_fail("최대 헤드리스 프레임 시간이 30 FPS 하한 예산을 초과했습니다.")
		return
	if maximum_nodes > MAXIMUM_NODE_BUDGET:
		_fail("대형 작전 Node 수가 예산을 초과했습니다.")
		return
	if maximum_electric_effects > MAXIMUM_ELECTRIC_EFFECTS:
		_fail("동시 전기 이펙트 수가 예산을 초과했습니다.")
		return
	if int(result[&"active_room_enemies"]) < MINIMUM_LARGE_ROOM_HORDE:
		_fail("대형 방 핵앤슬래시 최소 무리 수를 성능 시나리오가 충족하지 못했습니다.")
		return
	if float(map_performance.get(&"collision_compression_ratio", 1.0)) > 0.25:
		_fail("맵 충돌 병합률이 25% 예산을 초과했습니다.")
		return
	root.remove_child(game)
	game.free()
	print("PERFORMANCE_BUDGET_OK large_raid_60fps_cpu_budget node_budget electric_effect_budget")
	quit(0)


func _fail(message: String) -> void:
	printerr("PERFORMANCE_BUDGET_FAILED: %s" % message)
	quit(1)
