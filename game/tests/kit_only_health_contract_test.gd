extends SceneTree

var failures: Array[String] = []
var isolation: RefCounted

func _initialize() -> void:
	isolation = load("res://game/tests/support/save_test_isolation.gd").new()
	node_added.connect(isolation.isolate)
	call_deferred(&"_run")
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)

func _run() -> void:
	var player = load("res://game/features/player/player.tscn").instantiate()
	root.add_child(player)
	player.set_physics_process(false)
	player.take_damage(50.0)
	for source in [&"", &"regeneration", &"drop", &"level_up", &"buff", &"unknown"]:
		player.heal(20.0, source)
	check(is_equal_approx(player.current_health, 50.0), "non-kit healing bypass")
	player.heal(NAN, &"consumable")
	player.heal(-10, &"consumable")
	check(is_equal_approx(player.current_health, 50.0), "invalid healing")
	player.set_runtime_modifier_source(&"test_capacity", {&"max_health": {&"add": 50.0}})
	check(is_equal_approx(player.current_health, 50.0), "max HP buff healed wounds")
	var utility = load("res://game/features/p5_hub_progression/utility_investment_service.gd").new()
	var rows: Array[Dictionary] = [{&"utility_id": &"field_medkit", &"effect_id": &"heal", &"effect_value": 35.0, &"max_quantity": 2, &"use_condition": &"health_below_max"}]
	check(utility.configure(player, rows), "configure")
	check(utility.set_quantity(&"field_medkit", 2), "select")
	check(not utility.use_healing(&"field_medkit", player).get(&"success", false), "outside run")
	check(utility.begin_run(&"test_run"), "begin")
	check(utility.use_healing(&"field_medkit", player).get(&"success", false), "use")
	check(is_equal_approx(player.current_health, 85.0) and utility.active_quantities[&"field_medkit"] == 1, "heal and consume once")
	player.heal(1000.0, &"consumable")
	check(not utility.use_healing(&"field_medkit", player).get(&"success", false) and utility.active_quantities[&"field_medkit"] == 1, "full HP consumed")
	player.take_damage(1000.0)
	check(not utility.use_healing(&"field_medkit", player).get(&"success", false), "dead use")
	player.heal(20.0, &"consumable")
	check(is_zero_approx(player.current_health), "revive")
	utility.settle_run(false)
	check(utility.active_quantities.is_empty(), "run cleanup")
	# Replacement policy remains usable without editing consumers.
	var policy = load("res://game/features/player/health_recovery_policy.gd").new()
	policy.allowed_sources.append(&"regeneration")
	check(policy.allows(&"regeneration") and not player.can_receive_healing(&"regeneration"), "policy isolation")
	player.free()
	# Real assembled scenes, default stats, isolated save; CPU launch timing only.
	# No claim of GPU frame rate or a ten-minute release playthrough.
	for tier in ["small", "medium", "large"]:
		var game = load("res://game/scenes/game.tscn").instantiate()
		root.add_child(game)
		for frame in 5: await process_frame
		check(game.p5_hub_progression_service.set_utility_quantity(&"field_medkit", 2), "kit selection " + tier)
		var started := Time.get_ticks_usec()
		var launched: bool = game.start_run(tier)
		var launch_ms := (Time.get_ticks_usec() - started) / 1000.0
		check(launched, "launch " + tier)
		for frame in 5: await process_frame
		if launched:
			var button = game.health_bar.get_parent().get_node_or_null("MedkitButton")
			check(button != null and button.visible and button.disabled, "full-health kit UI " + tier)
			game.player.take_damage(50.0)
			var hp: float = game.player.current_health
			check(button != null and not button.disabled, "wounded kit UI " + tier)
			if button != null: button.pressed.emit()
			check(game.player.current_health > hp and button.text == "KIT 1", "button actual heal/consume " + tier)
			print("LAUNCH_CPU_SAMPLE tier=%s assembly_ms=%.3f renderer=%s" % [tier, launch_ms, DisplayServer.get_name()])
		game.free()
		paused = false
		for frame in 3: await process_frame
	if failures.is_empty(): print("KIT_ONLY_HEALTH_OK source_gate drop level buff invalid_amount wounded_capacity medkit_count full dead run_cleanup policy_extension")
	else: push_error(str(failures))
	quit(0 if failures.is_empty() else 1)
