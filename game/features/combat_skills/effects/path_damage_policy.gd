class_name PathDamagePolicy
extends Resource

## 선분을 따라 공개 take_damage 계약을 가진 대상에 피해를 주는 교체형 정책입니다.

@export_range(0.0, 10000.0, 1.0) var damage: float = 12.0
@export_range(1.0, 256.0, 1.0) var half_width: float = 40.0
@export_range(1, 128, 1) var maximum_targets: int = 24
@export var applied_status_id: StringName = &"ionized"
@export_range(0.0, 30.0, 0.1) var applied_status_duration: float = 4.0
@export var trigger_status_id: StringName = &"shock"
@export_range(0.0, 10000.0, 1.0) var trigger_bonus_damage: float = 8.0


func is_valid() -> bool:
	return damage >= 0.0 and half_width > 0.0 and maximum_targets > 0


func apply(
	target_container: Node,
	start: Vector2,
	destination: Vector2,
	damage_enabled: bool = true,
	mechanic_override: Dictionary = {}
) -> Dictionary:
	var effective_damage := damage * float(mechanic_override.get(&"damage_multiplier", 1.0))
	var snapshot := {
		&"damage": effective_damage if damage_enabled else 0.0,
		&"half_width": half_width,
		&"maximum_targets": maximum_targets,
		&"hit_count": 0,
		&"evaluated_targets": 0,
		&"status_triggers": 0,
	}
	if (
		not damage_enabled
		or effective_damage <= 0.0
		or not is_valid()
		or not is_instance_valid(target_container)
		or start.is_equal_approx(destination)
	):
		return snapshot
	var hit_count := 0
	var evaluated_targets := 0
	var width_squared := half_width * half_width
	var status_triggers := 0
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
		var target_damage := effective_damage
		if trigger_status_id != &"" and target.has_method(&"has_status") and bool(target.call(&"has_status", trigger_status_id)):
			target_damage += trigger_bonus_damage
			status_triggers += 1
			if target.has_method(&"consume_status"):
				target.call(&"consume_status", trigger_status_id, 1)
		target.call(&"take_damage", target_damage, {
			&"source_kind": &"blink_path",
			&"source_position": closest,
			&"impact_direction": start.direction_to(destination),
			&"impact_strength": clampf(target_damage / 12.0, 0.6, 1.6),
		})
		if applied_status_id != &"" and target.has_method(&"apply_status"):
			target.call(&"apply_status", applied_status_id, applied_status_duration, 1)
		hit_count += 1
	snapshot[&"hit_count"] = hit_count
	snapshot[&"evaluated_targets"] = evaluated_targets
	snapshot[&"status_triggers"] = status_triggers
	return snapshot


func get_snapshot() -> Dictionary:
	return {
		&"damage": damage,
		&"half_width": half_width,
		&"maximum_targets": maximum_targets,
		&"applied_status_id": applied_status_id,
		&"trigger_status_id": trigger_status_id,
		&"trigger_bonus_damage": trigger_bonus_damage,
	}
