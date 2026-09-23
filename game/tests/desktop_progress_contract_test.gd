extends SceneTree
const Store := preload("res://game/core/persistence/atomic_json_store.gd")
const Codec := preload("res://game/features/local_save/loadout_value_codec.gd")
const Progress := preload("res://game/features/local_save/desktop_progress_service.gd")
var failures: Array[String] = []
var test_root := ""
var phase := "write"


func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--save-root="): test_root = arg.trim_prefix("--save-root=")
		if arg.begins_with("--phase="): phase = arg.trim_prefix("--phase=")
	if test_root.is_empty():
		test_root = OS.get_cache_dir().path_join("sfh-save-contract-%d" % Time.get_ticks_usec())
	call_deferred(&"_run")


func _run() -> void:
	var game: Node = load("res://game/scenes/game.tscn").instantiate()
	var features: Resource = game.features.duplicate(true)
	for field in ["persistent_profile", "conditional_ranking", "meta_progression", "key_mapping", "skill_binding", "presentation_settings", "desktop_progress"]:
		features.set(field + "_storage_path", test_root.path_join(field + ".json"))
	features.map_seed = 67341
	game.features = features
	root.add_child(game)
	await process_frame
	await process_frame
	_check(game.get("start_hub") != null and not game.run_started, "restart must begin in hub")
	var service: Node = game.desktop_progress
	_check(service != null, "native save module missing")
	if service == null: return _finish()
	var bag: Node = game.inventory_system
	var gear: Node = game.equipment_system
	var profile: Node = game.persistent_profile
	# Same safe mode as the downloaded executable; other tests retain their legacy paths.
	profile.configure(features.persistent_profile_storage_path, true, true)
	if phase == "write":
		var quality_module_id := StringName(bag.call(&"add_catalog_item", &"ballistic_core_item", {
			&"quality_id": &"high_performance",
			&"quality_label": "고성능",
			&"performance_multiplier": 1.25,
			&"quality_option_ids": [&"overclocked_output"],
			&"quality_socket_count": 1,
			&"transaction_id": &"desktop-quality-persist",
		}))
		_check(quality_module_id != &"", "quality module added to hub bag")
		var editor: Node = load("res://game/features/inventory/inventory_edit_session.gd").new()
		game.add_child(editor)
		editor.configure(bag, gear)
		_check(editor.begin(), "begin hub edit")
		var rotated_item := false
		for entry in editor.inventory.get_snapshot().items:
			if entry.instance_id == quality_module_id:
				_check(editor.install_item(entry.instance_id, &"main"), "install module")
			if entry.item_id == &"rifle_scope_item":
				_check(editor.install_item(entry.instance_id, &"main"), "install part")
			if entry.item_id == &"field_medkit":
				_check(editor.move_item(entry.instance_id, Vector2i(8, 6)), "move bag item")
			if not rotated_item and bool(entry.get(&"can_rotate", false)) and editor.inventory.items.has(entry.instance_id):
				var base_size: Vector2i = entry.grid_size
				var rotated_size := Vector2i(base_size.y, base_size.x)
				for y in editor.inventory.grid_size.y:
					for x in editor.inventory.grid_size.x:
						var position := Vector2i(x, y)
						if (
							editor.inventory.can_place(base_size, position, entry.instance_id)
							and editor.inventory.can_place(rotated_size, position, entry.instance_id)
						):
							_check(editor.move_item(entry.instance_id, position), "move persistent rotation item")
							_check(editor.rotate_item(entry.instance_id), "rotate persistent bag item")
							rotated_item = true
							break
					if rotated_item:
						break
		_check(rotated_item, "rotatable bag item persisted")
		_check(editor.commit(), "commit hub editor")
		editor.free()
		var state: Resource = gear.get_equipment_state(&"main")
		_check(not state.installed_modules.is_empty(), "test module is equipped")
		if not state.installed_modules.is_empty():
			_check(gear.upgrade_module(&"main", state.installed_modules[0].instance_id), "upgrade module")
		_check(gear.upgrade_part(&"main", &"rifle_scope"), "upgrade part")
		_check(gear.set_active_weapon_slot(&"secondary"), "secondary weapon")
		var reserve_id := StringName(bag.add_catalog_item(&"ballistic_core_item", {&"upgrade_level": 6, &"reserve_proof": &"two-process"}))
		_check(reserve_id != &"" and bag.store_in_reserve(reserve_id), "real hub reserve checkpoint")
		_check(service.flush(), "hub save: %s" % service.get_snapshot())
		# Uncommitted editor changes must not leak into automatic checkpoints.
		var draft_editor: Node = load("res://game/features/inventory/inventory_edit_session.gd").new()
		game.add_child(draft_editor)
		draft_editor.configure(bag, gear)
		draft_editor.begin()
		for entry in draft_editor.inventory.get_snapshot().items:
			if entry.item_id == &"field_medkit":
				_check(draft_editor.move_item(entry.instance_id, Vector2i(9, 5)), "uncommitted draft move")
		_check(service.flush(), "save live state, not draft")
		draft_editor.free()
		profile.add_credits(137)
		for item_id in [&"assault_rifle", &"tactical_vest", &"ballistic_core", &"rifle_scope"]:
			profile.add_warehouse_item(item_id, 2)
		profile.register_shop_offer(&"buy_tactical_vest")
		profile.unlock_skill(&"magnetic_field")
		profile.add_codex_progress(&"test_collection", 3)
		profile.add_crafted_item({"instance_id": "persist-crafted", "definition_id": "assault_rifle", "affixes": [{"id": "power", "value": 1.25}]})
		_check(profile.get_storage_status().ok, "safe profile saved")
		var meta: Node = load("res://game/features/meta_progression/meta_progression_system.gd").new()
		game.add_child(meta)
		meta.configure(features.meta_progression_storage_path, true, true)
		meta.settle_run({&"character": 9, &"weapon": 6, &"armor": 4})
		_check(meta.get_storage_status().ok, "safe meta saved")
		game.conditional_ranking_system.submit_run({&"run_id": "restart-proof", &"success": true, &"condition_key": "desktop-restart", &"penalty_score": 10, &"kills": 12, &"recovered_value": 222, &"elapsed_seconds": 33.0})
		_check(service.begin_run(&"restart-proof", {&"entry_cost": 100}), "begin persisted run")
		service.unbind_hub()
		_check(service.finish_run(&"restart-proof", true, {"kills": 12, "recovered_credits": 222}), "record extracted run")
		_check(service.finish_run(&"restart-proof", true, {}), "duplicate result ignored")
		_check(service.get_snapshot().total_runs == 1, "duplicate history guard")
		_store_contracts()
	else:
		_check(not service.get_snapshot().blocked, "restore service: %s" % service.get_snapshot())
		var state: Resource = gear.get_equipment_state(&"main")
		_check(not state.installed_modules.is_empty() and state.installed_modules[0].upgrade_level == 2, "module upgrade persisted")
		_check(
			not state.installed_modules.is_empty()
			and is_equal_approx(state.installed_modules[0].quality_multiplier(), 1.25)
			and state.installed_modules[0].item_quality_payload.get(
				&"transaction_id", &""
			) == &"desktop-quality-persist",
			"quality payload persisted across process restart"
		)
		_check(state.part_upgrade_levels.get(&"rifle_scope", 0) == 2, "part upgrade persisted")
		_check(gear.active_weapon_slot == &"secondary", "active weapon persisted")
		var moved := false
		var restored_rotation := false
		for entry in bag.get_snapshot().items:
			if entry.item_id == &"field_medkit": moved = entry.position == Vector2i(8, 6)
			if bool(entry.get(&"rotated", false)):
				var base_size: Vector2i = entry.get(&"base_grid_size", Vector2i.ZERO)
				restored_rotation = entry.grid_size == Vector2i(base_size.y, base_size.x)
		_check(moved, "bag position persisted")
		_check(restored_rotation, "bag rotation persisted")
		var reserve_entries: Array = bag.get_reserve_entries()
		_check(reserve_entries.size() == 1 and reserve_entries[0].runtime_payload.get(&"reserve_proof") == &"two-process" and reserve_entries[0].runtime_payload.get(&"upgrade_level") == 6, "reserve instance persisted across process restart")
		_check(profile.get_snapshot().banked_credits == 5137, "banked credits persisted")
		for item_id in [&"assault_rifle", &"tactical_vest", &"ballistic_core", &"rifle_scope"]:
			_check(profile.has_warehouse_item(item_id, 2), "warehouse item: %s" % item_id)
		_check(profile.is_shop_offer_registered(&"buy_tactical_vest") and &"magnetic_field" in profile.get_snapshot().unlocked_skill_ids, "unlocks persisted")
		_check(profile.get_codex_progress(&"test_collection") == 3 and profile.get_snapshot().crafted_items.size() == 1, "codex/crafted affixes persisted")
		var meta: Node = load("res://game/features/meta_progression/meta_progression_system.gd").new()
		game.add_child(meta)
		meta.configure(features.meta_progression_storage_path, true, true)
		_check(meta.get_snapshot().levels[&"character"] == 3 and meta.get_snapshot().levels[&"weapon"] == 2, "meta growth persisted")
		_check(game.conditional_ranking_system.get_entries("desktop-restart").size() == 1, "local ranking persisted")
		_check(service.get_snapshot().total_runs == 1 and service.get_snapshot().extractions == 1, "history persisted")
		_check(game.start_run("small"), "restored equipment can launch real operation")
		_check(game.run_started and game.player != null, "restored operation assembled")
		_check(game.meta_progression_system.get_snapshot().levels[&"character"] == 3, "real operation uses restored growth")
		# No mid-raid snapshot: a new service simulates killing the process in combat.
		var interrupted := Progress.new()
		game.add_child(interrupted)
		_check(interrupted.configure(features.desktop_progress_storage_path), "interrupted load")
		_check(interrupted.get_snapshot().total_runs == 2 and interrupted.get_snapshot().history[0].outcome == "interrupted", "interrupted run recorded once")
		var again := Progress.new()
		game.add_child(again)
		again.configure(features.desktop_progress_storage_path)
		_check(again.get_snapshot().total_runs == 2, "interrupted record not duplicated")
		var codec := Codec.new()
		var saved: Dictionary = codec.decode(Store.new().read(features.desktop_progress_storage_path).data.loadout)
		_check(saved.gear.is_empty(), "interrupted equipped gear lost, no free recovery")
		_check(saved.bag.items.size() > 0, "hub bag retained; no transient loot copied")
		_check(saved.bag.get(&"reserve", {}).size() == 1, "interrupted operation preserves hub reserve")
	game.free()
	await process_frame
	_finish()


