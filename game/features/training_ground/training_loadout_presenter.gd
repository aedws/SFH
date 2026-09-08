class_name TrainingLoadoutPresenter
extends PanelContainer

var service: Node
var state_label: Label
var skill_buttons: Array[Button] = []
var latest_snapshot: Dictionary = {}
var socket_choice: OptionButton
var socket_button: Button
var finish_button: Button
var socket_catalog: Array = []


func configure(new_service: Node) -> bool:
	if (
		not is_instance_valid(new_service)
		or not new_service.has_signal(&"loadout_state_changed")
		or not new_service.has_method(&"get_loadout_snapshot")
	):
		return false
	service = new_service
	_build_ui()
	service.connect(&"loadout_state_changed", _on_state_changed)
	_on_state_changed(service.call(&"get_loadout_snapshot"))
	return true


func get_snapshot() -> Dictionary:
	return {
		&"visible": visible,
		&"state": latest_snapshot.duplicate(true),
		&"text": state_label.text if state_label != null else "",
	}


func _build_ui() -> void:
	custom_minimum_size = Vector2(368.0, 112.0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.01, 0.045, 0.06, 0.9)
	panel.border_color = Color(0.2, 0.78, 0.72, 0.8)
	panel.set_border_width_all(1)
	add_theme_stylebox_override("panel", panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 5)
	add_child(content)
	state_label = Label.new()
	state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	state_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	state_label.add_theme_font_size_override("font_size", 12)
	state_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	state_label.add_theme_color_override("font_color", Color(0.73, 0.9, 0.88))
	content.add_child(state_label)
	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 6)
	content.add_child(button_row)
	for slot_index in 3:
		var button := Button.new()
		button.custom_minimum_size = Vector2(0.0, 28.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.add_theme_font_size_override("font_size", 12)
		button.text = "[%d] 스킬" % (slot_index + 1)
		button.icon = GameUI.icon("skill")
		button.expand_icon = true
		button.add_theme_constant_override(&"icon_max_width", 16)
		button.pressed.connect(_cycle_skill.bind(slot_index))
		button_row.add_child(button)
		skill_buttons.append(button)
	var socket_row := HBoxContainer.new()
	content.add_child(socket_row)
	socket_choice = OptionButton.new()
	socket_choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	socket_choice.fit_to_longest_item = false
	socket_choice.custom_minimum_size = Vector2(140, 30)
	socket_choice.add_theme_font_size_override("font_size", 12)
	socket_row.add_child(socket_choice)
	socket_button = Button.new()
	socket_button.text = "장착/해제"
	socket_button.add_theme_font_size_override("font_size", 12)
	socket_button.pressed.connect(_toggle_socket)
	socket_row.add_child(socket_button)
	finish_button = Button.new()
	finish_button.text = "훈련 종료"
	finish_button.tooltip_text = "훈련 전 장비로 복원하고 종료합니다."
	finish_button.add_theme_font_size_override("font_size", 12)
	finish_button.pressed.connect(func(): service.call(&"request_stop"))
	socket_row.add_child(finish_button)


func _on_state_changed(snapshot: Dictionary) -> void:
	latest_snapshot = snapshot.duplicate(true)
	visible = bool(snapshot.get(&"active", false))
	var editing := bool(snapshot.get(&"free_editing", false))
	state_label.text = "무료 시험 · I/U/E 장비 · 종료 시 원복" if editing else "복원 대기 · 종료·원복으로 재시도"
	state_label.tooltip_text = state_label.text
	socket_catalog = snapshot.get(&"socket_catalog", [])
	var selected := socket_choice.selected
	socket_choice.clear()
	var slots: Dictionary = snapshot.get(&"sockets", {}).get(&"slots", {})
	for entry in socket_catalog:
		var installed := false
		for slot in slots.get(entry.socket_type, []):
			installed = installed or slot.get(&"item_id", &"") == entry.item_id
		socket_choice.add_item(("장착 · " if installed else "") + String(entry.display_name))
	if not socket_catalog.is_empty():
		socket_choice.select(clampi(selected, 0, socket_catalog.size() - 1))
	else:
		socket_choice.add_item("보유 중인 룬·코어·유물 없음")
	socket_choice.tooltip_text = "보유 자산만 무료 시험 · 해제 시 가방 반환 · 종료 시 원복"
	socket_choice.disabled = not editing or socket_catalog.is_empty()
	socket_button.disabled = not editing or socket_catalog.is_empty()
	var skills: Array = snapshot.get(&"skills", [])
	for index in skill_buttons.size():
		var name := String((skills[index] as Dictionary).get(&"display_name", "SKILL")) if index < skills.size() else "SKILL"
		var key := String((skills[index] as Dictionary).get(&"input_label", str(index + 1))) if index < skills.size() else str(index + 1)
		skill_buttons[index].text = "[%s] %s" % [key, name]
		skill_buttons[index].tooltip_text = skill_buttons[index].text
		skill_buttons[index].disabled = not editing or index >= skills.size()


func _cycle_skill(slot_index: int) -> void:
	if not is_instance_valid(service) or not service.has_method(&"cycle_training_skill"):
		return
	_show_result(service.call(&"cycle_training_skill", slot_index))


func _toggle_socket() -> void:
	if socket_choice.selected < 0 or socket_choice.selected >= socket_catalog.size():
		return
	_show_result(service.call(&"toggle_training_socket", StringName(socket_catalog[socket_choice.selected].item_id)))


func _show_result(result: Dictionary) -> void:
	if not result.get(&"success", false):
		state_label.text = "변경 불가 · 태그/슬롯 확인 · %s" % result.get(&"reason", "")
