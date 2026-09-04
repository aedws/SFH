class_name TrainingScenarioResetService
extends RefCounted

var spawner: Node
var active_definition: Resource
var reset_revision := 0


func configure(dummy_spawner: Node) -> bool:
	if (
		not is_instance_valid(dummy_spawner)
		or not dummy_spawner.has_method(&"spawn")
		or not dummy_spawner.has_method(&"clear")
		or not dummy_spawner.has_method(&"get_active_targets")
	):
		return false
	spawner = dummy_spawner
	return true


func activate(definition: Resource) -> Dictionary:
	if definition == null or not definition.has_method(&"is_valid") or not bool(definition.call(&"is_valid")):
		return {&"success": false, &"reason": "훈련 시나리오 정의가 유효하지 않음"}
	active_definition = definition
	return _spawn_active(&"activate")


func reset() -> Dictionary:
	if active_definition == null:
		return {&"success": false, &"reason": "활성 훈련 시나리오 없음"}
	return _spawn_active(&"reset")


func stop() -> Dictionary:
	var removed := int(spawner.call(&"clear")) if is_instance_valid(spawner) else 0
	active_definition = null
	return {&"success": true, &"removed_count": removed, &"reset_revision": reset_revision}


func get_snapshot() -> Dictionary:
	return {
		&"active_scenario_id": (
			active_definition.get("scenario_id") if active_definition != null else &""
		),
		&"reset_revision": reset_revision,
		&"active_count": (
			spawner.call(&"get_active_targets").size() if is_instance_valid(spawner) else 0
		),
	}


func _spawn_active(reason: StringName) -> Dictionary:
	var targets: Array = spawner.call(&"spawn", active_definition)
	if targets.size() != int(active_definition.get("dummy_count")):
		spawner.call(&"clear")
		active_definition = null
		return {&"success": false, &"reason": "훈련 더미 생성 실패"}
	reset_revision += 1
	return {
		&"success": true,
		&"reason": reason,
		&"scenario": active_definition.call(&"get_snapshot"),
		&"dummy_count": targets.size(),
		&"reset_revision": reset_revision,
	}
