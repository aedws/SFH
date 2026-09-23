extends SceneTree

const GAME = preload("res://game/scenes/game.tscn")
const REGEN = preload("res://game/features/combat_resources/energy_regeneration_policy.gd")
var failures := PackedStringArray()
var isolation: RefCounted

class Actor extends Node2D:
	func heal(_amount: float, _source: StringName = &"") -> void: pass
	func get_health_snapshot() -> Dictionary: return {&"current": 100.0}


func _init() -> void:
	isolation = preload("res://game/tests/support/save_test_isolation.gd").new()
	node_added.connect(isolation.isolate)
	_run.call_deferred()


func _run() -> void:
	_test_ap()
	var game = GAME.instantiate()
	root.add_child(game)
	for frame in 5: await process_frame
	_check(is_instance_valid(game.start_hub), "hub assembled")
	var training: Node = game.training_ground_service
	var sockets: Node = training.socket_provider
	var skills: Node = game.training_combat_skill_system
	var weapon: Node = game.auto_weapon
	var bag: Node = game.inventory_system
	for id in bag.items.keys(): bag.store_in_reserve(id)
	_check(training.get_loadout_snapshot().socket_catalog.is_empty(), "unowned hidden")
	game._cycle_hub_training()
	_check(not training.toggle_training_socket(&"arc_rune").success, "unowned cannot trial")
	var original_bag: Dictionary = bag.export_runtime_state()
	var base_damage := float(weapon.get_runtime_snapshot().damage)
	var base_skills: Array = skills.get_skill_states()
	_check(sockets.socket_item(&"arc_rune").success, "rune binds active weapon")
	_check(is_equal_approx(weapon.get_runtime_snapshot().damage, base_damage * 1.15), "bound weapon gains damage")
	game.equipment_system.switch_active_weapon()
	var other_damage := float(weapon.get_runtime_snapshot().damage)
	weapon.remove_runtime_modifiers(&"session_sockets")
	_check(is_equal_approx(other_damage, weapon.get_runtime_snapshot().damage), "Q swap has no leaked bonus")
	# Restore through public value contract, not private effect methods.
	_check(sockets.restore_runtime_state(sockets.export_runtime_state()), "scope restoration")
	game.equipment_system.switch_active_weapon()
	_check(is_equal_approx(weapon.get_runtime_snapshot().damage, base_damage * 1.15), "Q back retains binding")
	var target_id := StringName(base_skills[1].skill_id)
	_check(sockets.socket_item(&"capacitor_core", {&"skill": target_id}).success, "explicit target skill")
	var modified: Array = skills.get_skill_states()
	for index in modified.size():
		var expected := float(base_skills[index].cooldown_seconds) * (0.85 if index == 1 else 1.0)
		_check(is_equal_approx(modified[index].cooldown_seconds, expected), "skill scope %d" % index)
	var invalid: Dictionary = sockets.export_runtime_state()
	invalid.equipped[&"core"][0].bindings.clear()
	_check(not sockets.restore_runtime_state(invalid), "unbound state fails closed")
	_check(not sockets.socket_item(&"phase_artifact", {&"player": &"unknown"}).success, "invalid target rejected")
	var before_live: Dictionary = sockets.export_runtime_state()
	var csv := FileAccess.get_file_as_string("res://game/features/session_sockets/data/session_socket_rules.csv")
	_check(not sockets.load_csv_text(csv.replace("capacitor_core_cycle,capacitor_core", "capacitor_core_cycle,missing_core"), "invalid live"), "destructive live catalog rejected")
	_check(sockets.export_runtime_state() == before_live, "live rejection preserves bindings")
	# Fill the bag: release must not delete an item or its effect.
	var filler := InventoryItemDefinition.new()
	filler.item_id = &"fixture"
	filler.item_type = &"consumable"
	filler.display_name = "Fixture"
	while bag.add_item(filler) != &"": pass
	_check(not sockets.unsocket(&"rune", 0).success, "full bag keeps socket")
	_check(sockets.get_snapshot().installed_count == 2, "no deletion on full bag")
	_check(not sockets.acquire_items(&"arc_rune", 2).success, "full bag duplicate grant fails")
	_check(sockets.get_snapshot().installed_count == 2, "grant rollback keeps original")
	bag.restore_runtime_state(original_bag)
	_check(sockets.unsocket(&"rune", 0).success, "release returns to bag")
	_check(bag.get_items_by_type(&"rune").size() == 1, "one real returned item")
	_check(sockets.get_owned_catalog_items().size() == 2, "owned includes bag and installed")
	# Real inventory action cannot bypass pending edits or lose the item on cancel.
	game.inventory_window.open_panel()
	var entry: Dictionary = bag.get_items_by_type(&"rune")[0]
	game.inventory_window._on_item_selected(entry)
	_check(not game.inventory_window.action_button.disabled, "returned rune usable through I")
	game.inventory_window.session.dirty = true
	game.inventory_window.action_button.pressed.emit()
	_check(game.inventory_window.confirmation_visible, "runtime action respects dirty draft")
	game.inventory_window.resolve_exit(&"cancel")
	_check(bag.get_items_by_type(&"rune").size() == 1, "cancel does not consume")
	game.inventory_window.action_button.pressed.emit()
	game.inventory_window.resolve_exit(&"discard")
	_check(bag.get_items_by_type(&"rune").is_empty(), "I action resockets returned asset")
	game.inventory_window.close_panel()
	_check(game._finish_hub_training(), "training finish")
	_check(sockets.get_snapshot().installed_count == 0, "trial sockets cleared")
	var codec := preload("res://game/features/local_save/loadout_value_codec.gd").new()
	_check(codec.encode(bag.export_runtime_state()) == codec.encode(original_bag), "trial grants and bag edits restored")
	game.queue_free()
	for frame in 3: await process_frame
	if failures.is_empty():
		print("PROVISIONAL_POLICY_OK ap_delay_frame_partition_restore scoped_weapon_q scoped_skill owned_training bag_full_atomic inventory_action_cancel restore live_rejection")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)


