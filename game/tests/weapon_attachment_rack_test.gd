extends SceneTree
var failures := PackedStringArray()
var isolation: RefCounted

func _init() -> void:
	isolation = preload("res://game/tests/support/save_test_isolation.gd").new()
	node_added.connect(isolation.isolate)
	_run.call_deferred()

func _run() -> void:
	var game = load("res://game/scenes/game.tscn").instantiate()
	root.add_child(game)
	await _frames()
	var window = game.inventory_window
	window.open_panel()
	window.request_tab(1)
	await _frames()
	var rack = window.weapon_rack
	_check(rack.boards.size() == 2, "both equipped weapon cards exist")
	_check(not window.gear_column.visible and rack.visible, "text gear list replaced only in weapon tab")
	var main_board = rack.boards[&"main"]
	_check(main_board.socket_buttons.size() == 3, "actual rifle sockets only")
	var optic: Button = main_board.socket_buttons[&"optic"]
	optic.grab_focus()
	await _tap(KEY_ENTER)
	_check(window.selected_slot == &"main" and window.selected_socket == &"optic", "keyboard activation targets weapon and socket")
	var scope_id: StringName = &""
	var pistol_id: StringName = &""
	for entry: Dictionary in window.session.inventory.get_snapshot()[&"items"]:
		if entry.get(&"item_type") == &"part":
			if entry[&"linked_resource"].socket_id == &"optic": scope_id = entry[&"instance_id"]
			if entry[&"linked_resource"].socket_id == &"muzzle": pistol_id = entry[&"instance_id"]
	_check(scope_id != &"" and pistol_id != &"", "owned part fixtures")
	_check(not window.session.replace_part(pistol_id, &"main"), "incompatible pistol part rejected")
	window._install_socket_item(scope_id)
	_check(window.session.dirty, "slot action edits a draft")
	_check(window.session.equipment.get_equipment_state(&"main").installed_parts.size() == 1, "scope installed on selected weapon")
	_check(game.equipment_system.get_equipment_state(&"main").installed_parts.is_empty(), "live gear untouched before save")
	var part: Resource = window.session.equipment.get_equipment_state(&"main").installed_parts[0]
	var bag_before: Dictionary = window.session.inventory.export_runtime_state()
	window.session.inventory.remove_item_instances(window.session.inventory.items.keys())
	window.session.inventory.grid_size = Vector2i.ONE
	var compact_part: Resource = load("res://game/features/inventory/items/rifle_scope_item.tres").duplicate()
	compact_part.grid_size = Vector2i.ONE
	var compact_id: StringName = window.session.inventory.add_item(compact_part)
	_check(not window.session.remove_modification(&"main", &"part", part.part_id), "full bag rejects unequip")
	_check(not window.session.get_item_entry(compact_id).is_empty(), "failed unequip keeps bag contents")
	_check(window.session.equipment.get_equipment_state(&"main").installed_parts.size() == 1, "failed unequip keeps installed part")
	window.session.inventory.restore_runtime_state(bag_before)
	var replacement: StringName = window.session.inventory.add_linked_resource(part, {&"upgrade_level": 2})
	_check(window.session.replace_part(replacement, &"main"), "occupied socket can replace atomically")
	_check(window.session.equipment.get_equipment_state(&"main").part_upgrade_levels[part.part_id] == 2, "replacement upgrade level retained")
	var returned_count := 0
	for entry: Dictionary in window.session.inventory.get_snapshot()[&"items"]:
		if entry.get(&"linked_resource") == part:
			returned_count += 1
	_check(returned_count == 1, "old part returned once")
	window.request_tab(0)
	_check(window.confirmation_visible and window.current_tab == 1, "tab departure requires save decision")
	window.resolve_exit(&"cancel")
	_check(window.session.dirty and window.current_tab == 1, "cancel keeps draft and tab")
	window.close_panel()
	window.resolve_exit(&"discard")
	_check(game.equipment_system.get_equipment_state(&"main").installed_parts.is_empty(), "discard preserves live equipment")
	window.open_panel()
	window.request_tab(1)
	window._install_socket_item(scope_id)
	window.close_panel()
	window.resolve_exit(&"save")
	_check(game.equipment_system.get_equipment_state(&"main").installed_parts.size() == 1, "save applies attachment")
	window.open_panel()
	window.request_tab(1)
	window._on_weapon_socket_selected(&"main", &"optic")
	window._remove_modification(&"part", part.part_id)
	_check(window.session.equipment.get_equipment_state(&"main").installed_parts.is_empty(), "slot removal returns part to draft bag")
	for dimensions in [Vector2i(1280,720), Vector2i(1050,720), Vector2i(844,720), Vector2i(640,720)]:
		root.content_scale_size = Vector2i.ZERO
		root.size = dimensions
		await _frames()
		var cards: Array = window.weapon_rack.get_snapshot()[&"cards"]
		_check(cards[0][&"rect"].end.y <= cards[1][&"rect"].position.y, "weapon cards stacked without overlap")
		for board in window.weapon_rack.boards.values():
			for button in board.socket_buttons.values():
				_check(Rect2(Vector2.ZERO, board.size).encloses(button.get_rect()), "socket within card at %d" % dimensions.x)
		_check(window.size.x <= dimensions.x, "window fits viewport")
	window.close_panel()
	window.resolve_exit(&"discard")
	var future = load("res://game/features/equipment/weapon_parts_board.gd").new()
	future.inventory_card_mode = true
	future.size = Vector2(280, 174)
	root.add_child(future)
	var future_state: Resource = game.equipment_system.get_equipment_state(&"main").duplicate(true)
	for socket in [&"grip", &"stock", &"laser", &"bipod", &"rail", &"battery", &"barrel"]:
		future_state.definition.part_socket_ids.append(socket)
	future.configure(future_state)
	await _frames()
	for a in future.socket_buttons.values():
		_check(Rect2(Vector2.ZERO, future.size).encloses(a.get_rect()), "future socket inside growing card")
		for b in future.socket_buttons.values():
			if a != b: _check(not a.get_rect().intersects(b.get_rect()), "future sockets never overlap")
	future.free()
	game.free()
	await _frames()
	if failures.is_empty():
		print("WEAPON_ATTACHMENT_RACK_OK two_cards actual_sockets keyboard compatible_only replace_return save_discard four_widths future_sockets")
		quit(0)
	else:
		for failure in failures: printerr(failure)
		quit(1)

func _frames() -> void:
	for frame in 8: await process_frame

func _tap(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await _frames()

func _check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