func _store_contracts() -> void:
	var path := test_root.path_join("atomic-contract.json")
	var store := Store.new()
	_check(store.write(path, {"value": 1}), "initial write")
	_check(store.write(path, {"value": 2}), "backup rotation")
	var corrupt := FileAccess.open(path, FileAccess.WRITE)
	corrupt.store_string("{broken")
	corrupt.close()
	var recovered := store.read(path)
	_check(recovered.ok and recovered.status == "recovered" and recovered.data.value == 1, "corrupt primary recovery")
	_check(store.write(path, {"value": 3}), "recovered save keeps previous backup")
	_check(store.read(path).data.value == 3, "repaired primary")
	var newer := FileAccess.open(path, FileAccess.WRITE)
	newer.store_string('{"format":"SFH_JSON_999"}')
	newer.close()
	_check(not store.write(path, {"value": 4}), "newer save cannot be overwritten or downgraded")
	var blocked := Progress.new()
	root.add_child(blocked)
	_check(not blocked.configure(path) and blocked.get_snapshot().blocked, "newer format shows blocking state")
	_check(not blocked.flush(), "blocked state cannot rewrite file")
	blocked.free()
	var unwritable_path := test_root.path_join("not-a-directory")
	var blocker := FileAccess.open(unwritable_path, FileAccess.WRITE)
	blocker.store_string("fixture: this path is a file")
	blocker.close()
	_check(not store.write(unwritable_path.path_join("child.json"), {}), "write error is explicit")
	var codec := Codec.new()
	codec.decode({"t": "resource", "type": "res://malicious.gd", "v": {}})
	_check(not codec.error.is_empty(), "unregistered resource denied")
	var disabled := Progress.new()
	root.add_child(disabled)
	var disabled_path := test_root.path_join("disabled.json")
	disabled.configure(disabled_path, false)
	disabled.flush()
	_check(not FileAccess.file_exists(disabled_path), "disabled module performs no writes")
	disabled.free()
	# Legacy profile is read and safely upgraded without resetting acquired values.
	var legacy_path := test_root.path_join("legacy-profile.json")
	var legacy := FileAccess.open(legacy_path, FileAccess.WRITE)
	legacy.store_string('{"banked_credits":321,"warehouse":{"scrap":9},"unlock_ids":["operation_gate"]}')
	legacy.close()
	var profile: Node = load("res://game/features/persistent_profile/persistent_profile.gd").new()
	root.add_child(profile)
	profile.configure(legacy_path, true, true)
	_check(profile.get_snapshot().banked_credits == 321 and profile.has_warehouse_item(&"scrap", 9), "legacy retained")
	profile.add_credits(1)
	_check(store.read(legacy_path).data.banked_credits == 322, "legacy upgraded")
	profile.free()


func _check(ok: bool, label: String) -> void:
	if not ok:
		failures.append(label)
		printerr("DESKTOP_PROGRESS_FAILED: " + label)


func _finish() -> void:
	if failures.is_empty():
		print("DESKTOP_PROGRESS_OK phase=%s hub_bag bag_rotation module_part_levels item_quality profile_warehouse_unlocks meta ranking history process_restart atomic_backup corrupt_recovery legacy_migration optional_module" % phase)
	quit(0 if failures.is_empty() else 1)
