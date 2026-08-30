class_name EnemySpawnTierConfig
extends Resource

@export var tier_id: StringName = &"small"
@export_range(1, 1000, 1) var minimum_active_enemies: int = 24
@export_range(1, 1000, 1) var maximum_active_enemies: int = 36
@export_range(1, 100, 1) var minimum_reinforcement_batch: int = 6
@export_range(1, 100, 1) var maximum_reinforcement_batch: int = 10
@export_range(0.1, 30.0, 0.1) var reinforcement_interval_seconds: float = 1.2
@export_range(0.1, 1.0, 0.05) var reinforcement_trigger_ratio: float = 0.75
@export_range(100.0, 3000.0, 10.0) var spawn_radius: float = 620.0
@export_range(0.0, 10.0, 0.1) var initial_delay_seconds: float = 0.15


func is_valid() -> bool:
	return (
		minimum_active_enemies > 0
		and maximum_active_enemies >= minimum_active_enemies
		and minimum_reinforcement_batch > 0
		and maximum_reinforcement_batch >= minimum_reinforcement_batch
		and maximum_reinforcement_batch <= maximum_active_enemies
		and reinforcement_interval_seconds > 0.0
		and reinforcement_trigger_ratio > 0.0
		and reinforcement_trigger_ratio <= 1.0
		and spawn_radius >= 100.0
		and initial_delay_seconds >= 0.0
	)
