extends SceneTree
## Instrumented source soak, not release-binary or unassisted human acceptance.
const ACTIONS := [&"move_left", &"move_right", &"move_up", &"move_down", &"primary_attack"]
var isolation: RefCounted
var game: Node
var tier := "medium"
var duration := 600.0
var output_dir := ""
var failures := PackedStringArray()
var samples: Array[float] = []
var visits := {}
var corridor_frames := 0
var combat_frames := 0
var max_nodes := 0
var max_static_bytes := 0
var route := PackedVector2Array()
var destination := -1
var steering_at := 0.0
var skill_at := 0.0
var report_at := 0.0
var repath_at := 0.0
var last_position := Vector2.ZERO
var distance_moved := 0.0
var motion_checkpoint := Vector2.ZERO
var motion_at := 0.0
var capture_seconds := 0.0
var capture_count := 0
var capture_max_ms := 0.0
var capture_at := 0.0
var slow_frame_events: Array[Dictionary] = []
var driver_max_ms := 0.0

func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--tier="): tier = arg.trim_prefix("--tier=")
		if arg.begins_with("--seconds="): duration = float(arg.trim_prefix("--seconds="))
		if arg.begins_with("--output="): output_dir = arg.trim_prefix("--output=")
		if arg.begins_with("--capture-seconds="): capture_seconds = maxf(0.0, float(arg.trim_prefix("--capture-seconds=")))
	isolation = load("res://game/tests/support/save_test_isolation.gd").new()
	node_added.connect(isolation.isolate)
	_run.call_deferred()

