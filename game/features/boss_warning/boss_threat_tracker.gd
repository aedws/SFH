class_name BossThreatTracker
extends RefCounted

signal boss_appeared(pursuer: bool)

var source: Node
var targets: Dictionary = {}
var announced: Dictionary = {}


func configure(spawner: Node) -> bool:
	reset()
	if not is_instance_valid(spawner) or not spawner.has_signal(&"enemy_spawned") \
		or not spawner.has_method(&"get_active_targets"):
		return false
	source = spawner
	source.connect(&"enemy_spawned", register_target)
	# Initial spawns can precede HUD installation. Use the same registration path.
	for target in source.call(&"get_active_targets"):
		register_target(target)
	return true


func register_target(target: Node) -> void:
	if not is_instance_valid(target) or not target is Node2D or target.is_queued_for_deletion() \
		or not target.has_method(&"get_combat_identity") or not target.has_signal(&"defeated"):
		return
	var identity: Dictionary = target.call(&"get_combat_identity")
	var id := target.get_instance_id()
	if not bool(identity.get(&"is_boss", false)) or announced.has(id):
		return
	if target.has_method(&"get_targeting_snapshot") \
		and float(target.call(&"get_targeting_snapshot").get(&"current_health", 1.0)) <= 0.0:
		return
	announced[id] = true
	var defeated_callback := _on_defeated.bind(id)
	var exit_callback := _remove_target.bind(id)
	target.connect(&"defeated", defeated_callback)
	target.tree_exiting.connect(exit_callback)
	targets[id] = {&"node": target, &"defeated": defeated_callback, &"exit": exit_callback}
	boss_appeared.emit(bool(identity.get(&"is_elite_pursuer", false)))


func get_threats() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id in targets.keys():
		var target: Node2D = targets[id][&"node"]
		if not is_instance_valid(target) or target.is_queued_for_deletion():
			_remove_target(id)
			continue
		result.append({&"id": id, &"world_position": target.global_position})
	return result


func reset() -> void:
	if is_instance_valid(source) and source.is_connected(&"enemy_spawned", register_target):
		source.disconnect(&"enemy_spawned", register_target)
	source = null
	for id in targets.keys():
		_remove_target(id)
	announced.clear()


func _on_defeated(_reward: int, _position: Vector2, id: int) -> void:
	_remove_target(id)


func _remove_target(id: int) -> void:
	if not targets.has(id):
		return
	var entry: Dictionary = targets[id]
	var target: Node = entry[&"node"]
	if is_instance_valid(target):
		if target.is_connected(&"defeated", entry[&"defeated"]):
			target.disconnect(&"defeated", entry[&"defeated"])
		if target.tree_exiting.is_connected(entry[&"exit"]):
			target.tree_exiting.disconnect(entry[&"exit"])
	targets.erase(id)
