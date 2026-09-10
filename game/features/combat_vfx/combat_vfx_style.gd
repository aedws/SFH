class_name CombatVfxStyle
extends Resource

## Presentation only: contrast, hold and release. Never changes targeting or damage.
@export var world_z: int = 12
@export_range(0.1, 0.6, 0.01) var pulse_lifetime: float = 0.34
@export_range(0.03, 0.2, 0.01) var bright_hold: float = 0.10
@export_range(1.0, 12.0, 0.5) var stroke_width: float = 5.0
@export var shadow_color := Color(0.01, 0.02, 0.035, 0.9)
@export var core_color := Color(0.94, 1.0, 1.0, 1.0)

func envelope(age: float, lifetime: float = -1.0) -> float:
	if lifetime < 0.0: lifetime = pulse_lifetime
	return clampf((lifetime - age) / maxf(0.001, lifetime - minf(bright_hold, lifetime * 0.5)), 0.0, 1.0)

func stroke(canvas: CanvasItem, points: PackedVector2Array, tint: Color, alpha: float = 1.0, width: float = -1.0) -> void:
	if points.size() < 2 or alpha <= 0.0: return
	if width < 0.0: width = stroke_width
	# Dark separation works on bright floors; broad color + narrow white works in shadow.
	canvas.draw_polyline(points, Color(shadow_color, shadow_color.a * alpha), width + 4.0, true)
	canvas.draw_polyline(points, Color(tint, alpha * 0.85), width, true)
	canvas.draw_polyline(points, Color(core_color, alpha), maxf(2.8, width * 0.32), true)

func arc_points(radius: float, first: float, last: float, center := Vector2.ZERO) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 33: points.append(center + Vector2.from_angle(lerpf(first, last, float(i)/32.0)) * radius)
	return points

func bolt(start: Vector2, end: Vector2, phase: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var tangent := start.direction_to(end).orthogonal()
	var amplitude := minf(12.0, start.distance_to(end) * 0.05)
	for i in 9:
		var t := float(i)/8.0
		points.append(start.lerp(end,t) + tangent * sin(t*PI) * sin(i*2.3+phase*18.0) * amplitude)
	return points
