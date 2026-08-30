class_name BattlefieldFogOfWar
extends CanvasLayer

const MAX_SHADER_ROOM_RECTS := 64

@export_range(80.0, 500.0, 10.0) var corridor_near_radius: float = 170.0
@export_range(300.0, 1600.0, 10.0) var corridor_forward_distance: float = 780.0
@export_range(20.0, 85.0, 1.0) var corridor_half_angle_degrees: float = 62.0
@export_range(1.0, 30.0, 1.0) var corridor_angle_softness_degrees: float = 12.0
@export_range(10.0, 300.0, 10.0) var corridor_distance_softness: float = 130.0
@export_range(0.0, 80.0, 2.0) var room_edge_softness: float = 18.0
@export var fog_color := Color(0.008, 0.014, 0.025, 0.97)

@onready var overlay: ColorRect = %FogOverlay

var tracked_actor: Node2D
var visibility_provider: Node
var room_world_rects: Array[Rect2] = []
var visibility_mode: StringName = &"corridor"
var active_room_index: int = -1
var current_facing_direction := Vector2.RIGHT
var active_screen_room_count: int = 0


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
	_update_focus()
	return true


func get_snapshot() -> Dictionary:
	return {
		&"corridor_near_radius": corridor_near_radius,
		&"corridor_forward_distance": corridor_forward_distance,
		&"corridor_half_angle_degrees": corridor_half_angle_degrees,
		&"room_edge_softness": room_edge_softness,
		&"fog_color": fog_color,
		&"tracks_actor": is_instance_valid(tracked_actor),
		&"has_visibility_provider": is_instance_valid(visibility_provider),
		&"visibility_mode": visibility_mode,
		&"active_room_index": active_room_index,
		&"facing_direction": current_facing_direction,
		&"room_rect_count": room_world_rects.size(),
		&"screen_room_rect_count": active_screen_room_count,
		&"canvas_layer": layer,
	}


func _process(_delta: float) -> void:
	_update_focus()


func _apply_static_shader_parameters() -> void:
	var shader_material := overlay.material as ShaderMaterial
	if shader_material == null:
		return
	shader_material.set_shader_parameter(&"corridor_near_radius", corridor_near_radius)
	shader_material.set_shader_parameter(&"corridor_forward_distance", corridor_forward_distance)
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


func _update_focus() -> void:
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
	var active_room_rect := Rect2()
	visibility_mode = &"corridor"
	active_room_index = -1
	if is_instance_valid(visibility_provider):
		var context: Dictionary = visibility_provider.call(
			&"get_visibility_region", tracked_actor.global_position
		)
		visibility_mode = context.get(&"mode", &"corridor")
		active_room_index = int(context.get(&"room_index", -1))
		if visibility_mode == &"room":
			active_room_rect = _world_rect_to_screen(
				context.get(&"world_rect", Rect2()), canvas_transform
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
	shader_material.set_shader_parameter(
		&"visibility_mode", 1 if visibility_mode == &"room" else 0
	)
	shader_material.set_shader_parameter(&"active_room_rect", Vector4(
		active_room_rect.position.x,
		active_room_rect.position.y,
		active_room_rect.end.x,
		active_room_rect.end.y
	))
	shader_material.set_shader_parameter(&"room_count", screen_room_rects.size())
	shader_material.set_shader_parameter(&"room_rects", screen_room_rects)


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
