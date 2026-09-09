class_name MeleeStrikePolicy
extends RefCounted
## Pure geometry. Damage, actors, rendering and physics are owned by the caller.

static func contains(offset: Vector2, direction: Vector2, reach: float, angle_deg: float, mode: StringName) -> bool:
	if direction.is_zero_approx() or reach <= 0.0: return false
	if offset.length_squared() > reach * reach: return false
	var forward := offset.dot(direction.normalized())
	if forward < 0.0: return false
	if mode == &"melee_thrust":
		var half_width := maxf(8.0, reach * tan(deg_to_rad(angle_deg * 0.5)))
		return absf(offset.dot(direction.normalized().orthogonal())) <= half_width
	return offset.is_zero_approx() or absf(direction.angle_to(offset)) <= deg_to_rad(angle_deg * 0.5)
