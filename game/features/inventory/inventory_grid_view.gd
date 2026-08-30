class_name InventoryGridView
extends Control

signal item_selected(entry: Dictionary)

@export_range(24.0, 72.0, 1.0) var cell_pixel_size: float = 50.0

var inventory_provider: Node
var snapshot: Dictionary = {}
var selected_instance_id: StringName


func configure(provider: Node) -> void:
	inventory_provider = provider
	if provider.has_signal(&"inventory_changed"):
		provider.connect(&"inventory_changed", Callable(self, &"_on_inventory_changed"))
	_on_inventory_changed(provider.call(&"get_snapshot"))


func _on_inventory_changed(new_snapshot: Dictionary) -> void:
	snapshot = new_snapshot
	var dimensions: Vector2i = snapshot.get(&"grid_size", Vector2i.ZERO)
	custom_minimum_size = Vector2(dimensions) * cell_pixel_size
	queue_redraw()


func _draw() -> void:
	var dimensions: Vector2i = snapshot.get(&"grid_size", Vector2i.ZERO)
	var grid_rect := Rect2(Vector2.ZERO, Vector2(dimensions) * cell_pixel_size)
	draw_rect(grid_rect, Color(0.018, 0.028, 0.04, 1.0), true)
	for y in range(dimensions.y):
		for x in range(dimensions.x):
			if (x + y) % 2 == 0:
				draw_rect(
					Rect2(Vector2(x, y) * cell_pixel_size, Vector2.ONE * cell_pixel_size),
					Color(0.035, 0.055, 0.07, 0.42),
					true
				)
	for x in range(dimensions.x + 1):
		var x_position := float(x) * cell_pixel_size
		var line_width := 2.0 if x % 4 == 0 else 1.0
		draw_line(Vector2(x_position, 0.0), Vector2(x_position, dimensions.y * cell_pixel_size), Color(0.16, 0.3, 0.32, 0.82), line_width)
	for y in range(dimensions.y + 1):
		var y_position := float(y) * cell_pixel_size
		var line_width := 2.0 if y % 4 == 0 else 1.0
		draw_line(Vector2(0.0, y_position), Vector2(dimensions.x * cell_pixel_size, y_position), Color(0.16, 0.3, 0.32, 0.82), line_width)

	for entry in snapshot.get(&"items", []):
		var selected: bool = entry[&"instance_id"] == selected_instance_id
		var item_rect := _entry_rect(entry).grow(-3.0 if selected else -2.0)
		draw_rect(item_rect, entry[&"panel_color"], true)
		var border_color := Color(1.0, 0.78, 0.3, 1.0) if selected else Color(0.55, 0.8, 0.82, 0.9)
		draw_rect(item_rect, border_color, false, 3.0 if selected else 2.0)
		draw_string(
			ThemeDB.fallback_font,
			item_rect.position + Vector2(6.0, 18.0),
			String(entry[&"display_name"]),
			HORIZONTAL_ALIGNMENT_LEFT,
			item_rect.size.x - 12.0,
			15,
			Color(0.95, 0.98, 0.98, 1.0)
		)
		if entry[&"grid_size"] != Vector2i.ONE:
			draw_string(
				ThemeDB.fallback_font,
				item_rect.end - Vector2(36.0, 6.0),
				"%dx%d" % [entry[&"grid_size"].x, entry[&"grid_size"].y],
				HORIZONTAL_ALIGNMENT_RIGHT,
				32.0,
				11,
				Color(0.78, 0.88, 0.89, 0.9)
			)


func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return
	for entry in snapshot.get(&"items", []):
		if _entry_rect(entry).has_point(mouse_event.position):
			selected_instance_id = entry[&"instance_id"]
			item_selected.emit(entry)
			queue_redraw()
			accept_event()
			return


func _entry_rect(entry: Dictionary) -> Rect2:
	return Rect2(
		Vector2(entry[&"position"]) * cell_pixel_size,
		Vector2(entry[&"grid_size"]) * cell_pixel_size
	)
