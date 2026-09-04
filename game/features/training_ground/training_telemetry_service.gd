class_name TrainingTelemetryService
extends Node

signal snapshot_changed(snapshot: Dictionary)
signal measurement_finalized(snapshot: Dictionary)

const COLLECTOR := preload("res://game/features/training_ground/combat_telemetry_collector.gd")

var collector
var scenario: Dictionary = {}
var refresh_interval_seconds := 0.1
var refresh_elapsed := 0.0


func configure(new_refresh_interval_seconds: float = 0.1) -> bool:
	if new_refresh_interval_seconds <= 0.0:
		return false
	refresh_interval_seconds = new_refresh_interval_seconds
	collector = COLLECTOR.new()
	return true


func begin(new_scenario: Dictionary) -> bool:
	if collector == null or new_scenario.is_empty():
		return false
	var duration := float(new_scenario.get(&"measurement_seconds", 0.0))
	if not bool(collector.call(&"begin", duration)):
		return false
	scenario = new_scenario.duplicate(true)
	refresh_elapsed = 0.0
	snapshot_changed.emit(get_snapshot())
	return true


func _process(delta: float) -> void:
	if collector == null or not bool(collector.get("active")):
		return
	refresh_elapsed += delta
	var just_finished := bool(collector.call(&"advance", delta))
	if just_finished or refresh_elapsed >= refresh_interval_seconds:
		refresh_elapsed = 0.0
		var snapshot := get_snapshot()
		snapshot_changed.emit(snapshot)
		if just_finished:
			measurement_finalized.emit(snapshot)


func advance(delta: float) -> void:
	_process(delta)


func record_hit(damage: float, armor_penetration: float = 0.0) -> bool:
	if collector == null or not bool(collector.call(&"record_hit", damage, armor_penetration)):
		return false
	snapshot_changed.emit(get_snapshot())
	return true


func record_resource_use(ap_spent: float, cooldown_seconds: float) -> bool:
	if collector == null or not bool(collector.call(
		&"record_resource_use", ap_spent, cooldown_seconds
	)):
		return false
	snapshot_changed.emit(get_snapshot())
	return true


func stop() -> Dictionary:
	if collector == null:
		return {}
	if scenario.is_empty():
		return get_snapshot()
	var snapshot: Dictionary = collector.call(&"stop")
	snapshot[&"scenario_id"] = scenario.get(&"scenario_id", &"")
	snapshot[&"scenario_name"] = scenario.get(&"display_name", "")
	scenario.clear()
	snapshot_changed.emit(snapshot)
	measurement_finalized.emit(snapshot)
	return snapshot


func get_snapshot() -> Dictionary:
	var result: Dictionary = collector.call(&"get_snapshot") if collector != null else {}
	result[&"scenario_id"] = scenario.get(&"scenario_id", &"")
	result[&"scenario_name"] = scenario.get(&"display_name", "")
	result[&"configured"] = collector != null
	return result
