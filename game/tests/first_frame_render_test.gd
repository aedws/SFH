extends SceneTree
## Real renderer timing. Never equate CPU submission/frame wall time with GPU timestamp duration.
var isolation: RefCounted
var tier := "medium"
var disable_fog := false
var force_tiles := false

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--tier="): tier = arg.trim_prefix("--tier=")
		if arg == "--without-fog": disable_fog = true
		if arg == "--flush-tiles": force_tiles = true
	isolation = load("res://game/tests/support/save_test_isolation.gd").new()
	node_added.connect(isolation.isolate)
	_run.call_deferred()

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.title = "SFH isolated first-frame timing"
	var game = load("res://game/scenes/game.tscn").instantiate()
	game.features = game.features.duplicate(true)
	game.features.map_seed = 8675309
	if disable_fog: game.features.fog_of_war_enabled = false
	root.add_child(game)
	for frame in 12: await process_frame
	var began := Time.get_ticks_usec()
	if not game.start_run(tier):
		push_error("FIRST_FRAME_FAILED launch: %s run_started=%s recovery=%s" % [game.status_label.text, game.run_started, game.initialization_recovery_active])
		quit(1)
		return
	var assembly_ms := (Time.get_ticks_usec() - began) / 1000.0
	var flush_ms := 0.0
	if force_tiles and game.map_generator.floor_layer.has_method(&"update_internals"):
		var flush_begin := Time.get_ticks_usec()
		game.map_generator.floor_layer.update_internals()
		flush_ms = (Time.get_ticks_usec() - flush_begin) / 1000.0
	var samples: Array[float] = []
	var previous := Time.get_ticks_usec()
	for frame in 30:
		if DisplayServer.get_name() == "headless": await process_frame
		else: await RenderingServer.frame_post_draw
		var now := Time.get_ticks_usec()
		samples.append((now - previous) / 1000.0)
		previous = now
	print("FIRST_FRAME_RESULT ", JSON.stringify({"tier":tier,"gpu":RenderingServer.get_video_adapter_name(), "renderer":DisplayServer.get_name(), "without_fog":disable_fog, "assembly_ms":assembly_ms,"tile_flush_ms":flush_ms,"post_draw_intervals_ms":samples,"floor":game.map_generator.floor_layer.get_snapshot()}))
	game.free()
	paused = false
	for frame in 3: await process_frame
	print("FIRST_FRAME_OK")
	quit()
