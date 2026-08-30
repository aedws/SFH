class_name PathDamagePolicy
extends Resource

## 선분을 따라 공개 take_damage 계약을 가진 대상에 피해를 주는 교체형 정책입니다.

@export_range(0.0, 10000.0, 1.0) var damage: float = 12.0
@export_range(1.0, 256.0, 1.0) var half_width: float = 40.0
@export_range(1, 128, 1) var maximum_targets: int = 24


func is_valid() -> bool:
	return damage >= 0.0 and half_width > 0.0 and maximum_targets > 0


func apply(
	target_container: Node,
	start: Vector2,
	destination: Vector2,
	damage_enabled: bool = true
) -> Dictionary:
	var snapshot := {
		&"damage": damage if damage_enabled else 0.0,
		&"half_width": half_width,
		&"maximum_targets": maximum_targets,
		&"hit_count": 0,
		&"evaluated_targets": 0,
	}
	if (
		not damage_enabled
		or damage <= 0.0
		or not is_valid()
		or not is_instance_valid(target_container)
		or start.is_equal_approx(destination)
	):
		return snapshot
	var hit_count := 0
	var evaluated_targets := 0
	var width_squared := half_width * half_width
	for child_index in target_container.get_child_count():
		if hit_count >= maximum_targets:
			break
		var candidate := target_container.get_child(child_index)
		if (
			not candidate is Node2D
			or not candidate.has_method(&"take_damage")
			or candidate.is_queued_for_deletion()
		):
			continue
		evaluated_targets += 1
		var target := candidate as Node2D
		var closest := Geometry2D.get_closest_point_to_segment(
			target.global_position, start, destination
		)
		if target.global_position.distance_squared_to(closest) > width_squared:
			continue
		target.call(&"take_damage", damage)
		hit_count += 1
	snapshot[&"hit_count"] = hit_count
	snapshot[&"evaluated_targets"] = evaluated_targets
	return snapshot


func get_snapshot() -> Dictionary:
	return {
		&"damage": damage,
		&"half_width": half_width,
		&"maximum_targets": maximum_targets,
	}
