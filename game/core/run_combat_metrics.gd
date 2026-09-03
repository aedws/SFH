class_name RunCombatMetrics
extends RefCounted

## Spawns/despawns are not defeats. Explicit role identity, not HP/rank heuristics.
var kills := 0
var boss_kills := 0
var generation := 0
var registered := {}


func reset() -> void:
	kills = 0
	boss_kills = 0
	generation += 1
	registered.clear()


func register_enemy(enemy: Node) -> void:
	if not is_instance_valid(enemy) or not enemy.has_signal(&"defeated"):
		return
	var id := enemy.get_instance_id()
	if registered.has(id):
		return
	registered[id] = true
	var identity: Dictionary = enemy.call(&"get_combat_identity") if enemy.has_method(&"get_combat_identity") else {}
	enemy.connect(&"defeated", _on_defeated.bind(bool(identity.get(&"is_boss", false)), generation), CONNECT_ONE_SHOT)


func get_snapshot() -> Dictionary:
	return {&"kills": kills, &"boss_kills": boss_kills}


func _on_defeated(_reward: int, _position: Vector2, is_boss: bool, registered_generation: int) -> void:
	if registered_generation != generation:
		return
	kills += 1
	if is_boss:
		boss_kills += 1
