class_name ElectricArcEffect
extends Node2D

## 짧은 수명의 전기 궤적을 제한된 주기로 생성하고 캐시해 그립니다.

var profile: Resource
var maximum_radius: float = 120.0
var trail_vector := Vector2.RIGHT * 120.0
var followed_target: Node2D
var elapsed_seconds: float = 0.0
var refresh_accumulator: float = 0.0
var geometry_rebuild_count: int = 0
var cached_arcs: Array[PackedVector2Array] = []
var random := RandomNumberGenerator.new()


func configure_radial(
	radius: float,
	new_profile: Resource,
	new_followed_target: Node2D = null
) -> bool:
	if not _accept_profile(new_profile):
		return false
	maximum_radius = maxf(8.0, radius)
	followed_target = new_followed_target
	_rebuild_geometry()
	return true


func configure_trail(vector: Vector2, new_profile: Resource) -> bool:
	if not _accept_profile(new_profile) or vector.length() < 4.0:
		return false
	trail_vector = vector
	_rebuild_geometry()
	return true


func get_snapshot() -> Dictionary:
	return {
		&"pattern": profile.get("pattern") if profile != null else "",
		&"line_segments": int(profile.call(&"estimated_line_segments")) if profile != null else 0,
		&"geometry_refresh_hz": float(profile.get("geometry_refresh_hz")) if profile != null else 0.0,
		&"geometry_rebuild_count": geometry_rebuild_count,
		&"cached_arc_count": cached_arcs.size(),
	}


func _accept_profile(new_profile: Resource) -> bool:
	if (
		new_profile == null
		or not new_profile.has_method(&"is_valid")
		or not new_profile.has_method(&"estimated_line_segments")
		or not bool(new_profile.call(&"is_valid"))
	):
		return false
	profile = new_profile
	add_to_group(&"combat_skill_electric_effect")
	random.seed = int(Time.get_ticks_usec()) ^ int(get_instance_id())
	return true


func _process(delta: float) -> void:
	if profile == null:
		queue_free()
		return
	var safe_delta := maxf(0.0, delta)
	elapsed_seconds += safe_delta
	refresh_accumulator += safe_delta
	var lifetime := float(profile.get("lifetime_seconds"))
	if elapsed_seconds >= lifetime:
		queue_free()
		return
	self_modulate.a = clampf(1.0 - elapsed_seconds / lifetime, 0.0, 1.0)
	if is_instance_valid(followed_target):
		global_position = followed_target.global_position
	var refresh_interval := 1.0 / float(profile.get("geometry_refresh_hz"))
	if refresh_accumulator >= refresh_interval:
		refresh_accumulator = fmod(refresh_accumulator, refresh_interval)
		_rebuild_geometry()


func _rebuild_geometry() -> void:
	cached_arcs.clear()
	match String(profile.get("pattern")):
		"trail":
			_build_trail_arcs()
		"burst":
			_build_burst_arcs()
		_:
			_build_ring_arcs()
	geometry_rebuild_count += 1
	queue_redraw()


func _build_trail_arcs() -> void:
	var arc_count := int(profile.get("arc_count"))
	var point_count := int(profile.get("points_per_arc"))
	var jitter := float(profile.get("jitter_pixels"))
	var perpendicular := trail_vector.normalized().orthogonal()
	for arc_index in arc_count:
		var points := PackedVector2Array()
		var lane_offset := (float(arc_index) - float(arc_count - 1) * 0.5) * 2.5
		for point_index in point_count:
			var ratio := float(point_index) / float(point_count - 1)
			var envelope := sin(ratio * PI)
			var noise := random.randf_range(-jitter, jitter) * envelope
			points.append(trail_vector * ratio + perpendicular * (lane_offset + noise))
		cached_arcs.append(points)


func _build_ring_arcs() -> void:
	var arc_count := int(profile.get("arc_count"))
	var point_count := int(profile.get("points_per_arc"))
	var jitter := float(profile.get("jitter_pixels"))
	var arc_span := TAU / float(arc_count) * 0.84
	for arc_index in arc_count:
		var points := PackedVector2Array()
		var start_angle := TAU * float(arc_index) / float(arc_count) + random.randf_range(-0.08, 0.08)
		for point_index in point_count:
			var ratio := float(point_index) / float(point_count - 1)
			var angle := start_angle + arc_span * ratio
			var radius_noise := random.randf_range(-jitter, jitter) * sin(ratio * PI)
			points.append(Vector2.from_angle(angle) * (maximum_radius + radius_noise))
		cached_arcs.append(points)


func _build_burst_arcs() -> void:
	var arc_count := int(profile.get("arc_count"))
	var point_count := int(profile.get("points_per_arc"))
	var jitter := float(profile.get("jitter_pixels"))
	for arc_index in arc_count:
		var points := PackedVector2Array()
		var direction := Vector2.from_angle(TAU * float(arc_index) / float(arc_count) + random.randf_range(-0.24, 0.24))
		var perpendicular := direction.orthogonal()
		for point_index in point_count:
			var ratio := float(point_index) / float(point_count - 1)
			var noise := random.randf_range(-jitter, jitter) * sin(ratio * PI)
			points.append(direction * maximum_radius * ratio + perpendicular * noise)
		cached_arcs.append(points)


func _draw() -> void:
	if profile == null:
		return
	var fill_alpha := float(profile.get("field_fill_alpha"))
	if fill_alpha > 0.0 and String(profile.get("pattern")) != "trail":
		var fill_color: Color = profile.get("glow_color")
		fill_color.a = fill_alpha
		draw_circle(Vector2.ZERO, maximum_radius, fill_color, true)
	var glow_color: Color = profile.get("glow_color")
	var core_color: Color = profile.get("core_color")
	var glow_width := float(profile.get("glow_width"))
	var core_width := float(profile.get("core_width"))
	for points in cached_arcs:
		draw_polyline(points, glow_color, glow_width, true)
		draw_polyline(points, core_color, core_width, true)
