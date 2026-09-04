class_name TrainingTelemetryPresenter
extends MarginContainer

var service: Node
var title_label: Label
var timer_label: Label
var damage_label: Label
var resource_label: Label
var progress_bar: ProgressBar
var latest_snapshot: Dictionary = {}


func configure(new_service: Node) -> bool:
	if (
		not is_instance_valid(new_service)
		or not new_service.has_signal(&"telemetry_snapshot_changed")
		or not new_service.has_method(&"get_telemetry_snapshot")
	):
		return false
	service = new_service
	_build_ui()
	service.connect(&"telemetry_snapshot_changed", _on_snapshot_changed)
	service.connect(&"telemetry_finalized", _on_snapshot_changed)
	visible = false
	return true


func get_snapshot() -> Dictionary:
	return {
		&"visible": visible,
		&"compact_width": custom_minimum_size.x,
		&"telemetry": latest_snapshot.duplicate(true),
	}


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	position = Vector2(-392.0, 24.0)
	custom_minimum_size = Vector2(368.0, 154.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("margin_left", 14)
	add_theme_constant_override("margin_top", 10)
	add_theme_constant_override("margin_right", 14)
	add_theme_constant_override("margin_bottom", 10)
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.01, 0.045, 0.06, 0.92)
	panel.border_color = Color("02e5e1")
	panel.set_border_width_all(1)
	panel.corner_radius_top_left = 4
	panel.corner_radius_top_right = 4
	panel.corner_radius_bottom_left = 4
	panel.corner_radius_bottom_right = 4
	add_theme_stylebox_override("panel", panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	add_child(content)
	title_label = _label("TRAINING // TELEMETRY", 14, Color("02e5e1"))
	timer_label = _label("측정 대기", 13, Color(0.78, 0.91, 0.92))
	damage_label = _label("DPS 0.0 · HIT 0.0 · TOTAL 0", 13, Color.WHITE)
	resource_label = _label("AP/s -- · COOLDOWN --", 12, Color(0.63, 0.78, 0.82))
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(0, 8)
	progress_bar.show_percentage = false
	progress_bar.max_value = 1.0
	content.add_child(title_label)
	content.add_child(timer_label)
	content.add_child(damage_label)
	content.add_child(resource_label)
	content.add_child(progress_bar)


func _label(text_value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _on_snapshot_changed(snapshot: Dictionary) -> void:
	latest_snapshot = snapshot.duplicate(true)
	var scenario_name := String(snapshot.get(&"scenario_name", ""))
	visible = not scenario_name.is_empty()
	if not visible:
		return
	var finalized := bool(snapshot.get(&"finalized", false))
	title_label.text = "TRAINING // %s" % ("RESULT LOCKED" if finalized else "LIVE")
	timer_label.text = "%s · %04.1f / %04.1fs" % [
		scenario_name,
		float(snapshot.get(&"elapsed_seconds", 0.0)),
		float(snapshot.get(&"window_seconds", 0.0)),
	]
	damage_label.text = "DPS %.1f · HIT %.1f · TOTAL %.0f / %d" % [
		float(snapshot.get(&"dps", 0.0)),
		float(snapshot.get(&"maximum_hit", 0.0)),
		float(snapshot.get(&"total_damage", 0.0)),
		int(snapshot.get(&"hit_count", 0)),
	]
	var ap_cycles := int(snapshot.get(&"resource_events", 0))
	resource_label.text = "AP/s %s · COOLDOWN %s" % [
		("%.1f" % float(snapshot.get(&"ap_per_second", 0.0))) if ap_cycles > 0 else "--",
		("%.2fs" % float(snapshot.get(&"average_cooldown", 0.0))) if int(snapshot.get(&"cooldown_cycles", 0)) > 0 else "--",
	]
	progress_bar.value = float(snapshot.get(&"window_ratio", 0.0))
