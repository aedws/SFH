extends SceneTree

var failures := PackedStringArray()

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var fog = load("res://game/features/fog_of_war/fog_of_war.gd").new()
	var rect := Rect2(-130.0, 70.0, 640.0, 480.0)
	for index in 144:
		var transform := Transform2D(float(index) * 0.13, Vector2(0.7 + index % 3, -1.2), 0.2, Vector2(100.0, -60.0))
		var corners := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
		var expected := Rect2(transform * corners[0], Vector2.ZERO)
		for corner in corners: expected = expected.expand(transform * corner)
		var actual: Rect2 = fog._world_rect_to_screen(rect, transform)
		_check(actual.position.distance_to(expected.position) < 0.002 and actual.size.distance_to(expected.size) < 0.002, "affine fog bounds %d" % index)
	fog.free()
	var player = load("res://game/features/player/player.tscn").instantiate()
	root.add_child(player)
	player.set_physics_process(false)
	var feedback = player.get_node("MovementFeedback")
	feedback.set_physics_process(false)
	var camera: Camera2D = player.get_node("Camera2D")
	var director = load("res://game/features/hit_feedback/hit_feedback_director.gd").new()
	root.add_child(director)
	var profile = load("res://game/features/hit_feedback/configs/default_hit_feedback.tres").duplicate()
	_check(director.configure(camera, profile) and not director.is_processing(), "idle hit director sleeps")
	_check(director.register_actor(player), "damage signal contract")
	var health_before: float = player.current_health
	player.take_damage(1.0, {&"impact_direction": Vector2.RIGHT})
	_check(is_equal_approx(player.current_health, health_before - 1.0), "feedback preserves damage")
	_check(director.is_processing() and director.total_hits == 1, "hit wakes director")
	director._process(1.0 / 60.0)
	_check(camera.offset.length() >= 1.0, "single hit readable kick")
	for index in 100:
		director._on_actor_damaged(10.0, 0.0, Vector2.ZERO, {&"lethal": true, &"impact_direction": Vector2.RIGHT}, player)
	director._process(1.0 / 60.0)
	_check(director.impacts.size() == profile.maximum_active_impacts, "impact cap")
	_check(camera.offset.length() <= profile.maximum_camera_offset + 0.001, "horde camera cap")
	_check(bool(director.impacts.back().get(&"lethal", false)), "kill ring metadata")
	for frame in 120: director._process(1.0 / 60.0)
	_check(not director.is_processing() and camera.offset.is_zero_approx(), "effect drains to idle")
	profile.maximum_camera_offset = 0.0
	director._on_actor_damaged(10.0, 0.0, Vector2.ZERO, {}, player)
	director._process(1.0 / 60.0)
	_check(camera.offset.is_zero_approx(), "zero camera setting honored")
	for index in 14:
		feedback.advance_feedback(Vector2(658.0, 0.0), 280.0, 1.0 / 60.0, true, Vector2(index * 11.0, 0.0))
	_check(feedback.trail_points.size() <= feedback.maximum_trail_points, "trail bounded")
	_check(feedback.get_feedback_snapshot().camera_lead_pixels > 30.0, "dash camera response")
	feedback.advance_feedback(Vector2(658.0, 0.0), 280.0, 1.0 / 60.0, true, Vector2(1500.0, 0.0))
	_check(feedback.trail_points.size() == 1 and not feedback.trail.visible, "warp has no cross-room trail")
	feedback.set_feedback_enabled(false)
	_check(feedback.trail_points.is_empty() and feedback.visual_intensity == 0.0 and camera.position.is_zero_approx(), "feedback reset")
	_check(is_equal_approx(player.movement.speed, 280.0) and Engine.time_scale == 1.0, "speed and global clock unchanged")
	director.queue_free()
	player.queue_free()
	await process_frame
	for failure in failures: printerr(failure)
	print("FRAME_FEEDBACK_OK fog_affine_144 idle_wake hit_kick kill_ring horde_cap zero_camera warp_trail reset damage_speed_clock_unchanged" if failures.is_empty() else "FRAME_FEEDBACK_FAILED")
	quit(0 if failures.is_empty() else 1)

func _check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
