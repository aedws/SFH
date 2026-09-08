class_name KeyMappingPanel
extends Control

signal panel_visibility_changed(is_open: bool)

## K로 열고, 선택한 Action의 다음 키보드/마우스 입력을 서비스에 전달합니다.

var provider: Node
var skill_provider: Node
var presentation_provider: Node
var paused_before_open: bool = false
var awaiting_action: StringName = &""
var binding_buttons: Dictionary = {}
var skill_binding_buttons: Dictionary = {}
var rows_container: VBoxContainer
var skill_rows_container: VBoxContainer
var status_label: Label
var summary_label: Label
var key_badge_label: Label
var presentation_rows_container: VBoxContainer
var presentation_summary_label: Label
var settings_panel: PanelContainer
var layout_dirty := false
const UI = preload("res://game/features/presentation_theme/game_ui.gd")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(&"game_modal_panel")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	visible = false


func configure(
	new_provider: Node,
	new_skill_provider: Node = null,
	new_presentation_provider: Node = null
) -> bool:
	if (
		new_provider == null
		or not new_provider.has_method(&"rebind_action")
		or not new_provider.has_method(&"reset_defaults")
		or not new_provider.has_method(&"get_entries")
	):
		return false
	provider = new_provider
	skill_provider = new_skill_provider
	presentation_provider = new_presentation_provider
	if provider.has_signal(&"bindings_changed"):
		var callback := Callable(self, &"_on_bindings_changed")
		if not provider.is_connected(&"bindings_changed", callback):
			provider.connect(&"bindings_changed", callback)
	if is_instance_valid(skill_provider) and skill_provider.has_signal(&"bindings_changed"):
		var skill_callback := Callable(self, &"_on_skill_bindings_changed")
		if not skill_provider.is_connected(&"bindings_changed", skill_callback):
			skill_provider.connect(&"bindings_changed", skill_callback)
	if is_instance_valid(presentation_provider) and presentation_provider.has_signal(&"settings_changed"):
		var presentation_callback := Callable(self, &"_on_presentation_settings_changed")
		if not presentation_provider.is_connected(&"settings_changed", presentation_callback):
			presentation_provider.connect(&"settings_changed", presentation_callback)
	_refresh_rows()
	_refresh_skill_rows()
	_refresh_presentation_rows()
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
		if panel != self and panel.visible and panel.has_method(&"request_leave"):
			panel.call(&"request_leave", func():
				panel.call(&"close_panel")
				open_panel()
			)
			return
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
		&"presentation_settings_available": is_instance_valid(presentation_provider),
		&"presentation_settings": (
			presentation_provider.call(&"get_snapshot")
			if is_instance_valid(presentation_provider) else {}
		),
		&"window_minimum_size": Vector2(920.0, 620.0),
	}


func _build_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.015, 0.025, 0.04, 0.94)
	add_child(backdrop)
	settings_panel = PanelContainer.new()
	settings_panel.minimum_size_changed.connect(func(): layout_dirty = true)
	settings_panel.custom_minimum_size = Vector2(920.0, 620.0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.025, 0.055, 0.075, 0.98)
	panel_style.border_color = Color("02e5e1c7")
	panel_style.set_border_width_all(2)
	panel_style.corner_radius_top_left = 2
	panel_style.corner_radius_top_right = 2
	panel_style.corner_radius_bottom_left = 2
	panel_style.corner_radius_bottom_right = 2
	settings_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(settings_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	settings_panel.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)
	var header := HBoxContainer.new()
	content.add_child(header)
	var title := Label.new()
	title.text = "요원 · 입력 설정"
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
	UI.action(close_button, "move")
	header.add_child(close_button)
	var description := Label.new()
	description.text = "키 배치 · 스킬 배치 · HUD·모바일\n손에 맞는 조작과 화면을 만드세요. 키 중복은 자동 교환 · ESC는 취소로 고정."
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
	var presentation_scroll := ScrollContainer.new()
	presentation_scroll.name = "HUD·모바일"
	presentation_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	presentation_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(presentation_scroll)
	presentation_rows_container = VBoxContainer.new()
	presentation_rows_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	presentation_rows_container.add_theme_constant_override("separation", 10)
	presentation_scroll.add_child(presentation_rows_container)
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
	resized.connect(_apply_responsive_size)
	_apply_responsive_size()


func _refresh_rows() -> void:
	if rows_container == null or provider == null:
		return
	for child in rows_container.get_children():
		child.queue_free()
	binding_buttons.clear()
	var entries: Array = provider.call(&"get_entries")
	summary_label.text = "조작 %d개 · 변경 즉시 저장" % entries.size()
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
		name_label.custom_minimum_size.x = 0.0
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		var button := Button.new()
		button.text = String(entry[&"binding_text"])
		button.custom_minimum_size = Vector2(140.0, 44.0)
		button.tooltip_text = "선택 후 원하는 키 입력 · ESC 취소"
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
		name_label.custom_minimum_size.x = 0.0
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		var binding_label := Label.new()
		binding_label.text = "%s · 물리 키 %s" % [entry[&"action_slot_label"], entry[&"binding_text"]]
		binding_label.custom_minimum_size.x = 0.0
		binding_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		binding_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		binding_label.modulate = Color("02e5e1")
		row.add_child(binding_label)
		var previous_button := Button.new()
		previous_button.text = "< 이전"
		previous_button.custom_minimum_size = Vector2(56.0, 44.0)
		previous_button.text = "<"
		previous_button.tooltip_text = "이전 스킬 슬롯"
		var skill_id: StringName = entry[&"skill_id"]
		previous_button.pressed.connect(_cycle_skill_slot.bind(skill_id, -1))
		row.add_child(previous_button)
		var next_button := Button.new()
		next_button.text = "다음 >"
		next_button.custom_minimum_size = Vector2(56.0, 44.0)
		next_button.text = ">"
		next_button.tooltip_text = "다음 스킬 슬롯"
		next_button.pressed.connect(_cycle_skill_slot.bind(skill_id, 1))
		row.add_child(next_button)
		skill_rows_container.add_child(row)
		skill_binding_buttons[skill_id] = next_button


