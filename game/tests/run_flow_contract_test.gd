extends SceneTree

const COLLECTOR := preload("res://game/features/run_flow/run_flow_collector.gd")
const TELEMETRY := preload("res://game/features/run_flow/run_flow_telemetry.gd")
var failures := PackedStringArray()

class Source extends Node:
	signal encounter_started(room: int, count: int)
	signal encounter_cleared(room: int)
	signal reward_collected(room: int, amount: int)
	signal decision_observed(id: int, stage: StringName, action: StringName)
	var room := 1
	func get_visibility_region(_point: Vector2) -> Dictionary:
		return {&"room_index": room}

func check(value: bool, label: String) -> void:
	if not value: failures.append(label)

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var c := COLLECTOR.new()
	c.begin("fixture")
	c.enter(1, 0)
	c.encounter(1, 1)
	c.encounter(1, 2) # duplicate cannot move the start
	c.clear(1, 61)
	c.clear(1, 62)
	c.decision(10, &"open", &"", 63)
	c.decision(10, &"open", &"", 64)
	c.decision(10, &"resolve", &"stored", 65)
	c.enter(-1, 66) # corridor does not finish the loop
	c.enter(1, 67)
	c.enter(2, 90)
	c.encounter(2, 91)
	c.enter(3, 92)
	c.encounter(3, 93)
	c.clear(2, 94) # an earlier patrol clears remotely
	c.decision(11, &"open", &"", 95)
	c.decision(11, &"interrupt", &"out_of_range", 96)
	c.decision(11, &"open", &"", 97)
	c.decision(11, &"resolve", &"deferred", 101)
	c.decision(12, &"open", &"", 102)
	c.finish("lost", 103)
	var s := c.snapshot()
	check(s.complete_loops == 1 and s.visits[0].loop_s == 90 and s.visits[0].combat_s == 60, "exact loop durations and duplicate guard")
	check(s.visits[1].status == "left_before_clear", "overlapping remote clear not a completed loop")
	check(s.decisions[0].duration_s == 2 and s.decisions[0].resolved, "decision retains original opening")
	check(not s.decisions[1].resolved and s.decisions[2].action == "deferred" and s.decisions[2].duration_s == 4, "walk away versus explicit defer and revisit")
	check(not s.decisions[3].resolved and s.pending_decisions == 0, "death interrupts pending choice")
	c.clear(3, 110)
	c.finish("extracted", 120)
	check(c.snapshot() == s and s.human_acceptance == "not_evaluated", "terminal immutable and no fabricated FUN acceptance")
	s.visits.clear()
	check(c.snapshot().visits.size() == 3, "snapshot isolation")
	c.begin("next")
	check(c.snapshot().visits.is_empty() and not c.ended, "new run reset")
	c.clear(99, 1)
	c.enter(1, 0)
	check(c.missing == 2, "missing and backwards samples explicit")
	for i in 600: c.enter(i, i + 2)
	check(c.visits.size() == 512 and c.overflow == 88, "bounded memory and explicit overflow")
	var source := Source.new()
	var actor := Node2D.new()
	var telemetry := TELEMETRY.new()
	root.add_child(source)
	root.add_child(actor)
	root.add_child(telemetry)
	telemetry.report_path = OS.get_cache_dir().path_join("sfh-flow-%d.json" % Time.get_ticks_usec())
	check(telemetry.configure("signals", actor, source, source, source), "public source configuration")
	source.encounter_started.emit(1, 5)
	source.decision_observed.emit(40, &"open", &"")
	paused = true
	var deadline := Time.get_ticks_usec() + 60000
	while Time.get_ticks_usec() < deadline: await process_frame
	source.decision_observed.emit(40, &"resolve", &"stored")
	paused = false
	source.encounter_cleared.emit(1)
	source.room = 2
	deadline = Time.get_ticks_usec() + 150000
	while Time.get_ticks_usec() < deadline: await process_frame
	var report := telemetry.finish("extracted")
	check(report.complete_loops == 1 and report.decisions[0].duration_s >= 0.05, "real signals and wall pause retained")
	var persisted = JSON.parse_string(FileAccess.get_file_as_string(telemetry.report_path))
	check(persisted.run_id == "signals" and persisted.ended, "report persisted without profile mutation")
	check(telemetry.report_saved and source.get_signal_connection_list(&"encounter_started").is_empty(), "save result and source disconnect")
	check(telemetry.finish("lost") == report, "idempotent finish")
	telemetry.report_path = ""
	telemetry.configure("instant_region", actor, source, source, source)
	source.room = 3
	source.decision_observed.emit(50, &"open", &"")
	source.decision_observed.emit(50, &"resolve", &"deferred")
	check(telemetry.get_snapshot().decisions[0].room == 3, "decision refreshes position before periodic poll")
	telemetry.finish("extracted")
	check(telemetry.configure("optional", actor, source, null, null), "missing optional modules tolerated")
	check(not telemetry.get_snapshot().sources.encounter_started, "missing sources cannot masquerade as coverage")
	telemetry.finish("returned_to_hub")
	telemetry.configure("write_failure", actor, source, null, null)
	telemetry.report_path = OS.get_cache_dir()
	check(not telemetry.finish("lost").report_saved, "write failure cannot block settlement")
	telemetry.free()
	source.free()
	actor.free()
	await _game_wiring()
	if failures.is_empty(): print("RUN_FLOW_OK bounded loops decisions overlap pause reset persistence actual_game")
	else:
		for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)

func _game_wiring() -> void:
	var game = load("res://game/scenes/game.tscn").instantiate()
	var config: Resource = game.features.duplicate(true)
	var directory := OS.get_cache_dir().path_join("sfh-flow-game-%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(directory)
	for field in ["persistent_profile", "conditional_ranking", "meta_progression", "key_mapping", "skill_binding", "presentation_settings", "desktop_progress"]:
		config.set(field + "_storage_path", directory.path_join(field + ".json"))
	game.features = config
	root.add_child(game)
	for frame in 6: await process_frame
	check(game.start_run("small"), "actual operation launch")
	for frame in 6: await process_frame
	check(is_instance_valid(game.run_flow_telemetry), "actual Game installs module")
	if is_instance_valid(game.run_flow_telemetry):
		game.run_flow_telemetry.report_path = directory.path_join("flow.json")
		check(game.run_flow_telemetry.get_snapshot().context.tier_id == "small", "operation scale retained in report")
		check(game.run_flow_telemetry.get_snapshot().sources.decision_observed, "actual field loot signal wired")
		var loot = game.field_loot_acquisition_service
		var drop = loot.spawn_candidate(game.player.global_position, {
			&"item_id": &"arc_rune", &"grade": 3, &"quantity": 1, &"source_type": &"room_reward"})
		check(drop != null, "actual loot exists")
		if drop != null:
			drop.call(&"_process", 0.0)
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
			var choices: Array = game.run_flow_telemetry.get_snapshot().decisions
			check(choices.size() == 1 and choices[0].resolved, "physical F produces one resolved observation")
			check(game.field_loot_acquisition_service.get_snapshot().total_acquired == 1, "observation does not duplicate reward")
		game._settle_run_loot(false)
		check(game.run_flow_telemetry.get_snapshot().ended, "actual settlement ends telemetry")
		game._return_to_start_hub()
		for frame in 6: await process_frame
		check(game.run_flow_telemetry == null, "hub clears telemetry instance")
		config.run_flow_enabled = false
		check(game.start_run("small") and game.run_flow_telemetry == null, "feature disabled operation still launches")
	game.free()
	paused = false
