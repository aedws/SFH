extends SceneTree
const Grid = preload("res://game/features/inventory/grid_inventory.gd")
const Policy = preload("res://game/features/inventory/inventory_reserve_policy.gd")
const Codec = preload("res://game/features/local_save/loadout_value_codec.gd")
const Progress = preload("res://game/features/local_save/desktop_progress_service.gd")
const Store = preload("res://game/core/persistence/atomic_json_store.gd")
var failures: Array[String] = []
var isolation := preload("res://game/tests/support/save_test_isolation.gd").new()

class Gear extends Node:
	signal customization_changed(snapshot: Dictionary)
	signal active_weapon_changed(slot: StringName, definition: Resource)
	func export_runtime_state() -> Dictionary: return {}
	func validate_runtime_state(_state: Dictionary) -> PackedStringArray: return PackedStringArray()
	func restore_runtime_state(_state: Dictionary) -> bool: return true


func _initialize() -> void:
	node_added.connect(isolation.isolate)
	call_deferred(&"_run")


func signature(value: Variant) -> String:
	var codec := Codec.new()
	var encoded: Variant = codec.encode(value)
	check(codec.error.is_empty(), "codec accepts preserved resources")
	return JSON.stringify(encoded)


func _run() -> void:
	var bag := Grid.new()
	root.add_child(bag)
	var catalog := InventoryCatalog.new()
	check(bag.configure(catalog), "empty source")
	bag.set_reserve_access(true)
	var definition: InventoryItemDefinition = load("res://game/features/inventory/items/spare_assault_rifle.tres").duplicate(true)
	definition.grid_size = Vector2i(2, 3)
	var equipment := EquipmentItemState.new()
	equipment.configure(&"unique-rifle", definition.linked_resource, {&"quality_id": &"high_performance", &"performance_multiplier": 1.25})
	equipment.level = 7
	equipment.install_part(load("res://game/features/equipment/definitions/parts/rifle_scope.tres"), 3)
	var id := bag.add_item_with_payload(definition, {&"equipment_state": equipment, &"upgrade_level": 4, &"affixes": [{&"id": &"preserved", &"value": 1.17}]}, Vector2i(8, 5))
	check(bag.rotate_item(id), "source rotated")
	for i in 10: check(bag.add_item(definition) != &"", "fill migration fixture %d" % i)
	var source := bag.export_runtime_state()
	var original := signature(Policy.record(source, id))
	for rows in [3, 4, 5, 6]:
		var plan := bag.prepare_capacity_restore(source, Vector2i(12, rows))
		check(not plan.is_empty() and bag.validate_runtime_state(plan).is_empty(), "capacity valid %d" % rows)
		check(plan.items.size() + plan.reserve.size() == source.items.size(), "no loss at %d rows" % rows)
		for key in source.items:
			var actual: Dictionary = plan.reserve.get(key, {})
			if actual.is_empty(): actual = Policy.record(plan, key)
			var expected := Policy.record(source, key)
			# Repacking is allowed; identity, original orientation and payload are not changed.
			actual.position = expected.position
			check(signature(actual) == signature(expected), "full instance preserved %s/%d" % [key, rows])
	check(signature(Policy.record(source, id)) == original, "planning never mutates source")
	check(bag.resize_with_reserve(Vector2i(12, 3)), "apply shrink")
	check(bag.reserve.size() > 0, "overflow is separate from carried items")
	var compact := bag.export_runtime_state()
	var reserve_id: StringName = bag.reserve.keys()[0]
	var before := signature(compact)
	check(not bag.retrieve_from_reserve(reserve_id) and signature(bag.export_runtime_state()) == before, "full bag retrieval atomic")
	var bad := bag.export_runtime_state()
	bad.reserve[bad.items.keys()[0]] = bad.reserve[reserve_id]
	check(not bag.restore_runtime_state(bad) and signature(bag.export_runtime_state()) == before, "duplicate instance rejected without mutation")
	for corrupt in [{&"reserve": []}, {&"placements": []}, {&"serials": {&"bad": -1}}]:
		bad = bag.export_runtime_state()
		bad.merge(corrupt, true)
		check(not bag.restore_runtime_state(bad), "malformed saved state rejected")
	var copied := bag.get_reserve_entries()
	copied[0].definition.display_name = "tampered copy"
	check(bag.reserve[reserve_id].definition.display_name != "tampered copy", "public reserve copy isolated")
	var codec := Codec.new()
	var restored: Dictionary = Codec.new().decode(JSON.parse_string(JSON.stringify(codec.encode(compact))))
	check(bag.restore_runtime_state(restored), "serialized reserve restored")
	check(bag.resize_with_reserve(Vector2i(12, 8)), "expand without auto-claim")
	for entry in bag.get_reserve_entries(): check(bag.retrieve_from_reserve(entry.instance_id), "retrieve original instance")
	check(bag.reserve.is_empty() and bag.items.size() == source.items.size(), "all originals retrieved")
	check(signature(bag.get_runtime_payload(id)) == signature(source.runtime_payloads[id]) and bag.rotations[id], "options upgrades rotation after retrieval")
	bag.set_reserve_access(false)
	before = signature(bag.export_runtime_state())
	check(not bag.store_in_reserve(id) and not bag.resize_with_reserve(Vector2i.ONE), "combat access denied")
	check(signature(bag.export_runtime_state()) == before, "combat denial unchanged")
	bag.set_reserve_access(true)
	check(bag.store_in_reserve(id), "hub deposit")
	bag.serials.clear() # Legacy saves may lack a reliable high-water mark.
	var next_id := bag.add_item(definition)
	check(next_id != id and bag.reserve.has(id), "serial collision cannot overwrite reserve")
	bag.free()
	await _persist(source)
	await _ui()
	for failure in failures: push_error(failure)
	if failures.is_empty(): print("INVENTORY_RESERVE_OK migration_36_48_60_72 original_id payload rotation upgrades no_duplicate rollback native_restart hub_only responsive_save_cancel")
	quit(0 if failures.is_empty() else 1)


