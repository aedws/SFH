extends SceneTree

const POLICY = preload("res://game/features/run_pressure/configs/default_run_pressure.tres")
const SERVICE = preload("res://game/features/run_pressure/run_pressure_service.gd")
var failures := PackedStringArray()
var isolation: RefCounted

class Actor extends Node2D:
	func get_runtime_stats() -> Dictionary: return {&"movement_speed": 200.0}

class Spawner extends Node:
	var calls := 0
	var fail_count := 1
	var pressure_calls := 0
	var profile := {}
	func set_run_pressure(damage: float, speed: float) -> bool:
		pressure_calls += 1
		return damage == 1.35 and speed == 1.15
	func spawn_elite_pursuer_at(_position: Vector2, data: Dictionary) -> Node2D:
		calls += 1
		profile = data.duplicate(true)
		if calls <= fail_count: return null
		var enemy := Node2D.new()
		add_child(enemy)
		return enemy

func _init() -> void:
	isolation = preload("res://game/tests/support/save_test_isolation.gd").new()
	node_added.connect(isolation.isolate)
	_run.call_deferred()

func check(value: bool, label: String) -> void:
	if not value: failures.append(label)

func _run() -> void:
	root.size = Vector2i(1280, 800)
	var actor := Actor.new()
	var spawn := Spawner.new()
	var service := SERVICE.new()
	root.add_child(actor)
	root.add_child(spawn)
	root.add_child(service)
	var config: Resource = POLICY.duplicate(true)
	check(service.configure(config, actor, spawn, null, 10.0), "configuration")
	config.collapse_seconds = 2.0
	var collapsed := [0]
	service.collapse_requested.connect(func(): collapsed[0] += 1)
	service.advance_to(1199.99)
	check(not service.corrupted and spawn.calls == 0, "threshold before 20 minutes")
	service.advance_to(1200.0)
	check(service.corrupted and spawn.calls == 1 and not service.hunter_created and spawn.pressure_calls == 1, "corruption once despite failed hunter")
	service.advance_to(1200.5)
	check(spawn.calls == 1, "retry throttled")
	service.advance_to(1201.0)
	check(spawn.calls == 2 and service.hunter_created, "retry without credits or new event")
	check(is_equal_approx(float(spawn.profile.move_speed), 216.0) and is_equal_approx(float(spawn.profile.contact_damage), 11.2) and spawn.profile.ignore_room_barriers, "explicit player relative hunter profile")
	service.hunter.free()
	service.advance_to(1500.0)
	service.advance_to(-1.0)
	service.advance_to(NAN)
	service.advance_to(INF)
	check(spawn.calls == 2 and service.elapsed == 1500.0 and spawn.pressure_calls == 1, "no respawn or backwards nonfinite clock")
	service.advance_to(1799.99)
	check(collapsed[0] == 0 and service.get_snapshot().urgent, "one minute warning before deadline")
	service.advance_to(1800.0)
	service.advance_to(3600.0)
	check(collapsed[0] == 1 and service.elapsed == 1800.0, "exact deadline once frozen source")
	check(service.configure(POLICY, actor, spawn), "next run reset")
	service.advance_to(5000)
	check(spawn.calls == 2 and collapsed[0] == 2, "clock leap fails without spawning late hunter")
	service.configure(POLICY, actor)
	service.finish()
	service.advance_to(1800)
	check(collapsed[0] == 2, "extraction terminal cancels later deadline")
	var invalid: Resource = POLICY.duplicate(true)
	invalid.enemy_speed_multiplier = NAN
	check(not service.configure(invalid, actor), "invalid policy rejected")
	service.free()
	spawn.free()
	actor.free()
	await _real_world()
	await _game_flow()
	if failures.is_empty(): print("RUN_PRESSURE_OK thresholds frozen_policy retry_once coexistence actual_enemy_stats door_independent deadline_single_settlement early_extract disabled hud")
	else:
		for failure in failures: printerr("RUN_PRESSURE_FAILED " + failure)
	quit(0 if failures.is_empty() else 1)

