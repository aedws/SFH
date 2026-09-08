class_name RoguelikeFogRuntime
extends RefCounted
## Geometry provider + pure FOV + opaque memory compositor. World simulation is untouched.
const FIELD := preload("res://game/features/fog_of_war/visibility_field.gd")
const SHADER := preload("res://game/features/fog_of_war/roguelike_fog.gdshader")
var field = FIELD.new()
var actor: Node2D
var host: CanvasLayer
var provider: Node
var material: ShaderMaterial
var texture: ImageTexture
var visibility_multiplier := 1.0
var refresh_remaining := 0.0
var last_actor_cell := Vector2i(2147483647, 2147483647)
var dynamic_blocker_count := 0
var last_door_signature := -1
var space_disclosure := false
var reveal_blend := 1.0


func configure(owner: CanvasLayer, tracked_actor: Node2D, geometry_provider: Node) -> bool:
	host = owner
	actor = tracked_actor
	provider = geometry_provider
	space_disclosure = bool(owner.space_visibility_enabled) and provider.has_method(&"get_visibility_spaces")
	if space_disclosure: field = preload("res://game/features/fog_of_war/space_visibility_field.gd").new()
	if not field.configure(provider.call(&"get_fog_geometry")): return false
	if space_disclosure:
		field.configure_spaces(provider.call(&"get_visibility_spaces"))
		field.hysteresis_pixels = owner.doorway_hysteresis_pixels
	texture = ImageTexture.create_from_image(field.image)
	material = ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter(&"visibility_map", texture)
	material.set_shader_parameter(&"grid_origin", Vector2(field.bounds.position) * field.cell_size)
	material.set_shader_parameter(&"grid_size", Vector2(field.bounds.size))
	material.set_shader_parameter(&"cell_size", field.cell_size)
	material.set_shader_parameter(&"space_disclosure", space_disclosure)
	host.overlay.material = material
	update(0, true)
	return true


func update(delta: float, force: bool = false) -> void:
	if not is_instance_valid(actor):
		host.set_process(false)
		return
	var transform := actor.get_canvas_transform().affine_inverse()
	material.set_shader_parameter(&"screen_world_origin", transform.origin)
	material.set_shader_parameter(&"screen_world_x", transform.x)
	material.set_shader_parameter(&"screen_world_y", transform.y)
	material.set_shader_parameter(&"viewport_size", host.get_viewport().get_visible_rect().size)
	material.set_shader_parameter(&"focus_world", actor.global_position)
	material.set_shader_parameter(&"sight_radius", host.sight_radius * visibility_multiplier)
	reveal_blend = minf(1,reveal_blend + maxf(delta,0)/maxf(0.01,host.room_enter_transition_seconds))
	material.set_shader_parameter(&"space_reveal_blend", reveal_blend)
	material.set_shader_parameter(&"space_brightness", clampf(visibility_multiplier,0.45,1))
	refresh_remaining -= maxf(0, delta)
	var current_cell := field.world_to_cell(actor.global_position)
	var doors := host.get_tree().get_nodes_in_group(&"fog_visibility_blocker")
	var door_signature := 0
	for door in doors:
		if not door.is_queued_for_deletion(): door_signature += door.get_instance_id()
	if force or current_cell != last_actor_cell or refresh_remaining <= 0 or door_signature != last_door_signature:
		refresh_remaining = host.fov_refresh_seconds
		last_door_signature = door_signature
		last_actor_cell = current_cell
		var blockers: Dictionary = {}
		var door_rects := PackedVector4Array()
		for blocker in doors:
			if blocker.is_queued_for_deletion() or not blocker.has_method(&"get_visibility_bounds"): continue
			var rect: Rect2 = blocker.call(&"get_visibility_bounds")
			if door_rects.size() < 64:
				door_rects.append(Vector4(rect.position.x, rect.position.y, rect.end.x, rect.end.y))
			var begin := field.world_to_cell(rect.position + Vector2.ONE * 0.01)
			var end := field.world_to_cell(rect.end - Vector2.ONE * 0.01)
			for y in range(begin.y, end.y + 1):
				for x in range(begin.x, end.x + 1): blockers[Vector2i(x, y)] = true
		dynamic_blocker_count = blockers.size()
		material.set_shader_parameter(&"door_count", door_rects.size())
		material.set_shader_parameter(&"door_rects", door_rects)
		var previous_space: int = field.active_space if space_disclosure else -1
		if field.update(actor.global_position, ceili(host.sight_radius * visibility_multiplier / field.cell_size), blockers):
			if space_disclosure and previous_space != field.active_space:
				reveal_blend = 1.0 if force else 0.0
				material.set_shader_parameter(&"space_reveal_blend", reveal_blend)
			texture.update(field.image)


func get_snapshot() -> Dictionary:
	var region: Dictionary = provider.call(&"get_visibility_region", actor.global_position) if is_instance_valid(actor) and is_instance_valid(provider) and provider.has_method(&"get_visibility_region") else {}
	return {&"policy": &"space_disclosure" if space_disclosure else &"roguelike_three_state", &"tracks_actor": is_instance_valid(actor),
		&"has_visibility_provider": is_instance_valid(provider), &"visibility_mode": region.get(&"mode", &"corridor"),
		&"active_room_index": region.get(&"room_index", -1), &"visibility_multiplier": visibility_multiplier,
		&"sight_radius": host.sight_radius * visibility_multiplier, &"visible_cell_count": field.visible_cells.size(),
		&"explored_cell_count": field.explored_cells.size(), &"fov_updates": field.updates,
		&"last_compute_usec": field.last_compute_usec, &"mask_bytes": field.bounds.size.x * field.bounds.size.y * 4,
		&"dynamic_blocker_count": dynamic_blocker_count, &"omnidirectional": true,
		&"memory_terrain_only": true, &"room_auto_reveal": space_disclosure, &"minimap_visibility_independent": true,
		&"space": field.current_space() if space_disclosure else {}, &"reveal_blend":reveal_blend,
		&"canvas_layer": host.layer, &"fog_color": Color(0.008, 0.014, 0.025, 1)}
