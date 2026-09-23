extends SceneTree
const Grid = preload("res://game/features/inventory/grid_inventory.gd")
const Protection = preload("res://game/features/inventory/inventory_run_protection.gd")
const Capacity = preload("res://game/features/inventory/inventory_capacity_service.gd")
const Profile = preload("res://game/features/persistent_profile/persistent_profile.gd")
const Progress = preload("res://game/features/local_save/desktop_progress_service.gd")
const Codec = preload("res://game/features/local_save/loadout_value_codec.gd")
var failures: Array[String] = []
var isolation := preload("res://game/tests/support/save_test_isolation.gd").new()
var native_game := false

class Gear extends Node:
	signal customization_changed(snapshot: Dictionary)
	signal active_weapon_changed(slot: StringName, definition: Resource)
	func export_runtime_state() -> Dictionary: return {}
	func validate_runtime_state(_state: Dictionary) -> PackedStringArray: return PackedStringArray()
	func restore_runtime_state(_state: Dictionary) -> bool: return true

class Lifecycle extends Node:
	var definition: Resource
	func get_definition(_id: StringName) -> Resource: return definition

class ProtectedRun extends Node:
	signal protected_inventory_changed
	var baseline: Dictionary
	var bag: Node
	func get_protected_return_state(extracted: bool) -> Dictionary:
		return InventoryRunProtection.returning(baseline, bag.export_runtime_state(), extracted)

func _initialize() -> void:
	node_added.connect(isolation.isolate)
	node_added.connect(func(node: Node):
		if native_game and node.scene_file_path == "res://game/scenes/game.tscn": node.features.desktop_progress_enabled = true)
	_run.call_deferred()

func check(value: bool, message: String) -> void:
	if not value: failures.append(message)

func item(type: StringName, size := Vector2i.ONE) -> InventoryItemDefinition:
	var result := InventoryItemDefinition.new()
	result.item_id = StringName("test_" + String(type))
	result.display_name = String(type)
	result.item_type = type
	result.grid_size = size
	return result

func empty_bag() -> Node:
	var bag := Grid.new()
	root.add_child(bag)
	bag.configure(InventoryCatalog.new())
	bag.set_reserve_access(true)
	return bag

func signature(value: Variant) -> String: return JSON.stringify(Codec.new().encode(value))

func _run() -> void:
	_blueprint_geometry()
	_geometry()
	_capacity()
	await _persistence()
	await _native_game()
	for extracted in [false, true]: await _game(extracted)
	for failure in failures: push_error(failure)
	if failures.is_empty(): print("INVENTORY_POUCH_OK types rotation stable_ids staged_capacity atomic_payment draft death extraction interrupt_restart responsive")
	quit(0 if failures.is_empty() else 1)

func _blueprint_geometry() -> void:
	var headers := ",".join(LootLifecycleTable.COLUMNS)
	var row := "test_blueprint,도면,blueprint,2,1,,0,false,테스트,persistent_asset,permanent_unlock,permanent_unlock,lost,0,ruined_city,true"
	var parsed := LootLifecycleTable.parse(headers + "\n" + row)
	check(parsed.errors.is_empty() and parsed.data[&"test_blueprint"].grid_size == Vector2i(2, 1), "blueprint uses Item grid dimensions")
	for invalid in ["0", "13", "1.5", ""]:
		check(not LootLifecycleTable.parse(headers + "\n" + row.replace("blueprint,2,1", "blueprint,%s,1" % invalid)).errors.is_empty(), "invalid blueprint width " + invalid)
	var provider := Lifecycle.new()
	provider.definition = parsed.data[&"test_blueprint"]
	root.add_child(provider)
	var bag := empty_bag()
	var adapter := FieldLootInventoryService.new()
	var gear := Gear.new()
	root.add_child(gear)
	adapter.configure(bag, gear, null, provider)
	var result := adapter.acquire(&"test_blueprint", 1)
	check(result.success and bag.items[result.instance_ids[0]].grid_size == Vector2i(2, 1), "physical blueprint keeps configured dimensions")
	bag.free()
	gear.free()
	provider.free()