func _real_world() -> void:
	var fixture := Node2D.new()
	root.add_child(fixture)
	var actor = preload("res://game/features/player/player.tscn").instantiate()
	fixture.add_child(actor)
	actor.position = Vector2(8000, 8000)
	var spawn = preload("res://game/features/spawning/enemy_spawner.tscn").instantiate()
	fixture.add_child(spawn)
	spawn.configure(actor, fixture, false, null, true, true, load("res://game/features/spawning/configs/small.tres"))
	spawn.set_reinforcement_paused(&"test", true)
	var normal: Node2D = spawn.spawn_enemy_at(actor.position + Vector2(1000, 0))
	var damage: float = normal.contact_damage
	var speed: float = normal.move_speed
	var hp: float = normal.health_component.current_value
	var service := SERVICE.new()
	fixture.add_child(service)
	service.configure(POLICY, actor, spawn, null, 10)
	service.advance_to(1200)
	spawn.set_run_pressure(1.35, 1.15)
	check(is_equal_approx(normal.contact_damage, damage * 1.35) and is_equal_approx(normal.move_speed, speed * 1.15), "actual existing enemy stats no repeated multiplication")
	check(normal.health_component.current_value == hp, "corruption cannot heal existing enemies")
	var fresh: Node2D = spawn.spawn_enemy_at(actor.position + Vector2(-1000, 0))
	check(is_equal_approx(fresh.contact_damage, normal.contact_damage), "future spawn inherits pressure")
	check(spawn.total_spawned == 2 and service.hunter.ignore_room_barriers and not (service.hunter.collision_mask & 16), "hunter excludes normal budget and door collision")
	var door = preload("res://game/features/room_encounters/room_door_barrier.gd").new()
	fixture.add_child(door)
	door.configure(actor.position + Vector2(80, 0), Vector2(16, 256))
	service.hunter.global_position = actor.position + Vector2(180, 0)
	for frame in 80: await physics_frame
	check(service.hunter.global_position.x < door.global_position.x, "hunter actually crosses sealed door")
	fixture.queue_free()
	await process_frame

func _game_flow() -> void:
	for mode in ["collapse", "extract", "disabled"]:
		var game = load("res://game/scenes/game.tscn").instantiate()
		game.features = game.features.duplicate(true)
		game.features.run_pressure_enabled = mode != "disabled"
		root.add_child(game)
		for frame in 5: await process_frame
		check(game.start_run("small"), "real operation launch " + mode)
		for frame in 4: await process_frame
		game.player.configure_damage(false) # Fixture safety only; does not bypass collapse.
		if is_instance_valid(game.operation_tutorial_overlay): game.operation_tutorial_overlay.dismiss()
		paused = false
		if mode == "disabled":
			check(game.run_pressure_service == null, "optional service removed")
			game.advance_run_clock(1900)
			check(not game.run_ended, "disabled module does not end operation")
			game._abandon_run_to_start_hub()
		else:
			var before: float = game.elapsed_time
			paused = true
			game.advance_run_clock(1200)
			check(game.elapsed_time == before, "paused game clock cannot trigger pressure")
			paused = false
			game.credit_ledger.add_carried(ceili(float(game.active_contract.entry_cost) * 0.5))
			check(game.elite_pursuit_service.triggered, "existing recovery boss retained")
			game.advance_run_clock(1200 - game.elapsed_time)
			check(game.run_pressure_service.hunter_created and game.enemy_spawner.get_snapshot().elite_pursuer_count == 2, "both pursuit bosses coexist")
			check("붕괴 10:00" in game.time_label.text and "30:00" in game.time_label.tooltip_text, "visible deadline plus explanation")
			if mode == "collapse":
				if "--render" in OS.get_cmdline_user_args():
					for frame in 3: await process_frame
					await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png("res://build/qa-run-pressure-ui.png")
				game.inventory_window.open_panel()
				game.advance_run_clock(1800 - game.elapsed_time)
				check(game.run_ended and "붕괴" in game.end_title.text and not game.inventory_window.visible, "deadline closes real-time bag and fails operation")
				check(game.credit_ledger.get_snapshot().carried == 0 and not game.last_loot_settlement.extracted, "collapse loses carried loot not success")
			else:
				game._on_extraction_completed(game.player)
				check(game.run_ended and game.last_loot_settlement.extracted, "early extraction success")
			var bank: int = game.persistent_profile.banked_credits
			var result: Dictionary = game.last_loot_settlement.duplicate(true)
			game.advance_run_clock(1900)
			game._on_extraction_completed(game.player)
			game._on_player_died()
			check(game.persistent_profile.banked_credits == bank and game.last_loot_settlement == result, "terminal outcome immutable against late extraction/death")
			game._return_to_start_hub()
			check(game.run_pressure_service == null and not game.run_started, "hub has no pressure clock")
		paused = false
		game.queue_free()
		for frame in 3: await process_frame
