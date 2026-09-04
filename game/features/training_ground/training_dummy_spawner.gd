class_name TrainingDummySpawner
extends Node

signal dummy_spawned(dummy: Node)
signal dummy_defeated(dummy: Node)
signal all_dummies_defeated

var target: Node2D
var dummy_parent: Node2D
var config: Resource
var active_dummies: Array[Node] = []


func configure(new_target: Node2D, new_dummy_parent: Node2D, new_config: Resource) -> bool:
	if (
		not is_instance_valid(new_target)
		or not is_instance_valid(new_dummy_parent)
		or new_config == null
		or not new_config.has_method(&"is_valid")
		or not bool(new_config.call(&"is_valid"))
	):
		return false
	target = new_target
	dummy_parent = new_dummy_parent
	config = new_config
	return true


func spawn(definition: Resource) -> Array[Node2D]:
	clear()
	if definition == null or not definition.has_method(&"is_valid") or not bool(definition.call(&"is_valid")):
		return []
	var result: Array[Node2D] = []
	var count := int(definition.get("dummy_count"))
	for index in count:
		var dummy := _spawn_one(definition, index)
		if dummy == null:
			clear()
			return []
		result.append(dummy)
	return result


func clear() -> int:
	var removed := 0
	for dummy in active_dummies:
		if is_instance_valid(dummy):
			var parent := dummy.get_parent()
			if parent != null:
				parent.remove_child(dummy)
			dummy.free()
			removed += 1
	active_dummies.clear()
	return removed


func get_active_targets() -> Array[Node2D]:
	_prune_invalid()
	var result: Array[Node2D] = []
	for dummy in active_dummies:
		if dummy is Node2D:
			result.append(dummy as Node2D)
	return result


func get_snapshot() -> Dictionary:
	_prune_invalid()
	var positions: Array[Vector2] = []
	for dummy in active_dummies:
		if dummy is Node2D:
			positions.append((dummy as Node2D).global_position)
	return {&"active_count": active_dummies.size(), &"positions": positions}


func _spawn_one(definition: Resource, index: int) -> Node2D:
	var scene: PackedScene = config.get("dummy_scene")
	var dummy := scene.instantiate() as Node2D
	if (
		dummy == null
		or not dummy.has_method(&"configure")
		or not dummy.has_method(&"set_boss_role")
		or not dummy.has_signal(&"defeated")
	):
		if dummy != null:
			dummy.free()
		return null
	dummy.set("move_speed", 0.0)
	dummy.set("max_health", float(definition.get("dummy_health")))
	dummy.set("max_armor", float(definition.get("dummy_armor")))
	dummy.set("contact_damage", 0.0)
	dummy.set("experience_reward", 0)
	dummy.set("priority_rank", 5 if String(definition.get("dummy_mode")) == "single" else 2)
	dummy.call(&"set_boss_role", String(definition.get("dummy_mode")) == "single")
	dummy.set_meta(&"training_dummy", true)
	dummy.set_meta(&"training_scenario_id", definition.get("scenario_id"))
	dummy.set_meta(&"training_dummy_index", index)
	dummy_parent.add_child(dummy)
	dummy.global_position = _formation_position(definition, index)
	dummy.call(&"configure", target, false, null, true, true, {}, null, null)
	active_dummies.append(dummy)
	dummy.connect(&"defeated", _on_dummy_defeated.bind(dummy), CONNECT_ONE_SHOT)
	dummy.tree_exited.connect(_on_dummy_tree_exited.bind(dummy), CONNECT_ONE_SHOT)
	dummy_spawned.emit(dummy)
	return dummy


func _formation_position(definition: Resource, index: int) -> Vector2:
	var anchor: Vector2 = config.get("formation_anchor")
	if String(definition.get("dummy_mode")) == "single":
		return anchor
	var count := int(definition.get("dummy_count"))
	var columns := mini(int(config.get("dense_columns")), count)
	var rows := ceili(float(count) / float(columns))
	var column := index % columns
	var row := index / columns
	var spacing := float(config.get("formation_spacing"))
	return anchor + Vector2(
		(float(column) - float(columns - 1) * 0.5) * spacing,
		(float(row) - float(rows - 1) * 0.5) * spacing
	)


func _on_dummy_defeated(_reward: int, _world_position: Vector2, dummy: Node) -> void:
	dummy_defeated.emit(dummy)
	call_deferred(&"_emit_clear_if_empty")


func _on_dummy_tree_exited(dummy: Node) -> void:
	active_dummies.erase(dummy)
	call_deferred(&"_emit_clear_if_empty")


func _emit_clear_if_empty() -> void:
	_prune_invalid()
	if active_dummies.is_empty():
		all_dummies_defeated.emit()


func _prune_invalid() -> void:
	for index in range(active_dummies.size() - 1, -1, -1):
		if not is_instance_valid(active_dummies[index]) or active_dummies[index].is_queued_for_deletion():
			active_dummies.remove_at(index)
