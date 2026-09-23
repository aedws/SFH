extends SceneTree
## Real field acquisition, bag/socket transitions and the game's settlement wiring.
var failures := PackedStringArray()

func check(value: bool, label: String) -> void:
	if not value: failures.append(label)

func _init() -> void: _run.call_deferred()

func _run() -> void:
	for extracted in [true, false]:
		var game = load("res://game/scenes/game.tscn").instantiate()
		var features: Resource = game.features.duplicate(true)
		var directory := OS.get_cache_dir().path_join("sfh-rune-settlement-%d" % Time.get_ticks_usec())
		DirAccess.make_dir_recursive_absolute(directory)
		for field in ["persistent_profile", "conditional_ranking", "meta_progression", "key_mapping", "skill_binding", "presentation_settings", "desktop_progress"]:
			features.set(field + "_storage_path", directory.path_join(field + ".json"))
		game.features = features
		root.add_child(game)
		for frame in 6: await process_frame
		# New base capacity is 36: leave room for this acquisition fixture in the hub.
		for id in game.inventory_system.items.keys(): game.inventory_system.store_in_reserve(id)
		check(game.start_run("small"), "operation starts")
		for frame in 4: await process_frame
		var loot = game.field_loot_acquisition_service
		var sockets = game.session_socket_service
		# Three runes exceed duplicate capacity: equipped and carried copies coexist.
		for item_id in [&"arc_rune", &"arc_rune", &"arc_rune", &"capacitor_core", &"phase_artifact"]:
			var drop: Node2D = loot.spawn_candidate(game.player.global_position, {
				&"item_id": item_id, &"grade": 3, &"quantity": 1, &"source_type": &"room_reward"})
			check(drop != null, "field drop exists")
			if drop == null: continue
			drop.call(&"_process", 0.0)
			check(loot.focused_drop == drop, "proximity selects real drop")
			var press := InputEventKey.new()
			press.keycode = KEY_F
			press.physical_keycode = KEY_F
			press.pressed = true
			Input.parse_input_event(press)
			await process_frame
			press = InputEventKey.new()
			press.keycode = KEY_F
			press.physical_keycode = KEY_F
			Input.parse_input_event(press)
			await process_frame
			check(not is_instance_valid(drop), "F acquired drop exactly once")
		check(sockets.get_snapshot().installed_count >= 3, "socketed rune core artifact")
		check(sockets.inventory_adapter.first_owned(&"arc_rune") != &"", "excess rune in bag")
		var ledger: Dictionary = loot.get_snapshot().acquired_items.duplicate(true)
		check(int(ledger.get(&"arc_rune", {}).get(&"quantity", 0)) == 3, "ledger includes equipped copies")
		check(sockets.unsocket(&"rune", 0).success, "unequip returns rune")
		check(sockets.socket_owned_item(&"arc_rune").success, "bag rune re-equipped")
		check(loot.get_snapshot().acquired_items == ledger, "repeated placement cannot duplicate acquisition")
		var wallet: int = game.persistent_profile.banked_credits
		var result: Dictionary = game._settle_run_loot(extracted)
		check(result.success and result.extracted == extracted, "game settlement success")
		check(result.converted_credits == (510 if extracted else 0), "three runes + core + artifact convert only on extraction")
		check(game.persistent_profile.banked_credits == wallet + (510 if extracted else 0), "actual profile paid once")
		if not extracted:
			check(result.lost_items.get(&"arc_rune", 0) == 3 and result.lost_items.get(&"phase_artifact", 0) == 1, "equipped items also lost on death")
		else:
			check("510" in game._format_run_loot_settlement(result), "player result includes equipped conversion")
		var repeat: Dictionary = game._settle_run_loot(extracted)
		check(repeat.duplicate_ignored and game.persistent_profile.banked_credits == wallet + (510 if extracted else 0), "repeat settlement cannot pay twice")
		game.queue_free()
		for frame in 4: await process_frame
	if failures.is_empty(): print("EQUIPPED_RUNE_SETTLEMENT_OK physical_f ledger bag_socket roundtrip extraction_510 death_loss idempotent result_text")
	else:
		for failure in failures: printerr("EQUIPPED_RUNE_SETTLEMENT_FAILED " + failure)
	quit(0 if failures.is_empty() else 1)
