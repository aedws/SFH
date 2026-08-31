class_name PlayerMovementFeedback
extends Node2D

## 이동 규칙을 바꾸지 않고 출발·급정지·선회·대시를 눈에 보이게 만드는 선택형 표현 모듈입니다.

const ACCENT := Color("02e5e1")

@export var enabled: bool = true
@export_range(0.0, 12.0, 0.5) var body_lead_pixels: float = 5.0
@export_range(0.0, 0.3, 0.01) var body_stretch: float = 0.12
@export_range(0.0, 80.0, 1.0) var camera_lead_pixels: float = 30.0
@export_range(1.0, 40.0, 1.0) var camera_response: float = 18.0
@export_range(0.05, 0.5, 0.01) var cue_duration: float = 0.18
@export_range(2, 16, 1) var maximum_trail_points: int = 10
@export_range(1.0, 16.0, 0.5) var dash_trail_width: float = 9.0

@onready var actor := get_parent() as CharacterBody2D
@onready var body := actor.get_node_or_null("Body") as Polygon2D
@onready var heading := actor.get_node_or_null("Heading") as Polygon2D
@onready var camera := actor.get_node_or_null("Camera2D") as Camera2D

var body_base_position := Vector2.ZERO
var body_base_scale := Vector2.ONE
var heading_base_position := Vector2.ZERO
var heading_base_scale := Vector2.ONE
var camera_base_position := Vector2.ZERO
var previous_velocity := Vector2.ZERO
var last_direction := Vector2.RIGHT
var launch_cue: float = 0.0
var brake_cue: float = 0.0
var turn_cue: float = 0.0
var dash_cue: float = 0.0
var speed_ratio: float = 0.0
var visual_intensity: float = 0.0
var trail_points: Array[Vector2] = []
var trail_decay_accumulator: float = 0.0
var trail: Line2D


func _ready() -> void:
	if body != null:
		body_base_position = body.position
		body_base_scale = body.scale
	if heading != null:
		heading_base_position = heading.position
		heading_base_scale = heading.scale
	if camera != null:
		camera_base_position = camera.position
	_create_trail()
	set_physics_process(enabled)
	if not enabled:
		_restore_visuals()


func _physics_process(delta: float) -> void:
	if actor == null:
		return
	var movement_snapshot: Dictionary = actor.call(&"get_movement_snapshot")
	advance_feedback(
		actor.velocity,
		maxf(1.0, float(movement_snapshot.get(&"speed", 1.0))),
		delta,
		bool(movement_snapshot.get(&"dash_active", false)),
		actor.global_position
	)


func set_feedback_enabled(is_enabled: bool) -> void:
	enabled = is_enabled
	set_physics_process(enabled)
	if not enabled:
		trail_points.clear()
		_restore_visuals()
	else:
		queue_redraw()


func advance_feedback(
	world_velocity: Vector2,
	maximum_speed: float,
	delta: float,
	dash_active: bool,
	world_position: Vector2
) -> Dictionary:
	var safe_delta := maxf(0.0, delta)
	var previous_speed := previous_velocity.length()
	var current_speed := world_velocity.length()
	var safe_speed := maxf(1.0, maximum_speed)
	speed_ratio = clampf(current_speed / safe_speed, 0.0, 1.5)
	var start_threshold := safe_speed * 0.55
	var stop_threshold := safe_speed * 0.12
	if previous_speed <= stop_threshold and current_speed >= start_threshold:
		launch_cue = 1.0
	if previous_speed >= start_threshold and current_speed <= stop_threshold:
		brake_cue = 1.0
	if previous_speed >= start_threshold and current_speed >= start_threshold:
		var previous_direction := previous_velocity.normalized()
		var current_direction := world_velocity.normalized()
		if previous_direction.dot(current_direction) < 0.35:
			turn_cue = 1.0
	if current_speed > 0.01:
		last_direction = world_velocity.normalized()
	if dash_active:
		dash_cue = 1.0
	var cue_decay := safe_delta / maxf(0.01, cue_duration)
	launch_cue = move_toward(launch_cue, 0.0, cue_decay)
	brake_cue = move_toward(brake_cue, 0.0, cue_decay)
	turn_cue = move_toward(turn_cue, 0.0, cue_decay)
	dash_cue = move_toward(dash_cue, 0.0, cue_decay * (0.45 if dash_active else 1.0))
	visual_intensity = maxf(
		maxf(launch_cue, brake_cue),
		maxf(turn_cue, maxf(dash_cue, minf(0.42, speed_ratio * 0.28)))
	)
	_update_actor_visuals(safe_delta, dash_active)
	_update_trail(world_position, safe_delta, current_speed, safe_speed, dash_active)
	previous_velocity = world_velocity
	queue_redraw()
	return get_feedback_snapshot()


func get_feedback_snapshot() -> Dictionary:
	return {
		&"enabled": enabled,
		&"speed_ratio": speed_ratio,
		&"visual_intensity": visual_intensity,
		&"launch_cue_active": launch_cue > 0.05,
		&"brake_cue_active": brake_cue > 0.05,
		&"turn_cue_active": turn_cue > 0.05,
		&"dash_cue_active": dash_cue > 0.05,
		&"trail_point_count": trail_points.size(),
		&"trail_width": trail.width if trail != null else 0.0,
		&"body_offset_pixels": (
			body.position.distance_to(body_base_position) if body != null else 0.0
		),
		&"camera_lead_pixels": (
			camera.position.distance_to(camera_base_position) if camera != null else 0.0
		),
	}


