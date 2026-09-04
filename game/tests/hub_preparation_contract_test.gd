extends SceneTree

const CODEC = preload("res://game/features/local_save/loadout_value_codec.gd")
var isolation := preload("res://game/tests/support/save_test_isolation.gd").new()
var failures: Array[String] = []


func _init() -> void:
	node_added.connect(isolation.isolate)
	call_deferred(&"_run")


func _run() -> void:
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(1280, 720)
	var game: Node = load("res://game/scenes/game.tscn").instantiate()
	root.add_child(game)
	for _frame in 5: await process_frame
	var prep: Control = game.hub_preparation_panel
	_check(prep != null and not game.run_started and not paused, "boot in moving lobby")
	var station: Node2D = game.hub_service_stations.get_node("PreparationStation")
	# The scene's position is configurable, not hardcoded in Game/input routing.
	station.position += Vector2(140, 0)
	game.player.global_position = station.global_position
	for _frame in 4: await physics_frame
	await _tap(KEY_F)
	_check(prep.visible and paused and not game.run_setup_overlay.visible, "F opens placed preparation station")
	_check(not game.main_weapon_investment_button.is_visible_in_tree(), "no weapon rental selector")
	var initial_character: StringName = game.character_selection_service.get_snapshot().character_id
	await _click(game.character_selection_button)
	var selected_character: Dictionary = game.character_selection_service.get_snapshot()
	_check(selected_character.character_id != initial_character, "character changed in lobby")
	for dimensions in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(640, 360), Vector2i(390, 844)]:
		root.size = dimensions
		for _frame in 8: await process_frame
		var bounds := root.get_visible_rect().grow(1)
		_check(bounds.encloses(prep.panel.get_global_rect()), "preparation bounds %s / %s" % [dimensions, prep.panel.get_global_rect()])
		_check(bounds.encloses(prep.inventory_button.get_global_rect()) and bounds.encloses(prep.close_button.get_global_rect()), "preparation fixed actions %s" % dimensions)
	root.size = Vector2i(1280, 720)
	for _frame in 8: await process_frame
	await _click(prep.inventory_button)
	var window: Control = game.inventory_window
	_check(window.visible and not prep.visible and paused, "preparation to inventory")
	for _frame in 3: await process_frame
	var inventory_density: Dictionary = window.call(&"get_density_snapshot")
	_check(
		bool(inventory_density.get(&"open_layout_ready", false))
		and float(inventory_density.get(&"bag_viewport_width", 0.0)) > 240.0
		and (inventory_density.get(&"grid_minimum_size", Vector2.ZERO) as Vector2).x >= 480.0,
		"inventory first-open stable grid layout"
	)
	var editor: Node = window.session
	var weapon_id: StringName
	for entry: Dictionary in editor.inventory.get_items_by_type(&"weapon"):
		if entry.linked_resource.weapon_id == &"assault_rifle": weapon_id = entry.instance_id
	_check(editor.equip_item(weapon_id, &"main"), "equip actual bag weapon instance")
	for kind in [&"module", &"part"]:
		var installed := false
		for entry: Dictionary in editor.inventory.get_items_by_type(kind):
			if editor.install_item(entry.instance_id, &"main"):
				installed = true
				break
		_check(installed, "draft install %s" % kind)
	var state: Resource = editor.equipment.get_equipment_state(&"main")
	state.level = 2
	var credits: int = game.persistent_profile.get_snapshot().banked_credits
	_check(not game.start_run("small") and game.persistent_profile.get_snapshot().banked_credits == credits, "direct launch cannot bypass dirty editor")
	game.call(&"_open_run_setup")
	_check(window.confirmation_visible and not game.run_setup_overlay.visible, "gate respects save confirmation")
	window.resolve_exit(&"cancel")
	_check(window.visible and editor.dirty and not game.run_setup_overlay.visible, "cancel stays editing")
	game.call(&"_open_run_setup")
	for _frame in 4: await process_frame
	await _click(window.confirm_buttons[0])
	_check(not window.visible and game.run_setup_overlay.visible and paused, "save then gate: %s" % editor.error_message)
	await _tap(KEY_ESCAPE)
	_check(not paused and not game.run_setup_overlay.visible, "cancel briefing returns moving hub")
	await _tap(KEY_Q)
	_check(game.equipment_system.active_weapon_slot == &"secondary", "lobby active secondary")
	var equipment_before := _gear(game)
	var inventory_before: Variant = CODEC.new().encode(game.inventory_system.export_runtime_state())
	game.player.global_position = game.start_hub.get_operation_position()
	for _frame in 4: await physics_frame
	await _tap(KEY_F)
	await _click(game.operation_setup_presenter.next_button)
	_check(game.operation_setup_presenter.equipped_summary.is_visible_in_tree(), "operation step 2 read-only actual equipment")
	_check("READY" in game.operation_setup_presenter.equipped_summary.text, "operation step 2 readiness summary")
	_check(not game.character_selection_button.is_visible_in_tree() and not game.shop_button.is_visible_in_tree(), "no preparation edits in operation steps")
	await _click(game.operation_setup_presenter.next_button)
	await _click(game.operation_setup_presenter.launch_button)
	for _frame in 5: await process_frame
	_check(game.run_started and not paused, "physical gate to combat: %s" % game.status_label.text)
	_check(_gear(game) == equipment_before, "weapon armor modules parts levels active slot identical at launch")
	_check(CODEC.new().encode(game.inventory_system.export_runtime_state()) == inventory_before, "bag items positions preserved at launch")
	_check(game.character_selection_service.get_snapshot().character_id == selected_character.character_id, "lobby character retained")
	_check(game.active_contract.get(&"investment_context", {}).get(&"loadout_investment", {}).get(&"weapon_paths", {}).is_empty(), "no equipment override in contract")
	game.call(&"_abandon_run_to_start_hub")
	for _frame in 4: await process_frame
	_check(_gear(game) == equipment_before and not paused, "normal return retains prepared item instances")
	# A non-catalog weapon must enter without the old default rifle being restored.
	# Extend the fixture's slot rule through the public state contract; production
	# keeps its existing rifle/pistol restrictions rather than silently bypassing them.
	var extension: Dictionary = game.equipment_system.export_runtime_state()
	var rule: Resource = extension.loadout.get_slot_rule(&"main")
	rule.allowed_major_tags.clear()
	rule.allowed_middle_tags.clear()
	rule.allowed_minor_tags.clear()
	_check(game.equipment_system.restore_runtime_state(extension), "extended slot rule accepted")
	_check(game.equipment_system.equip_definition(&"main", load("res://game/features/equipment/definitions/weapons/greatsword.tres")), "extended fixture equips greatsword")
	_check(game.start_run("medium"), "non-catalog weapon launch")
	_check(game.equipment_system.get_weapon(&"main").weapon_id == &"greatsword", "non-catalog weapon preserved")
	game.call(&"_abandon_run_to_start_hub")
	game.free()
	var optional: Node = load("res://game/scenes/game.tscn").instantiate()
	optional.features = optional.features.duplicate(true)
	optional.features.hub_preparation_enabled = false
	root.add_child(optional)
	for _frame in 4: await process_frame
	_check(optional.hub_preparation_panel == null and get_nodes_in_group(&"hub_service_station").is_empty(), "optional station UI removable")
	_check(optional.start_hub != null and optional.inventory_window != null and optional.start_run("small"), "hub inventory gate survive optional removal")
	optional.free()
	paused = false
	if failures.is_empty():
		print("HUB_PREPARATION_OK physical_station shop_lobby readonly_review dirty_save_guard actual_item_instances weapon_armor_modules_parts_levels active_slot bag_preserved no_rental_override non_catalog_weapon return optional viewports_4")
		quit(0)
	else:
		printerr("HUB_PREPARATION_FAILED: %s" % " / ".join(failures))
		quit(1)


func _gear(game: Node) -> Dictionary:
	var result := {}
	for slot in [&"main", &"secondary", &"body", &"feet"]:
		result[slot] = CODEC.new().encode(game.equipment_system.get_equipment_state(slot))
	result[&"active"] = game.equipment_system.active_weapon_slot
	return result


func _tap(key: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	for _frame in 4: await process_frame


func _click(button: Button) -> void:
	if not button.is_visible_in_tree():
		_check(false, "hidden click %s" % button.name)
		return
	var event := InputEventMouseButton.new()
	event.position = button.get_global_transform_with_canvas() * (button.size * 0.5)
	event.global_position = event.position
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	for _frame in 4: await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("CHECK FAILED: %s" % message)
