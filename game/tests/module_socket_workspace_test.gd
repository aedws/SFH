extends SceneTree
var failures := PackedStringArray()
var isolation: RefCounted

class ExtendedModuleBalance extends Node:
	func get_maximum_level(_kind, _id, _fallback) -> int: return 4
	func get_module_capacity_cost(_id, level, _fallback) -> int: return 1 if level == 4 else 8

func _init() -> void:
	isolation = preload("res://game/tests/support/save_test_isolation.gd").new()
	node_added.connect(isolation.isolate)
	_run.call_deferred()

func _run() -> void:
	var weapon: Resource = load("res://game/features/equipment/definitions/weapons/assault_rifle.tres").duplicate(true)
	weapon.module_cost_limit = 20
	var state := EquipmentItemState.new()
	state.configure(&"main", weapon)
	var a := EquipmentModuleDefinition.new()
	a.module_id = &"fixture_a"
	a.display_name = "시험 모듈 A"
	a.module_tags = [&"electric"]
	a.cost_by_upgrade_level = PackedInt32Array([5, 3])
	var b: EquipmentModuleDefinition = a.duplicate(true)
	b.module_id = &"fixture_b"
	_check(not state.assign_module_socket(0, &"electric"), "max level required")
	state.level = state.maximum_level()
	_check(state.assign_module_socket(0, &"electric"), "socket assigned at max")
	_check(state.install_module(&"a", a, 1, {}, 0) and state.install_module(&"b", b, 1, {}, 1), "specific slots")
	_check(state.used_module_cost() == 8, "matching 5 rounds up to 3; other slot remains 5")
	_check(state.upgrade_module(&"a") and state.used_module_cost() == 7, "upgrade cost then socket discount")
	_check(state.assign_module_socket(0, &"other") and state.used_module_cost() == 8, "mismatch neutral")
	state.remove_module(&"a")
	_check(state.module_at_socket(1).instance_id == &"b" and state.module_at_socket(0) == null, "remove preserves physical slots")
	_check(not state.install_module(&"a", a, 1, {}, 1), "occupied socket rejected")
	var armor := EquipmentArmorDefinition.new()
	armor.module_cost_limit = 3
	armor.module_slot_limit = 2
	var armor_state := EquipmentItemState.new()
	armor_state.configure(&"body", armor)
	_check(not armor_state.can_install_module(a, 1, 0) and armor_state.can_install_module(a, 2, 0), "actual upgrade cost controls armor capacity")
	_check(not armor_state.assign_module_socket(0, &"electric"), "armor max level gate")
	armor_state.level = armor_state.maximum_level()
	_check(armor_state.assign_module_socket(0, &"electric") and armor_state.install_module(&"armor_a", a, 1, {}, 0), "armor matching slot fits capacity")
	_check(not armor_state.assign_module_socket(0, &"other") and armor_state.used_module_cost() == 3, "socket change over capacity rolls back")
	var invalid_policy := ModuleSocketPolicy.new()
	invalid_policy.matching_cost_multiplier = -1.0
	_check(not invalid_policy.is_valid(), "invalid policy rejected")
	var extended_balance := ExtendedModuleBalance.new()
	var extended := EquipmentItemState.new()
	extended.configure(&"character", CharacterModuleDefinition.new())
	extended.set_upgrade_balance_provider(extended_balance)
	_check(extended.install_module(&"extended", a, 4, {}, 0), "extended balance install")
	_check(extended.installed_modules[0].upgrade_level == 4 and extended.used_module_cost() == 1, "balance maximum and cost preserved beyond resource fallback")
	_check(extended.validation_errors().is_empty(), "extended balance validates")
	extended_balance.free()
	var old := EquipmentItemState.new()
	old.configure(&"main", weapon)
	old.granted_module_tags = [&"electric"]
	var legacy := EquipmentModuleInstance.new()
	legacy.configure(&"legacy", a)
	old.installed_modules.append(legacy)
	_check(old.used_module_cost() == 3 and old.module_at_socket(0) == legacy, "legacy discount and implicit slot retained")
	var codec = preload("res://game/features/local_save/loadout_value_codec.gd").new()
	var encoded = codec.encode(state)
	var restored = codec.decode(encoded)
	_check(codec.error.is_empty() and restored.used_module_cost() == state.used_module_cost() and restored.module_at_socket(1) != null, "native value codec roundtrip")
	var game = load("res://game/scenes/game.tscn").instantiate()
	root.add_child(game)
	await _frames()
	var gear: Node = game.equipment_system
	gear.set_external_character_level(40)
	var carrier = gear.get_equipment_state(&"character")
	_check(carrier.level == carrier.maximum_level() and not carrier.is_armor() and not carrier.is_weapon(), "separate external-level carrier")
	var original: Dictionary = gear.get_stat_modifiers()
	var window: Control = game.inventory_window
	window.open_modules(&"character")
	await _frames()
	var board: Control = window.module_workspace
	_check(board.visible and board.target == &"character" and board.targets.item_count == 7, "weapon two + armor four + character module targets")
	var module_id := &""
	for entry in window.session.inventory.get_snapshot()[&"items"]:
		if entry.get(&"linked_resource") is EquipmentModuleDefinition:
			module_id = entry[&"instance_id"]
			break
	_check(module_id != &"", "owned module fixture exists")
	var definition: Resource = window.session.get_item_entry(module_id).get(&"linked_resource")
	_check(window.session.assign_module_socket(&"character", 0, definition.module_tags[0]), "character draft socket")
	_check(window.session.install_module_in_socket(module_id, &"character", 0), "character draft install")
	_check(gear.get_stat_modifiers() == original and carrier.installed_modules.is_empty(), "preview does not mutate player")
	window.close_panel()
	_check(window.confirmation_visible, "ESC departure guarded")
	window.resolve_exit(&"cancel")
	_check(window.visible and window.session.dirty, "continue preserves draft")
	window.close_panel()
	window.resolve_exit(&"save")
	_check(gear.get_equipment_state(&"character").installed_modules.size() == 1 and not window.visible, "saved character install")
	_check(gear.get_stat_modifiers() != original, "character module affects actual player modifier source")
	var save: Dictionary = gear.export_runtime_state()
	var save_codec = preload("res://game/features/local_save/loadout_value_codec.gd").new()
	var decoded: Dictionary = save_codec.decode(save_codec.encode(save))
	_check(save_codec.error.is_empty() and gear.restore_runtime_state(decoded), "whole gear and character persisted")
	window.open_modules(&"main")
	await _frames()
	for dimensions in [Vector2i(1280,720), Vector2i(1050,720), Vector2i(844,600), Vector2i(640,720)]:
		root.content_scale_size = dimensions
		await _frames()
		_check(board.size.x <= window.size.x and board.installed.columns >= 1, "responsive board width %s" % dimensions)
		for child in board.installed.get_children():
			_check(child.size.x >= 104 and child.size.y >= 142, "readable card hit area")
	window.close_panel()
	game.queue_free()
	await _frames()
	if failures.is_empty():
		print("MODULE_SOCKET_WORKSPACE_OK max_gate slot_matching rounding upgrade legacy persistence character_stats draft_guard three_kinds four_widths")
		quit(0)
	else:
		for message in failures: push_error(message)
		quit(1)

func _frames() -> void:
	for frame in 8: await process_frame

func _check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