func _geometry() -> void:
	var bag := empty_bag()
	for type in [&"weapon", &"armor", &"module", &"part", &"consumable"]:
		var id: StringName = bag.add_item(item(type))
		check(not bag.transfer_pouch(id, false) and bag.items.has(id), "forbidden type untouched " + String(type))
	var id: StringName = bag.add_item_with_payload(item(&"blueprint", Vector2i(2, 1)), {&"quality": 7}, Vector2i(4, 3))
	check(bag.transfer_pouch(id, false) and bag.rotate_pouch_item(id), "pouch transfer and rotation")
	check(bag.pouch[id].rotated and bag.pouch[id].runtime_payload.quality == 7, "original metadata preserved")
	var second: StringName = bag.add_item(item(&"core", Vector2i(1, 2)))
	check(bag.transfer_pouch(second, false), "fill exact four cells")
	var third: StringName = bag.add_item(item(&"artifact"))
	var before := signature(bag.export_runtime_state())
	check(not bag.transfer_pouch(third, false) and signature(bag.export_runtime_state()) == before, "full pouch atomic rejection")
	var malformed: Dictionary = bag.export_runtime_state()
	malformed.reserve[id] = malformed.pouch[id]
	check(not bag.restore_runtime_state(malformed), "cross-compartment duplicate rejected")
	check(bag.transfer_pouch(id, true) and bag.items.has(id) and bag.rotations[id], "withdraw same instance and rotation")
	var entry: Dictionary = bag.take_item_entry(id)
	check(bag.return_item_entry(id, entry) and not bag.return_item_entry(id, entry), "stable roundtrip cannot duplicate")
	var legacy: Dictionary = bag.export_runtime_state()
	legacy.erase(&"pouch")
	legacy.erase(&"pouch_size")
	check(bag.restore_runtime_state(legacy) and bag.pouch_size == Vector2i(2,2), "legacy save defaults")
	bag.free()

