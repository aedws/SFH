class_name KeyMappingPanel
extends Control

signal panel_visibility_changed(is_open: bool)

## K로 열고, 선택한 Action의 다음 키보드/마우스 입력을 서비스에 전달합니다.

var provider: Node
var skill_provider: Node
var paused_before_open: bool = false
var awaiting_action: StringName = &""
var binding_buttons: Dictionary = {}
var skill_binding_buttons: Dictionary = {}
var rows_container: VBoxContainer
var skill_rows_container: VBoxContainer
var status_label: Label
var summary_label: Label
var key_badge_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(&"game_modal_panel")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	visible = false


func configure(new_provider: Node, new_skill_provider: Node = null) -> bool:
	if (
		new_provider == null
		or not new_provider.has_method(&"rebind_action")
		or not new_provider.has_method(&"reset_defaults")
		or not new_provider.has_method(&"get_entries")
	):
		return false
	provider = new_provider
	skill_provider = new_skill_provider
	if provider.has_signal(&"bindings_changed"):
		var callback := Callable(self, &"_on_bindings_changed")
		if not provider.is_connected(&"bindings_changed", callback):
			provider.connect(&"bindings_changed", callback)
	if is_instance_valid(skill_provider) and skill_provider.has_signal(&"bindings_changed"):
		var skill_callback := Callable(self, &"_on_skill_bindings_changed")
		if not skill_provider.is_connected(&"bindings_changed", skill_callback):
			skill_provider.connect(&"bindings_changed", skill_callback)
	_refresh_rows()
	_refresh_skill_rows()
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
	_refresh_skill_rows()
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
		&"physical_binding_row_count": binding_buttons.size(),
		&"skill_binding_row_count": skill_binding_buttons.size(),
		&"separate_binding_levels": is_instance_valid(skill_provider),
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
	panel_style.border_color = Color("02e5e1c7")
	panel_style.set_border_width_all(2)
	panel_style.corner_radius_top_left = 2
	panel_style.corner_radius_top_right = 2
	panel_style.corner_radius_bottom_left = 2
	panel_style.corner_radius_bottom_right = 2
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
	title.text = "입력 설정"
	title.add_theme_font_size_override("font_size", 30)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	key_badge_label = Label.new()
	key_badge_label.text = "K · OPEN  |  ESC · CLOSE"
	key_badge_label.modulate = Color("02e5e1")
	header.add_child(key_badge_label)
	var close_button := Button.new()
	close_button.text = "닫기"
	close_button.custom_minimum_size = Vector2(82.0, 38.0)
	close_button.pressed.connect(close_panel)
	header.add_child(close_button)
	var description := Label.new()
	description.text = "키 배치에서는 물리 키를, 스킬 배치에서는 원하는 스킬의 1~9 슬롯을 바꿉니다. 충돌 항목은 자동 교환되며 ESC는 안전을 위해 고정됩니다."
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.modulate = Color(0.72, 0.82, 0.86)
	content.add_child(description)
	summary_label = Label.new()
	summary_label.modulate = Color("02e5e1")
	content.add_child(summary_label)
	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_theme_font_size_override("font_size", 18)
	content.add_child(tabs)
	var key_scroll := ScrollContainer.new()
	key_scroll.name = "키 배치"
	key_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	key_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(key_scroll)
	rows_container = VBoxContainer.new()
	rows_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows_container.add_theme_constant_override("separation", 6)
	key_scroll.add_child(rows_container)
	var skill_scroll := ScrollContainer.new()
	skill_scroll.name = "스킬 배치"
	skill_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	skill_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(skill_scroll)
	skill_rows_container = VBoxContainer.new()
	skill_rows_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skill_rows_container.add_theme_constant_override("separation", 8)
	skill_scroll.add_child(skill_rows_container)
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
			category_label.modulate = Color("02e5e1")
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


func _refresh_skill_rows() -> void:
	if skill_rows_container == null:
		return
	for child in skill_rows_container.get_children():
		child.queue_free()
	skill_binding_buttons.clear()
	if not is_instance_valid(skill_provider):
		var unavailable := Label.new()
		unavailable.text = "스킬 배치 모듈이 비활성화되어 있습니다."
		skill_rows_container.add_child(unavailable)
		return
	var guide := Label.new()
	guide.text = "스킬마다 이전/다음 슬롯을 선택합니다. 사용 중인 슬롯을 고르면 두 스킬이 서로 교환됩니다."
	guide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guide.modulate = Color(0.72, 0.82, 0.86)
	skill_rows_container.add_child(guide)
	for entry: Dictionary in skill_provider.call(&"get_entries"):
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 54.0
		row.add_theme_constant_override("separation", 10)
		var name_label := Label.new()
		name_label.text = String(entry[&"display_name"])
		name_label.custom_minimum_size.x = 280.0
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		var binding_label := Label.new()
		binding_label.text = "%s · 물리 키 %s" % [entry[&"action_slot_label"], entry[&"binding_text"]]
		binding_label.custom_minimum_size.x = 260.0
		binding_label.modulate = Color("02e5e1")
		row.add_child(binding_label)
		var previous_button := Button.new()
		previous_button.text = "< 이전"
		previous_button.custom_minimum_size = Vector2(100.0, 40.0)
		var skill_id: StringName = entry[&"skill_id"]
		previous_button.pressed.connect(_cycle_skill_slot.bind(skill_id, -1))
		row.add_child(previous_button)
		var next_button := Button.new()
		next_button.text = "다음 >"
		next_button.custom_minimum_size = Vector2(100.0, 40.0)
		next_button.pressed.connect(_cycle_skill_slot.bind(skill_id, 1))
		row.add_child(next_button)
		skill_rows_container.add_child(row)
		skill_binding_buttons[skill_id] = next_button


func _cycle_skill_slot(skill_id: StringName, direction: int) -> void:
	var actions: Array[StringName] = skill_provider.call(&"get_allowed_actions")
	if actions.is_empty():
		return
	var current: StringName = skill_provider.call(&"action_for_skill", skill_id)
	var current_index := actions.find(current)
	var target_index := posmod(current_index + direction, actions.size())
	var result: Dictionary = skill_provider.call(&"assign_skill", skill_id, actions[target_index])
	status_label.text = String(result.get(&"message", "스킬 배치를 변경하지 못했습니다."))
	_refresh_skill_rows()


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
	var physical_saved := bool(provider.call(&"reset_defaults", true))
	var skills_saved := (
		bool(skill_provider.call(&"reset_defaults", true))
		if is_instance_valid(skill_provider) else true
	)
	status_label.text = (
		"모든 키와 스킬 위치를 기본값으로 복원하고 저장했습니다."
		if physical_saved and skills_saved
		else "기본값을 저장하지 못했습니다."
	)
	_refresh_rows()
	_refresh_skill_rows()


func _display_name(action_id: StringName) -> String:
	for entry: Dictionary in provider.call(&"get_entries"):
		if entry[&"action_id"] == action_id:
			return String(entry[&"display_name"])
	return String(action_id)


func _on_bindings_changed(_snapshot: Dictionary) -> void:
	if awaiting_action.is_empty():
		_refresh_rows()
		_refresh_skill_rows()


func _on_skill_bindings_changed(_snapshot: Dictionary) -> void:
	_refresh_skill_rows()
