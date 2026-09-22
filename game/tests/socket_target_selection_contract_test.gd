extends SceneTree

const GAME = preload("res://game/scenes/game.tscn")
var failures := PackedStringArray()
var isolation: RefCounted


func _init() -> void:
	isolation = preload("res://game/tests/support/save_test_isolation.gd").new()
	node_added.connect(isolation.isolate)
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1280, 800)
	var game = GAME.instantiate()
	root.add_child(game)
	for frame in 5: await process_frame
	var original_bag: Dictionary = game.inventory_system.export_runtime_state()
	game._cycle_hub_training()
	var training: Node = game.training_ground_service
	var sockets: Node = training.socket_provider
	var skills: Node = game.training_combat_skill_system
	var bag: Node = game.inventory_system
	var window: GridInventoryWindow = game.inventory_window
	var base: Array = skills.get_skill_states()
	var groups: Array = training.get_inventory_action_targets(&"capacitor_core")
	_check(groups.size() == 1 and groups[0].candidates.size() == base.size(), "live equipped skill candidates")
	groups[0].candidates.clear()
	_check(training.get_inventory_action_targets(&"capacitor_core")[0].candidates.size() == base.size(), "candidate snapshot is detached")
	var core := InventoryItemDefinition.new()
	core.item_id = &"capacitor_core"
	core.display_name = "축전 코어"
	core.item_type = &"core"
	core.grid_size = Vector2i.ONE
	var first_id: StringName = bag.add_item(core)
	var second_id: StringName = bag.add_item(core)
	window.open_panel()
	window._on_item_selected(window.session.get_item_entry(second_id))
	_check(window.runtime_target_picker.visible and window.action_button.disabled, "multiple skill targets require explicit choice")
	var before: Dictionary = bag.export_runtime_state()
	window._apply_selection()
	_check(bag.export_runtime_state() == before and sockets.get_snapshot().installed_count == 0, "missing selection cannot consume")
	var picker: OptionButton = window.runtime_target_picker.choices[&"skill"]
	picker.select(2)
	picker.item_selected.emit(2)
	var chosen := StringName(base[1].skill_id)
	_check(window.runtime_target_picker.get_selection().get(&"skill") == chosen and not window.action_button.disabled, "second skill selected in UI")
	_check("먼저 선택" not in window.status_label.text, "choice clears prior validation message")
	if "--render" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		for frame in 8: await process_frame
		await RenderingServer.frame_post_draw
		_check(root.get_visible_rect().encloses(window.get_global_rect()), "rendered inventory inside viewport")
		_check(window.detail_column.get_global_rect().encloses(picker.get_global_rect()), "target picker fits inspection column")
		root.get_texture().get_image().save_png("res://build/qa-socket-target-ui.png")
	window.session.dirty = true
	window.action_button.pressed.emit()
	_check(window.confirmation_visible, "draft confirmation before runtime action")
	window.resolve_exit(&"cancel")
	_check(bag.export_runtime_state() == before and sockets.get_snapshot().installed_count == 0, "cancel preserves bag and sockets")
	_check(window.runtime_target_picker.get_selection().get(&"skill") == chosen, "cancel keeps explicit selection")
	window.action_button.pressed.emit()
	window.resolve_exit(&"discard")
	_check(bag.get_snapshot().items.any(func(entry): return entry.instance_id == first_id), "first identical core retained")
	_check(not bag.get_snapshot().items.any(func(entry): return entry.instance_id == second_id), "only selected core consumed")
	_check(sockets.get_snapshot().slots[&"core"][0].bindings[&"skill"].target_id == chosen, "save continuation preserves target")
	for index in base.size():
		var expected := float(base[index].cooldown_seconds) * (0.85 if index == 1 else 1.0)
		_check(is_equal_approx(skills.get_skill_states()[index].cooldown_seconds, expected), "actual cooldown applies only to selected skill %d" % index)
	_check(not window.runtime_target_picker.visible, "picker hidden after consumption")
	_check(sockets.unsocket(&"core", 0).success, "core returns to bag")
	var released: Dictionary = sockets.export_runtime_state()
	before = bag.export_runtime_state()
	_check(not training.perform_targeted_inventory_item_action(&"capacitor_core", {&"skill": &"removed_skill"}, first_id).success, "stale skill rejected")
	_check(not training.perform_targeted_inventory_item_action(&"capacitor_core", {}, first_id).success, "missing kind has no default fallback")
	_check(not training.perform_targeted_inventory_item_action(&"capacitor_core", {&"skill": chosen}, &"missing_instance").success, "missing selected item cannot consume identical item")
	_check(bag.export_runtime_state() == before and sockets.export_runtime_state() == released, "failed commands preserve both providers")
	# A Q/equipment switch while confirmation is open invalidates the captured weapon.
	var rune := core.duplicate()
	rune.item_id = &"arc_rune"
	rune.item_type = &"rune"
	rune.display_name = "전도 룬"
	var rune_id: StringName = bag.add_item(rune)
	window.session.begin()
	window._bind_draft()
	window._on_item_selected(window.session.get_item_entry(rune_id))
	_check(not window.action_button.disabled, "single current weapon is shown and selectable")
	window.session.dirty = true
	window.action_button.pressed.emit()
	game.equipment_system.switch_active_weapon()
	window.resolve_exit(&"discard")
	_check(sockets.get_snapshot().installed_count == 0, "changed weapon does not get fallback effect")
	_check(bag.get_snapshot().items.any(func(entry): return entry.instance_id == rune_id), "changed weapon keeps rune")
	_check("대상이 변경" in window.status_label.text, "stale target has actionable feedback")
	# A live rule changing effect kind cannot reinterpret an old selection.
	var csv := FileAccess.get_file_as_string("res://game/features/session_sockets/data/session_socket_rules.csv")
	_check(sockets.load_csv_text(csv.replace("replace_oldest,skill,cooldown_multiply", "replace_oldest,weapon,cooldown_multiply"), "test live"), "uninstalled catalog can change")
	before = bag.export_runtime_state()
	_check(not training.perform_targeted_inventory_item_action(&"capacitor_core", {&"skill": chosen}, first_id).success, "changed effect kind rejected")
	_check(bag.export_runtime_state() == before, "catalog change cannot spend core")
	_check(sockets.load_csv_text(csv, "locked restored"), "restore catalog")
	# Responsive picker, detached selection, and close ordering are view contracts.
	window._on_item_selected(window.session.get_item_entry(first_id))
	picker = window.runtime_target_picker.choices[&"skill"]
	picker.select(3)
	picker.item_selected.emit(3)
	var third := StringName(base[2].skill_id)
	window._refresh()
	_check(window.runtime_target_picker.get_selection().get(&"skill") == third, "unrelated refresh retains selection")
	picker = window.runtime_target_picker.choices[&"skill"]
	picker.get_popup().popup()
	var cancel := InputEventAction.new()
	cancel.action = &"ui_cancel"
	cancel.pressed = true
	window._input(cancel)
	_check(window.visible and not picker.get_popup().visible, "ESC closes choice popup before inventory")
	_check(picker.custom_minimum_size.y >= 44 and not picker.fit_to_longest_item, "touch height and bounded width")
	window.action_button.pressed.emit()
	_check(sockets.get_snapshot().slots[&"core"][0].bindings[&"skill"].target_id == third, "third skill selectable after release")
	window.close_panel()
	_check(game._finish_hub_training(), "training exits")
	_check(bag.export_runtime_state() == original_bag and sockets.get_snapshot().installed_count == 0, "training restores entry state")
	_check(not training.perform_targeted_inventory_item_action(&"capacitor_core", {&"skill": chosen}, first_id).success, "inactive training rejects command")
	_check(game.start_run("small"), "normal operation launch")
	for frame in 5: await process_frame
	window = game.inventory_window
	bag = game.inventory_system
	skills = game.combat_skill_system
	base = skills.get_skill_states()
	var run_core: StringName = bag.add_item(core)
	window.open_panel()
	_check(not paused and window.realtime, "operation selection remains realtime")
	window._on_item_selected(window.session.get_item_entry(run_core))
	picker = window.runtime_target_picker.choices[&"skill"]
	picker.select(3)
	picker.item_selected.emit(3)
	var elapsed: float = game.elapsed_time
	for frame in 4: await physics_frame
	_check(game.elapsed_time > elapsed, "operation time continues while choosing")
	window.session.dirty = true
	window.action_button.pressed.emit()
	_check(window.confirmation_visible, "operation save confirmation")
	window.resolve_exit(&"save")
	for index in base.size():
		var expected := float(base[index].cooldown_seconds) * (0.85 if index == 2 else 1.0)
		_check(is_equal_approx(skills.get_skill_states()[index].cooldown_seconds, expected), "operation third skill effect %d" % index)
	window.close_panel()
	game._abandon_run_to_start_hub()
	for frame in 5: await process_frame
	_check(is_instance_valid(game.start_hub), "operation returns to hub")
	game.queue_free()
	for frame in 3: await process_frame
	if failures.is_empty():
		print("SOCKET_TARGET_SELECTION_OK explicit_second_third_skill actual_cooldowns exact_instance cancel stale_weapon stale_skill live_kind_change responsive_picker training_restore")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)


func _check(value: bool, message: String) -> void:
	if not value: failures.append(message)
