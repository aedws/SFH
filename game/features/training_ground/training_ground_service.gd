class_name TrainingGroundService
extends Node

signal scenario_activated(snapshot: Dictionary)
signal scenario_reset(snapshot: Dictionary)
signal scenario_stopped(snapshot: Dictionary)
signal dummy_spawned(dummy: Node)

const DEFINITION := preload("res://game/features/training_ground/training_scenario_definition.gd")
const SPAWNER := preload("res://game/features/training_ground/training_dummy_spawner.gd")
const RESET_SERVICE := preload("res://game/features/training_ground/training_scenario_reset_service.gd")

var config: Resource
var definitions: Dictionary = {}
var scenario_order := PackedStringArray()
var spawner: Node
var reset_service
var reset_pending := false


func configure(target: Node2D, dummy_parent: Node2D, scenario_rows: Array[Dictionary],
		ground_config: Resource) -> bool:
	if (
		not is_instance_valid(target)
		or not is_instance_valid(dummy_parent)
		or ground_config == null
		or not ground_config.has_method(&"is_valid")
		or not bool(ground_config.call(&"is_valid"))
	):
		return false
	config = ground_config
	definitions.clear()
	scenario_order.clear()
	for row in scenario_rows:
		var definition = DEFINITION.new()
		if not bool(definition.call(&"configure", row)) or definitions.has(definition.get("scenario_id")):
			definitions.clear()
			scenario_order.clear()
			return false
		definitions[definition.get("scenario_id")] = definition
		scenario_order.append(String(definition.get("scenario_id")))
	if definitions.is_empty():
		return false
	spawner = SPAWNER.new()
	add_child(spawner)
	if not bool(spawner.call(&"configure", target, dummy_parent, config)):
		return false
	spawner.connect(&"dummy_spawned", func(dummy): dummy_spawned.emit(dummy))
	spawner.connect(&"all_dummies_defeated", _on_all_dummies_defeated)
	reset_service = RESET_SERVICE.new()
	return bool(reset_service.call(&"configure", spawner))


func activate_scenario(scenario_id: StringName) -> Dictionary:
	var definition: Resource = definitions.get(scenario_id)
	if definition == null:
		return {&"success": false, &"reason": "훈련 시나리오 없음"}
	reset_pending = false
	var result: Dictionary = reset_service.call(&"activate", definition)
	if bool(result.get(&"success", false)):
		scenario_activated.emit(get_snapshot())
	return result


func activate_next_scenario() -> Dictionary:
	if scenario_order.is_empty():
		return {&"success": false, &"reason": "훈련 시나리오 없음"}
	var current := StringName(reset_service.call(&"get_snapshot").get(&"active_scenario_id", &""))
	var next_index := 0
	if current != &"":
		var current_index := scenario_order.find(String(current))
		next_index = (current_index + 1) % scenario_order.size()
	return activate_scenario(StringName(scenario_order[next_index]))


func reset_active_scenario() -> Dictionary:
	reset_pending = false
	var result: Dictionary = reset_service.call(&"reset")
	if bool(result.get(&"success", false)):
		scenario_reset.emit(get_snapshot())
	return result


func stop() -> Dictionary:
	reset_pending = false
	var result: Dictionary = reset_service.call(&"stop")
	scenario_stopped.emit(get_snapshot())
	return result


func get_scenario_rows() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for scenario_id in scenario_order:
		var definition: Resource = definitions.get(StringName(scenario_id))
		result.append(definition.call(&"get_snapshot"))
	return result


func get_active_targets() -> Array[Node2D]:
	return spawner.call(&"get_active_targets") if is_instance_valid(spawner) else []


func get_snapshot() -> Dictionary:
	var reset_snapshot: Dictionary = (
		reset_service.call(&"get_snapshot") if reset_service != null else {}
	)
	return {
		&"scenario_count": definitions.size(),
		&"scenario_ids": scenario_order.duplicate(),
		&"active_scenario_id": reset_snapshot.get(&"active_scenario_id", &""),
		&"active_count": reset_snapshot.get(&"active_count", 0),
		&"reset_revision": reset_snapshot.get(&"reset_revision", 0),
		&"auto_reset_after_clear": bool(config.get("auto_reset_after_clear")) if config != null else false,
		&"general_spawn_budget_impact": 0,
	}


func _on_all_dummies_defeated() -> void:
	if (
		reset_pending
		or config == null
		or not bool(config.get("auto_reset_after_clear"))
		or StringName(reset_service.call(&"get_snapshot").get(&"active_scenario_id", &"")) == &""
	):
		return
	reset_pending = true
	var timer := get_tree().create_timer(float(config.get("reset_delay_seconds")))
	timer.timeout.connect(_perform_delayed_reset, CONNECT_ONE_SHOT)


func _perform_delayed_reset() -> void:
	if not reset_pending:
		return
	reset_pending = false
	reset_active_scenario()