func _refresh_presentation_rows() -> void:
	if presentation_rows_container == null:
		return
	for child in presentation_rows_container.get_children():
		child.queue_free()
	if not is_instance_valid(presentation_provider):
		var unavailable := Label.new()
		unavailable.text = "HUD·모바일 표시 설정 모듈이 비활성화되어 있습니다."
		presentation_rows_container.add_child(unavailable)
		return
	var guide := Label.new()
	guide.text = "플레이어 상태 HUD 위치, 화면 키 배지 형식, 모바일 키패드 표시 방식을 바꿉니다. 변경은 브라우저와 PC에서 각각 저장됩니다."
	guide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guide.modulate = Color(0.72, 0.82, 0.86)
	presentation_rows_container.add_child(guide)
	var snapshot: Dictionary = presentation_provider.call(&"get_snapshot")
	presentation_summary_label = Label.new()
	presentation_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	presentation_summary_label.text = "현재 · HUD %s · 키 %s · 모바일 %s" % [
		snapshot.get(&"hud_anchor_label", "좌하단"),
		snapshot.get(&"key_label_format_label", "간결"),
		snapshot.get(&"mobile_controls_mode_label", "터치 자동"),
	]
	presentation_summary_label.modulate = Color("02e5e1")
	presentation_rows_container.add_child(presentation_summary_label)
	_add_presentation_row(
		"플레이어 상태 HUD 위치",
		"체력·경험치·레벨·휴대 크레딧 묶음을 좌하단/중앙/우하단으로 이동합니다.",
		String(snapshot.get(&"hud_anchor_label", "좌하단")),
		&"hud_anchor"
	)
	_add_presentation_row(
		"HUD 키 표시 포맷",
		"행동 아이콘 아래의 키를 간결/대괄호/숨김으로 표시합니다.",
		String(snapshot.get(&"key_label_format_label", "간결")),
		&"key_label_format"
	)
	_add_presentation_row(
		"모바일 키패드",
		"터치 기기 자동 감지, 항상 표시, 항상 숨김 중에서 선택합니다.",
		String(snapshot.get(&"mobile_controls_mode_label", "터치 자동")),
		&"mobile_controls_mode"
	)
	_add_presentation_row(
		"모바일 버튼·글자 크기",
		"100% / 125% / 150%. 조이스틱·공격·스킬·에너지 표시를 확대합니다. 좁은 화면은 겹치지 않는 최대 크기로 자동 제한합니다.",
		String(snapshot.get(&"mobile_ui_scale_label", "125%")),
		&"mobile_ui_scale"
	)


func _add_presentation_row(
	title_text: String,
	description_text: String,
	value_text: String,
	setting_id: StringName
) -> void:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	presentation_rows_container.add_child(row)
	var header := HBoxContainer.new()
	row.add_child(header)
	var title := Label.new()
	title.text = title_text
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 18)
	header.add_child(title)
	var button := Button.new()
	button.text = "%s  ›" % value_text
	button.set_meta(&"presentation_setting", setting_id)
	button.custom_minimum_size = Vector2(180, 44)
	button.pressed.connect(_cycle_presentation_setting.bind(setting_id))
	header.add_child(button)
	var description := Label.new()
	description.text = description_text
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.modulate = Color(0.62, 0.74, 0.8)
	row.add_child(description)


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
	var presentation_saved := (
		bool(presentation_provider.call(&"reset_defaults", true))
		if is_instance_valid(presentation_provider) else true
	)
	status_label.text = (
		"모든 키와 스킬 위치를 기본값으로 복원하고 저장했습니다."
		if physical_saved and skills_saved and presentation_saved
		else "기본값을 저장하지 못했습니다."
	)
	_refresh_rows()
	_refresh_skill_rows()
	_refresh_presentation_rows()


func _cycle_presentation_setting(setting_id: StringName) -> void:
	if not is_instance_valid(presentation_provider):
		return
	match setting_id:
		&"hud_anchor":
			presentation_provider.call(&"cycle_hud_anchor", 1)
		&"key_label_format":
			presentation_provider.call(&"cycle_key_label_format", 1)
		&"mobile_controls_mode":
			presentation_provider.call(&"cycle_mobile_controls_mode", 1)
		&"mobile_ui_scale":
			presentation_provider.call(&"cycle_mobile_ui_scale", 1)
	_refresh_presentation_rows()


func _apply_responsive_size() -> void:
	if settings_panel == null:
		return
	settings_panel.custom_minimum_size = Vector2.ZERO
	settings_panel.size = Vector2(minf(size.x - 24, 920), minf(size.y - 24, 620)).max(Vector2.ONE)
	settings_panel.position = (size - settings_panel.size) * 0.5
	key_badge_label.visible = size.x >= 700


func _process(_delta: float) -> void:
	if layout_dirty:
		layout_dirty = false
		_apply_responsive_size()


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


func _on_presentation_settings_changed(_snapshot: Dictionary) -> void:
	_refresh_presentation_rows()
