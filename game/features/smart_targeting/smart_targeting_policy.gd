class_name SmartTargetingPolicy
extends Resource

## 스킬 정의가 요청한 대상 유형을 하나의 교체형 정책에서 해석합니다.

@export_range(32.0, 600.0, 8.0) var density_radius := 180.0
@export_range(1.0, 20.0, 1.0) var maximum_priority_rank := 5.0


func is_valid() -> bool:
	return density_radius > 0.0 and maximum_priority_rank > 0.0


func resolve(mode: StringName, origin: Vector2, candidates: Array, maximum_range: float, input_direction: Vector2 = Vector2.RIGHT) -> Dictionary:
	var safe_range := maxf(1.0, maximum_range)
	var target: Node2D
	var target_point := origin
	var direction := input_direction.normalized() if not input_direction.is_zero_approx() else Vector2.RIGHT
	match mode:
		&"highest_health", &"elite", &"nearest":
			target = select_target_for_mode(mode, origin, candidates, safe_range)
		&"densest":
			target_point = select_densest_point(origin, candidates, safe_range)
			target = _nearest_to_point(target_point, candidates, safe_range)
		&"direction":
			target_point = origin + direction * safe_range
		_:
			target_point = origin
	if is_instance_valid(target):
		target_point = target.global_position
		direction = origin.direction_to(target_point)
	return {&"mode": mode, &"target": target, &"target_point": target_point, &"direction": direction}


func select_target(origin: Vector2, candidates: Array, maximum_range: float) -> Node2D:
	return select_target_for_mode(&"nearest", origin, candidates, maximum_range)


func select_target_for_mode(mode: StringName, origin: Vector2, candidates: Array, maximum_range: float) -> Node2D:
	var best: Node2D
	var best_primary := -INF
	var best_distance := INF
	for candidate in candidates:
		if not candidate is Node2D or candidate.is_queued_for_deletion():
			continue
		var target := candidate as Node2D
		var distance := origin.distance_to(target.global_position)
		if distance > maximum_range:
			continue
		var snapshot := _snapshot(target)
		var primary := -distance
		if mode == &"highest_health":
			primary = float(snapshot.get(&"maximum_health", 0.0))
		elif mode == &"elite":
			primary = float(snapshot.get(&"priority_rank", 1.0)) * 100000.0 + float(snapshot.get(&"maximum_health", 0.0))
		if primary > best_primary or (is_equal_approx(primary, best_primary) and distance < best_distance):
			best = target
			best_primary = primary
			best_distance = distance
	return best


func select_densest_point(origin: Vector2, candidates: Array, maximum_range: float) -> Vector2:
	var valid: Array[Node2D] = []
	for candidate in candidates:
		if candidate is Node2D and not candidate.is_queued_for_deletion() and origin.distance_to((candidate as Node2D).global_position) <= maximum_range:
			valid.append(candidate as Node2D)
	if valid.is_empty():
		return origin
	var best_cluster: Array[Node2D] = []
	var best_anchor_distance := INF
	var radius_squared := density_radius * density_radius
	for anchor in valid:
		var cluster: Array[Node2D] = []
		for candidate in valid:
			if anchor.global_position.distance_squared_to(candidate.global_position) <= radius_squared:
				cluster.append(candidate)
		var anchor_distance := origin.distance_squared_to(anchor.global_position)
		if cluster.size() > best_cluster.size() or (cluster.size() == best_cluster.size() and anchor_distance < best_anchor_distance):
			best_cluster = cluster
			best_anchor_distance = anchor_distance
	var center := Vector2.ZERO
	for target in best_cluster:
		center += target.global_position
	return center / float(best_cluster.size())


func get_snapshot() -> Dictionary:
	return {&"modes": PackedStringArray(["nearest", "highest_health", "elite", "densest", "direction"]), &"density_radius": density_radius, &"maximum_priority_rank": maximum_priority_rank}


func _snapshot(target: Node2D) -> Dictionary:
	return target.call(&"get_targeting_snapshot") if target.has_method(&"get_targeting_snapshot") else {}


func _nearest_to_point(point: Vector2, candidates: Array, maximum_distance: float) -> Node2D:
	var nearest: Node2D
	var nearest_distance := maximum_distance
	for candidate in candidates:
		if candidate is Node2D:
			var distance := point.distance_to((candidate as Node2D).global_position)
			if distance < nearest_distance:
				nearest = candidate as Node2D
				nearest_distance = distance
	return nearest
