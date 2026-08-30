class_name GridInventoryWindow
extends PanelContainer

@onready var grid_view: Control = %GridView
@onready var header_summary: Label = %HeaderSummary
@onready var inventory_count: Label = %InventoryCount
@onready var capacity_label: Label = %CapacityLabel
@onready var capacity_bar: ProgressBar = %CapacityBar
@onready var selected_type: Label = %SelectedType
@onready var selected_name: Label = %SelectedName
@onready var selected_meta: Label = %SelectedMeta
@onready var selected_description: Label = %SelectedDescription

var paused_before_open: bool = false
var inventory_provider: Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(&"game_modal_panel")
	visible = false
	grid_view.connect(&"item_selected", Callable(self, &"_on_item_selected"))


func configure(new_inventory_provider: Node) -> void:
	inventory_provider = new_inventory_provider
	grid_view.call(&"configure", inventory_provider)
	if inventory_provider.has_signal(&"inventory_changed"):
		var callback := Callable(self, &"_on_inventory_changed")
		if not inventory_provider.is_connected(&"inventory_changed", callback):
			inventory_provider.connect(&"inventory_changed", callback)
	_on_inventory_changed(inventory_provider.call(&"get_snapshot"))


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel") and not event.is_echo():
		close_panel()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"toggle_inventory") and not event.is_echo():
		toggle_panel()
		get_viewport().set_input_as_handled()


func toggle_panel() -> void:
	if visible:
		close_panel()
	else:
		open_panel()


func open_panel() -> void:
	for panel in get_tree().get_nodes_in_group(&"game_modal_panel"):
		if panel != self and panel.has_method(&"close_panel"):
			panel.call(&"close_panel")
	paused_before_open = get_tree().paused
	move_to_front()
	visible = true
	get_tree().paused = true


func close_panel() -> void:
	if not visible:
		return
	visible = false
	get_tree().paused = paused_before_open


func _on_item_selected(entry: Dictionary) -> void:
	var type_label := _type_label(entry.get(&"item_type", &"item"))
	var grid_size: Vector2i = entry.get(&"grid_size", Vector2i.ONE)
	var position: Vector2i = entry.get(&"position", Vector2i.ZERO)
	selected_type.text = "%s / SELECTED ITEM" % type_label.to_upper()
	selected_name.text = String(entry.get(&"display_name", "이름 없음"))
	selected_meta.text = "%s · %d×%d · %d칸 점유" % [
		type_label,
		grid_size.x,
		grid_size.y,
		grid_size.x * grid_size.y,
	]
	selected_description.text = "%s\n\n배치 좌표  X %02d · Y %02d\n인스턴스  %s" % [
		entry.get(&"description", "설명 없음"),
		position.x + 1,
		position.y + 1,
		entry.get(&"instance_id", &"unknown"),
	]


func _on_inventory_changed(snapshot: Dictionary) -> void:
	var dimensions: Vector2i = snapshot.get(&"grid_size", Vector2i.ZERO)
	var entries: Array = snapshot.get(&"items", [])
	var used_cells := 0
	for entry: Dictionary in entries:
		var footprint: Vector2i = entry.get(&"grid_size", Vector2i.ONE)
		used_cells += footprint.x * footprint.y
	var total_cells := dimensions.x * dimensions.y
	header_summary.text = "아이템 %d개 · 사용 %d/%d칸 · 여유 %d칸" % [
		entries.size(), used_cells, total_cells, maxi(0, total_cells - used_cells),
	]
	inventory_count.text = "%02d ITEMS" % entries.size()
	capacity_label.text = "공간 사용  %d / %d칸  ·  %.0f%%" % [
		used_cells,
		total_cells,
		(float(used_cells) / float(total_cells) * 100.0) if total_cells > 0 else 0.0,
	]
	capacity_bar.max_value = maxi(1, total_cells)
	capacity_bar.value = used_cells


func get_density_snapshot() -> Dictionary:
	return {
		&"window_size": size,
		&"grid_minimum_size": grid_view.custom_minimum_size,
		&"detail_minimum_width": %DetailPanel.custom_minimum_size.x,
		&"cell_pixel_size": float(grid_view.get("cell_pixel_size")),
	}


func _type_label(item_type: StringName) -> String:
	return {
		&"weapon": "무기",
		&"armor": "방어구",
		&"module": "모듈",
		&"part": "고유 파츠",
		&"consumable": "소모품",
	}.get(item_type, "아이템")