func _test_ap() -> void:
	var actor := Actor.new()
	root.add_child(actor)
	var resources = load("res://game/features/combat_resources/combat_resource_system.tscn").instantiate()
	root.add_child(resources)
	resources.set_process(false)
	var config = load("res://game/features/combat_resources/configs/default_combat_resources.tres").duplicate(true)
	var loadout = load("res://game/features/combat_skills/configs/default_combat_skills.tres")
	_check(resources.configure(actor, actor, loadout, config), "AP configuration")
	_check(resources.consume_for_skill(0), "AP spend")
	resources.advance(0.75)
	_check(is_equal_approx(resources.current_energy, 80), "AP delay")
	resources.advance(0.5)
	_check(is_equal_approx(resources.current_energy, 82.5), "partial frame after delay")
	var saved: Dictionary = resources.export_runtime_state()
	resources.advance(100.0)
	_check(is_equal_approx(resources.current_energy, 100), "AP capped")
	_check(resources.restore_runtime_state(saved), "AP restore accepted")
	_check(resources.export_runtime_state() == saved, "AP timer and charge restore exact")
	resources.advance(NAN)
	_check(resources.export_runtime_state() == saved, "invalid delta rejected")
	saved.regeneration_idle_seconds = -1.0
	_check(not resources.restore_runtime_state(saved), "invalid timer rejected")
	config.regeneration_policy.enabled = false
	resources.advance(1.0)
	_check(is_equal_approx(resources.current_energy, 82.5), "policy disabled independently")
	config.regeneration_policy = REGEN.new()
	config.regeneration_policy.energy_per_second = 3.0
	resources.advance(1.0)
	_check(is_equal_approx(resources.current_energy, 85.5), "policy replaced without service rewrite")
	var partition := REGEN.new()
	_check(is_equal_approx(partition.recovered_amount(0.0, 1.25), partition.recovered_amount(0.0, 0.75) + partition.recovered_amount(0.75, 0.5)), "frame partition invariant")
	resources.free()
	actor.free()


func _check(value: bool, message: String) -> void:
	if not value: failures.append(message)