func _update_actor_visuals(delta: float, dash_active: bool) -> void:
	var dash_weight := maxf(dash_cue, 1.0 if dash_active else 0.0)
	var lead_weight := clampf(speed_ratio, 0.0, 1.0)
	if body != null:
		var body_target := body_base_position + last_direction * body_lead_pixels * lead_weight
		body.position = body.position.lerp(body_target, _response_weight(22.0, delta))
		var stretch := body_stretch * maxf(lead_weight * 0.45, dash_weight)
		var squash := stretch * 0.45
		var directional_scale := Vector2(
			1.0 + absf(last_direction.x) * stretch - absf(last_direction.y) * squash,
			1.0 + absf(last_direction.y) * stretch - absf(last_direction.x) * squash
		)
		body.scale = body.scale.lerp(
			body_base_scale * directional_scale,
			_response_weight(24.0, delta)
		)
	if heading != null:
		heading.position = heading.position.lerp(
			heading_base_position + last_direction * (2.0 + dash_weight * 3.0),
			_response_weight(26.0, delta)
		)
		heading.scale = heading.scale.lerp(
			heading_base_scale * (1.0 + dash_weight * 0.22),
			_response_weight(24.0, delta)
		)
	if camera != null:
		var camera_multiplier := 1.45 if dash_active else 1.0
		var camera_target := (
			camera_base_position
			+ last_direction * camera_lead_pixels * lead_weight * camera_multiplier
		)
		camera.position = camera.position.lerp(
			camera_target,
			_response_weight(camera_response, delta)
		)


func _update_trail(
	world_position: Vector2,
	delta: float,
	current_speed: float,
	maximum_speed: float,
	dash_active: bool
) -> void:
	if trail == null:
		return
	var moving := current_speed >= maximum_speed * 0.28
	if moving and (trail_points.is_empty() or trail_points[-1].distance_to(world_position) >= 3.0):
		trail_points.append(world_position)
	var point_limit := maximum_trail_points if dash_active else mini(5, maximum_trail_points)
	while trail_points.size() > point_limit:
		trail_points.pop_front()
	if not moving:
		trail_decay_accumulator += delta
		while trail_decay_accumulator >= 0.025 and not trail_points.is_empty():
			trail_points.pop_front()
			trail_decay_accumulator -= 0.025
	else:
		trail_decay_accumulator = 0.0
	trail.clear_points()
	for point in trail_points:
		trail.add_point(point)
	trail.width = lerpf(3.0, dash_trail_width, maxf(dash_cue, 1.0 if dash_active else 0.0))
	trail.visible = trail_points.size() >= 2


func _create_trail() -> void:
	trail = Line2D.new()
	trail.name = "VelocityTrail"
	trail.z_index = -1
	trail.joint_mode = Line2D.LINE_JOINT_ROUND
	trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 1.0])
	fade.colors = PackedColorArray([
		Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.0),
		Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.78),
	])
	trail.gradient = fade
	add_child(trail)
	trail.set_as_top_level(true)
	trail.global_position = Vector2.ZERO
	trail.visible = false


func _draw() -> void:
	if not enabled or visual_intensity <= 0.04:
		return
	var side := Vector2(-last_direction.y, last_direction.x)
	var backward := -last_direction
	var streak_count := 3 if dash_cue > 0.25 else 2
	for index in streak_count:
		var distance := 24.0 + index * 11.0
		var half_gap := 11.0 + index * 3.0
		var alpha := (0.18 + visual_intensity * 0.46) * (1.0 - index * 0.18)
		var start := backward * distance + side * half_gap
		var finish := start + backward * (9.0 + visual_intensity * 13.0)
		var mirrored_start := backward * distance - side * half_gap
		var mirrored_finish := mirrored_start + backward * (9.0 + visual_intensity * 13.0)
		draw_line(start, finish, Color(ACCENT.r, ACCENT.g, ACCENT.b, alpha), 2.0)
		draw_line(mirrored_start, mirrored_finish, Color(ACCENT.r, ACCENT.g, ACCENT.b, alpha), 2.0)
	if launch_cue > 0.05:
		draw_arc(Vector2.ZERO, 22.0 + (1.0 - launch_cue) * 10.0, -0.8, 0.8, 12, Color(ACCENT.r, ACCENT.g, ACCENT.b, launch_cue * 0.75), 2.0)
	if brake_cue > 0.05:
		draw_arc(Vector2.ZERO, 20.0 + (1.0 - brake_cue) * 8.0, 0.0, TAU, 24, Color(1.0, 0.72, 0.24, brake_cue * 0.7), 2.0)
	if turn_cue > 0.05:
		draw_line(side * 24.0, -side * 24.0, Color(ACCENT.r, ACCENT.g, ACCENT.b, turn_cue * 0.6), 2.0)


func _restore_visuals() -> void:
	if body != null:
		body.position = body_base_position
		body.scale = body_base_scale
	if heading != null:
		heading.position = heading_base_position
		heading.scale = heading_base_scale
	if camera != null:
		camera.position = camera_base_position
	if trail != null:
		trail.clear_points()
		trail.visible = false
	queue_redraw()


func _response_weight(response: float, delta: float) -> float:
	return 1.0 - exp(-maxf(0.0, response) * maxf(0.0, delta))
