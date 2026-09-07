class_name TargetCandidateArea
extends Area2D
## Broad phase only: preserves provider ownership/order and policy center-distance rules.
## Physics overlap lists lag new shapes by a frame. Prime using the provider, not an empty list.

@export_flags_2d_physics var target_mask := 2
var _circle := CircleShape2D.new()
var _ready_frame := -1
var _configured_radius := -1.0
var _seen := {}
var _previous_origin := Vector2.INF


func _ready() -> void:
	collision_layer = 0
	collision_mask = target_mask
	monitorable = false
	var collision := CollisionShape2D.new()
	collision.shape = _circle
	add_child(collision)
	_ready_frame = Engine.get_physics_frames() + 2


func collect(allowed: Array, origin: Vector2, radius: float) -> Array:
	if not is_finite(radius) or radius <= 0.0:
		return []
	if not is_equal_approx(_configured_radius, radius):
		_circle.radius = radius
		_configured_radius = radius
		_ready_frame = Engine.get_physics_frames() + 2
	if not _previous_origin.is_finite() or _previous_origin.distance_to(origin) > radius * 0.5:
		_ready_frame = Engine.get_physics_frames() + 2
	_previous_origin = origin
	var overlaps := {}
	for body in get_overlapping_bodies():
		overlaps[body.get_instance_id()] = true
	var priming := Engine.get_physics_frames() <= _ready_frame
	var result: Array = []
	var next_seen := {}
	for candidate in allowed:
		if not is_instance_valid(candidate) or not candidate is Node2D or candidate.is_queued_for_deletion():
			continue
		var id: int = candidate.get_instance_id()
		next_seen[id] = true
		if origin.distance_squared_to(candidate.global_position) > radius * radius:
			continue
		# Non-physics providers remain supported (custom/training targets).
		if priming or not _seen.has(id) or not candidate is PhysicsBody2D or overlaps.has(id):
			result.append(candidate)
	_seen = next_seen
	return result