func _capacity() -> void:
	var bag := empty_bag()
	var profile := Profile.new()
	root.add_child(profile)
	profile.configure("", false)
	var service := Capacity.new()
	root.add_child(service)
	check(service.bind(bag, profile, func(): return true), "capacity binds")
	check(bag.grid_size == Vector2i(12,3) and bag.pouch_size == Vector2i(2,2), "base 36 and 4")
	check(not service.get_quote(&"backpack").available, "unapproved prices locked")
	var csv := FileAccess.get_file_as_string(InventoryCapacityCatalog.PATH)
	var fixture := csv.replace("false,pending", "true,provisional")
	check(service.catalog.load_csv(fixture), "test-only approved prices")
	var count: int = service.get_rows().size()
	check(not service.catalog.load_csv(fixture.replace("12,4,1000", "12,7,1000")) and service.get_rows().size() == count, "bad live rows preserve last good")
	var quote := service.get_quote(&"backpack")
	var stale := quote.duplicate(true)
	stale.credit_cost = 1
	check(not service.purchase(&"backpack", stale).success and profile.banked_credits == 5000, "stale quote no payment")
	check(service.purchase(&"backpack", quote).success and bag.grid_size == Vector2i(12,4) and profile.banked_credits == 4000, "atomic stage one purchase")
	check(not service.purchase(&"backpack", quote).success and profile.banked_credits == 4000, "repeat click no double payment")
	profile.banked_credits = 30000
	for rows in [5,6]:
		check(service.purchase(&"backpack", service.get_quote(&"backpack")).success and bag.grid_size.y == rows, "next stage %d" % rows)
	for rows in [3,4]:
		check(service.purchase(&"pouch", service.get_quote(&"pouch")).success and bag.pouch_size.y == rows, "pouch next stage %d" % rows)
	check(service.get_quote(&"backpack").is_empty() and service.get_quote(&"pouch").is_empty(), "max bounds")
	service.free()
	profile.free()
	bag.free()
	# A failed durable profile write cannot grant expansion or lose money.
	bag = empty_bag()
	profile = Profile.new()
	root.add_child(profile)
	var directory := OS.get_cache_dir().path_join("sfh-capacity-%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(directory)
	profile.configure(directory.path_join("profile.json"), true, true)
	var blocker := FileAccess.open(directory.path_join("blocked"), FileAccess.WRITE)
	blocker.store_string("test")
	blocker.close()
	profile.storage_path = directory.path_join("blocked/profile.json")
	service = Capacity.new()
	root.add_child(service)
	service.catalog.load_csv(fixture)
	service.bind(bag, profile, func(): return true)
	check(not service.purchase(&"backpack", service.get_quote(&"backpack")).success and profile.banked_credits == 5000 and bag.grid_size.y == 3 and not profile.is_unlocked(&"container_backpack_1"), "write failure rolls back payment and unlock")
	service.free()
	profile.free()
	bag.free()

func _persistence() -> void:
	var directory := OS.get_cache_dir().path_join("sfh-pouch-%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(directory)
	var path := directory.path_join("progress.json")
	var bag := empty_bag()
	var gear := Gear.new()
	root.add_child(gear)
	var progress := Progress.new()
	root.add_child(progress)
	check(progress.configure(path) and progress.bind_hub(bag, gear) and progress.begin_run(&"interrupted-pouch", {}), "native start checkpoint")
	progress.unbind_hub()
	var provider := ProtectedRun.new()
	provider.bag = bag
	provider.baseline = bag.export_runtime_state()
	root.add_child(provider)
	check(progress.bind_run_protection(provider), "bind run protection")
	var id: StringName = bag.add_item_with_payload(item(&"artifact"), {&"options": {&"identity": 73}})
	bag.transfer_pouch(id, false)
	provider.protected_inventory_changed.emit()
	check(progress.flush(), "native protected checkpoint")
	# Recreate the service from disk: interrupted run never extracts or restores free loot.
	progress.unbind_run_protection()
	progress.free()
	progress = Progress.new()
	root.add_child(progress)
	check(progress.configure(path) and progress.bind_hub(bag, gear), "restart native protection")
	check(bag.reserve.has(id) and bag.pouch.is_empty() and bag.items.is_empty() and bag.reserve[id].runtime_payload.options.identity == 73, "interrupted original preserved only in reserve")
	check(progress.document.history[0].outcome == "interrupted" and progress.document.extractions == 0, "no crash extraction")
	progress.free()
	provider.free()
	bag.free()
	gear.free()
	await process_frame

func frames() -> void:
	for i in 8: await process_frame

func _native_game() -> void:
	native_game = true
	var game: Node = load("res://game/scenes/game.tscn").instantiate()
	root.add_child(game)
	await frames()
	var settings: Resource = game.features.duplicate(true)
	check(game.desktop_progress.enabled, "actual game native enabled")
	for id in game.inventory_system.items.keys(): game.inventory_system.store_in_reserve(id)
	check(game.start_run("small"), "native actual launch")
	await frames()
	var definition := item(&"artifact")
	var id: StringName = game.inventory_system.add_item_with_payload(definition, {&"original": 91})
	check(game.inventory_system.transfer_pouch(id, false), "native actual protect")
	check(game.desktop_progress.flush(), "native game checkpoint")
	game._on_player_died()
	check(game.desktop_progress.document.pending_run.is_empty(), "native death completes run")
	game._return_to_start_hub()
	await frames()
	check(game.inventory_system.reserve.has(id), "native in-memory hub original")
	check(game.desktop_progress.flush(), "native hub flush")
	game.free()
	paused = false
	game = load("res://game/scenes/game.tscn").instantiate()
	game.features = settings
	root.add_child(game)
	await frames()
	check(game.inventory_system.reserve.has(id) and game.inventory_system.reserve[id].runtime_payload.original == 91, "actual scene restart original")
	check(game.equipment_system.install_module(&"main", &"abandon_test", load("res://game/features/equipment/definitions/modules/ballistic_core.tres")), "native abandon custom loadout fixture")
	check(game.start_run("small"), "native second launch")
	await frames()
	# Launch normalizes the character carrier; compare the committed launch checkpoint.
	var prepared_gear: Dictionary = Codec.new().decode(game.desktop_progress.document.loadout).gear
	id = game.inventory_system.add_item(definition)
	game.inventory_system.transfer_pouch(id, false)
	game._abandon_run_to_start_hub()
	await frames()
	check(game.inventory_system.reserve.has(id) and game.desktop_progress.document.pending_run.is_empty(), "abandon protection and native history finalized")
	check(game.equipment_system.get_equipment_state(&"main").installed_modules.size() == 1, "manual abandon preserves prior equipment policy")
	var saved: Dictionary = Codec.new().decode(game.desktop_progress.document.loadout)
	# Opening hub views lazily creates an empty character carrier from a legacy null.
	for key in prepared_gear:
		if key == &"character_module_state" and prepared_gear[key] == null:
			var carrier: Resource = saved.gear.get(key)
			check(carrier == null or (carrier.installed_modules.is_empty() and carrier.installed_parts.is_empty()), "empty character carrier normalization")
		else:
			check(signature(saved.gear.get(key)) == signature(prepared_gear[key]), "abandon native gear retained " + String(key))
	check(game.desktop_progress.document.extractions == 0, "abandon has no extraction award")
	game.free()
	paused = false
	native_game = false

func click(button: Button) -> void:
	await frames()
	check(root.get_visible_rect().encloses(button.get_global_rect()), "UI action visible")
	var motion := InputEventMouseMotion.new()
	motion.position = button.get_global_rect().get_center()
	Input.parse_input_event(motion)
	await process_frame
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = motion.position
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame
	await frames()

func _game(extracted: bool) -> void:
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(1280,800)
	var game: Node = load("res://game/scenes/game.tscn").instantiate()
	root.add_child(game)
	await frames()
	# Empty test bag through its normal hub storage, not by changing capacity rules.
	for id in game.inventory_system.items.keys(): game.inventory_system.store_in_reserve(id)
	check(game.start_run("small"), "real launch with tiered bag")
	await frames()
	var loot: Node = game.field_loot_acquisition_service
	var bag: Node = game.inventory_system
	for item_id in [&"arc_rune", &"arc_rune", &"arc_rune", &"tactical_vest_blueprint"]:
		var drop: Node2D = loot.spawn_candidate(game.player.global_position, {&"item_id":item_id, &"grade":3, &"quantity":1, &"source_type":&"room_reward"})
		check(drop != null, "drop exists")
		if drop == null: continue
		drop.call(&"_process", 0.0)
		for pressed in [true,false]:
			var event := InputEventKey.new()
			event.physical_keycode = KEY_F
			event.keycode = KEY_F
			event.pressed = pressed
			Input.parse_input_event(event)
			await process_frame
		check(not is_instance_valid(drop), "physical F acquires")
	var rune_id: StringName = game.session_socket_service.inventory_adapter.first_owned(&"arc_rune")
	check(rune_id != &"", "overflow rune physical")
	var blueprint_id: StringName = &""
	for id in bag.items:
		if bag.items[id].item_type == &"blueprint": blueprint_id = id
	check(blueprint_id != &"", "blueprint now physical")
	var window: Control = game.inventory_window
	window.open_panel()
	await frames()
	window._on_item_selected(window.session.get_item_entry(rune_id))
	await click(window.pouch_panel.toggle)
	await click(window.pouch_panel.store_button)
	check(window.session.dirty and bag.items.has(rune_id), "pouch edit remains draft")
	window.close_panel()
	window.resolve_exit(&"discard")
	check(bag.items.has(rune_id) and bag.pouch.is_empty(), "discard protects nothing")
	window.open_panel()
	window._on_item_selected(window.session.get_item_entry(rune_id))
	await click(window.pouch_panel.store_button)
	window.close_panel()
	window.resolve_exit(&"save")
	check(bag.pouch.has(rune_id) and not bag.items.has(rune_id), "UI save moves original")
	check(bag.transfer_pouch(blueprint_id, false), "protect actual blueprint")
	window.open_panel()
	for dimensions in [Vector2i(1280,800),Vector2i(844,390),Vector2i(390,844)]:
		root.size = dimensions
		await frames()
		check(root.get_visible_rect().grow(1).encloses(window.get_global_rect()), "pouch screen fits " + str(dimensions))
		check(window.pouch_panel.body.visible, "pouch expanded")
		if "--render" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://build/qa-pouch-%dx%d.png" % [dimensions.x, dimensions.y])
	window.close_panel()
	var count: int = bag.reserve.size()
	var wallet: int = game.persistent_profile.banked_credits
	var result: Dictionary = game._settle_run_loot(extracted)
	check(result.success, "normal settlement")
	if extracted:
		check(result.converted_credits == 180 and result.permanent_unlocks.has(&"tactical_vest_blueprint"), "protected items normal successful settlement")
	else:
		check(result.lost_items.get(&"arc_rune", 0) == 2 and not result.lost_items.has(&"tactical_vest_blueprint") and result.protected_count == 2, "only unprotected copies lost")
		check("보호 주머니 2개" in game._format_run_loot_settlement(result), "player receives protection notice")
	var repeat: Dictionary = game._settle_run_loot(extracted)
	check(repeat.duplicate_ignored and game.persistent_profile.banked_credits == wallet + (180 if extracted else 0), "settlement idempotent")
	game.lose_equipped_loadout_on_return = not extracted
	game._return_to_start_hub()
	await frames()
	bag = game.inventory_system
	check(bag.reserve.size() == count + (0 if extracted else 2), "hub return original count")
	check(bag.pouch.is_empty() and not bag.items.has(rune_id), "no restored duplicate after settlement")
	if not extracted:
		check(bag.reserve.has(rune_id) and bag.reserve.has(blueprint_id), "actual death return retains both original IDs")
		bag.retrieve_from_reserve(rune_id)
		bag.transfer_pouch(rune_id, false)
		check(game.start_run("small"), "bring protected original into next run")
		await frames()
		bag = game.inventory_system
		check(bag.transfer_pouch(rune_id, true), "withdraw original in second run")
		check(game.session_socket_service.socket_owned_item(&"arc_rune", {}, rune_id).success, "socket carried original")
		check(game.session_socket_service.unsocket(&"rune", 0).success and bag.items.has(rune_id), "socket roundtrip retains identity")
		bag.transfer_pouch(rune_id, false)
		var next: Dictionary = game._settle_run_loot(true)
		check(next.converted_credits == 60, "brought original converts exactly once next extraction")
		game._return_to_start_hub()
		await frames()
		check(not game.inventory_system.reserve.has(rune_id) and not game.inventory_system.pouch.has(rune_id), "no permanent copy after normal conversion")
	game.free()
	paused = false
