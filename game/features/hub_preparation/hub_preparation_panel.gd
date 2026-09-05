class_name HubPreparationPanel
extends Control
## Hosts lobby preparation controls through a public presentation contract.
signal panel_visibility_changed(is_open: bool)
signal inventory_requested
var paused_before_open := false
var panel: PanelContainer
var content_host: VBoxContainer
var close_button: Button
var inventory_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(&"game_modal_panel")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.03, 0.04, 0.94)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("06151b")
	style.border_color = Color("02e5e1")
	style.set_border_width_all(1)
	style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	var title := Label.new()
	title.text = "HUB // 로드아웃 준비"
	column.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	content_host = VBoxContainer.new()
	content_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_host.add_theme_constant_override("separation", 8)
	scroll.add_child(content_host)
	inventory_button = Button.new()
	inventory_button.text = "가방·장비 세팅 · I / U / E"
	inventory_button.custom_minimum_size.y = 44
	inventory_button.pressed.connect(func():
		close_panel()
		inventory_requested.emit())
	column.add_child(inventory_button)
	close_button = Button.new()
	close_button.text = "세팅 완료 · 로비로 돌아가기 (ESC)"
	close_button.custom_minimum_size.y = 44
	close_button.pressed.connect(close_panel)
	column.add_child(close_button)
	resized.connect(_layout)
	visible = false
	_layout()


func configure(content: Control) -> bool:
	if content == null: return false
	if content.get_parent() != null: content.reparent(content_host)
	else: content_host.add_child(content)
	content.show()
	return true


func open_panel() -> void:
	if visible: return
	for other in get_tree().get_nodes_in_group(&"game_modal_panel"):
		if other == self or not other.visible: continue
		if other.has_method(&"request_leave"):
			other.call(&"request_leave", func():
				other.call(&"close_panel")
				open_panel())
			return
		if other.has_method(&"close_panel"): other.call(&"close_panel")
	paused_before_open = get_tree().paused
	visible = true
	move_to_front()
	get_tree().paused = true
	panel_visibility_changed.emit(true)
	close_button.grab_focus()


func close_panel() -> void:
	if not visible: return
	visible = false
	get_tree().paused = paused_before_open
	panel_visibility_changed.emit(false)


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel") and not event.is_echo():
		close_panel()
		get_viewport().set_input_as_handled()


func _layout() -> void:
	if panel == null: return
	var target := Vector2(minf(760, size.x - 24), minf(640, size.y - 24))
	panel.position = (size - target) * 0.5
	panel.size = target
