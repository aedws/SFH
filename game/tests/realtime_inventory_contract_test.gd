extends SceneTree

var failures := PackedStringArray()

func check(value: bool, label: String) -> void:
	if not value: failures.append(label)

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	root.size = Vector2i(1280, 800)
	var game = load("res://game/scenes/game.tscn").instantiate()
	var features: Resource = game.features.duplicate(true)
	var directory := OS.get_cache_dir().path_join("sfh-realtime-bag-%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(directory)
	for field in ["persistent_profile", "conditional_ranking", "meta_progression", "key_mapping", "skill_binding", "presentation_settings", "desktop_progress"]:
		features.set(field + "_storage_path", directory.path_join(field + ".json"))
	game.features = features
	root.add_child(game)
	for frame in 6: await process_frame
	# Leave one small item for draft movement and free pickup space in the base tier.
	var seeds: Array = game.inventory_system.get_snapshot().items
	var retained: StringName = &""
	for entry in seeds:
		if retained == &"" and entry.grid_size == Vector2i.ONE: retained = entry.instance_id
		else: game.inventory_system.store_in_reserve(entry.instance_id)
	game.inventory_window.open_panel()
	check(paused, "hub preparation still pauses")
	game.inventory_window.close_panel()
	check(not paused and game.start_run("small"), "hub to operation")
	for frame in 6: await process_frame
	var window = game.inventory_window
	window.open_panel()
	check(window.visible and not paused, "combat inventory must not pause world")
	if paused:
		window.close_panel()
		_finish(game)
		return
	if "--render" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		for frame in 8: await process_frame
		await RenderingServer.frame_post_draw
		check(root.get_visible_rect().encloses(window.get_global_rect()), "rendered window inside viewport")
		root.get_texture().get_image().save_png("res://build/qa-realtime-inventory.png")
		print("REALTIME_INVENTORY_RENDER_OK")
	var before: float = game.elapsed_time
	game.player.movement.dash_cooldown_remaining = 0.8
	game.combat_skill_system.cooldowns[0] = 2.0
	check(game.auto_weapon.ui_input_blocked and game.combat_skill_system.ui_input_blocked, "game wires action gates")
	var enemy = load("res://game/features/enemies/enemy.tscn").instantiate()
	game.actors_container.add_child(enemy)
	enemy.position = game.player.position + Vector2(120, 0)
	enemy.configure(game.player, true)
	var enemy_origin: Vector2 = enemy.position
	Input.action_press(&"move_right")
	Input.action_press(&"dash")
	Input.action_press(&"primary_attack")
	var origin: Vector2 = game.player.position
	for frame in 8: await physics_frame
	check(game.elapsed_time > before, "real frames advance run clock")
	check(game.player.position.distance_to(origin) < 0.1, "UI input cannot move player")
	check(enemy.position.distance_to(enemy_origin) > 0.1, "actual enemy pursuit continues")
	enemy.queue_free()
	check(game.player.movement.dash_cooldown_remaining < 0.8, "dash recovery continues")
	check(game.combat_skill_system.cooldowns[0] < 2.0, "skill recovery continues")
	check(not game.auto_weapon.try_fire_once() and not game.combat_skill_system.try_activate(0), "UI cannot activate attacks")
	for action in [&"move_right", &"dash", &"primary_attack"]: Input.action_release(action)
	check(_edit(window.session), "draft editing available")
	window.close_panel()
	check(window.confirmation_visible and not paused, "save confirmation also real time")
	var hp: float = game.player.current_health
	game.player.take_damage(10.0)
	check(game.player.current_health < hp, "real damage while confirming")
	check("전투 진행 중" in window.header_summary.text and "HP" in window.header_summary.text, "visible risk and live health")
	var damaged_hp: float = game.player.current_health
	Input.action_press(&"primary_attack")
	window.resolve_exit(&"save")
	check(not window.visible and game.player.current_health <= damaged_hp, "saving cannot restore pre-hit HP")
	check(game.auto_weapon.ui_release_required and not game.auto_weapon.ui_input_blocked, "close click requires release before firing")
	Input.action_release(&"primary_attack")
	for frame in 3: await process_frame
	check(not game.auto_weapon.ui_release_required, "release rearms attack")
	# A separate pause owner keeps its pause; the real-time window never clears it.
	paused = true
	window.open_panel()
	window.close_panel()
	check(paused, "external pause ownership preserved")
	paused = false
	window.open_panel()
	game._on_level_increased(2)
	check(not game.run_buff_selector.visible and not game.pending_buff_levels.is_empty(), "level selection waits for editor")
	window.close_panel()
	for frame in 3: await process_frame
	check(game.run_buff_selector.visible and paused, "queued level selection opens after editor")
	game.run_buff_selector._select_choice(0)
	window.open_panel()
	check(not window.session.conflicted, "new session has fresh snapshot")
	check(_edit(window.session), "second draft")
	var filler := InventoryItemDefinition.new()
	filler.item_id = &"live_pickup"
	filler.display_name = "실시간 획득"
	filler.item_type = &"test"
	var id: StringName = game.inventory_system.add_item(filler)
	check(id != &"" and window.session.conflicted and not window.session.commit(), "live pickup rejects stale save")
	window.close_panel()
	window.resolve_exit(&"discard")
	check(game.inventory_system.items.has(id), "discard retains newly acquired loot")
	window.open_panel()
	check(_edit(window.session), "death draft")
	window.close_panel()
	game.player.take_damage(100000.0)
	check(game.run_ended and game.game_over_overlay.visible and paused, "death settles with result pause")
	check(not window.visible and not window.confirmation_visible and not window.session.commit(), "death invalidates pending draft")
	window.resolve_exit(&"save")
	window.open_panel()
	check(not window.visible and paused, "stale callbacks cannot reopen/unpause result")
	game._restart_run()
	for frame in 6: await process_frame
	check(not paused and not game.run_started, "death returns to usable hub")
	game.inventory_window.open_panel()
	check(game.inventory_window.visible and paused, "fresh hub inventory usable")
	game.inventory_window.close_panel()
	_finish(game)

func _finish(game: Node) -> void:
	paused = false
	game.queue_free()
	if failures.is_empty():
		print("REALTIME_INVENTORY_OK hub_pause clock damage cooldown input_gate atomic_save conflict death terminal_guard")
	else:
		for failure in failures: printerr("REALTIME_INVENTORY_FAILED " + failure)
	quit(0 if failures.is_empty() else 1)

func _edit(session: Node) -> bool:
	var entry: Dictionary = session.inventory.get_snapshot().items[0]
	for y in session.inventory.grid_size.y:
		for x in session.inventory.grid_size.x:
			var destination := Vector2i(x, y)
			if destination != entry.position and session.inventory.can_place(entry.grid_size, destination, entry.instance_id):
				return session.move_item(entry.instance_id, destination)
	return false
