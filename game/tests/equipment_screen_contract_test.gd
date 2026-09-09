extends SceneTree
var failures: Array[String] = []
var capture_dir := ""
var isolation := preload("res://game/tests/support/save_test_isolation.gd").new()

func _initialize() -> void:
	node_added.connect(isolation.isolate)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="): capture_dir = arg.trim_prefix("--capture-dir=")
	call_deferred("_run")

func _run() -> void:
	var policy = preload("res://game/features/mobile_controls/mobile_viewport_policy.gd")
	_check(policy.logical_size(Vector2i(1920,1080), false) == Vector2i(1280,800), "PC stays 16:10")
	_check(ProjectSettings.get_setting("display/window/size/viewport_height") == 800, "native/export baseline")
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(1280,800)
	var game = load("res://game/scenes/game.tscn").instantiate()
	root.add_child(game)
	await _frames()
	var bag = game.inventory_window
	var bench = game.equipment_workbench
	var before: Dictionary = game.inventory_system.export_runtime_state()
	for dimensions in [Vector2i(1280,800),Vector2i(1440,900),Vector2i(1920,1200),Vector2i(1024,640),Vector2i(640,400),Vector2i(390,844)]:
		root.size = dimensions
		await _frames()
		bag.open_panel()
		for tab in 3:
			bag.request_tab(tab)
			bag.content_scroll.scroll_vertical = 0
			await _frames()
			_check(root.get_visible_rect().grow(1).encloses(bag.get_global_rect()), "bag frame %s/%d actual %s" % [dimensions,tab,bag.get_global_rect()])
			if tab == 1 and dimensions.x >= 1280:
				_check(bag.module_column.size.x >= bag.size.x * 0.35, "weapon gets display priority")
			if tab == 2:
				bag.module_workspace.configure(bag.session, &"body")
				await _frames()
				_check(not bag.module_workspace.equipment_preview.entry.is_empty(), "armor preview uses equipped definition")
			if dimensions.x in [1280,640]: await _capture("equipment-%dx%d-tab%d" % [dimensions.x,dimensions.y,tab])
		bag.close_panel()
		bench.open_panel()
		for slot in [&"main", &"body"]:
			bench._select_slot(slot)
			for tab in 2:
				bench.tabs.current_tab = tab
				await _frames()
				_check(root.get_visible_rect().grow(1).encloses(bench.get_global_rect()), "workbench frame %s/%s/%d actual %s" % [dimensions,slot,tab,bench.get_global_rect()])
				_check(bench.screen_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "no horizontal clipping")
				if dimensions.x >= 1280:
					var action: Button = bench.unequip_equipment_button if tab == 0 else bench.uninstall_selected_button
					_check(bench.screen_scroll.get_global_rect().encloses(action.get_global_rect()), "primary removal action visible %s/%d" % [slot, tab])
					var count: Label = bench.equipment_inventory_count if tab == 0 else bench.modification_inventory_count
					_check(count.size.y < 40, "header count must remain one line")
				if dimensions.x == 1280: await _capture("workbench-%s-tab%d" % [slot,tab])
		bench.close_panel()
	_check(game.inventory_system.export_runtime_state() == before, "presentation never mutates inventory")
	game.free()
	for failure in failures: push_error(failure)
	if failures.is_empty(): print("EQUIPMENT_SCREEN_OK ratio_16_10 viewports_6 bag_parts_modules workbench_weapon_armor immutable_inventory")
	quit(0 if failures.is_empty() else 1)

func _frames() -> void:
	for frame in 15: await process_frame

func _capture(label: String) -> void:
	if capture_dir.is_empty() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(capture_dir.path_join(label+".png"))

func _check(ok: bool, label: String) -> void:
	if not ok: failures.append(label)
