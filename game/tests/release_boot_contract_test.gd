extends SceneTree
## Run against the exported PCK, not just the editor's source resource cache.
const GAME = preload("res://game/scenes/game.tscn")
const SOCKETS = preload("res://game/features/session_sockets/configs/default_session_sockets.tres")
var isolation: RefCounted
var failures := PackedStringArray()


func _init() -> void:
	isolation = preload("res://game/tests/support/save_test_isolation.gd").new()
	node_added.connect(isolation.isolate)
	_run.call_deferred()


func _run() -> void:
	var raw_tables := 0
	for feature in DirAccess.get_directories_at("res://game/features"):
		var data_path := "res://game/features/%s/data" % feature
		if not DirAccess.dir_exists_absolute(data_path): continue
		for file_name in DirAccess.get_files_at(data_path):
			if not file_name.ends_with(".csv"): continue
			var file := FileAccess.open(data_path.path_join(file_name), FileAccess.READ)
			_check(file != null and not file.get_as_text().is_empty(), "raw CSV survives export: " + file_name)
			raw_tables += 1
	_check(raw_tables >= 18, "all gameplay CSV tables survive export")
	print("RELEASE_RAW_CSV_OK ", raw_tables)
	var workshop: Resource = load("res://game/features/p5_hub_progression/configs/default_workshop_roll_policy.tres").duplicate(true)
	_check(workshop.get_supply_policy() is EquipmentSupplyPolicy, "exported workshop retains explicit supply policy")
	if workshop.get_supply_policy() is EquipmentSupplyPolicy:
		_check(workshop.get_supply_policy().is_valid(), "exported supply policy valid")
		_check(workshop.describe({&"result_id": &"release_probe", &"minimum_sockets": 0, &"maximum_sockets": 1}).get(&"minimum_sockets") == 1,
			"exported crafting applies hub socket floor")
	var config: Resource = SOCKETS.duplicate(true)
	_check(config.binding_policy != null, "exported duplicate retains binding policy")
	_check(config.validation_errors().is_empty(), "exported socket config is valid")
	var game = GAME.instantiate()
	root.add_child(game)
	for frame in 6: await process_frame
	_check(not game.initialization_recovery_active, "no initialization recovery")
	_check(is_instance_valid(game.start_hub), "default boot opens hub")
	_check(is_instance_valid(game.player), "hub has controllable player")
	_check(not game.run_started, "boot does not bypass hub")
	var original_hint: String = game.hub_control_hint_label.text
	game.hub_control_hint_label.text = "초기 저장 상태 확인 중 ".repeat(50)
	for frame in 3: await process_frame
	game.hub_control_hint_label.text = original_hint
	for frame in 4: await process_frame
	_check(game.start_hub_hud.size.y <= 180.0, "hub contracts after temporary wrapped status")
	if failures.is_empty():
		_check(game.start_run(&"medium"), "exported medium raid starts")
		for frame in 6: await process_frame
		_check(game.run_started, "raid remains active after physics")
		_check(not game.initialization_recovery_active, "no raid recovery")
		game.status_label.text = "raid objective"
		game._on_enemy_training_damage(5.0, 0.0, Vector2.ZERO, {})
		_check(game.status_label.text == "raid objective", "raid damage cannot display training status")
		var camera: Camera2D = game.player.get_node("Camera2D")
		var screen_position: Vector2 = game.player.get_global_transform_with_canvas().origin
		print("RELEASE_VIEW ", {"player": game.player.global_position, "screen": screen_position,
			"camera_current": camera.is_current(), "camera_center": camera.get_screen_center_position(),
			"visible": game.player.is_visible_in_tree(), "fog": game.fog_of_war.get_snapshot()})
		_check(camera.is_current(), "raid camera is current")
		_check(camera.process_callback == Camera2D.CAMERA2D_PROCESS_PHYSICS,
			"camera smoothing does not depend on slow render frame delta")
		if DisplayServer.get_name() != "headless":
			await create_timer(1.0).timeout
			_check(Rect2(Vector2.ZERO, root.get_visible_rect().size).has_point(
				game.player.get_global_transform_with_canvas().origin), "player projects inside viewport")
			await RenderingServer.frame_post_draw
			var frame := root.get_texture().get_image()
			var projected: Vector2 = game.player.get_global_transform_with_canvas().origin
			var cyan_pixels := 0
			for x in range(maxi(0, int(projected.x) - 12), mini(frame.get_width(), int(projected.x) + 12)):
				for y in range(maxi(0, int(projected.y) - 12), mini(frame.get_height(), int(projected.y) + 12)):
					var pixel := frame.get_pixel(x, y)
					if pixel.r < 0.5 and pixel.g > 0.5 and pixel.b > 0.5: cyan_pixels += 1
			_check(cyan_pixels >= 40, "rendered player is not hidden by fog")
			print("RELEASE_PIXELS cyan=", cyan_pixels, " screen=", projected)
	game.queue_free()
	for frame in 3: await process_frame
	if failures.is_empty():
		print("RELEASE_BOOT_OK serialized_policy duplicate hub player medium_raid")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
