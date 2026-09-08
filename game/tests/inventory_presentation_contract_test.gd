extends SceneTree
var failures: Array[String] = []
var capture_dir := ""
var isolation := preload("res://game/tests/support/save_test_isolation.gd").new()

func _initialize() -> void:
	node_added.connect(isolation.isolate)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="): capture_dir = argument.trim_prefix("--capture-dir=")
	call_deferred(&"_run")

func _run() -> void:
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(1280,720)
	var game: Node = load("res://game/scenes/game.tscn").instantiate()
	root.add_child(game)
	await _frames()
	var window: Control = game.inventory_window
	window.open_panel()
	await _frames()
	var before: Dictionary = game.inventory_system.export_runtime_state()
	_check(window.slot_buttons.size() == game.equipment_system.get_slot_descriptors().size(),"only real equipment slots")
	for button: Button in window.slot_buttons.values():
		_check(not button.presentation.is_empty(),"equipped silhouette has real definition")
		_check(button.text.contains(button.item_label),"native button name retained")
	var entries: Array = window.session.inventory.get_snapshot().items
	for dimensions in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(640,360),Vector2i(390,844)]:
		root.size = dimensions
		await _frames()
		for tab in 3:
			window.request_tab(tab)
			await _frames()
			_check(root.get_visible_rect().grow(1).encloses(window.get_global_rect()),"window fits %s tab %d" % [dimensions,tab])
			if tab != 2:
				_check(window.grid_view.custom_minimum_size.x <= window.bag_scroll.size.x,"all columns accessible %s" % dimensions)
			_check(not window.session.dirty,"visual tab browsing does not edit inventory")
		window.request_tab(0)
		await _frames()
		if dimensions.x < 1000: _check(window.bag_scroll.get_parent().get_index()==0,"narrow layout puts bag first")
		window.grid_view.selected_instance_id = entries[0].instance_id
		window._on_item_selected(entries[0])
		await _frames()
		_check(window.selected_preview.entry.get(&"instance_id") == entries[0].get(&"instance_id") and not entries[0].is_empty(),"preview matches selected actual item")
		await _capture("inventory-%dx%d" % [dimensions.x,dimensions.y])
	_check(game.inventory_system.export_runtime_state() == before,"presenter never changes real bag")
	root.size = Vector2i(1280,720)
	window.content_scroll.scroll_vertical = 0
	await _frames()
	var grid: Control = window.grid_view
	var target: Vector2 = grid._entry_rect(entries[1]).get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = target
	grid._gui_input(motion)
	_check(grid.tooltip_text.contains(entries[1].display_name),"small item has complete hover name")
	grid.grab_focus()
	await _tap(KEY_RIGHT)
	_check(window.selected_preview.entry.instance_id == entries[1].instance_id,"keyboard grid selection updates preview")
	var destination := Vector2i(7,5)
	_check(grid.request_move(entries[1].instance_id,destination),"item movement still routes through draft")
	_check(window.session.dirty and game.inventory_system.export_runtime_state()==before,"move is not auto-saved")
	window.close_panel()
	_check(window.confirmation_visible,"closing a dirty inventory requires confirmation")
	window.resolve_exit(&"cancel")
	_check(window.visible and window.session.dirty,"cancel keeps editing")
	window.close_panel()
	window.resolve_exit(&"discard")
	_check(not window.visible and game.inventory_system.export_runtime_state()==before,"discard preserves real state")
	game.free()
	for failure in failures: push_error(failure)
	if failures.is_empty(): print("INVENTORY_PRESENTATION_OK viewports_4 tabs_3 silhouettes_real_slots hover keyboard preview draft_save_guard immutable_source")
	quit(0 if failures.is_empty() else 1)

func _frames() -> void:
	for frame in 10: await process_frame

func _tap(key: Key) -> void:
	var event := InputEventKey.new()
	event.keycode=key
	event.physical_keycode=key
	event.pressed=true
	Input.parse_input_event(event)
	await process_frame
	event=event.duplicate()
	event.pressed=false
	Input.parse_input_event(event)
	await _frames()

func _capture(label: String) -> void:
	if capture_dir.is_empty() or DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	_check(root.get_texture().get_image().save_png(capture_dir.path_join(label+".png"))==OK,"capture "+label)

func _check(condition: bool,label: String) -> void:
	if not condition: failures.append(label)
