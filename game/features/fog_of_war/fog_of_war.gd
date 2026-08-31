class_name BattlefieldFogOfWar
extends CanvasLayer

const MAX_SHADER_ROOM_RECTS := 64

@export_range(80.0, 500.0, 10.0) var corridor_near_radius: float = 170.0
@export_range(300.0, 1600.0, 10.0) var corridor_forward_distance: float = 780.0
@export_range(20.0, 85.0, 1.0) var corridor_half_angle_degrees: float = 62.0
@export_range(1.0, 30.0, 1.0) var corridor_angle_softness_degrees: float = 12.0
@export_range(10.0, 300.0, 10.0) var corridor_distance_softness: float = 130.0
@export_range(0.0, 80.0, 2.0) var room_edge_softness: float = 18.0
@export_range(0.05, 1.0, 0.01) var room_enter_transition_seconds: float = 0.22
@export_range(0.05, 1.0, 0.01) var room_exit_transition_seconds: float = 0.32
@export var fog_color := Color(0.008, 0.014, 0.025, 0.97)

@onready var overlay: ColorRect = %FogOverlay

var tracked_actor: Node2D
var visibility_provider: Node
var room_world_rects: Array[Rect2] = []
var visibility_mode: StringName = &"corridor"
var active_room_index: int = -1
var transition_room_index: int = -1
var transition_room_world_rect := Rect2()
var room_visibility_blend: float = 0.0
var current_facing_direction := Vector2.RIGHT
var active_screen_room_count: int = 0
var focus_initialized: bool = false
var visibility_multiplier: float = 1.0


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
	room_visibility_blend = 0.0
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
		&"room_edge_softness": room_edge_softness,
		&"room_enter_transition_seconds": room_enter_transition_seconds,
		&"room_exit_transition_seconds": room_exit_transition_seconds,
		&"room_visibility_blend": room_visibility_blend,
		&"fog_color": fog_color,
		&"tracks_actor": is_instance_valid(tracked_actor),
		&"has_visibility_provider": is_instance_valid(visibility_provider),
		&"visibility_mode": visibility_mode,
		&"active_room_index": active_room_index,
		&"transition_room_index": transition_room_index,
		&"facing_direction": current_facing_direction,
		&"room_rect_count": room_world_rects.size(),
		&"screen_room_rect_count": active_screen_room_count,
		&"canvas_layer": layer,
		&"visibility_multiplier": visibility_multiplier,
	}


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
	shader_material.set_shader_parameter(&"room_edge_softness", room_edge_softness)
	shader_material.set_shader_parameter(&"fog_color", fog_color)


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
	current_facing_direction = Vector2.RIGHT
	if tracked_actor.has_method(&"get_facing_direction"):
		current_facing_direction = tracked_actor.call(&"get_facing_direction")
	if current_facing_direction == Vector2.ZERO:
		current_facing_direction = Vector2.RIGHT
	var screen_direction := (
		(canvas_transform * current_facing_direction - canvas_transform * Vector2.ZERO).normalized()
	)
	var detected_room_rect := Rect2()
	visibility_mode = &"corridor"
	active_room_index = -1
	if is_instance_valid(visibility_provider):
		var context: Dictionary = visibility_provider.call(
			&"get_visibility_region", tracked_actor.global_position
		)
		visibility_mode = context.get(&"mode", &"corridor")
		active_room_index = int(context.get(&"room_index", -1))
		if visibility_mode == &"room":
			detected_room_rect = context.get(&"world_rect", Rect2())
	_update_room_transition(
		visibility_mode, active_room_index, detected_room_rect, delta, snap_transition
	)
	var transition_room_rect := _world_rect_to_screen(
		transition_room_world_rect, canvas_transform
	)
	var screen_room_rects := PackedVector4Array()
	var viewport_rect := Rect2(Vector2.ZERO, viewport_size)
	for world_rect in room_world_rects:
		var screen_rect := _world_rect_to_screen(world_rect, canvas_transform)
		if not screen_rect.intersects(viewport_rect, true):
			continue
		screen_room_rects.append(Vector4(
			screen_rect.position.x,
			screen_rect.position.y,
			screen_rect.end.x,
			screen_rect.end.y
		))
	active_screen_room_count = screen_room_rects.size()
	shader_material.set_shader_parameter(&"viewport_size", viewport_size)
	shader_material.set_shader_parameter(&"focus_position", screen_position)
	shader_material.set_shader_parameter(&"facing_direction", screen_direction)
	shader_material.set_shader_parameter(&"room_visibility_blend", room_visibility_blend)
	shader_material.set_shader_parameter(&"active_room_rect", Vector4(
		transition_room_rect.position.x,
		transition_room_rect.position.y,
		transition_room_rect.end.x,
		transition_room_rect.end.y
	))
	shader_material.set_shader_parameter(&"room_count", screen_room_rects.size())
	shader_material.set_shader_parameter(&"room_rects", screen_room_rects)


func _update_room_transition(
	detected_mode: StringName,
	detected_room_index: int,
	detected_room_rect: Rect2,
	delta: float,
	snap_transition: bool
) -> void:
	var target_blend := 0.0
	if detected_mode == &"room" and detected_room_index >= 0:
		target_blend = 1.0
		if transition_room_index != detected_room_index:
			transition_room_index = detected_room_index
			transition_room_world_rect = detected_room_rect
			if focus_initialized:
				room_visibility_blend = 0.0
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
