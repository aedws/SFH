extends SceneTree

var isolation := preload("res://game/tests/support/save_test_isolation.gd").new()
var failures: Array[String] = []
var game: Node
var selection_path: String
var mobile_completed := false

func _init() -> void:
	node_added.connect(isolation.isolate)
	call_deferred(&"_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(isolation.root_path)
	selection_path = isolation.root_path.path_join("mode.json")
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(1280, 720)
	_check(ProjectSettings.get_setting("application/run/main_scene") == "res://game/scenes/application.tscn", "shipped optional entry assembly")
	for mode in [&"off", &"on"]:
		var entry: Control = load("res://game/features/mobile_controls/control_mode_entry.tscn").instantiate()
		entry.launch_game = false
		entry.settings_path = selection_path
		root.add_child(entry)
		await _frames(4)
		_check(entry.pc_button.is_visible_in_tree() and entry.mobile_button.is_visible_in_tree(), "entry has two choices")
		await _click(entry.pc_button if mode == &"off" else entry.mobile_button)
		_check(entry.choosing, "actual click selected %s" % mode)
		entry.queue_free()
		await _frames(2)
		game = load("res://game/scenes/game.tscn").instantiate()
		game.features = game.features.duplicate(true)
		game.features.presentation_settings_storage_path = selection_path
		root.add_child(game)
		await _frames(8)
		_check(game.start_hub != null and not game.run_started and not paused, "%s enters moving lobby, not briefing" % mode)
		_check(game.mobile_control_pad.visible == (mode == &"on"), "persisted mode reaches Game %s" % mode)
		if mode == &"on":
			await _mobile_play()
			_check(mobile_completed, "mobile play contract reached its final assertion")
		game.queue_free()
		await _frames(3)
		paused = false
	root.content_scale_size = Vector2i.ZERO
	# Missing optional mobile module still builds the same keyboard lobby.
	game = load("res://game/scenes/game.tscn").instantiate()
	game.features = game.features.duplicate(true)
	game.features.mobile_controls_enabled = false
	root.add_child(game)
	await _frames(4)
	_check(game.mobile_control_pad == null and game.start_hub != null and not paused, "module off retains lobby")
	game.queue_free()
	await _frames(2)
	for error in failures: push_error(error)
	if failures.is_empty():
		print("MOBILE_CONTROL_ENTRY_OK pc_mobile_saved hub_gate_preserved joystick_multitouch attack_skill_menu_events pause_focus_release orientation_4 hud_reserved_regions module_off")
	quit(0 if failures.is_empty() else 1)

func _mobile_play() -> void:
	var pad: Control = game.mobile_control_pad
	for dimensions in [Vector2i(844, 390), Vector2i(390, 844), Vector2i(1280, 720), Vector2i(640, 360)]:
		root.size = dimensions
		await _frames(8)
		var bounds := root.get_visible_rect().grow(1)
		var state: Dictionary = pad.get_snapshot()
		_check(bounds.encloses(state.movement_rect) and bounds.encloses(state.combat_rect) and bounds.encloses(state.menu_rect), "pad bounds %s: %s" % [dimensions, state])
		_check(not state.movement_rect.intersects(state.combat_rect), "two hand areas disjoint %s" % dimensions)
		for button: Button in pad.action_buttons.values():
			if button.visible: _check(button.size.x >= 44 and button.size.y >= 44, "touch target >=44")
	root.size = Vector2i(844, 390)
	await _frames(6)
	var center: Vector2 = pad.joystick.get_global_rect().get_center()
	var before: Vector2 = game.player.global_position
	_touch(3, center + Vector2(50, 0), true)
	_check(not Input.is_action_pressed(&"primary_attack"), "joystick touch is not emulated mouse attack")
	_touch(4, pad.action_buttons[&"primary_attack"].get_global_rect().get_center(), true)
	_check(Input.is_action_pressed(&"move_right") and Input.is_action_pressed(&"primary_attack"), "two simultaneous finger actions")
	for _i in 12: await physics_frame
	_check(game.player.global_position.x > before.x + 5, "joystick moves actual player")
	var drag := InputEventScreenDrag.new()
	drag.index = 3
	drag.position = center + Vector2(-50, -50)
	root.push_input(drag, true)
	_check(Input.is_action_pressed(&"move_left") and Input.is_action_pressed(&"move_up"), "diagonal and turn")
	_touch(3, Vector2(-100, -100), false)
	_check(not Input.is_action_pressed(&"move_left") and Input.is_action_pressed(&"primary_attack"), "outside release only releases owning finger")
	_touch(4, Vector2(-100, -100), false)
	# Actual touch to action-event menus; no direct panel method used for opening.
	for pair in [[&"toggle_inventory", "inventory_window"], [&"toggle_key_mapping", "key_mapping_panel"]]:
		await _frames(2)
		_touch(6, pad.action_buttons[pair[0]].get_global_rect().get_center(), true)
		await _frames(3)
		var panel: Control = game.get(pair[1])
		_check(panel.visible and paused and not pad.visible, "touch opens %s and hides gameplay pad" % pair[0])
		_check(pad.pressed_actions.is_empty() and Input.emulate_mouse_from_touch, "modal releases touches and enables GUI touch")
		panel.call(&"close_panel")
		await _frames(3)
		_check(pad.visible and not paused, "modal returns mobile controls")
	# Use world interaction at the configured gate, then cancel and verify movement lobby.
	game.player.global_position = game.start_hub.to_global(game.start_hub.get_operation_position())
	for _i in 4: await physics_frame
	_touch(7, pad.action_buttons[&"interact"].get_global_rect().get_center(), true)
	await _frames(4)
	_check(game.run_setup_overlay.visible and paused, "mobile F opens actual lobby gate")
	game.call(&"_close_run_setup")
	await _frames(3)
	_check(game.start_hub != null and not paused, "briefing cancel restores lobby")
	_check(game.start_run("small"), "mobile selected gear launches combat")
	game.operation_tutorial_overlay.dismiss()
	await _frames(8)
	for dimensions in [Vector2i(844, 390), Vector2i(390, 844)]:
		root.size = dimensions
		await _frames(8)
		var snapshot: Dictionary = game.combat_hud_presenter.get_snapshot(game.hud_margin)
		_check(snapshot.layout_mode == &"mobile_touch" and not game.combat_skill_hud.visible and not game.dash_cooldown_hud.visible, "mobile removes duplicate PC HUD")
		for rect: Rect2 in [snapshot.core_rect, snapshot.telemetry_rect, snapshot.mission_rect]:
			_check(not rect.intersects(pad.movement_group.get_global_rect()) and not rect.intersects(pad.combat_group.get_global_rect()), "HUD clears both hands %s" % dimensions)
		_check(root.get_visible_rect().grow(1).encloses(game.minimap.get_global_rect()), "mobile minimap bounds")
	var energy_before := float(game.combat_skill_system.get_skill_states()[0].energy_current)
	_touch(10, pad.joystick.get_global_rect().get_center() + Vector2(50, 0), true)
	_touch(11, pad.action_buttons[&"primary_attack"].get_global_rect().get_center(), true)
	_touch(12, pad.action_buttons[&"combat_skill_1"].get_global_rect().get_center(), true)
	for _i in 10: await physics_frame
	_check(float(game.combat_skill_system.get_skill_states()[0].energy_current) < energy_before, "third finger casts actual skill while moving and firing")
	_check(not pad.energy_label.text.contains("--"), "touch HUD has current energy")
	pad.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check(not Input.is_action_pressed(&"primary_attack") and not Input.is_action_pressed(&"move_right") and pad.pressed_actions.is_empty(), "background tab releases all")
	pad.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	await _frames(3)
	game.presentation_settings_service.set_mobile_controls_mode(&"off")
	await _frames(4)
	_check(not pad.visible and game.combat_skill_hud.visible, "switch back restores PC HUD")
	game.call(&"_return_to_start_hub")
	await _frames(4)
	mobile_completed = true

func _touch(index: int, point: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = point
	event.pressed = pressed
	root.push_input(event, true)
	Input.flush_buffered_events()

func _click(button: Button) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = button.get_global_rect().get_center()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
		await _frames(2)

func _frames(count: int) -> void:
	for _i in count: await process_frame

func _check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
