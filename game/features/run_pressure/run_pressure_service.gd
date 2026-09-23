class_name RunPressureService
extends Node
## Driven only by the accepted run clock. No wall-clock timers or profile writes.
signal pressure_changed(snapshot: Dictionary)
signal hunter_spawned
signal collapse_requested

var policy: Resource
var player: Node2D
var spawner: Node
var map_provider: Node
var attack_reference := 1.0
var elapsed := 0.0
var finished := false
var corrupted := false
var hunter_created := false
var next_retry := 0.0
var hunter_attempts := 0
var hunter: Node2D


func configure(source: Resource, actor: Node2D, enemy_provider: Node = null,
		world_provider: Node = null, attack: float = 1.0) -> bool:
	if source == null or not source.has_method(&"is_valid") or not source.call(&"is_valid"):
		return false
	if not is_finite(attack) or attack <= 0.0: return false
	policy = source.duplicate(true)
	player = actor
	spawner = enemy_provider
	map_provider = world_provider
	attack_reference = attack
	elapsed = 0.0
	finished = false
	corrupted = false
	hunter_created = false
	hunter_attempts = 0
	next_retry = 0.0
	hunter = null
	return true


func advance_to(seconds: float) -> void:
	if policy == null or finished or not is_finite(seconds) or seconds < elapsed: return
	elapsed = minf(seconds, float(policy.get("collapse_seconds")))
	# A large clock step that crosses the deadline must fail without spawning a late boss.
	if elapsed >= float(policy.get("collapse_seconds")):
		finished = true
		collapse_requested.emit()
		return
	if not corrupted and elapsed >= float(policy.get("corruption_seconds")):
		corrupted = true
		if is_instance_valid(spawner) and spawner.has_method(&"set_run_pressure"):
			spawner.call(&"set_run_pressure", float(policy.get("enemy_damage_multiplier")),
				float(policy.get("enemy_speed_multiplier")))
		pressure_changed.emit(get_snapshot())
	if corrupted and not hunter_created and elapsed >= next_retry:
		_try_hunter()


func finish() -> void:
	finished = true


func get_snapshot() -> Dictionary:
	var result: Dictionary = policy.call(&"snapshot", elapsed) if policy != null else {}
	result.merge({&"finished": finished, &"hunter_spawned": hunter_created,
		&"hunter_alive": is_instance_valid(hunter), &"hunter_attempts": hunter_attempts,
		&"hunter_available": is_instance_valid(player) and is_instance_valid(spawner)
			and spawner.has_method(&"spawn_elite_pursuer_at")})
	return result


func _try_hunter() -> void:
	if not is_instance_valid(player) or not is_instance_valid(spawner) or not spawner.has_method(&"spawn_elite_pursuer_at"): return
	next_retry = elapsed + float(policy.get("spawn_retry_seconds"))
	hunter_attempts += 1
	var distance := float(policy.get("hunter_spawn_distance"))
	var position := player.global_position + Vector2.RIGHT * distance
	if is_instance_valid(map_provider) and map_provider.has_method(&"get_enemy_spawn_position"):
		position = map_provider.call(&"get_enemy_spawn_position", player.global_position, distance)
	if not position.is_finite(): return
	var stats: Dictionary = player.call(&"get_runtime_stats") if player.has_method(&"get_runtime_stats") else {}
	var profile := {
		&"move_speed": float(stats.get(&"movement_speed", 280.0)) * float(policy.get("hunter_speed_multiplier")),
		&"contact_damage": attack_reference * float(policy.get("hunter_attack_multiplier")),
		&"max_health": float(policy.get("hunter_health")), &"max_armor": float(policy.get("hunter_armor")),
		&"priority_rank": 5, &"is_boss": true, &"ignore_room_barriers": true,
	}
	hunter = spawner.call(&"spawn_elite_pursuer_at", position, profile)
	if not is_instance_valid(hunter): return
	hunter_created = true
	hunter.set_meta(&"run_pressure_hunter", true)
	hunter_spawned.emit()
