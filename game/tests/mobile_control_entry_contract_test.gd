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
	await _settings_and_tutorial_contract()
	root.size = Vector2i(1280, 720)
	_check(ProjectSettings.get_setting("application/run/main_scene") == "res://game/scenes/application.tscn", "shipped optional entry assembly")
	_check(ProjectSettings.get_setting("display/window/handheld/orientation") == DisplayServer.SCREEN_SENSOR_LANDSCAPE, "mobile native default is sensor landscape")
	for mode in [&"off", &"on"]:
		var entry: Control = load("res://game/features/mobile_controls/control_mode_entry.tscn").instantiate()
		entry.launch_game = false
		entry.settings_path = selection_path
		root.add_child(entry)
		await _frames(4)
		_check(entry.pc_button.is_visible_in_tree() and entry.mobile_button.is_visible_in_tree(), "entry has two choices")
		await _click(entry.pc_button if mode == &"off" else entry.mobile_button)
		_check(entry.choosing, "actual click selected %s" % mode)
		if mode == &"on":
			_check(entry.tutorial != null and entry.tutorial.visible, "first mobile choice shows blocking popup")
			_check(not entry.settings.mobile_tutorial_seen, "opening popup does not mark it complete")
			await _click(entry.tutorial.confirm_button)
			_check(entry.settings.mobile_tutorial_seen and not entry.tutorial.visible, "actual confirmation persists tutorial")
		else:
			_check(entry.tutorial == null and not entry.settings.mobile_tutorial_seen, "PC choice does not consume mobile tutorial")
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
	var repeat: Control = load("res://game/features/mobile_controls/control_mode_entry.tscn").instantiate()
	repeat.launch_game = false
	repeat.settings_path = selection_path
	root.add_child(repeat)
	await _frames(4)
	await _click(repeat.mobile_button)
	_check(repeat.tutorial == null, "new entry instance skips acknowledged mobile tutorial")
	repeat.queue_free()
	await _frames(2)
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
		print("MOBILE_CONTROL_ENTRY_OK pc_mobile_saved hub_gate_preserved joystick_multitouch attack_skill_menu_events pause_focus_release orientation_4 hud_reserved_regions module_off scale_3 persistence_migration tutorial_once_acknowledgement retry_on_failure")
	quit(0 if failures.is_empty() else 1)

func _settings_and_tutorial_contract() -> void:
	var test_path := isolation.root_path.path_join("settings-v1.json")
	var file := FileAccess.open(test_path, FileAccess.WRITE)
	file.store_string('{"version":1,"hud_anchor":"bottom_right","mobile_controls_mode":"off"}')
	file.close()
	var service := preload("res://game/features/presentation_settings/presentation_settings_service.gd").new()
	root.add_child(service)
	service.configure(test_path)
	_check(service.mobile_ui_scale == 1.25 and not service.mobile_tutorial_seen and service.hud_anchor == &"bottom_right", "v1 migration preserves PC settings and uses larger default")
	_check(not service.set_mobile_ui_scale(99) and service.mobile_ui_scale == 1.25, "invalid scale rejected")
	_check(service.set_mobile_ui_scale(1.5), "scale saved")
	_check(service.complete_mobile_tutorial(), "tutorial saved")
	service.queue_free()
	await _frames(2)
	service = preload("res://game/features/presentation_settings/presentation_settings_service.gd").new()
	root.add_child(service)
	service.configure(test_path)
	_check(service.mobile_ui_scale == 1.5 and service.mobile_tutorial_seen, "scale and seen flag survive new settings instance")
	service.reset_defaults()
	_check(service.mobile_ui_scale == 1.25 and service.mobile_tutorial_seen, "reset UI preserves tutorial acknowledgement")
	service.queue_free()
	await _frames(2)
	# Leaving before acknowledgement must not consume the first-use tutorial.
	var popup_path := isolation.root_path.path_join("popup.json")
	for attempt in 2:
		var entry: Control = load("res://game/features/mobile_controls/control_mode_entry.tscn").instantiate()
		entry.launch_game = false
		entry.settings_path = popup_path
		root.add_child(entry)
		await _frames(4)
		await _click(entry.mobile_button)
		_check(entry.tutorial != null and not entry.settings.mobile_tutorial_seen, "unacknowledged tutorial returns")
		for dimensions in [Vector2i(844, 390), Vector2i(390, 844), Vector2i(640, 360), Vector2i(320, 568)]:
			root.size = dimensions
			await _frames(5)
			_check(root.get_visible_rect().grow(1).encloses(entry.tutorial.panel.get_global_rect()), "popup bounds %s" % dimensions)
			_check(entry.orientation_button.visible == (dimensions.y > dimensions.x), "rotation request only shown in portrait")
			_check(entry.tutorial.orientation_button.visible == (dimensions.y > dimensions.x), "tutorial requests landscape without repeating the popup")
			_check(root.get_visible_rect().grow(1).encloses(entry.tutorial.confirm_button.get_global_rect()), "popup confirmation always reachable")
		if attempt == 1:
			(entry.tutorial.body.get_parent() as ScrollContainer).ensure_control_visible(entry.tutorial.scale_buttons[2])
			await _frames(3)
			await _click(entry.tutorial.scale_buttons[2])
			_check(entry.settings.mobile_ui_scale == 1.5, "popup changes size through public settings")
			entry.settings.storage_path = isolation.root_path.path_join("missing-directory/fail.json")
			await _click(entry.tutorial.confirm_button)
			_check(entry.tutorial.visible and not entry.settings.mobile_tutorial_seen and not entry.tutorial.error_label.text.is_empty(), "failed save keeps popup open and unseen")
			entry.settings.storage_path = popup_path
			await _click(entry.tutorial.confirm_button)
			_check(entry.settings.mobile_tutorial_seen and not entry.tutorial.visible, "save retry succeeds")
		entry.queue_free()
		await _frames(3)

