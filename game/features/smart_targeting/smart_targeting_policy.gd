class_name SmartTargetingPolicy
extends Resource

@export_range(0.0, 1.0, 0.05) var proximity_weight := 0.45
@export_range(0.0, 1.0, 0.05) var execute_weight := 0.20
@export_range(0.0, 1.0, 0.05) var priority_weight := 0.20
@export_range(0.0, 1.0, 0.05) var density_weight := 0.15
@export_range(32.0, 600.0, 8.0) var density_radius := 180.0
@export_range(1.0, 20.0, 1.0) var maximum_priority_rank := 5.0
@export_range(1.0, 40.0, 1.0) var reference_density_count := 8.0


func is_valid() -> bool:
	return (
		proximity_weight + execute_weight + priority_weight + density_weight > 0.0
		and density_radius > 0.0
		and maximum_priority_rank > 0.0
		and reference_density_count > 0.0
	)


func select_target(origin: Vector2, candidates: Array, maximum_range: float) -> Node2D:
	var best: Node2D
	var best_score := -INF
	for candidate in candidates:
		if not candidate is Node2D:
			continue
		var target := candidate as Node2D
		var distance := origin.distance_to(target.global_position)
		if distance > maximum_range:
			continue
		var snapshot: Dictionary = (
			target.call(&"get_targeting_snapshot")
			if target.has_method(&"get_targeting_snapshot") else {}
		)
		var current_health := float(snapshot.get(&"current_health", 1.0))
		var maximum_health := maxf(1.0, float(snapshot.get(&"maximum_health", current_health)))
		var score := proximity_weight * (1.0 - distance / maximum_range)
		score += execute_weight * (1.0 - current_health / maximum_health)
		score += priority_weight * clampf(
			float(snapshot.get(&"priority_rank", 1)) / maximum_priority_rank, 0.0, 1.0
		)
		score += density_weight * clampf(
			float(_nearby_count(target, candidates)) / reference_density_count, 0.0, 1.0
		)
		if score > best_score:
			best = target
			best_score = score
	return best


func get_snapshot() -> Dictionary:
	return {
		&"proximity_weight": proximity_weight,
		&"execute_weight": execute_weight,
		&"priority_weight": priority_weight,
		&"density_weight": density_weight,
		&"density_radius": density_radius,
		&"maximum_priority_rank": maximum_priority_rank,
		&"reference_density_count": reference_density_count,
	}


func _nearby_count(target: Node2D, candidates: Array) -> int:
	var result := 0
	var radius_squared := density_radius * density_radius
	for other in candidates:
		if (
			other is Node2D
			and other != target
			and target.global_position.distance_squared_to((other as Node2D).global_position)
			<= radius_squared
		):
			result += 1
	return result
