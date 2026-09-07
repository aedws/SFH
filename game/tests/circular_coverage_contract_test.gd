extends SceneTree

const SOLVER = preload("res://game/features/smart_targeting/circular_coverage_solver.gd")
var failures := PackedStringArray()

func _init() -> void:
	call_deferred(&"_run")

func _run() -> void:
	_case("bridge between anchors", PackedVector2Array([Vector2(-9, 0), Vector2(9, 0)]), 10, 100, 2)
	_case("diameter tangent", PackedVector2Array([Vector2(-10, 0), Vector2(10, 0)]), 10, 100, 2)
	_case("centroid loses boundary", PackedVector2Array([Vector2(-10, 0), Vector2(10, 0), Vector2(8, 0), Vector2(8, 0), Vector2(8, 0)]), 10, 100, 5)
	_case("cast boundary projection", PackedVector2Array([Vector2(90, -40), Vector2(90, 40)]), 40, 100, 2)
	_case("coincident actors", PackedVector2Array([Vector2(20, 20), Vector2(20, 20)]), 3, 100, 2)
	_case("empty", PackedVector2Array(), 10, 100, 0)
	for angle_index in 36:
		var direction := Vector2.from_angle(angle_index * TAU / 36)
		var ring := PackedVector2Array([direction * 9.999, -direction * 9.999, direction.orthogonal() * 9.999])
		_case("rotated near tangent %d" % angle_index, ring, 10, 100, 3)
	var random := RandomNumberGenerator.new()
	random.seed = 260307
	for trial in 240:
		var radius := random.randf_range(4, 80)
		var points := PackedVector2Array()
		for index in 4 + trial % 9:
			points.append(Vector2.from_angle(random.randf_range(0, TAU)) * random.randf_range(0, 200))
		_case("oracle %d" % trial, points, radius, 200, _oracle(points, radius))
		var center := SOLVER.solve(points, radius, 200)
		# Policy supplies stable coordinate order; the solver must not mutate it.
		_check(_hits(center, points, radius) == _oracle(points, radius), "input preserved %d" % trial)
	var samples := PackedFloat64Array()
	for layout in 3:
		var points := PackedVector2Array()
		for index in 72:
			var spacing := 12.0 if layout == 0 else 44.0
			points.append(Vector2(index % 9, index / 9) * spacing - Vector2(180, 160))
			if layout == 2:
				points[index] = Vector2.from_angle(index * TAU / 72) * 180
		for repeat in 24:
			var started := Time.get_ticks_usec()
			var center := SOLVER.solve(points, 180, 600)
			samples.append((Time.get_ticks_usec() - started) / 1000.0)
			_check(center.length() <= 600.001 and _hits(center, points, 180) > 0, "72 targets valid")
	samples.sort()
	var p95 := samples[int(samples.size() * 0.95)]
	print("CIRCULAR_COVERAGE_PERF targets=72 samples=%d p95_ms=%.3f max_ms=%.3f" % [samples.size(), p95, samples[-1]])
	# Request-time budget, not a claim about complete-frame/browser FPS.
	_check(p95 < 16.67, "72-target request p95 exceeds one 60Hz frame: %.3fms" % p95)
	if failures.is_empty():
		print("CIRCULAR_COVERAGE_OK maximum_hits bridge tangent centroid_guard cast_range oracle_240 coincident performance_72")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _case(label: String, points: PackedVector2Array, radius: float, cast_range: float, expected: int) -> void:
	var center := SOLVER.solve(points, radius, cast_range)
	_check(_hits(center, points, radius) == expected, "%s expected=%d actual=%d center=%s" % [label, expected, _hits(center, points, radius), center])
	_check(center.length() <= cast_range + 0.001, label + " cast range")

func _hits(center: Vector2, points: PackedVector2Array, radius: float) -> int:
	var count := 0
	for point in points:
		if center.distance_squared_to(point) <= radius * radius + maxf(0.000001, radius * radius * 0.000001):
			count += 1
	return count

func _oracle(points: PackedVector2Array, radius: float) -> int:
	# Independent O(n³) pair-circle intersection oracle, test fixtures only.
	var best := 0
	for a in points:
		best = maxi(best, _hits(a, points, radius))
		for b in points:
			var delta := b - a
			var distance := delta.length()
			if distance == 0 or distance > radius * 2:
				continue
			var midpoint := (a + b) * 0.5
			var height := sqrt(maxf(0, radius * radius - distance * distance * 0.25))
			var perpendicular := Vector2(-delta.y, delta.x) / distance
			best = maxi(best, _hits(midpoint + perpendicular * height, points, radius))
			best = maxi(best, _hits(midpoint - perpendicular * height, points, radius))
	return best

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
