class_name BattlefieldFogOfWar
extends CanvasLayer

const MAX_SHADER_ROOM_RECTS := 64
const MAX_OCCLUSION_RAYS := 48
const WALL_COLLISION_MASK := 16

@export_range(80.0, 500.0, 10.0) var corridor_near_radius: float = 220.0
@export_range(300.0, 1600.0, 10.0) var corridor_forward_distance: float = 780.0
@export_range(20.0, 85.0, 1.0) var corridor_half_angle_degrees: float = 68.0
@export_range(1.0, 30.0, 1.0) var corridor_angle_softness_degrees: float = 12.0
@export_range(10.0, 300.0, 10.0) var corridor_distance_softness: float = 130.0
@export_range(100.0, 600.0, 10.0) var corridor_comfort_shell_radius: float = 320.0
@export_range(0.0, 0.6, 0.01) var corridor_comfort_shell_visibility: float = 0.24
@export_range(0.0, 80.0, 2.0) var room_edge_softness: float = 18.0
@export_range(0.05, 1.0, 0.01) var room_enter_transition_seconds: float = 0.22
@export_range(0.05, 1.0, 0.01) var room_exit_transition_seconds: float = 0.32
@export_range(0.0, 30.0, 1.0) var doorway_hysteresis_pixels: float = 14.0
@export_range(1.0, 30.0, 1.0) var facing_smoothing_speed: float = 14.0
@export var occlusion_enabled: bool = true
@export_range(0.03, 0.2, 0.01) var occlusion_refresh_seconds: float = 0.07
@export_range(4.0, 48.0, 1.0) var occlusion_edge_softness: float = 18.0
@export_range(0.0, 0.3, 0.01) var explored_room_tint_strength: float = 0.12
@export_range(0.0, 0.04, 0.001) var fog_noise_strength: float = 0.008
@export var fog_color := Color(0.008, 0.014, 0.025, 0.97)
@export var explored_fog_color := Color(0.006, 0.09, 0.11, 0.97)

@onready var overlay: ColorRect = %FogOverlay

var tracked_actor: Node2D
var visibility_provider: Node
var room_world_rects: Array[Rect2] = []
var visibility_mode: StringName = &"corridor"
var active_room_index: int = -1
var transition_room_index: int = -1
var transition_room_world_rect := Rect2()
var transition_room_detection_rect := Rect2()
var room_visibility_blend: float = 0.0
var previous_room_world_rect := Rect2()
var previous_room_visibility_blend: float = 0.0
var current_facing_direction := Vector2.RIGHT
var active_screen_room_count: int = 0
var focus_initialized: bool = false
var visibility_multiplier: float = 1.0
var doorway_hysteresis_active: bool = false
var explored_room_indices: Dictionary = {}
var occlusion_distances := PackedFloat32Array()
var occlusion_refresh_remaining: float = 0.0
var last_occlusion_origin := Vector2.INF


func _ready() -> void:
	layer = 0
	process_mode = Node.PROCESS_MODE_PAUSABLE
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


func configure(actor: Node2D, new_visibility_provider: Node = null) -> bool:
	if not is_instance_valid(actor):
		return false
	tracked_actor = actor
	visibility_provider = null
	room_world_rects.clear()
	visibility_mode = &"corridor"
	active_room_index = -1
	transition_room_index = -1
	transition_room_world_rect = Rect2()
	transition_room_detection_rect = Rect2()
	room_visibility_blend = 0.0
	previous_room_world_rect = Rect2()
	previous_room_visibility_blend = 0.0
	doorway_hysteresis_active = false
	explored_room_indices.clear()
	occlusion_distances.resize(MAX_OCCLUSION_RAYS)
	occlusion_distances.fill(corridor_forward_distance * visibility_multiplier)
	occlusion_refresh_remaining = 0.0
	last_occlusion_origin = Vector2.INF
	focus_initialized = false
	if is_instance_valid(new_visibility_provider):
		if (
			not new_visibility_provider.has_method(&"get_visibility_region")
			or not new_visibility_provider.has_method(&"get_visibility_room_rects")
		):
			return false
		visibility_provider = new_visibility_provider
		for room_rect in visibility_provider.call(&"get_visibility_room_rects"):
			if room_rect is Rect2 and room_world_rects.size() < MAX_SHADER_ROOM_RECTS:
				room_world_rects.append(room_rect)
	_apply_static_shader_parameters()
	set_process(true)
	_update_focus(0.0, true)
	return true


func set_visibility_multiplier(multiplier: float) -> void:
	visibility_multiplier = clampf(multiplier, 0.25, 2.0)
	_apply_static_shader_parameters()