func _persist(source: Dictionary) -> void:
	var folder := OS.get_cache_dir().path_join("sfh-reserve-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	DirAccess.make_dir_recursive_absolute(folder)
	var path := folder.path_join("progress.json")
	var data := {"schema_version": 1, "loadout": Codec.new().encode({&"bag": source, &"gear": {}}), "history": [], "total_runs": 0, "extractions": 0, "pending_run": {}}
	check(Store.new().write(path, data), "legacy fixture write")
	var gear := Gear.new()
	root.add_child(gear)
	var bag := Grid.new()
	root.add_child(bag)
	var catalog := InventoryCatalog.new()
	catalog.restore_capacity = Vector2i(12, 3)
	bag.configure(catalog)
	var progress := Progress.new()
	root.add_child(progress)
	check(progress.configure(path) and progress.bind_hub(bag, gear), "native legacy migration")
	check(bag.grid_size == Vector2i(12, 3) and bag.reserve.size() > 0, "native capacity policy applied")
	check(progress.flush(), "migration checkpoint same atomic document")
	var expected := signature(bag.export_runtime_state())
	progress.unbind_hub()
	progress.free()
	progress = Progress.new()
	root.add_child(progress)
	check(progress.configure(path) and progress.bind_hub(bag, gear), "restart restore")
	check(signature(bag.export_runtime_state()) == expected, "migration idempotent on restart")
	var saved_text := FileAccess.get_file_as_string(path)
	var blocker := FileAccess.open(folder.path_join("blocked"), FileAccess.WRITE)
	blocker.store_string("fixture")
	blocker.close()
	progress.storage_path = folder.path_join("blocked/save.json")
	check(not progress.flush() and progress.blocked, "failed write blocks checkpoint")
	check(FileAccess.get_file_as_string(path) == saved_text, "failed write preserves last good source")
	progress.free()
	bag.free()
	gear.free()


func _ui() -> void:
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(1280, 800)
	var game: Node = load("res://game/scenes/game.tscn").instantiate()
	root.add_child(game)
	await frames()
	var window: Control = game.inventory_window
	var bag: Node = game.inventory_system
	window.open_panel()
	await frames()
	var id: StringName = bag.items.keys()[0]
	window._on_item_selected(window.session.get_item_entry(id))
	await click(window.reserve_button)
	check(window.session.dirty and bag.items.has(id), "UI deposit draft only")
	window.close_panel()
	check(window.confirmation_visible, "deposit requires confirmation")
	window.resolve_exit(&"discard")
	check(bag.items.has(id) and bag.reserve.is_empty(), "discard does not move real item")
	window.open_panel()
	window._on_item_selected(window.session.get_item_entry(id))
	await click(window.reserve_button)
	window.close_panel()
	window.resolve_exit(&"save")
	check(bag.reserve.has(id) and not bag.items.has(id), "save moves exactly once")
	window.open_panel()
	await click(window.reserve_toggle)
	window._select_reserve(id)
	for dimensions in [Vector2i(1280, 800), Vector2i(844, 390), Vector2i(390, 844)]:
		root.size = dimensions
		await frames()
		check(root.get_visible_rect().grow(1).encloses(window.get_global_rect()), "reserve UI fits %s" % dimensions)
		check(window.reserve_list.visible and not window.grid_view.visible, "reserve replaces grid")
		if "--render" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://build/qa-reserve-%dx%d.png" % [dimensions.x, dimensions.y])
	await click(window.reserve_list.get_child(0).get_child(1))
	window.close_panel()
	window.resolve_exit(&"save")
	check(bag.items.has(id) and bag.reserve.is_empty(), "UI retrieve same ID")
	bag.store_in_reserve(id)
	var reserved_payload := signature(bag.reserve[id])
	check(game.start_run("small"), "reserve aware state launch")
	await frames()
	window = game.inventory_window
	window.open_panel()
	check(window.realtime and window.reserve_toggle.disabled, "combat UI locks reserve")
	id = game.inventory_system.items.keys()[0]
	check(not window.session.transfer_reserve(id, false), "direct draft cannot bypass combat rule")
	window.close_panel()
	game._on_player_died()
	game._return_to_start_hub()
	await frames()
	check(game.inventory_system.reserve.size() == 1 and signature(game.inventory_system.reserve.values()[0]) == reserved_payload, "death and hub return preserve reserved original")
	game.free()
	paused = false


func frames() -> void:
	for i in 10: await process_frame


func click(button: Button) -> void:
	await frames()
	check(root.get_visible_rect().encloses(button.get_global_rect()), "clicked action on screen")
	var motion := InputEventMouseMotion.new()
	motion.position = button.get_global_rect().get_center()
	Input.parse_input_event(motion)
	await process_frame
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = motion.position
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await frames()


func check(value: bool, label: String) -> void:
	if not value: failures.append(label)
