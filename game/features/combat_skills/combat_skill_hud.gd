class_name CombatSkillHud
extends MarginContainer

var skill_system: Node
var title_labels: Array[Label] = []
var description_labels: Array[Label] = []
var status_labels: Array[Label] = []
var cooldown_bars: Array[ProgressBar] = []
var latest_states: Array[Dictionary] = []

@onready var skill_slots: HBoxContainer = %SkillSlots


func configure(new_skill_system: Node) -> bool:
	if (
		not is_instance_valid(new_skill_system)
		or not new_skill_system.has_signal(&"skill_states_changed")
		or not new_skill_system.has_method(&"get_skill_states")
	):
		return false
	skill_system = new_skill_system
	skill_system.connect(&"skill_states_changed", Callable(self, &"_on_skill_states_changed"))
	_on_skill_states_changed(skill_system.call(&"get_skill_states"))
	return true


func get_snapshot() -> Dictionary:
	return {
		&"visible": visible,
		&"slot_count": latest_states.size(),
		&"states": latest_states.duplicate(true),
	}


func _on_skill_states_changed(states: Array[Dictionary]) -> void:
	latest_states = states.duplicate(true)
	if title_labels.size() != states.size():
		_rebuild_slots(states)
	for index in states.size():
		var state := states[index]
		title_labels[index].text = "[%s]  %s" % [state[&"input_label"], state[&"display_name"]]
		description_labels[index].text = String(state[&"description"])
		var remaining := float(state[&"cooldown_remaining"])
		var ready := bool(state[&"ready"])
		status_labels[index].text = "READY" if ready else "재사용 %.1fs" % remaining
		status_labels[index].modulate = (
			Color(0.48, 1.0, 0.72, 1.0) if ready else Color(1.0, 0.7, 0.35, 1.0)
		)
		cooldown_bars[index].value = (1.0 - float(state[&"cooldown_ratio"])) * 100.0


func _rebuild_slots(states: Array[Dictionary]) -> void:
	for child in skill_slots.get_children():
		child.queue_free()
	title_labels.clear()
	description_labels.clear()
	status_labels.clear()
	cooldown_bars.clear()
	for state in states:
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(238.0, 94.0)
		var accent: Color = state[&"accent_color"]
		var slot_style := StyleBoxFlat.new()
		slot_style.bg_color = Color(0.04, 0.075, 0.095, 0.97)
		slot_style.border_color = Color(accent.r, accent.g, accent.b, 0.72)
		slot_style.set_border_width_all(1)
		slot_style.set_corner_radius_all(6)
		panel.add_theme_stylebox_override(&"panel", slot_style)
		var margin := MarginContainer.new()
		margin.add_theme_constant_override(&"margin_left", 12)
		margin.add_theme_constant_override(&"margin_top", 9)
		margin.add_theme_constant_override(&"margin_right", 12)
		margin.add_theme_constant_override(&"margin_bottom", 9)
		panel.add_child(margin)
		var content := VBoxContainer.new()
		content.add_theme_constant_override(&"separation", 3)
		margin.add_child(content)
		var title := Label.new()
		title.add_theme_font_size_override(&"font_size", 17)
		title.modulate = accent
		content.add_child(title)
		var description := Label.new()
		description.add_theme_font_size_override(&"font_size", 12)
		description.modulate = Color(0.72, 0.82, 0.86, 1.0)
		content.add_child(description)
		var footer := HBoxContainer.new()
		content.add_child(footer)
		var status := Label.new()
		status.custom_minimum_size = Vector2(88.0, 0.0)
		footer.add_child(status)
		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(112.0, 10.0)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.show_percentage = false
		footer.add_child(bar)
		skill_slots.add_child(panel)
		title_labels.append(title)
		description_labels.append(description)
		status_labels.append(status)
		cooldown_bars.append(bar)
