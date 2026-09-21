class_name EnemyAttackPolicy
extends Resource
## Geometry and timing only; no target, damage or scene ownership.
@export var enabled := true
@export_range(0.3, 0.5, 0.05) var windup_seconds := 0.4
@export_range(16.0, 160.0, 1.0) var reach := 48.0
@export_range(2.0, 32.0, 1.0) var half_width := 10.0
@export_range(0.0, 32.0, 1.0) var displacement_tolerance := 8.0
@export var warning_color := Color(1.0, 0.18, 0.12, 0.85)

func is_valid() -> bool:
	return is_finite(windup_seconds) and windup_seconds > 0.0 and is_finite(reach) and reach > 0.0 and is_finite(half_width) and half_width > 0.0 and half_width <= reach and is_finite(displacement_tolerance) and displacement_tolerance >= 0.0

func contains(offset: Vector2, direction: Vector2) -> bool:
	var forward := offset.dot(direction.normalized())
	return forward >= 0.0 and forward <= reach and absf(offset.cross(direction.normalized())) <= half_width
