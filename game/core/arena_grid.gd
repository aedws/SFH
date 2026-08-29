class_name ArenaGrid
extends Node2D

@export_range(16.0, 256.0, 8.0) var cell_size: float = 64.0
@export_range(2, 16, 1) var major_line_every: int = 4
@export var minor_line_color := Color(0.12, 0.16, 0.22, 0.65)
@export var major_line_color := Color(0.18, 0.25, 0.32, 0.9)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var inverse_canvas := get_viewport().get_canvas_transform().affine_inverse()
	var top_left := inverse_canvas * Vector2.ZERO
	var bottom_right := inverse_canvas * get_viewport_rect().size
	var start_x := floorf(top_left.x / cell_size) * cell_size
	var start_y := floorf(top_left.y / cell_size) * cell_size
	var end_x := bottom_right.x + cell_size
	var end_y := bottom_right.y + cell_size

	var x := start_x
	while x <= end_x:
		var column := int(round(x / cell_size))
		var color := major_line_color if column % major_line_every == 0 else minor_line_color
		draw_line(Vector2(x, top_left.y - cell_size), Vector2(x, end_y), color, 1.0)
		x += cell_size

	var y := start_y
	while y <= end_y:
		var row := int(round(y / cell_size))
		var color := major_line_color if row % major_line_every == 0 else minor_line_color
		draw_line(Vector2(top_left.x - cell_size, y), Vector2(end_x, y), color, 1.0)
		y += cell_size
