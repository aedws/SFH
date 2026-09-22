class_name RunFlowTelemetry
extends Node

const COLLECTOR := preload("res://game/features/run_flow/run_flow_collector.gd")
@export var report_path := "user://qa/run-flow-latest.json"
@export var sample_interval := 0.1
var collector := COLLECTOR.new()
var player: Node2D
var map_provider: Node
var started_usec := 0
var next_poll_usec := 0
var bindings: Array[Dictionary] = []
var report_saved := false
var sources: Dictionary = {}
var context: Dictionary = {}


func configure(id: String, actor: Node2D, map: Node, rooms: Node, loot: Node, operation: Dictionary = {}) -> bool:
	if id.is_empty() or not is_instance_valid(actor) or not is_instance_valid(map) or not map.has_method(&"get_visibility_region"):
		return false
	_disconnect_sources()
	player = actor
	map_provider = map
	collector.begin(id)
	started_usec = Time.get_ticks_usec()
	next_poll_usec = 0
	report_saved = false
	sources.clear()
	context = {"tier_id": String(operation.get(&"tier_id", "unknown")),
		"region_id": String(operation.get(&"region_id", "unknown")),
		"difficulty_id": String(operation.get(&"difficulty_id", "unknown")),
		"entry_cost": int(operation.get(&"entry_cost", 0)),
		"platform": "web" if OS.has_feature("web") else OS.get_name(),
		"headless": DisplayServer.get_name() == "headless",
		"initial_time_scale": Engine.time_scale, "time_scale_changed": false}
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bind(rooms, &"encounter_started", _on_encounter)
	_bind(rooms, &"encounter_cleared", _on_clear)
	_bind(rooms, &"reward_collected", _on_credit)
	_bind(loot, &"decision_observed", _on_decision)
	_observe_room()
	return true


func _bind(source: Node, event: StringName, callback: Callable) -> void:
	sources[String(event)] = is_instance_valid(source) and source.has_signal(event)
	if not is_instance_valid(source) or not source.has_signal(event): return
	source.connect(event, callback)
	bindings.append({"source": weakref(source), "event": event, "callback": callback})


func _disconnect_sources() -> void:
	for binding in bindings:
		var source = binding.source.get_ref()
		if is_instance_valid(source) and source.is_connected(binding.event, binding.callback):
			source.disconnect(binding.event, binding.callback)
	bindings.clear()


func _exit_tree() -> void:
	_disconnect_sources()


func _seconds() -> float:
	return (Time.get_ticks_usec() - started_usec) / 1000000.0


func _process(_delta: float) -> void:
	if collector.ended or collector.run_id.is_empty(): return
	if Engine.time_scale != float(context.initial_time_scale): context.time_scale_changed = true
	if Time.get_ticks_usec() >= next_poll_usec:
		next_poll_usec = Time.get_ticks_usec() + int(maxf(0.05, sample_interval) * 1000000)
		_observe_room()


func _observe_room() -> void:
	if not is_instance_valid(player) or not is_instance_valid(map_provider): return
	var region: Dictionary = map_provider.call(&"get_visibility_region", player.global_position)
	collector.enter(int(region.get(&"room_index", -1)), _seconds())


func _on_encounter(room: int, _count: int) -> void:
	_observe_room()
	collector.encounter(room, _seconds())


func _on_clear(room: int) -> void:
	_observe_room()
	collector.clear(room, _seconds())


func _on_credit(room: int, _amount: int) -> void:
	collector.credit(room, _seconds())


func _on_decision(id: int, stage: StringName, action: StringName) -> void:
	_observe_room()
	collector.decision(id, stage, action, _seconds())


func finish(reason: String) -> Dictionary:
	if not collector.ended:
		collector.finish(reason, _seconds())
		_disconnect_sources()
		var report := get_snapshot()
		report.erase("report_saved")
		if not report_path.is_empty():
			var directory := ProjectSettings.globalize_path(report_path.get_base_dir())
			if DirAccess.make_dir_recursive_absolute(directory) == OK:
				var file := FileAccess.open(report_path, FileAccess.WRITE)
				if file != null:
					file.store_string(JSON.stringify(report, "\t"))
					file.flush()
					report_saved = file.get_error() == OK
		print("RUN_FLOW_REPORT loops=%d decisions=%d missing=%d overflow=%d saved=%s" % [
			report.complete_loops, report.decisions.size(), report.missing_events, report.overflow, report_saved])
		if OS.has_feature("web"): print("RUN_FLOW_JSON " + JSON.stringify(get_snapshot()))
	return get_snapshot()


func get_snapshot() -> Dictionary:
	var report := collector.snapshot()
	report["report_saved"] = report_saved
	report["sources"] = sources.duplicate()
	report["context"] = context.duplicate(true)
	return report
