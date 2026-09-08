class_name WeaponDistancePolicy
extends RefCounted

# Normalized launch range : direct projectile damage multiplier. Piecewise linear.
const NEUTRAL := "0:1;1:1"


static func parse(value: String) -> PackedVector2Array:
	var result := PackedVector2Array()
	var entries := value.split(";", true)
	if entries.size() < 2 or entries.size() > 16:
		return result
	for entry in entries:
		var pair := entry.split(":", true)
		if pair.size() != 2 or not pair[0].is_valid_float() or not pair[1].is_valid_float():
			return PackedVector2Array()
		var x := float(pair[0])
		var y := float(pair[1])
		if not is_finite(x) or not is_finite(y) or x < 0.0 or x > 1.0 or y < 0.0 or y > 3.0:
			return PackedVector2Array()
		if not result.is_empty() and x <= result[-1].x:
			return PackedVector2Array()
		result.append(Vector2(x, y))
	if result[0].x != 0.0 or result[-1].x != 1.0:
		return PackedVector2Array()
	return result


static func multiplier(points: PackedVector2Array, distance_px: float, launch_range_px: float) -> float:
	if points.size() < 2 or not is_finite(launch_range_px) or launch_range_px <= 0.0:
		return 1.0
	var ratio := clampf(distance_px / launch_range_px, 0.0, 1.0)
	for index in range(1, points.size()):
		if ratio <= points[index].x:
			var a := points[index - 1]
			var b := points[index]
			return lerpf(a.y, b.y, (ratio - a.x) / (b.x - a.x))
	return points[-1].y