func get_snapshot() -> Dictionary:
	return {
		&"corridor_near_radius": corridor_near_radius,
		&"corridor_forward_distance": corridor_forward_distance,
		&"corridor_half_angle_degrees": corridor_half_angle_degrees,
		&"corridor_comfort_shell_radius": corridor_comfort_shell_radius,
		&"corridor_comfort_shell_visibility": corridor_comfort_shell_visibility,
		&"room_edge_softness": room_edge_softness,
		&"room_enter_transition_seconds": room_enter_transition_seconds,
		&"room_exit_transition_seconds": room_exit_transition_seconds,
		&"doorway_hysteresis_active": doorway_hysteresis_active,
		&"doorway_hysteresis_pixels": doorway_hysteresis_pixels,
		&"facing_smoothing_speed": facing_smoothing_speed,
		&"room_visibility_blend": room_visibility_blend,
		&"previous_room_visibility_blend": previous_room_visibility_blend,
		&"fog_color": fog_color,
		&"tracks_actor": is_instance_valid(tracked_actor),
		&"has_visibility_provider": is_instance_valid(visibility_provider),
		&"visibility_mode": visibility_mode,
		&"transition_phase": _transition_phase(),
		&"active_room_index": active_room_index,
		&"transition_room_index": transition_room_index,
		&"facing_direction": current_facing_direction,
		&"room_rect_count": room_world_rects.size(),
		&"screen_room_rect_count": active_screen_room_count,
		&"canvas_layer": layer,
		&"visibility_multiplier": visibility_multiplier,
		&"explored_room_count": explored_room_indices.size(),
		&"occlusion_enabled": occlusion_enabled,
		&"occlusion_ray_count": MAX_OCCLUSION_RAYS,
		&"occlusion_refresh_seconds": occlusion_refresh_seconds,
		&"occlusion_min_distance": _minimum_occlusion_distance(),
		&"occlusion_blocked_ray_count": _blocked_occlusion_ray_count(),
		&"room_occlusion_policy": &"active_room_only",
		&"corridor_comfort_policy": &"wide_front_near_shell_spatial_doorway_hysteresis",
		&"non_active_rooms_occluded": not room_world_rects.is_empty(),
		&"minimap_visibility_independent": true,
	}


func _minimum_occlusion_distance() -> float:
	var result := corridor_forward_distance * visibility_multiplier
	for distance in occlusion_distances:
		result = minf(result, distance)
	return result


func _blocked_occlusion_ray_count() -> int:
	var maximum_distance := corridor_forward_distance * visibility_multiplier
	var result := 0
	for distance in occlusion_distances:
		if distance < maximum_distance - occlusion_edge_softness:
			result += 1
	return result


func _transition_phase() -> StringName:
	if doorway_hysteresis_active and room_visibility_blend >= 0.999:
		return &"doorway_hysteresis"
	if visibility_mode == &"room":
		return &"room" if room_visibility_blend >= 0.999 else &"entering_room"
	return &"corridor" if room_visibility_blend <= 0.001 else &"leaving_room"


func _process(delta: float) -> void:
	_update_focus(delta)


func _apply_static_shader_parameters() -> void:
	var shader_material := overlay.material as ShaderMaterial
	if shader_material == null:
		return
	shader_material.set_shader_parameter(&"corridor_near_radius", corridor_near_radius * visibility_multiplier)
	shader_material.set_shader_parameter(&"corridor_forward_distance", corridor_forward_distance * visibility_multiplier)
	shader_material.set_shader_parameter(
		&"corridor_half_angle_radians", deg_to_rad(corridor_half_angle_degrees)
	)
	shader_material.set_shader_parameter(
		&"corridor_angle_softness_radians",
		deg_to_rad(corridor_angle_softness_degrees)
	)
	shader_material.set_shader_parameter(
		&"corridor_distance_softness", corridor_distance_softness
	)
	shader_material.set_shader_parameter(
		&"corridor_comfort_shell_radius", corridor_comfort_shell_radius * visibility_multiplier
	)
	shader_material.set_shader_parameter(
		&"corridor_comfort_shell_visibility", corridor_comfort_shell_visibility
	)
	shader_material.set_shader_parameter(&"room_edge_softness", room_edge_softness)
	shader_material.set_shader_parameter(&"occlusion_enabled", occlusion_enabled)
	shader_material.set_shader_parameter(&"occlusion_edge_softness", occlusion_edge_softness)
	shader_material.set_shader_parameter(&"explored_room_tint_strength", explored_room_tint_strength)
	shader_material.set_shader_parameter(&"fog_noise_strength", fog_noise_strength)
	shader_material.set_shader_parameter(&"fog_color", fog_color)
	shader_material.set_shader_parameter(&"explored_fog_color", explored_fog_color)