func _run() -> void:
	if DisplayServer.get_name() == "headless" or not tier in ["medium", "large"] or duration < 5.0 or output_dir.is_empty():
		printerr("RENDERED_SOAK_FAILED renderer/tier/duration/output required")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(output_dir)
	root.size = Vector2i(1280, 720)
	root.title = "SFH QA · %s · instrumented soak" % tier
	var initial_nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	game = load("res://game/scenes/game.tscn").instantiate()
	game.features = game.features.duplicate(true)
	game.features.map_seed = 8675309
	root.add_child(game)
	for frame in 4: await process_frame
	game._cycle_hub_training()
	await process_frame
	if not game._finish_hub_training() or not game.start_run(tier):
		printerr("RENDERED_SOAK_FAILED training restore/launch")
		quit(1)
		return
	# Only survival is overridden. Damage, enemy AI, fog, drops and UI still execute.
	game.player.set_runtime_modifier_source(&"soak_fixture", {&"max_health": {&"add": 100000.0, &"multiply": 1.0}})
	last_position = game.player.global_position
	motion_checkpoint = last_position
	var start := Time.get_ticks_usec()
	var previous_frame := start
	var drawn_before := Engine.get_frames_drawn()
	while float(Time.get_ticks_usec() - start) / 1000000.0 < duration:
		await process_frame
		var now := Time.get_ticks_usec()
		var elapsed := float(now - start) / 1000000.0
		samples.append(float(now - previous_frame) / 1000.0)
		previous_frame = now
		if not game.run_started or not is_instance_valid(game.player):
			failures.append("session ended before wall-clock duration")
			break
		max_nodes = maxi(max_nodes, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
		max_static_bytes = maxi(max_static_bytes, int(Performance.get_monitor(Performance.MEMORY_STATIC)))
		var position: Vector2 = game.player.global_position
		distance_moved += position.distance_to(last_position)
		last_position = position
		var visibility: Dictionary = game.map_generator.get_visibility_region(position)
		if int(visibility.get(&"room_index", -1)) >= 0: visits[int(visibility.room_index)] = true
		else: corridor_frames += 1
		var encounter: Dictionary = game.room_encounter_system.get_snapshot()
		if samples.back() > 33.334 and slow_frame_events.size() < 16:
			slow_frame_events.append({"at_seconds": elapsed, "frame_ms": samples.back(), "cpu_process_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, "cpu_physics_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0, "room": visibility.get(&"room_index", -1), "enemies": encounter.get(&"active_enemy_count", 0), "nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT)})
		if int(encounter.get(&"active_enemy_count", 0)) > 0: combat_frames += 1
		if position.distance_to(motion_checkpoint) > 24.0:
			motion_checkpoint = position
			motion_at = elapsed
		elif elapsed - motion_at > 45.0 and int(encounter.get(&"active_enemy_count", 0)) == 0 and not bool(encounter.get(&"all_encounters_completed", false)):
			failures.append("navigation stalled: position=%s destination=%d waypoint=%s" % [position, destination, route[0] if not route.is_empty() else Vector2.INF])
			break
		if game.run_buff_selector.visible:
			_release_inputs()
			_tap(KEY_1)
		elif not paused:
			Input.action_press(&"primary_attack")
			if elapsed >= steering_at:
				_steer(position, elapsed)
				steering_at = elapsed + 0.016
			if elapsed >= skill_at:
				_tap(KEY_1)
				_tap(KEY_2)
				_tap(KEY_3)
				skill_at = elapsed + 5.0
		if elapsed >= report_at:
			print("RENDERED_SOAK_SAMPLE %s" % JSON.stringify({"wall_seconds": snappedf(elapsed, 0.1), "game_seconds": game.elapsed_time, "nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT), "static_bytes": Performance.get_monitor(Performance.MEMORY_STATIC), "rooms": visits.size(), "combat_frames": combat_frames, "distance": distance_moved}))
			report_at = elapsed + 60.0
		if capture_seconds > 0.0 and elapsed >= capture_at:
			capture_at = elapsed + capture_seconds
			await RenderingServer.frame_post_draw
			var capture_start := Time.get_ticks_usec()
			root.get_texture().get_image().save_png(output_dir.path_join("%s-latest.png" % tier))
			capture_count += 1
			capture_max_ms = maxf(capture_max_ms, float(Time.get_ticks_usec() - capture_start) / 1000.0)
		driver_max_ms = maxf(driver_max_ms, float(Time.get_ticks_usec() - now) / 1000.0)
	_release_inputs()
	var actual_seconds := float(Time.get_ticks_usec() - start) / 1000000.0
	var frames_drawn := Engine.get_frames_drawn() - drawn_before
	var sum := 0.0
	var slow_frames := 0
	for value in samples:
		sum += value
		if value > 33.334: slow_frames += 1
	samples.sort()
	var report := {
		"tier": tier, "seed": 8675309, "wall_seconds": actual_seconds, "game_seconds": game.elapsed_time,
		"display_server": DisplayServer.get_name(), "gpu": RenderingServer.get_video_adapter_name(),
		"rendering_method": RenderingServer.get_current_rendering_method(), "frames_drawn": frames_drawn,
		"frames_over_33_ms": slow_frames, "capture_count": capture_count, "capture_max_ms": capture_max_ms,
		"slow_frame_events_first_16": slow_frame_events, "driver_max_ms": driver_max_ms,
		"average_frame_ms": sum / maxi(1, samples.size()), "p95_frame_ms": samples[int(samples.size() * 0.95)], "peak_frame_ms": samples.back(),
		"max_nodes": max_nodes, "max_static_bytes": max_static_bytes, "visited_rooms": visits.size(),
		"corridor_frames": corridor_frames, "combat_frames": combat_frames, "distance_moved": distance_moved,
		"projectiles_fired": game.auto_weapon.get_runtime_snapshot().get(&"total_projectiles_fired", 0),
		"encounters": game.room_encounter_system.get_snapshot(),
		"remaining_spawn_budget": game.enemy_spawner.get_remaining_spawn_budget(),
		"fixture": "scripted_navigation high_player_hp synthetic_godot_input no_time_scale no_position_override isolated_save",
		"human_acceptance": false, "web_parity": false, "long_memory_leak_certified": false,
	}
	if frames_drawn < 30 or distance_moved < 100.0: failures.append("render/movement evidence absent")
	if duration >= 600.0 and (visits.size() < 3 or corridor_frames == 0 or combat_frames < 600): failures.append("insufficient traversal/combat coverage")
	if Engine.time_scale != 1.0: failures.append("time scale changed")
	game.queue_free()
	for frame in 5: await process_frame
	report["remaining_nodes_delta"] = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)) - initial_nodes
	if int(report.remaining_nodes_delta) > 0: failures.append("nodes remained after teardown")
	report["failures"] = failures
	var file := FileAccess.open(output_dir.path_join("%s-result.json" % tier), FileAccess.WRITE)
	if file == null:
		printerr("RENDERED_SOAK_FAILED result write")
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("RENDERED_SOAK_RESULT %s" % JSON.stringify(report))
	print("RENDERED_SOAK_OK" if failures.is_empty() else "RENDERED_SOAK_FAILED")
	quit(0 if failures.is_empty() else 1)

func _steer(position: Vector2, elapsed: float) -> void:
	var rooms: Array = game.map_generator.get_room_encounter_snapshot()
	if destination < 0 or position.distance_to(rooms[destination].center) < 48.0:
		var nearest := INF
		for room: Dictionary in rooms:
			if room.is_start_room or room.is_extraction_room or game.room_encounter_system.is_room_completed(room.room_index): continue
			var distance: float = position.distance_to(room.center)
			if distance < nearest:
				nearest = distance
				destination = int(room.room_index)
		repath_at = 0.0
	# Blink/hit reactions can move past an old waypoint. Replan from the real position.
	if destination >= 0 and elapsed >= repath_at:
		route = game.map_generator.get_world_path(position, rooms[destination].center)
		repath_at = elapsed + 0.5
	# Player radius 18 exceeds the 17.5px wall-cell center clearance: allow safe-margin tolerance.
	while not route.is_empty() and position.distance_to(route[0]) < 2.0: route.remove_at(0)
	var direction := Vector2.ZERO if route.is_empty() else position.direction_to(route[0])
	var desired_strength := 0.0 if route.is_empty() else clampf(position.distance_to(route[0]) / 32.0, 0.025, 1.0)
	var deadzone := InputMap.action_get_deadzone(&"move_right")
	var strength := lerpf(deadzone, 1.0, desired_strength)
	for action in ACTIONS:
		if action != &"primary_attack": Input.action_release(action)
	if absf(direction.x) > 0.01: Input.action_press(&"move_right" if direction.x > 0.0 else &"move_left", absf(direction.x) * strength)
	if absf(direction.y) > 0.01: Input.action_press(&"move_down" if direction.y > 0.0 else &"move_up", absf(direction.y) * strength)

func _tap(key: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = true
	Input.parse_input_event(event)
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)

func _release_inputs() -> void:
	for action in ACTIONS: Input.action_release(action)
