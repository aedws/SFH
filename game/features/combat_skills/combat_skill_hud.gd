class_name CombatSkillHud
extends MarginContainer

var skill_system: Node
var title_labels: Array[Label] = []
var description_labels: Array[Label] = []
var status_labels: Array[Label] = []
var cooldown_bars: Array[ProgressBar] = []
var latest_states: Array[Dictionary] = []
var energy_state_band: StringName = &""

@onready var skill_slots: HBoxContainer = %SkillSlots
@onready var energy_bar: ProgressBar = %EnergyBar
@onready var energy_label: Label = %EnergyLabel
@onready var energy_state_label: Label = %EnergyStateLabel


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
	if states.is_empty() or float(states[0].get(&"energy_maximum", 0.0)) <= 0.0:
		energy_bar.visible = false
		energy_label.text = "비활성"
		energy_state_label.text = "NO RESOURCE"
	else:
		energy_bar.visible = true
		var energy_maximum := float(states[0][&"energy_maximum"])
		var energy_current := float(states[0][&"energy_current"])
		var energy_ratio := clampf(energy_current / energy_maximum, 0.0, 1.0)
		energy_bar.max_value = energy_maximum
		energy_bar.value = energy_current
		energy_label.text = "%d / %d" % [roundi(energy_current), roundi(energy_maximum)]
		if energy_ratio <= 0.15:
			energy_state_label.text = "CRITICAL · %d%%" % roundi(energy_ratio * 100.0)
			energy_state_label.modulate = Color(1.0, 0.42, 0.38, 1.0)
			_set_energy_fill_color(&"critical", Color(1.0, 0.32, 0.28, 1.0))
		elif energy_ratio <= 0.35:
			energy_state_label.text = "LOW · %d%%" % roundi(energy_ratio * 100.0)
			energy_state_label.modulate = Color(1.0, 0.74, 0.32, 1.0)
			_set_energy_fill_color(&"low", Color(1.0, 0.62, 0.2, 1.0))
		else:
			energy_state_label.text = "AVAILABLE · %d%%" % roundi(energy_ratio * 100.0)
			energy_state_label.modulate = Color(0.48, 1.0, 0.72, 1.0)
			_set_energy_fill_color(&"available", Color(0.12, 0.84, 0.88, 1.0))
	for index in states.size():
		var state := states[index]
		title_labels[index].text = "[%s]  %s" % [state[&"input_label"], state[&"display_name"]]
		description_labels[index].text = String(state[&"description"])
		var remaining := float(state[&"cooldown_remaining"])
		var ready := bool(state[&"ready"])
		var current_charges := int(state.get(&"current_charges", -1))
		var maximum_charges := int(state.get(&"maximum_charges", -1))
		if not bool(state.get(&"weapon_tags_ready", true)):
			status_labels[index].text = "무기 태그 불일치"
		elif maximum_charges < 0:
			status_labels[index].text = "READY" if ready else "재사용 %.1fs" % remaining
		elif ready:
			status_labels[index].text = "READY · EN %d · %d/%d" % [
				roundi(float(state.get(&"energy_cost", 0.0))), current_charges, maximum_charges,
			]
		elif remaining > 0.0:
			status_labels[index].text = "재사용 %.1fs · %d/%d" % [
				remaining, current_charges, maximum_charges,
			]
		elif current_charges <= 0:
			status_labels[index].text = "충전 %.1fs" % float(
				state.get(&"charge_recovery_remaining", 0.0)
			)
		else:
			status_labels[index].text = "에너지 부족 · EN %d" % roundi(
				float(state.get(&"energy_cost", 0.0))
			)
		status_labels[index].modulate = (
			Color(0.48, 1.0, 0.72, 1.0) if ready else Color(1.0, 0.7, 0.35, 1.0)
		)
		cooldown_bars[index].value = (1.0 - float(state[&"cooldown_ratio"])) * 100.0


func _set_energy_fill_color(state_band: StringName, color: Color) -> void:
	if energy_state_band == state_band:
		return
	energy_state_band = state_band
	var style := energy_bar.get_theme_stylebox(&"fill").duplicate() as StyleBoxFlat
	if style == null:
		return
	style.bg_color = color
	energy_bar.add_theme_stylebox_override(&"fill", style)


func _rebuild_slots(states: Array[Dictionary]) -> void:
	for child in skill_slots.get_children():
		child.queue_free()
	title_labels.clear()
	description_labels.clear()
	status_labels.clear()
	cooldown_bars.clear()
	for state in states:
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(156.0, 58.0)
		var accent: Color = state[&"accent_color"]
		var slot_style := StyleBoxFlat.new()
		slot_style.bg_color = Color(0.04, 0.075, 0.095, 0.97)
		slot_style.border_color = Color(accent.r, accent.g, accent.b, 0.72)
		slot_style.set_border_width_all(1)
		slot_style.set_corner_radius_all(6)
		panel.add_theme_stylebox_override(&"panel", slot_style)
		var margin := MarginContainer.new()
		margin.add_theme_constant_override(&"margin_left", 8)
		margin.add_theme_constant_override(&"margin_top", 5)
		margin.add_theme_constant_override(&"margin_right", 8)
		margin.add_theme_constant_override(&"margin_bottom", 5)
		panel.add_child(margin)
		var content := VBoxContainer.new()
		content.add_theme_constant_override(&"separation", 1)
		margin.add_child(content)
		var title := Label.new()
		title.add_theme_font_size_override(&"font_size", 12)
		title.modulate = accent
		content.add_child(title)
		var description := Label.new()
		description.visible = false
		description.add_theme_font_size_override(&"font_size", 9)
		description.modulate = Color(0.72, 0.82, 0.86, 1.0)
		content.add_child(description)
		var footer := HBoxContainer.new()
		content.add_child(footer)
		var status := Label.new()
		status.custom_minimum_size = Vector2(92.0, 0.0)
		status.add_theme_font_size_override(&"font_size", 9)
		footer.add_child(status)
		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(34.0, 7.0)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.show_percentage = false
		footer.add_child(bar)
		skill_slots.add_child(panel)
		title_labels.append(title)
		description_labels.append(description)
		status_labels.append(status)
		cooldown_bars.append(bar)
