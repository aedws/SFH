class_name BossEdgeProjection
extends RefCounted


static func project(screen_position: Vector2, viewport_size: Vector2, inset: float) -> Dictionary:
	if not screen_position.is_finite() or not viewport_size.is_finite() \
		or viewport_size.x <= inset * 2.0 or viewport_size.y <= inset * 2.0:
		return {}
	if Rect2(Vector2.ZERO, viewport_size).has_point(screen_position):
		return {}
	var center := viewport_size * 0.5
	var direction := screen_position - center
	var half := center - Vector2.ONE * inset
	var fraction := minf(
		half.x / absf(direction.x) if not is_zero_approx(direction.x) else INF,
		half.y / absf(direction.y) if not is_zero_approx(direction.y) else INF
	)
	return {&"position": center + direction * fraction, &"angle": direction.angle()}
