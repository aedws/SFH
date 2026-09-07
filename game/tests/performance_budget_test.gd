extends SceneTree
var save_test_isolation: RefCounted
var failures := PackedStringArray()
const WARMUP_FRAMES := 90
const SAMPLE_FRAMES := 240
const TARGET_FRAME_MS := 16.667
const MAXIMUM_PEAK_FRAME_MS := 33.334
const MAXIMUM_NODE_BUDGET := 6000
const MAXIMUM_ELECTRIC_EFFECTS := 3

func _init() -> void:
	save_test_isolation = preload("res://game/tests/support/save_test_isolation.gd").new()
	node_added.connect(save_test_isolation.isolate)
	_run.call_deferred()

func _run() -> void:
	for tier in ["medium", "large"]:
		for seed_value in [8675309, 4040600]:
			await _run_case(tier, seed_value)
	if failures.is_empty():
		print("PERFORMANCE_BUDGET_OK medium_large_cases_4 headless_cpu_only p95 node_budget electric_effect_budget teardown attack_input")
		quit(0)
	else:
		for failure in failures: printerr("PERFORMANCE_BUDGET_FAILED: " + failure)
		quit(1)

func _run_case(tier: String, seed_value: int) -> void:
	var nodes_before := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var game = load("res://game/scenes/game.tscn").instantiate()
	game.features = game.features.duplicate(true)
	game.features.run_setup_enabled = false
	game.features.start_hub_enabled = false
	game.features.map_size = tier
	game.features.map_seed = seed_value
	var started := Time.get_ticks_usec()
	root.add_child(game)
	await process_frame
	var launch_ms := float(Time.get_ticks_usec() - started) / 1000.0
	if not game.run_started:
		failures.append("작전 진입 실패 %s/%d" % [tier, seed_value])
		game.queue_free()
		await process_frame
		return
	# Keep damage and hit feedback enabled; only prevent fixture death ending samples.
	game.player.set_runtime_modifier_source(&"performance_fixture", {&"max_health": {&"add": 100000.0, &"multiply": 1.0}})
	var encounters: Node = game.room_encounter_system
	var tier_values: Dictionary = encounters.tier_values.duplicate(true)
	tier_values[&"minimum_enemies"] = tier_values[&"maximum_enemies"]
	encounters.tier_values = tier_values
	for room: Dictionary in game.map_generator.get_room_encounter_snapshot():
		if not room.is_start_room and not room.is_extraction_room:
			game.player.global_position = room.center
			encounters.try_start_room(room.room_index)
			break
	var initial_enemies := int(encounters.get_snapshot().get(&"active_enemy_count", 0))
	for frame in WARMUP_FRAMES: await process_frame
	game.combat_skill_system.advance(120.0)
	for index in 3: game.combat_skill_system.try_activate(index)
	Input.action_press(&"primary_attack")
	var samples: Array[float] = []
	var maximum_nodes := 0
	var maximum_effects := 0
	for frame in SAMPLE_FRAMES:
		var frame_started := Time.get_ticks_usec()
		await process_frame
		samples.append(float(Time.get_ticks_usec() - frame_started) / 1000.0)
		maximum_nodes = maxi(maximum_nodes, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
		maximum_effects = maxi(maximum_effects, get_node_count_in_group(&"combat_skill_electric_effect"))
	Input.action_release(&"primary_attack")
	var average := 0.0
	for sample in samples: average += sample
	average /= SAMPLE_FRAMES
	samples.sort()
	var p95 := samples[int(ceil(SAMPLE_FRAMES * 0.95)) - 1]
	var peak: float = samples.back()
	var map_perf: Dictionary = game.map_generator.get_performance_snapshot()
	var result := {
		&"display_server": DisplayServer.get_name(), &"gpu_fps_verified": false,
		&"viewport": root.get_visible_rect().size, &"map_tier": tier, &"seed": seed_value,
		&"sample_frames": SAMPLE_FRAMES, &"fixture": "maximum_room_horde high_player_hp real_attack_and_skills",
		&"launch_ms": snappedf(launch_ms, 0.001),
		&"average_wall_frame_ms": snappedf(average, 0.001), &"p95_wall_frame_ms": snappedf(p95, 0.001),
		&"peak_wall_frame_ms": snappedf(peak, 0.001), &"maximum_nodes": maximum_nodes,
		&"maximum_electric_effects": maximum_effects, &"initial_room_enemies": initial_enemies,
		&"projectiles_fired": game.auto_weapon.get_runtime_snapshot().get(&"total_projectiles_fired", 0),
		&"collision_shapes": map_perf.get(&"collision_shape_count", 0),
		&"collision_compression_ratio": map_perf.get(&"collision_compression_ratio", 1.0),
	}
	_check(average <= TARGET_FRAME_MS and p95 <= TARGET_FRAME_MS, "평균/p95 CPU 예산", tier, seed_value)
	_check(peak <= MAXIMUM_PEAK_FRAME_MS, "최대 CPU 예산", tier, seed_value)
	_check(maximum_nodes <= MAXIMUM_NODE_BUDGET, "Node 예산", tier, seed_value)
	_check(maximum_effects <= MAXIMUM_ELECTRIC_EFFECTS, "전기 효과 예산", tier, seed_value)
	_check(int(result.projectiles_fired) > 0, "실제 공격 발사 부하", tier, seed_value)
	_check(initial_enemies >= (24 if tier == "large" else 18), "최소 무리 부하", tier, seed_value)
	_check(float(map_perf.get(&"collision_compression_ratio", 1.0)) <= 0.25, "맵 충돌 병합", tier, seed_value)
	game.queue_free()
	for frame in 4: await process_frame
	result[&"remaining_nodes_delta"] = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)) - nodes_before
	_check(int(result.remaining_nodes_delta) <= 0, "세션 종료 Node 잔류", tier, seed_value)
	print("PERFORMANCE_BUDGET_RESULT %s" % JSON.stringify(result))

func _check(condition: bool, message: String, tier: String, seed_value: int) -> void:
	if not condition: failures.append("%s · %s/%d" % [message, tier, seed_value])
