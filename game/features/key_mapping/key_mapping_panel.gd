class_name KeyMappingPanel
extends Control

signal panel_visibility_changed(is_open: bool)

## K로 열고, 선택한 Action의 다음 키보드/마우스 입력을 서비스에 전달합니다.

var provider: Node
var paused_before_open: bool = false
var awaiting_action: StringName = &""
var binding_buttons: Dictionary = {}
var rows_container: VBoxContainer
var status_label: Label
var summary_label: Label
var key_badge_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(&"game_modal_panel")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	visible = false


func configure(new_provider: Node) -> bool:
	if (
		new_provider == null
		or not new_provider.has_method(&"rebind_action")
		or not new_provider.has_method(&"reset_defaults")
		or not new_provider.has_method(&"get_entries")
	):
		return false
	provider = new_provider
	if provider.has_signal(&"bindings_changed"):
		var callback := Callable(self, &"_on_bindings_changed")
		if not provider.is_connected(&"bindings_changed", callback):
			provider.connect(&"bindings_changed", callback)
	_refresh_rows()
	return true


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		if event.is_action_pressed(&"toggle_key_mapping") and not event.is_echo():
			open_panel()
			get_viewport().set_input_as_handled()
		return
	if not awaiting_action.is_empty():
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE:
				_cancel_capture("입력 대기를 취소했습니다.")
			else:
				_apply_capture(event)
			get_viewport().set_input_as_handled()
		elif event is InputEventMouseButton and event.pressed:
			_apply_capture(event)
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"ui_cancel") and not event.is_echo():
		close_panel()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"toggle_key_mapping") and not event.is_echo():
		close_panel()
		get_viewport().set_input_as_handled()


func open_panel() -> void:
	for panel in get_tree().get_nodes_in_group(&"game_modal_panel"):
		if panel != self and panel.has_method(&"close_panel"):
			panel.call(&"close_panel")
	paused_before_open = get_tree().paused
	move_to_front()
	visible = true
	get_tree().paused = true
	status_label.text = "바꿀 항목을 선택한 뒤 원하는 키 또는 마우스 버튼을 누르세요."
	_refresh_rows()
	panel_visibility_changed.emit(true)


func close_panel() -> void:
	if not visible:
		return
	awaiting_action = &""
	visible = false
	get_tree().paused = paused_before_open
	panel_visibility_changed.emit(false)


func get_snapshot() -> Dictionary:
	return {
		&"visible": visible,
		&"awaiting_action": awaiting_action,
		&"binding_row_count": binding_buttons.size(),
		&"window_minimum_size": Vector2(920.0, 620.0),
	}


func _build_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.015, 0.025, 0.04, 0.94)
	add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(920.0, 620.0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.025, 0.055, 0.075, 0.98)
	panel_style.border_color = Color(0.1, 0.8, 0.85, 0.78)
	panel_style.set_border_width_all(2)
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)
	var header := HBoxContainer.new()
	content.add_child(header)
	var title := Label.new()
	title.text = "키 설정"
	title.add_theme_font_size_override("font_size", 30)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	key_badge_label = Label.new()
	key_badge_label.text = "K · OPEN  |  ESC · CLOSE"
	key_badge_label.modulate = Color(0.35, 0.92, 0.95)
	header.add_child(key_badge_label)
	var close_button := Button.new()
	close_button.text = "닫기"
	close_button.custom_minimum_size = Vector2(82.0, 38.0)
	close_button.pressed.connect(close_panel)
	header.add_child(close_button)
	var description := Label.new()
	description.text = "이동·전투·스킬·메뉴 키를 직접 교체합니다. 중복 키는 기존 항목과 자동 교환되며 ESC는 안전을 위해 고정됩니다."
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.modulate = Color(0.72, 0.82, 0.86)
	content.add_child(description)
	summary_label = Label.new()
	summary_label.modulate = Color(0.2, 0.9, 0.75)
	content.add_child(summary_label)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	rows_container = VBoxContainer.new()
	rows_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows_container.add_theme_constant_override("separation", 6)
	scroll.add_child(rows_container)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	content.add_child(footer)
	status_label = Label.new()
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.add_child(status_label)
	var reset_button := Button.new()
	reset_button.text = "전체 기본값 복원"
	reset_button.custom_minimum_size = Vector2(170.0, 42.0)
	reset_button.pressed.connect(_reset_defaults)
	footer.add_child(reset_button)


func _refresh_rows() -> void:
	if rows_container == null or provider == null:
		return
	for child in rows_container.get_children():
		child.queue_free()
	binding_buttons.clear()
	var entries: Array = provider.call(&"get_entries")
	summary_label.text = "변경 가능 Action %d개 · 설정 즉시 저장 · 브라우저/PC 공통" % entries.size()
	for entry: Dictionary in entries:
		if entry[&"action_id"] == &"toggle_key_mapping":
			key_badge_label.text = "%s · OPEN  |  ESC · CLOSE" % entry[&"binding_text"]
			break
	var current_category := ""
	for entry: Dictionary in entries:
		var category := String(entry[&"category"])
		if category != current_category:
			current_category = category
			var category_label := Label.new()
			category_label.text = category.to_upper()
			category_label.modulate = Color(0.25, 0.86, 0.9)
			category_label.add_theme_font_size_override("font_size", 16)
			rows_container.add_child(category_label)
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 42.0
		row.add_theme_constant_override("separation", 10)
		var name_label := Label.new()
		name_label.text = String(entry[&"display_name"])
		name_label.custom_minimum_size.x = 260.0
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		var action_label := Label.new()
		action_label.text = String(entry[&"action_id"])
		action_label.custom_minimum_size.x = 210.0
		action_label.modulate = Color(0.48, 0.58, 0.64)
		row.add_child(action_label)
		var button := Button.new()
		button.text = String(entry[&"binding_text"])
		button.custom_minimum_size = Vector2(240.0, 38.0)
		var action_id: StringName = entry[&"action_id"]
		button.pressed.connect(_begin_capture.bind(action_id))
		row.add_child(button)
		rows_container.add_child(row)
		binding_buttons[action_id] = button


func _begin_capture(action_id: StringName) -> void:
	awaiting_action = action_id
	for id: StringName in binding_buttons:
		(binding_buttons[id] as Button).disabled = id != action_id
	(binding_buttons[action_id] as Button).text = "입력 대기 중..."
	status_label.text = "%s에 지정할 키를 누르세요. ESC는 취소합니다." % _display_name(action_id)


func _apply_capture(event: InputEvent) -> void:
	var action_id := awaiting_action
	var result: Dictionary = provider.call(&"rebind_action", action_id, event)
	awaiting_action = &""
	_refresh_rows()
	status_label.text = String(result.get(&"message", "키 설정을 변경하지 못했습니다."))


func _cancel_capture(message: String) -> void:
	awaiting_action = &""
	_refresh_rows()
	status_label.text = message


func _reset_defaults() -> void:
	awaiting_action = &""
	status_label.text = (
		"모든 키를 기본값으로 복원하고 저장했습니다."
		if bool(provider.call(&"reset_defaults", true))
		else "기본값을 저장하지 못했습니다."
	)
	_refresh_rows()


func _display_name(action_id: StringName) -> String:
	for entry: Dictionary in provider.call(&"get_entries"):
		if entry[&"action_id"] == action_id:
			return String(entry[&"display_name"])
	return String(action_id)


func _on_bindings_changed(_snapshot: Dictionary) -> void:
	if awaiting_action.is_empty():
		_refresh_rows()
