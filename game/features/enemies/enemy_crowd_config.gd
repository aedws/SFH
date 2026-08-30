class_name EnemyCrowdConfig
extends Resource

@export var enabled: bool = true
@export_range(20.0, 160.0, 1.0) var separation_radius: float = 44.0
@export_range(0.0, 3.0, 0.05) var separation_strength: float = 1.25
@export_range(0.02, 0.5, 0.01) var steering_update_interval: float = 0.08
@export_range(1, 32, 1) var maximum_neighbors: int = 8
@export_range(20.0, 160.0, 1.0) var minimum_spawn_spacing: float = 40.0
@export_range(1, 64, 1) var spawn_search_attempts: int = 20


func is_valid() -> bool:
	return (
		separation_radius >= 20.0
		and separation_strength >= 0.0
		and steering_update_interval > 0.0
		and maximum_neighbors > 0
		and minimum_spawn_spacing >= 20.0
		and spawn_search_attempts > 0
	)