func _mobile_play() -> void:
	var pad: Control = game.mobile_control_pad
	for dimensions in [Vector2i(844, 390), Vector2i(390, 844), Vector2i(1280, 720), Vector2i(640, 360), Vector2i(320, 568)]:
		root.size = dimensions
		var previous_width := 0.0
		for scale_value in [1.0, 1.25, 1.5]:
			game.presentation_settings_service.set_mobile_ui_scale(scale_value)
			await _frames(8)
			var bounds := root.get_visible_rect().grow(1)
			var state: Dictionary = pad.get_snapshot()
			_check(state.preferred_orientation == &"landscape" and state.portrait_fallback == (dimensions.y > dimensions.x), "landscape preferred with safe unsupported-browser fallback")
			_check(bounds.encloses(state.movement_rect) and bounds.encloses(state.combat_rect) and bounds.encloses(state.menu_rect), "pad bounds %s scale %s: %s" % [dimensions, scale_value, state])
			_check(not state.movement_rect.intersects(state.combat_rect), "two hand areas disjoint %s scale %s" % [dimensions, scale_value])
			_check(state.combat_rect.size.x > previous_width, "scale selection visibly enlarges controls")
			_check(bool(state.compact_skill_labels), "mobile skill buttons use compact semantic labels")
			for action_id in [&"combat_skill_1", &"combat_skill_2", &"combat_skill_3"]:
				var compact_text := String((state.combat_button_texts as Dictionary).get(action_id, ""))
				_check(compact_text.begins_with("[") and compact_text.length() <= 9, "skill label stays inside button: %s" % compact_text)
			previous_width = state.combat_rect.size.x
			for button: Button in pad.action_buttons.values():
				if button.visible: _check(button.size.x >= 44 and button.size.y >= 44, "touch target >=44")
	root.size = Vector2i(844, 390)
	await _frames(6)
	# Minimap/socket GUI outside the pad must remain touchable without firing a weapon.
	var gui := Button.new()
	gui.text = "GUI touch"
	gui.position = Vector2(360, 150)
	gui.size = Vector2(120, 50)
	gui.set_meta(&"clicks", 0)
	gui.pressed.connect(func(): gui.set_meta(&"clicks", int(gui.get_meta(&"clicks")) + 1))
	game.get_node("UI").add_child(gui)
	await _frames(2)
	_touch(20, gui.get_global_rect().get_center(), true)
	_check(not Input.is_action_pressed(&"primary_attack"), "GUI touch down is not weapon input")
	_touch(20, gui.get_global_rect().get_center(), false)
	await _frames(2)
	_check(int(gui.get_meta(&"clicks")) == 1 and not Input.is_action_pressed(&"primary_attack"), "outside-pad GUI touch without mouse weapon fire: clicks=%s attack=%s" % [gui.get_meta(&"clicks"), Input.is_action_pressed(&"primary_attack")])
	_touch(20, gui.get_global_rect().get_center(), true)
	pad.release_all()
	_check(int(gui.get_meta(&"clicks")) == 1, "canceled GUI touch must not click")
	_touch(20, gui.get_global_rect().get_center(), true)
	var canceled := InputEventScreenTouch.new()
	canceled.index = 20
	canceled.position = gui.get_global_rect().get_center()
	canceled.canceled = true
	root.push_input(canceled, true)
	_check(int(gui.get_meta(&"clicks")) == 1, "OS touch cancellation must not click")
	gui.queue_free()
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
		if pair[0] == &"toggle_key_mapping":
			var tabs := panel.presentation_rows_container.get_parent().get_parent() as TabContainer
			tabs.current_tab = (panel.presentation_rows_container.get_parent() as Control).get_index()
			var scale_button := _find_scale_button(panel)
			await _frames(3)
			(panel.presentation_rows_container.get_parent() as ScrollContainer).ensure_control_visible(scale_button)
			await _frames(3)
			var old_scale: float = game.presentation_settings_service.mobile_ui_scale
			await _click(scale_button)
			_check(game.presentation_settings_service.mobile_ui_scale != old_scale, "actual settings UI changes scale")
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
	game.presentation_settings_service.set_mobile_ui_scale(1.5)
	await _frames(8)
	for phase in [0, 1200, 1740]:
		game.advance_run_clock(maxf(0, phase - game.elapsed_time))
		for dimensions in [Vector2i(844, 390), Vector2i(390, 844)]:
			root.size = dimensions
			await _frames(8)
			var snapshot: Dictionary = game.combat_hud_presenter.get_snapshot(game.hud_margin)
			_check(snapshot.layout_mode == &"mobile_touch" and not game.combat_skill_hud.visible and not game.dash_cooldown_hud.visible, "mobile removes duplicate PC HUD")
			for rect: Rect2 in [snapshot.core_rect, snapshot.telemetry_rect, snapshot.mission_rect]:
				_check(root.get_visible_rect().grow(1).encloses(rect), "mobile HUD bounds")
				_check(not rect.intersects(pad.movement_group.get_global_rect()) and not rect.intersects(pad.combat_group.get_global_rect()), "HUD clears both hands %s" % dimensions)
			_check(root.get_visible_rect().grow(1).encloses(game.minimap.get_global_rect()), "mobile minimap bounds")
			_check(not snapshot.mission_rect.intersects(game.minimap.get_global_rect()), "mission and minimap do not overlap")
			_check(not snapshot.mission_rect.intersects(snapshot.core_rect), "mission clears vitals")
			if snapshot.mission_rect.intersects(snapshot.core_rect): print("MOBILE_MISSION_VITALS ", phase, " ", dimensions, " ", snapshot.mission_rect, " ", snapshot.core_rect, " min=", game.combat_hud_presenter.mission_tracker.get_combined_minimum_size())
			_check(game.time_label.is_visible_in_tree() and "붕괴" in game.time_label.text, "mobile deadline remains visible")
			if "--render" in OS.get_cmdline_user_args() and phase == 1200:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://build/qa-pressure-mobile-%d.png" % dimensions.x)
	var energy_before := float(game.combat_skill_system.get_skill_states()[0].energy_current)
	var skill_id: StringName = game.combat_skill_system.get_skill_states()[0].skill_id
	game.skill_binding_service.assign_skill(skill_id, &"combat_skill_9")
	await _frames(3)
	_touch(10, pad.joystick.get_global_rect().get_center() + Vector2(50, 0), true)
	_touch(11, pad.action_buttons[&"primary_attack"].get_global_rect().get_center(), true)
	_touch(12, pad.action_buttons[&"combat_skill_1"].get_global_rect().get_center(), true)
	for _i in 10: await physics_frame
	_check(float(game.combat_skill_system.get_skill_states()[0].energy_current) < energy_before, "third finger casts actual skill while moving and firing")
	_check(Input.is_action_pressed(&"combat_skill_9") and not Input.is_action_pressed(&"combat_skill_1"), "touch slot follows remapped skill action")
	_check(not pad.energy_label.text.contains("--"), "touch HUD has current energy")
	pad.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check(not Input.is_action_pressed(&"primary_attack") and not Input.is_action_pressed(&"move_right") and pad.pressed_actions.is_empty(), "background tab releases all")
	_check(not Input.is_action_pressed(&"combat_skill_9"), "release uses action captured before remapping")
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

func _find_scale_button(node: Node) -> Button:
	if node is Button and node.get_meta(&"presentation_setting", &"") == &"mobile_ui_scale": return node
	for child in node.get_children():
		var found := _find_scale_button(child)
		if found != null: return found
	return null

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
