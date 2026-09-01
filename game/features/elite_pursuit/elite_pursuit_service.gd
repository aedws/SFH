class_name ElitePursuitService
extends Node

signal pursuit_triggered(threshold: int, carried_credits: int, elite_count: int)

const SPAWNER_METHODS := [&"spawn_elite_pursuer_at", &"get_active_targets"]

var player: Node2D
var credit_ledger: Node
var enemy_spawner: Node
var map_provider: Node
var config: Resource
var deployment_cost := 0
var threshold_credits := 0
var player_attack_reference := 1.0
var triggered := false
var spawned_elites: Array[Node] = []
var last_carried_credits := 0
var random := RandomNumberGenerator.new()


func configure(
	new_player: Node2D,
	new_credit_ledger: Node,
	new_enemy_spawner: Node,
	new_map_provider: Node,
	new_config: Resource,
	new_deployment_cost: int,
	new_player_attack_reference: float,
	seed_value: int = 0
) -> bool:
	if (
		not is_instance_valid(new_player)
		or not _supports_methods(new_credit_ledger, [&"get_snapshot"])
		or not new_credit_ledger.has_signal(&"credits_changed")
		or not _supports_methods(new_enemy_spawner, SPAWNER_METHODS)
		or new_config == null
		or not new_config.has_method(&"is_valid")
		or not bool(new_config.call(&"is_valid"))
		or new_deployment_cost < 0
	):
		return false
	player = new_player
	credit_ledger = new_credit_ledger
	enemy_spawner = new_enemy_spawner
	map_provider = new_map_provider
	config = new_config
	deployment_cost = new_deployment_cost
	threshold_credits = maxi(1, ceili(
		float(deployment_cost) * float(config.get("carried_credit_threshold_multiplier"))
	))
	player_attack_reference = maxf(0.1, new_player_attack_reference)
	triggered = false
	spawned_elites.clear()
	last_carried_credits = int(credit_ledger.call(&"get_snapshot").get(&"carried", 0))
	random.seed = seed_value if seed_value != 0 else int(Time.get_ticks_usec())
	var callback := Callable(self, &"_on_credits_changed")
	if not credit_ledger.is_connected(&"credits_changed", callback):
		credit_ledger.connect(&"credits_changed", callback)
	_evaluate_threshold(last_carried_credits)
	return true


func get_snapshot() -> Dictionary:
	_prune_elites()
	return {
		&"configured": player != null and credit_ledger != null and enemy_spawner != null,
		&"deployment_cost": deployment_cost,
		&"threshold_credits": threshold_credits,
		&"last_carried_credits": last_carried_credits,
		&"triggered": triggered,
		&"active_elite_count": spawned_elites.size(),
		&"spawned_elite_count": spawned_elites.size(),
		&"room_independent": true,
		&"door_state_independent": true,
		&"infinite_pursuit": true,
		&"player_speed_multiplier": (
			float(config.get("player_speed_multiplier")) if config != null else 0.0
		),
		&"player_attack_multiplier": (
			float(config.get("player_attack_multiplier")) if config != null else 0.0
		),
	}


func force_evaluate(carried_credits: int) -> bool:
	last_carried_credits = maxi(0, carried_credits)
	return _evaluate_threshold(last_carried_credits)


func _on_credits_changed(carried: int, _secured: int) -> void:
	last_carried_credits = carried
	_evaluate_threshold(carried)


func _evaluate_threshold(carried: int) -> bool:
	if triggered or carried < threshold_credits or not is_instance_valid(player):
		return false
	triggered = true
	var count := random.randi_range(
		int(config.get("minimum_elite_count")),
		int(config.get("maximum_elite_count"))
	)
	var player_stats: Dictionary = (
		player.call(&"get_runtime_stats") if player.has_method(&"get_runtime_stats") else {}
	)
	var player_speed := float(player_stats.get(&"movement_speed", 280.0))
	var profile := {
		&"move_speed": player_speed * float(config.get("player_speed_multiplier")),
		&"contact_damage": player_attack_reference * float(config.get("player_attack_multiplier")),
		&"max_health": float(config.get("maximum_health")),
		&"max_armor": float(config.get("maximum_armor")),
		&"priority_rank": int(config.get("priority_rank")),
		&"ignore_room_barriers": true,
	}
	for index in count:
		var position := _random_spawn_position(index, count)
		var elite: Node2D = enemy_spawner.call(&"spawn_elite_pursuer_at", position, profile)
		if is_instance_valid(elite):
			spawned_elites.append(elite)
	pursuit_triggered.emit(threshold_credits, carried, spawned_elites.size())
	return not spawned_elites.is_empty()


func _random_spawn_position(index: int, count: int) -> Vector2:
	var angle := random.randf_range(0.0, TAU) + TAU * float(index) / float(maxi(1, count))
	var distance := random.randf_range(
		float(config.get("minimum_spawn_distance")),
		float(config.get("maximum_spawn_distance"))
	)
	var requested := player.global_position + Vector2.RIGHT.rotated(angle) * distance
	if is_instance_valid(map_provider) and map_provider.has_method(&"get_enemy_spawn_position"):
		return map_provider.call(&"get_enemy_spawn_position", player.global_position, distance)
	return requested


func _prune_elites() -> void:
	for index in range(spawned_elites.size() - 1, -1, -1):
		if not is_instance_valid(spawned_elites[index]):
			spawned_elites.remove_at(index)


func _supports_methods(candidate: Node, methods: Array) -> bool:
	if not is_instance_valid(candidate):
		return false
	for method_name in methods:
		if not candidate.has_method(method_name):
			return false
	return true