func _update_focus(delta: float = 0.0, snap_transition: bool = false) -> void:
	if not is_instance_valid(tracked_actor):
		set_process(false)
		return
	var shader_material := overlay.material as ShaderMaterial
	if shader_material == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var screen_position := tracked_actor.get_global_transform_with_canvas().origin
	var canvas_transform := tracked_actor.get_canvas_transform()
	var requested_direction := current_facing_direction
	if tracked_actor.has_method(&"get_facing_direction"):
		requested_direction = tracked_actor.call(&"get_facing_direction")
	if requested_direction == Vector2.ZERO:
		requested_direction = current_facing_direction if current_facing_direction != Vector2.ZERO else Vector2.RIGHT
	requested_direction = requested_direction.normalized()
	if not focus_initialized or snap_transition:
		current_facing_direction = requested_direction
	else:
		var facing_weight := 1.0 - exp(-facing_smoothing_speed * maxf(0.0, delta))
		current_facing_direction = Vector2.from_angle(lerp_angle(
			current_facing_direction.angle(), requested_direction.angle(), facing_weight
		))
	var screen_direction := (
		(canvas_transform * current_facing_direction - canvas_transform * Vector2.ZERO).normalized()
	)
	var detected_room_rect := Rect2()
	var detected_room_detection_rect := Rect2()
	var transition_mode := &"corridor"
	var transition_room := -1
	visibility_mode = &"corridor"
	active_room_index = -1
	doorway_hysteresis_active = false
	if is_instance_valid(visibility_provider):
		var context: Dictionary = visibility_provider.call(
			&"get_visibility_region", tracked_actor.global_position
		)
		visibility_mode = context.get(&"mode", &"corridor")
		active_room_index = int(context.get(&"room_index", -1))
		if visibility_mode == &"room":
			detected_room_rect = context.get(&"world_rect", Rect2())
			detected_room_detection_rect = context.get(&"detection_rect", detected_room_rect)
			explored_room_indices[active_room_index] = true
			transition_mode = &"room"
			transition_room = active_room_index
		elif (
			transition_room_index >= 0
			and room_visibility_blend > 0.0
			and transition_room_detection_rect.grow(doorway_hysteresis_pixels).has_point(
				tracked_actor.global_position
			)
		):
			doorway_hysteresis_active = true
			transition_mode = &"room"
			transition_room = transition_room_index
			detected_room_rect = transition_room_world_rect
			detected_room_detection_rect = transition_room_detection_rect
	_update_room_transition(
		transition_mode,
		transition_room,
		detected_room_rect,
		detected_room_detection_rect,
		delta,
		snap_transition
	)
	_update_occlusion_rays(delta, snap_transition, canvas_transform)
	var transition_room_rect := _world_rect_to_screen(
		transition_room_world_rect, canvas_transform
	)
	var screen_room_rects := PackedVector4Array()
	var screen_room_memory := PackedFloat32Array()
	var viewport_rect := Rect2(Vector2.ZERO, viewport_size)
	for room_index in range(room_world_rects.size()):
		var world_rect := room_world_rects[room_index]
		var screen_rect := _world_rect_to_screen(world_rect, canvas_transform)
		if not screen_rect.intersects(viewport_rect, true):
			continue
		screen_room_rects.append(Vector4(
			screen_rect.position.x,
			screen_rect.position.y,
			screen_rect.end.x,
			screen_rect.end.y
		))
		screen_room_memory.append(1.0 if explored_room_indices.has(room_index) else 0.0)
	active_screen_room_count = screen_room_rects.size()
	shader_material.set_shader_parameter(&"viewport_size", viewport_size)
	shader_material.set_shader_parameter(&"focus_position", screen_position)
	shader_material.set_shader_parameter(&"facing_direction", screen_direction)
	shader_material.set_shader_parameter(&"room_visibility_blend", room_visibility_blend)
	shader_material.set_shader_parameter(
		&"previous_room_visibility_blend", previous_room_visibility_blend
	)
	shader_material.set_shader_parameter(&"active_room_rect", Vector4(
		transition_room_rect.position.x,
		transition_room_rect.position.y,
		transition_room_rect.end.x,
		transition_room_rect.end.y
	))
	var previous_screen_rect := _world_rect_to_screen(
		previous_room_world_rect, canvas_transform
	)
	shader_material.set_shader_parameter(&"previous_room_rect", Vector4(
		previous_screen_rect.position.x,
		previous_screen_rect.position.y,
		previous_screen_rect.end.x,
		previous_screen_rect.end.y
	))
	shader_material.set_shader_parameter(&"room_count", screen_room_rects.size())
	shader_material.set_shader_parameter(&"room_rects", screen_room_rects)
	shader_material.set_shader_parameter(&"room_memory", screen_room_memory)
	shader_material.set_shader_parameter(&"occlusion_distances", occlusion_distances)


