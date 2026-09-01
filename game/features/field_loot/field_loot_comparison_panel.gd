class_name FieldLootComparisonPanel
extends PanelContainer

var title_label: Label
var meta_label: Label
var comparison_label: Label
var lifecycle_label: Label
var outcome_label: Label
var controls_label: Label
var current_snapshot: Dictionary = {}


func _ready() -> void:
	name = "FieldLootComparisonPanel"
	set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	offset_left = -390.0
	offset_right = -20.0
	offset_top = -112.0
	offset_bottom = 112.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_build_surface()


func show_comparison(snapshot: Dictionary) -> void:
	current_snapshot = snapshot.duplicate(true)
	if snapshot.is_empty():
		hide_comparison()
		return
	title_label.text = String(snapshot.get(&"display_name", "UNKNOWN LOOT"))
	meta_label.text = "G%d · %s · 수량 %d · 보유 %d" % [
		int(snapshot.get(&"candidate_grade", 1)),
		String(snapshot.get(&"item_type", &"unknown")).to_upper(),
		int(snapshot.get(&"quantity", 1)),
		int(snapshot.get(&"owned_count", 0)),
	]
	comparison_label.text = "비교  %s · 현재 %s" % [
		String(snapshot.get(&"comparison_label", "신규 획득")),
		String(snapshot.get(&"active_weapon_name", "없음")),
	]
	lifecycle_label.text = "%s · %s" % [
		String(snapshot.get(&"family_label", "")),
		String(snapshot.get(&"use_label", "")),
	]
	outcome_label.text = "%s  /  %s" % [
		String(snapshot.get(&"extract_label", "")),
		String(snapshot.get(&"death_label", "")),
	]
	var equip_preview: Dictionary = snapshot.get(&"equip_preview", {})
	controls_label.text = (
		"R 즉시 장착   ·   F 런 보관   ·   ESC 보류"
		if bool(equip_preview.get(&"available", false))
		else "F 획득   ·   ESC 보류"
	)
	if bool(equip_preview.get(&"available", false)):
		outcome_label.text += "\n%s · %s" % [
			"임시 정책" if equip_preview.get(&"policy_status", &"") == &"provisional" else "확정 정책",
			String(equip_preview.get(&"previous_destination_label", "")),
		]
	visible = true


func hide_comparison() -> void:
	current_snapshot.clear()
	visible = false


func get_snapshot() -> Dictionary:
	return {
		&"visible": visible,
		&"item_id": current_snapshot.get(&"item_id", &""),
		&"has_comparison": not current_snapshot.is_empty(),
		&"shows_extract_result": not outcome_label.text.is_empty() if outcome_label != null else false,
		&"shows_cancel_and_select": (
			"F" in controls_label.text and "ESC 보류" in controls_label.text
		) if controls_label != null else false,
		&"shows_immediate_equip": "R 즉시 장착" in controls_label.text if controls_label != null else false,
		&"viewport_safe": _inside_viewport(),
	}


func _build_surface() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.01, 0.04, 0.055, 0.94)
	panel_style.border_color = Color("02e5e1")
	panel_style.set_border_width_all(1)
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_bottom_right = 4
	add_theme_stylebox_override("panel", panel_style)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	margin.add_child(content)
	var kicker := _label("FIELD ACQUISITION // COMPARE", 12, Color("02e5e1"))
	content.add_child(kicker)
	title_label = _label("", 22, Color(0.92, 0.98, 1.0))
	content.add_child(title_label)
	meta_label = _label("", 13, Color(0.63, 0.76, 0.8))
	content.add_child(meta_label)
	comparison_label = _label("", 14, Color(0.97, 0.73, 0.28))
	content.add_child(comparison_label)
	lifecycle_label = _label("", 13, Color(0.68, 0.95, 0.91))
	content.add_child(lifecycle_label)
	outcome_label = _label("", 12, Color(0.76, 0.83, 0.85))
	outcome_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(outcome_label)
	controls_label = _label("F 획득   ·   ESC 보류", 13, Color("02e5e1"))
	content.add_child(controls_label)


func _label(text_value: String, size_value: int, color: Color) -> Label:
	var result := Label.new()
	result.text = text_value
	result.add_theme_font_size_override("font_size", size_value)
	result.add_theme_color_override("font_color", color)
	return result


func _inside_viewport() -> bool:
	if not is_inside_tree():
		return false
	var viewport_rect := get_viewport_rect()
	var rect := get_global_rect()
	return viewport_rect.encloses(rect) or (
		rect.position.x >= 0.0 and rect.position.y >= 0.0
		and rect.end.x <= viewport_rect.end.x and rect.end.y <= viewport_rect.end.y
	)
