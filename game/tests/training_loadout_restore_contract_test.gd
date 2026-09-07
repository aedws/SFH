extends SceneTree

const LOADOUT = preload("res://game/features/training_ground/training_loadout_service.gd")
const CODEC = preload("res://game/features/local_save/loadout_value_codec.gd")
var failures := PackedStringArray()

class StateProvider extends Node:
	var value := 1
	var fail_once := false
	func export_runtime_state() -> Dictionary:
		return {&"value": value}
	func validate_runtime_state(_state: Dictionary) -> PackedStringArray:
		return PackedStringArray()
	func restore_runtime_state(state: Dictionary) -> bool:
		value = int(state.value)
		if fail_once:
			fail_once = false
			return false
		return true

class CheckpointProvider extends Node:
	var held := false
	var fail_once := true
	func begin_temporary_loadout() -> bool:
		held = true
		return true
	func end_temporary_loadout() -> bool:
		if fail_once:
			fail_once = false
			return false
		held = false
		return true

func _init() -> void:
	call_deferred(&"_run")

func _run() -> void:
	var bag := StateProvider.new()
	var gear := StateProvider.new()
	var future := StateProvider.new()
	for node in [bag, gear, future]: root.add_child(node)
	var transaction := LOADOUT.new()
	_check(transaction.configure(gear, bag), "configure")
	_check(transaction.register_runtime_provider(&"future", future), "future participant")
	_check(transaction.begin_session(), "capture all participants")
	_check(not transaction.register_runtime_provider(&"late", future), "active registration rejected")
	bag.value = 9
	gear.value = 9
	future.value = 9
	gear.fail_once = true
	_check(not transaction.restore_and_finish(), "injected mid-restore failure")
	_check(transaction.active and transaction.session_snapshot != null, "original retained for retry")
	_check(not transaction.begin_session() and not transaction.get_snapshot().free_editing, "failed restore blocks new trial")
	_check(bag.value == 9 and gear.value == 9 and future.value == 9, "partial restore rolled back")
	_check(transaction.restore_and_finish(), "retry succeeds")
	_check(bag.value == 1 and gear.value == 1 and future.value == 1, "all original values restored")
	_check(not transaction.restore_and_finish() and bag.value == 1, "repeated finish cannot replay changes")
	var checkpoint := CheckpointProvider.new()
	root.add_child(checkpoint)
	_check(transaction.configure_checkpoint_provider(checkpoint) and transaction.begin_session(), "checkpoint acquired")
	bag.value = 8
	_check(not transaction.restore_and_finish() and transaction.active and checkpoint.held, "checkpoint failure retains original")
	_check(transaction.restore_and_finish() and not checkpoint.held and bag.value == 1, "checkpoint retry safe")
	checkpoint.free()
	for node in [bag, gear, future]: node.free()

	var game = load("res://game/scenes/game.tscn").instantiate()
	var features: Resource = game.features.duplicate(true)
	var test_root := OS.get_cache_dir().path_join("sfh-training-contract-%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(test_root)
	for field in ["persistent_profile", "conditional_ranking", "meta_progression", "key_mapping", "skill_binding", "presentation_settings", "desktop_progress"]:
		features.set(field + "_storage_path", test_root.path_join(field + ".json"))
	game.features = features
	root.add_child(game)
	for frame in 6: await process_frame
	var service: Node = game.training_ground_service
	var skills: Node = game.training_combat_skill_system
	_check(game.skill_binding_service.assign_skill(&"blink", &"combat_skill_9").success, "user remapped key")
	var original_bindings: Dictionary = game.skill_binding_service.get_snapshot()
	var saved_gear: Variant = _encoded(game.equipment_system)
	var saved_bag: Variant = _encoded(game.inventory_system)
	var saved_skills := _skill_ids(skills)
	var saved_credits: int = game.persistent_profile.call(&"get_snapshot").get(&"credits", -1)
	_check(not service.call(&"cycle_training_skill", 0).success, "inactive skill edits rejected")
	_check(not skills.call(&"try_activate", 0), "inactive skill input rejected")
	game.call(&"_cycle_hub_training")
	await process_frame
	_check(game.desktop_progress.get_snapshot().temporary_loadout, "native checkpoint suspended")
	# Inspect real child button bounds, not only the outer panel.
	var original_size := root.content_scale_size
	for dimensions in [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.content_scale_size = dimensions
		for frame in 3: await process_frame
		var layout: Dictionary = game.training_hud_layout.get_snapshot()
		_check(layout.all_inside_viewport and layout.panels_do_not_overlap, "responsive training HUD %s" % dimensions)
		var presenter: Control = game.training_loadout_presenter
		for control in presenter.skill_buttons + [presenter.socket_choice, presenter.socket_button, presenter.finish_button]:
			_check(presenter.get_global_rect().grow(1).encloses(control.get_global_rect()), "button inside panel %s" % dimensions)
	root.content_scale_size = original_size
	for frame in 3: await process_frame
	var stored_before: Variant = game.desktop_progress.document.loadout.duplicate(true)
	game.equipment_system.call(&"take_equipment_state", &"secondary")
	var changed_skill := false
	for index in saved_skills.size():
		service.call(&"cycle_training_skill", index)
		changed_skill = changed_skill or _skill_ids(skills) != saved_skills
	_check(changed_skill, "compatible skill changed")
	var assigned_actions: Array = []
	for index in saved_skills.size():
		var current_id := StringName(_skill_ids(skills)[index])
		var action: StringName = skills.binding_provider.action_for_skill(current_id)
		_check(action == game.skill_binding_service.action_for_skill(StringName(saved_skills[index])), "replacement inherits original remapped action")
		_check(action not in assigned_actions, "no duplicate trial skill actions")
		assigned_actions.append(action)
	var fired: Array = []
	skills.skill_activated.connect(func(index, id, _result): fired.append([index, id]))
	var key_event := InputEventAction.new()
	key_event.action = assigned_actions[0]
	key_event.pressed = true
	Input.parse_input_event(key_event)
	await process_frame
	key_event.pressed = false
	Input.parse_input_event(key_event)
	_check(not fired.is_empty() and fired[0][0] == 0 and fired[0][1] == StringName(_skill_ids(skills)[0]), "actual remapped input fires replacement")
	var catalog: Array = service.call(&"get_loadout_snapshot").socket_catalog
	_check(not catalog.is_empty(), "existing RunAsset catalog exposed")
	for entry in catalog:
		_check(service.call(&"toggle_training_socket", entry.item_id).success, "free socket %s" % entry.item_id)
	_check(service.call(&"get_loadout_snapshot").sockets.installed_count == catalog.size(), "socket effects installed")
	_check(game.desktop_progress.flush(), "save during training succeeds with original checkpoint")
	_check(game.desktop_progress.document.loadout == stored_before, "temporary gear not persisted")
	_check(not game.desktop_progress.begin_run(&"unsafe", {}), "save boundary blocks unfinished training launch")
	# The real button command cancels training, and repeated entry starts from original.
	game.training_loadout_presenter.finish_button.pressed.emit()
	_check(not service.call(&"get_loadout_snapshot").active, "finish UI closes training")
	_check(_encoded(game.equipment_system) == saved_gear and _encoded(game.inventory_system) == saved_bag, "gear/bag exact value restore")
	_check(_skill_ids(skills) == saved_skills, "skills restored without leaving hub")
	_check(game.skill_binding_service.get_snapshot() == original_bindings, "permanent skill bindings untouched")
	_check(service.call(&"get_loadout_snapshot").sockets.installed_count == 0, "all temporary sockets cleared")
	_check(not game.desktop_progress.get_snapshot().temporary_loadout, "checkpoint resumed after restore")
	_check(game.persistent_profile.call(&"get_snapshot").get(&"credits", -1) == saved_credits, "no credit charge")
	game.call(&"_cycle_hub_training")
	# Active lasting skill effects and AP/charges must not survive finishing.
	var resource_baseline: Dictionary = game.training_combat_resource_system.export_runtime_state()
	_check(skills.try_activate(2), "speed effect activation")
	_check(not skills.owned_effects.is_empty(), "lasting effect registered")
	_check(game.call(&"_finish_hub_training"), "finish lasting effect")
	_check(skills.owned_effects.is_empty(), "lasting effect cancelled")
	_check(game.training_combat_resource_system.export_runtime_state() == resource_baseline, "AP charges restored")
	game.call(&"_cycle_hub_training")
	await process_frame
	_check(_skill_ids(skills) == saved_skills, "reentry skill baseline")
	# A dirty inventory exit cancellation must keep the training session alive.
	game.inventory_window.open_panel()
	await process_frame
	game.inventory_window.session.dirty = true
	game.call(&"_open_run_setup")
	_check(game.inventory_window.confirmation_visible, "pending draft exit confirmation")
	game.inventory_window.resolve_exit(&"cancel")
	_check(service.call(&"get_loadout_snapshot").active, "cancel keeps training and original snapshot")
	game.inventory_window.close_panel()
	game.inventory_window.resolve_exit(&"discard")
	game.call(&"_open_run_setup")
	_check(game.run_setup_overlay.visible and not service.call(&"get_loadout_snapshot").active, "gate restores before briefing")
	game.call(&"_close_run_setup")
	_check(_encoded(game.equipment_system) == saved_gear, "briefing cancel preserves original")
	game.call(&"_cycle_hub_training")
	game.equipment_system.call(&"take_equipment_state", &"secondary")
	game.call(&"_on_hub_service_requested", &"shop")
	_check(not service.get_loadout_snapshot().active and _encoded(game.equipment_system) == saved_gear, "shop restores before economic actions")
	game.shop_browser_panel.close_panel()
	game.call(&"_cycle_hub_training")
	game.equipment_system.call(&"take_equipment_state", &"secondary")
	# Force a safe scenario reset failure without modifying production data.
	service.reset_service.active_definition = null
	_check(not service.reset_active_scenario().success, "injected reset failure")
	_check(not service.get_loadout_snapshot().active and _encoded(game.equipment_system) == saved_gear, "reset failure restores")
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("TRAINING_LOADOUT_RESTORE_OK participants rollback_retry checkpoint_retry skill_restore free_sockets checkpoint_guard repeat_entry ui_stop cancel_gate no_credit_charge hud_3_sizes effect_cleanup resources_restore shop_gate reset_failure remapped_input binding_isolation")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)

func _encoded(provider: Node) -> Variant:
	return CODEC.new().encode(provider.call(&"export_runtime_state"))

func _skill_ids(provider: Node) -> PackedStringArray:
	var result := PackedStringArray()
	for state in provider.call(&"get_skill_states"): result.append(String(state.skill_id))
	return result

func _check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
