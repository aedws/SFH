class_name TacticalMinimapView
extends Control

signal warp_requested(room_index: int)

@export var background_color := Color(0.018, 0.03, 0.045, 1.0)
@export var floor_color := Color(0.18, 0.38, 0.43, 1.0)
@export var street_color := Color("192c34")
@export var yard_color := Color("40575b")
@export var obstacle_color := Color(0.63, 0.43, 0.24, 1.0)
@export var player_color := Color(0.35, 1.0, 0.72, 1.0)
@export var extraction_color := Color(1.0, 0.68, 0.22, 1.0)

var tracked_actor: Node2D
var cell_bounds := Rect2i()
var cell_size: float = 32.0
var extraction_position := Vector2.ZERO
var extraction_candidates: Array = []
var map_texture: ImageTexture
var redraw_elapsed: float = 0.0
var room_definitions: Array[Dictionary] = []
var warp_targets: Dictionary = {}
var interactive := false
var rendered_map_rect := Rect2()
var map_spaces: Array = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_process(false)


func configure(snapshot: Dictionary, actor: Node2D) -> void:
	tracked_actor = actor
	cell_bounds = snapshot.get(&"cell_bounds", Rect2i()) as Rect2i
	cell_size = float(snapshot.get(&"cell_size", 32.0))
	extraction_position = snapshot.get(&"extraction_position", Vector2.ZERO) as Vector2
	extraction_candidates = snapshot.get(&"extraction_candidates", [])
	room_definitions.assign(snapshot.get(&"rooms", []))
	map_spaces=snapshot.get(&"map_spaces",[]).duplicate(true)
	_build_map_texture(
		snapshot.get(&"floor_cells", PackedVector2Array()) as PackedVector2Array,
		snapshot.get(&"obstacle_cells", PackedVector2Array()) as PackedVector2Array
	)
	set_process(true)
	queue_redraw()


func set_warp_targets(targets: Array[Dictionary]) -> void:
	warp_targets.clear()
	for target in targets:
		warp_targets[int(target.get(&"room_index", -1))] = target
	queue_redraw()


func set_interactive(value: bool) -> void:
	interactive = value
	mouse_filter = Control.MOUSE_FILTER_STOP if value else Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func get_warp_target_count() -> int:
	return warp_targets.size()


func _process(delta: float) -> void:
	redraw_elapsed += delta
	if redraw_elapsed >= 0.08:
		redraw_elapsed = 0.0
		queue_redraw()


func _build_map_texture(
	floor_cells: PackedVector2Array,
	obstacle_cells: PackedVector2Array
) -> void:
	if cell_bounds.size.x <= 0 or cell_bounds.size.y <= 0:
		map_texture = null
		return

	var image := Image.create(
		cell_bounds.size.x,
		cell_bounds.size.y,
		false,
		Image.FORMAT_RGBA8
	)
	image.fill(background_color)
	var image_bounds := Rect2i(Vector2i.ZERO, cell_bounds.size)
	for cell_value in floor_cells:
		var cell := Vector2i(cell_value) - cell_bounds.position
		if image_bounds.has_point(cell):
			image.set_pixelv(cell, floor_color)
	# Optional provider geometry separates urban buildings from the surrounding paved lots.
	# Old providers have no spaces and retain the original floor presentation.
	for space: Dictionary in map_spaces:
		var rect: Rect2i=space.get(&"cell_rect",Rect2i())
		rect.position-=cell_bounds.position
		rect=rect.intersection(image_bounds)
		var kind: StringName=space.get(&"kind",&"")
		var color := floor_color if kind==&"room" else (street_color if kind==&"street" else yard_color)
		if rect.has_area(): image.fill_rect(rect,color)
	for cell_value in obstacle_cells:
		var cell := Vector2i(cell_value) - cell_bounds.position
		if image_bounds.has_point(cell):
			image.set_pixelv(cell, obstacle_color)
	map_texture = ImageTexture.create_from_image(image)