func _update_room_transition(
	detected_mode: StringName,
	detected_room_index: int,
	detected_room_rect: Rect2,
	detected_room_detection_rect: Rect2,
	delta: float,
	snap_transition: bool
) -> void:
	var target_blend := 0.0
	if detected_mode == &"room" and detected_room_index >= 0:
		target_blend = 1.0
		if transition_room_index != detected_room_index:
			if transition_room_index >= 0 and room_visibility_blend > 0.0:
				previous_room_world_rect = transition_room_world_rect
				previous_room_visibility_blend = room_visibility_blend
			transition_room_index = detected_room_index
			transition_room_world_rect = detected_room_rect
			transition_room_detection_rect = detected_room_detection_rect
			if focus_initialized:
				room_visibility_blend = 0.0
	if previous_room_visibility_blend > 0.0:
		previous_room_visibility_blend = move_toward(
			previous_room_visibility_blend,
			0.0,
			maxf(0.0, delta) / maxf(0.001, room_exit_transition_seconds)
		)
		if previous_room_visibility_blend <= 0.0001:
			previous_room_visibility_blend = 0.0
			previous_room_world_rect = Rect2()
	if not focus_initialized or snap_transition:
		room_visibility_blend = target_blend
		focus_initialized = true
	else:
		var duration := (
			room_enter_transition_seconds
			if target_blend > room_visibility_blend
			else room_exit_transition_seconds
		)
		room_visibility_blend = move_toward(
			room_visibility_blend, target_blend, maxf(0.0, delta) / maxf(0.001, duration)
		)
	if target_blend <= 0.0 and room_visibility_blend <= 0.0001:
		room_visibility_blend = 0.0
		transition_room_index = -1
		transition_room_world_rect = Rect2()
		transition_room_detection_rect = Rect2()


func _update_occlusion_rays(
	delta: float,
	force_refresh: bool,
	canvas_transform: Transform2D
) -> void:
	var maximum_screen_distance := corridor_forward_distance * visibility_multiplier
	if occlusion_distances.size() != MAX_OCCLUSION_RAYS:
		occlusion_distances.resize(MAX_OCCLUSION_RAYS)
		occlusion_distances.fill(maximum_screen_distance)
	if not occlusion_enabled:
		occlusion_distances.fill(maximum_screen_distance)
		return
	occlusion_refresh_remaining -= maxf(0.0, delta)
	var origin := tracked_actor.global_position
	if (
		not force_refresh
		and occlusion_refresh_remaining > 0.0
		and origin.distance_squared_to(last_occlusion_origin) < 64.0
	):
		return
	occlusion_refresh_remaining = occlusion_refresh_seconds
	last_occlusion_origin = origin
	var screen_scale := maxf(0.001, canvas_transform.x.length())
	var maximum_world_distance := maximum_screen_distance / screen_scale
	var world := tracked_actor.get_world_2d()
	if world == null:
		occlusion_distances.fill(maximum_screen_distance)
		return
	var space_state := world.direct_space_state
	for ray_index in range(MAX_OCCLUSION_RAYS):
		var angle := TAU * float(ray_index) / float(MAX_OCCLUSION_RAYS)
		var direction := Vector2.from_angle(angle)
		var destination := origin + direction * maximum_world_distance
		var query := PhysicsRayQueryParameters2D.create(
			origin, destination, WALL_COLLISION_MASK
		)
		query.collide_with_areas = false
		var hit := space_state.intersect_ray(query)
		var hit_position: Vector2 = hit.get(&"position", destination)
		occlusion_distances[ray_index] = origin.distance_to(hit_position) * screen_scale


func _world_rect_to_screen(world_rect: Rect2, canvas_transform: Transform2D) -> Rect2:
	if world_rect.size == Vector2.ZERO:
		return Rect2()
	var corners := PackedVector2Array([
		canvas_transform * world_rect.position,
		canvas_transform * Vector2(world_rect.end.x, world_rect.position.y),
		canvas_transform * world_rect.end,
		canvas_transform * Vector2(world_rect.position.x, world_rect.end.y),
	])
	var minimum := corners[0]
	var maximum := corners[0]
	for corner in corners:
		minimum.x = minf(minimum.x, corner.x)
		minimum.y = minf(minimum.y, corner.y)
		maximum.x = maxf(maximum.x, corner.x)
		maximum.y = maxf(maximum.y, corner.y)
	return Rect2(minimum, maximum - minimum)
