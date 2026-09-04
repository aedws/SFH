class_name TrainingLoadoutPresenter
extends PanelContainer

var service: Node
var state_label: Label
var skill_buttons: Array[Button] = []
var latest_snapshot: Dictionary = {}


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
	custom_minimum_size = Vector2(368.0, 74.0)
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
	state_label.add_theme_color_override("font_color", Color(0.73, 0.9, 0.88))
	content.add_child(state_label)
	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 6)
	content.add_child(button_row)
	for slot_index in 3:
		var button := Button.new()
		button.custom_minimum_size = Vector2(105.0, 28.0)
		button.text = "[%d] SKILL" % (slot_index + 1)
		button.pressed.connect(_cycle_skill.bind(slot_index))
		button_row.add_child(button)
		skill_buttons.append(button)


func _on_state_changed(snapshot: Dictionary) -> void:
	latest_snapshot = snapshot.duplicate(true)
	visible = bool(snapshot.get(&"active", false))
	state_label.text = "무료 시험 세팅 · I 가방 / U 장비 / E 모듈 · 퇴장 시 원복"
	var skills: Array = snapshot.get(&"skills", [])
	for index in skill_buttons.size():
		var name := String((skills[index] as Dictionary).get(&"display_name", "SKILL")) if index < skills.size() else "SKILL"
		skill_buttons[index].text = "[%d] %s" % [index + 1, name]


func _cycle_skill(slot_index: int) -> void:
	if not is_instance_valid(service) or not service.has_method(&"cycle_training_skill"):
		return
	service.call(&"cycle_training_skill", slot_index)
