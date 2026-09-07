class_name CircularCoverageSolver
extends RefCounted

## Pure geometry, evaluated only on targeting requests. No scene/state ownership.
## Angular sweep: O(n² log n) time, O(n) temporary storage per anchor.

static func solve(points: PackedVector2Array, radius: float, cast_range: float) -> Vector2:
	if points.is_empty():
		return Vector2.ZERO
	var best := points[0]
	var best_count := 0
	var best_anchor_distance := INF
	var radius_squared := radius * radius
	# Numerical boundary tolerance only (not an extra gameplay radius).
	var tolerance := maxf(0.000001, radius_squared * 0.000001)
	for anchor in points:
		var starts := PackedFloat64Array()
		var ends := PackedFloat64Array()
		var coincident := 0
		for point in points:
			var offset := point - anchor
			var distance := offset.length()
			if distance == 0.0:
				coincident += 1
				continue
			if distance > radius * 2.0:
				continue
			var half_angle := acos(clampf(distance / (radius * 2.0), -1.0, 1.0))
			var start := fposmod(offset.angle() - half_angle, TAU)
			var finish := start + half_angle * 2.0
			starts.append(start)
			ends.append(minf(finish, TAU))
			if finish >= TAU:
				starts.append(0.0)
				ends.append(finish - TAU)
		# Native numeric sorts avoid per-comparison GDScript callbacks/allocations.
		starts.sort()
		ends.sort()
		var count := coincident
		var peak := coincident
		var angle := 0.0
		var widest := -1.0
		var start_index := 0
		var end_index := 0
		while end_index < ends.size():
			var event_angle: float
			# Starts before ends: a closed circle includes tangent points.
			if start_index < starts.size() and starts[start_index] <= ends[end_index]:
				event_angle = starts[start_index]
				start_index += 1
				count += 1
				if count > peak:
					peak = count
					angle = event_angle
					widest = 0.0
			else:
				event_angle = ends[end_index]
				end_index += 1
				count -= 1
			# Prefer the interior of a maximum-coverage interval to its boundary.
			var next_start := starts[start_index] if start_index < starts.size() else TAU
			var next_end := ends[end_index] if end_index < ends.size() else TAU
			var width := minf(next_start, next_end) - event_angle
			if count >= peak and width > 0.0 and (count > peak or width > widest):
				peak = count
				angle = event_angle + width * 0.5
				widest = width
		if peak < best_count:
			continue
		var center := anchor if starts.is_empty() else anchor + Vector2.from_angle(angle) * radius
		# All eligible points are inside this convex cast disk. Projection cannot
		# increase distance to any of them, including near-range-edge clusters.
		center = center.limit_length(cast_range)
		var covered := PackedVector2Array()
		var sum := Vector2.ZERO
		for point in points:
			if center.distance_squared_to(point) <= radius_squared + tolerance:
				covered.append(point)
				sum += point
		# A centroid can lose boundary targets: use it only if coverage is retained.
		if not covered.is_empty():
			var centroid := sum / covered.size()
			var safe_centroid := true
			for point in covered:
				if centroid.distance_squared_to(point) > radius_squared + tolerance:
					safe_centroid = false
					break
			if safe_centroid:
				center = centroid
				if covered.size() == points.size():
					return center
		var anchor_distance := anchor.length_squared()
		if covered.size() > best_count or (covered.size() == best_count and anchor_distance < best_anchor_distance):
			best = center
			best_count = covered.size()
			best_anchor_distance = anchor_distance
	return best
