class_name InventoryGridView
extends Control

signal item_selected(entry: Dictionary)
signal item_move_requested(instance_id: StringName, cell: Vector2i)

@export_range(24.0, 72.0, 1.0) var cell_pixel_size: float = 50.0

var inventory_provider: Node
var snapshot: Dictionary = {}
var selected_instance_id: StringName
var move_handler: Callable
var drop_cell := Vector2i(-1, -1)
var drop_size := Vector2i.ONE
var drop_valid := false
const ART = preload("res://game/features/inventory/inventory_item_art.gd")
const PREVIEW = preload("res://game/features/inventory/inventory_item_preview.gd")
var hovered_instance_id: StringName = &""

func _ready() -> void:
	focus_mode = FOCUS_ALL
	mouse_exited.connect(func():
		hovered_instance_id = &""
		queue_redraw())


func configure(provider: Node) -> void:
	if is_instance_valid(inventory_provider) and inventory_provider.inventory_changed.is_connected(_on_inventory_changed):
		inventory_provider.inventory_changed.disconnect(_on_inventory_changed)
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
		var tint: Color = entry[&"panel_color"]
		var hovered: bool = entry[&"instance_id"] == hovered_instance_id
		draw_rect(item_rect, Color("17323e") if selected or hovered else Color("0b1c27"), true)
		var border_color := Color("02e5e1") if selected else Color(tint.lightened(0.2), 0.9 if hovered else 0.5)
		draw_rect(item_rect, border_color, false, 3.0 if selected else 2.0)
		draw_rect(Rect2(item_rect.position,Vector2(item_rect.size.x,3)),tint.lightened(0.2))
		var caption := item_rect.size.x >= 90 and item_rect.size.y >= 60
		var art_rect := item_rect.grow(-6)
		if caption: art_rect.size.y -= 19
		ART.draw_item(self,art_rect,entry)
		if caption:
			draw_rect(Rect2(item_rect.position+Vector2(0,item_rect.size.y-22),Vector2(item_rect.size.x,22)),Color("08151f"))
			draw_string(get_theme_default_font(),Vector2(item_rect.position.x+6,item_rect.end.y-7),String(entry[&"display_name"]),HORIZONTAL_ALIGNMENT_LEFT,item_rect.size.x-12,12,Color("e6f3f5"))
		if selected:
			draw_circle(item_rect.position+Vector2(item_rect.size.x-7,8),3,ART.ACCENT)


	if drop_cell.x >= 0:
		draw_rect(Rect2(Vector2(drop_cell) * cell_pixel_size, Vector2(drop_size) * cell_pixel_size),
			Color(0.0, 0.9, 0.8, 0.3) if drop_valid else Color(1.0, 0.2, 0.2, 0.4), true)


func _get_drag_data(position: Vector2) -> Variant:
	for entry: Dictionary in snapshot.get(&"items", []):
		if _entry_rect(entry).has_point(position):
			selected_instance_id = entry[&"instance_id"]
			item_selected.emit(entry)
			var preview := PREVIEW.new()
			preview.custom_minimum_size = Vector2(120,72)
			preview.size = preview.custom_minimum_size
			preview.present(entry)
			set_drag_preview(preview)
			return {&"kind": &"inventory_item", &"instance_id": selected_instance_id,
				&"offset": Vector2i(position / cell_pixel_size) - Vector2i(entry[&"position"]),
				&"grid_size": entry[&"grid_size"]}
	return null


func _can_drop_data(position: Vector2, data: Variant) -> bool:
	if not data is Dictionary or data.get(&"kind") != &"inventory_item":
		return false
	drop_cell = Vector2i((position / cell_pixel_size).floor()) - Vector2i(data.get(&"offset", Vector2i.ZERO))
	drop_size = data.get(&"grid_size", Vector2i.ONE)
	drop_valid = inventory_provider.can_place(drop_size, drop_cell, data[&"instance_id"])
	queue_redraw()
	return drop_valid


func _drop_data(position: Vector2, data: Variant) -> void:
	if _can_drop_data(position, data):
		request_move(data[&"instance_id"], drop_cell)


func request_move(instance_id: StringName, cell: Vector2i) -> bool:
	item_move_requested.emit(instance_id, cell)
	return bool(move_handler.call(instance_id, cell)) if move_handler.is_valid() else false


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		drop_cell = Vector2i(-1, -1)
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var next_hover: StringName = &""
		for entry: Dictionary in snapshot.get(&"items", []):
			if _entry_rect(entry).has_point(event.position):
				next_hover = entry[&"instance_id"]
				tooltip_text = "%s · %s · %d×%d칸\n클릭: 상세 / 드래그: 이동" % [entry.display_name,ART.LABELS.get(entry.item_type,"아이템"),entry.grid_size.x,entry.grid_size.y]
		if next_hover != hovered_instance_id:
			hovered_instance_id = next_hover
			if next_hover == &"": tooltip_text = ""
			queue_redraw()
		return
	if event is InputEventKey and event.pressed and event.keycode in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN,KEY_ENTER,KEY_SPACE]:
		var entries: Array = snapshot.get(&"items",[])
		if entries.is_empty(): return
		var index := -1
		for i in entries.size():
			if entries[i].instance_id == selected_instance_id: index = i
		if event.keycode in [KEY_LEFT,KEY_UP]: index -= 1
		elif event.keycode in [KEY_RIGHT,KEY_DOWN]: index += 1
		index = posmod(index,entries.size()) if index >= 0 else entries.size()-1
		selected_instance_id = entries[index].instance_id
		item_selected.emit(entries[index])
		queue_redraw()
		accept_event()
		return
	if not event is InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return
	grab_focus()
	for entry in snapshot.get(&"items", []):
		if _entry_rect(entry).has_point(mouse_event.position):
			selected_instance_id = entry[&"instance_id"]
			item_selected.emit(entry)
			queue_redraw()
			accept_event()
			return
	if selected_instance_id != &"" and move_handler.is_valid():
		request_move(selected_instance_id, Vector2i((mouse_event.position / cell_pixel_size).floor()))
		accept_event()


func _entry_rect(entry: Dictionary) -> Rect2:
	return Rect2(
		Vector2(entry[&"position"]) * cell_pixel_size,
		Vector2(entry[&"grid_size"]) * cell_pixel_size
	)