func _draw() -> void:
	var available_rect := Rect2(
		Vector2(6.0, 6.0),
		Vector2(maxf(1.0, size.x - 12.0), maxf(1.0, size.y - 12.0))
	)
	draw_rect(available_rect, background_color, true)
	if map_texture == null or cell_bounds.size.x <= 0 or cell_bounds.size.y <= 0:
		return

	var pixel_size := Vector2(cell_bounds.size)
	var fit_scale := minf(available_rect.size.x / pixel_size.x, available_rect.size.y / pixel_size.y)
	var rendered_size := pixel_size * fit_scale
	var rendered_origin := available_rect.position + (available_rect.size - rendered_size) * 0.5
	var rendered_rect := Rect2(rendered_origin, rendered_size)
	rendered_map_rect = rendered_rect
	draw_texture_rect(map_texture, rendered_rect, false)
	draw_rect(rendered_rect, Color(0.39, 0.69, 0.72, 0.72), false, 1.0)
	if interactive:
		_draw_warp_targets(rendered_rect)

	var extraction_marker := _world_to_minimap(extraction_position, rendered_rect)
	var diamond := PackedVector2Array([
		extraction_marker + Vector2(0.0, -5.5),
		extraction_marker + Vector2(5.5, 0.0),
		extraction_marker + Vector2(0.0, 5.5),
		extraction_marker + Vector2(-5.5, 0.0),
	])
	draw_colored_polygon(diamond, extraction_color)
	draw_polyline(diamond + PackedVector2Array([diamond[0]]), Color.WHITE, 1.0, true)
	for candidate: Dictionary in extraction_candidates:
		if (candidate.position as Vector2).is_equal_approx(extraction_position): continue
		var marker := _world_to_minimap(candidate.position, rendered_rect)
		var alternate := diamond.duplicate()
		for i in alternate.size(): alternate[i] += marker - extraction_marker
		draw_colored_polygon(alternate, extraction_color)
		draw_polyline(alternate + PackedVector2Array([alternate[0]]), Color.WHITE, 1.0, true)

	if is_instance_valid(tracked_actor):
		var player_marker := _world_to_minimap(tracked_actor.global_position, rendered_rect)
		draw_circle(player_marker, 5.5, Color(0.015, 0.035, 0.04, 0.95))
		draw_circle(player_marker, 3.7, player_color)
		if tracked_actor is CharacterBody2D:
			var velocity := (tracked_actor as CharacterBody2D).velocity
			if velocity.length_squared() > 1.0:
				draw_line(
					player_marker,
					player_marker + velocity.normalized() * 9.0,
					Color.WHITE,
					2.0,
					true
				)


func _world_to_minimap(world_position: Vector2, rendered_rect: Rect2) -> Vector2:
	var cell_position := world_position / cell_size - Vector2(cell_bounds.position)
	var normalized := Vector2(
		cell_position.x / float(cell_bounds.size.x),
		cell_position.y / float(cell_bounds.size.y)
	)
	return rendered_rect.position + normalized * rendered_rect.size


func _draw_warp_targets(rendered_rect: Rect2) -> void:
	for room_index: int in warp_targets:
		var target: Dictionary = warp_targets[room_index]
		var marker := _world_to_minimap(target.get(&"world_position", Vector2.ZERO), rendered_rect)
		var color := extraction_color if target.get(&"kind", &"") == &"extraction" else player_color
		draw_circle(marker, 8.0, Color(background_color, 0.9))
		draw_arc(marker, 7.0, 0.0, TAU, 20, color, 2.0, true)
		draw_circle(marker, 2.0, color)


func _gui_input(event: InputEvent) -> void:
	if not interactive or not event is InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	var room_index := _room_at_minimap_position(mouse_event.position)
	if warp_targets.has(room_index):
		warp_requested.emit(room_index)
		accept_event()


func _room_at_minimap_position(local_position: Vector2) -> int:
	var safe_rect := rendered_map_rect.abs()
	if safe_rect.size.x <= 0.0 or safe_rect.size.y <= 0.0 or not safe_rect.has_point(local_position):
		return -1
	var normalized := (local_position - safe_rect.position) / safe_rect.size
	var cell_position := Vector2(cell_bounds.position) + normalized * Vector2(cell_bounds.size)
	var world_position := cell_position * cell_size
	for room in room_definitions:
		var room_rect: Rect2 = room.get(&"world_rect", Rect2())
		if room_rect.has_point(world_position):
			return int(room.get(&"room_index", -1))
	return -1
