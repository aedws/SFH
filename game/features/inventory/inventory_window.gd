class_name GridInventoryWindow
extends PanelContainer

@onready var grid_view: Control = %GridView
@onready var detail_label: Label = %DetailLabel

var paused_before_open: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(&"game_modal_panel")
	visible = false
	grid_view.connect(&"item_selected", Callable(self, &"_on_item_selected"))


func configure(inventory_provider: Node) -> void:
	grid_view.call(&"configure", inventory_provider)


func _unhandled_input(event: InputEvent) -> void:
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
	visible = true
	get_tree().paused = true


func close_panel() -> void:
	if not visible:
		return
	visible = false
	get_tree().paused = paused_before_open


func _on_item_selected(entry: Dictionary) -> void:
	detail_label.text = "%s · %s · %dx%d\n%s" % [
		entry[&"display_name"],
		entry[&"item_type"],
		entry[&"grid_size"].x,
		entry[&"grid_size"].y,
		entry[&"description"],
	]
