class_name TacticalMinimapView
extends Control

@export var background_color := Color(0.018, 0.03, 0.045, 1.0)
@export var floor_color := Color(0.18, 0.38, 0.43, 1.0)
@export var obstacle_color := Color(0.63, 0.43, 0.24, 1.0)
@export var player_color := Color(0.35, 1.0, 0.72, 1.0)
@export var extraction_color := Color(1.0, 0.68, 0.22, 1.0)

var tracked_actor: Node2D
var cell_bounds := Rect2i()
var cell_size: float = 32.0
var extraction_position := Vector2.ZERO
var map_texture: ImageTexture
var redraw_elapsed: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_process(false)


func configure(snapshot: Dictionary, actor: Node2D) -> void:
	tracked_actor = actor
	cell_bounds = snapshot.get(&"cell_bounds", Rect2i()) as Rect2i
	cell_size = float(snapshot.get(&"cell_size", 32.0))
	extraction_position = snapshot.get(&"extraction_position", Vector2.ZERO) as Vector2
	_build_map_texture(
		snapshot.get(&"floor_cells", PackedVector2Array()) as PackedVector2Array,
		snapshot.get(&"obstacle_cells", PackedVector2Array()) as PackedVector2Array
	)
	set_process(true)
	queue_redraw()


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
	for cell_value in obstacle_cells:
		var cell := Vector2i(cell_value) - cell_bounds.position
		if image_bounds.has_point(cell):
			image.set_pixelv(cell, obstacle_color)
	map_texture = ImageTexture.create_from_image(image)


func _draw() -> void:
	var available_rect := Rect2(Vector2(6.0, 6.0), size - Vector2(12.0, 12.0))
	draw_rect(available_rect, background_color, true)
	if map_texture == null or cell_bounds.size.x <= 0 or cell_bounds.size.y <= 0:
		return

	var pixel_size := Vector2(cell_bounds.size)
	var fit_scale := minf(available_rect.size.x / pixel_size.x, available_rect.size.y / pixel_size.y)
	var rendered_size := pixel_size * fit_scale
	var rendered_origin := available_rect.position + (available_rect.size - rendered_size) * 0.5
	var rendered_rect := Rect2(rendered_origin, rendered_size)
	draw_texture_rect(map_texture, rendered_rect, false)
	draw_rect(rendered_rect, Color(0.39, 0.69, 0.72, 0.72), false, 1.0)

	var extraction_marker := _world_to_minimap(extraction_position, rendered_rect)
	var diamond := PackedVector2Array([
		extraction_marker + Vector2(0.0, -5.5),
		extraction_marker + Vector2(5.5, 0.0),
		extraction_marker + Vector2(0.0, 5.5),
		extraction_marker + Vector2(-5.5, 0.0),
	])
	draw_colored_polygon(diamond, extraction_color)
	draw_polyline(diamond + PackedVector2Array([diamond[0]]), Color.WHITE, 1.0, true)

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
