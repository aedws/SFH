class_name ElitePursuitConfig
extends Resource

@export_range(0.1, 10.0, 0.1) var carried_credit_threshold_multiplier := 1.0
@export_range(1, 5, 1) var minimum_elite_count := 1
@export_range(1, 5, 1) var maximum_elite_count := 2
@export_range(64.0, 1600.0, 16.0) var minimum_spawn_distance := 420.0
@export_range(64.0, 2000.0, 16.0) var maximum_spawn_distance := 680.0
@export_range(1.01, 1.5, 0.01) var player_speed_multiplier := 1.08
@export_range(1.01, 2.0, 0.01) var player_attack_multiplier := 1.12
@export_range(1.0, 1000.0, 1.0) var maximum_health := 24.0
@export_range(0.0, 1000.0, 1.0) var maximum_armor := 10.0
@export_range(1, 5, 1) var priority_rank := 4


func is_valid() -> bool:
	return (
		carried_credit_threshold_multiplier > 0.0
		and minimum_elite_count > 0
		and maximum_elite_count >= minimum_elite_count
		and maximum_spawn_distance >= minimum_spawn_distance
		and player_speed_multiplier > 1.0
		and player_attack_multiplier > 1.0
		and maximum_health > 0.0
		and maximum_armor >= 0.0
		and priority_rank >= 1
	)


func get_snapshot() -> Dictionary:
	return {
		&"threshold_multiplier": carried_credit_threshold_multiplier,
		&"minimum_elite_count": minimum_elite_count,
		&"maximum_elite_count": maximum_elite_count,
		&"minimum_spawn_distance": minimum_spawn_distance,
		&"maximum_spawn_distance": maximum_spawn_distance,
		&"player_speed_multiplier": player_speed_multiplier,
		&"player_attack_multiplier": player_attack_multiplier,
		&"maximum_health": maximum_health,
		&"maximum_armor": maximum_armor,
		&"priority_rank": priority_rank,
	}
