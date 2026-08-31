extends RefCounted

## 기존 HUD 데이터 노드를 유지하면서 전술 정보 계층과 화면 점유율만 교체합니다.

var detail_row: HBoxContainer


func install(hud: Control) -> bool:
	if hud == null:
		return false
	hud.set_anchor(SIDE_LEFT, 0.0)
	hud.set_anchor(SIDE_TOP, 0.0)
	hud.set_anchor(SIDE_RIGHT, 0.0)
	hud.set_anchor(SIDE_BOTTOM, 0.0)
	hud.offset_left = 16.0
	hud.offset_top = 14.0
	hud.offset_right = 1056.0
	hud.offset_bottom = 158.0
	var panel := hud.get_node_or_null("Panel") as PanelContainer
	var content := hud.get_node_or_null("Panel/Margin/Content") as VBoxContainer
	if panel == null or content == null:
		return false
	panel.add_theme_stylebox_override("panel", _style_box(Color("061018eb"), Color("247d78"), 7, 1))
	content.add_theme_constant_override("separation", 2)
	var title := content.get_node("TopRow/Title") as Label
	title.text = "SFH // RAID"
	title.add_theme_color_override("font_color", Color("7ce7d5"))
	title.add_theme_font_size_override("font_size", 15)
	(content.get_node("HealthRow/Caption") as Label).text = "VITAL"
	(content.get_node("ExperienceRow/Caption") as Label).text = "RUN XP"
	for label_path in ["TopRow/TimeLabel", "TopRow/LevelLabel", "TopRow/KillsLabel", "TopRow/CreditLabel", "TopRow/MapLabel"]:
		(content.get_node(label_path) as Label).add_theme_font_size_override("font_size", 11)
	var health := content.get_node("HealthRow/HealthBar") as ProgressBar
	health.custom_minimum_size.y = 16.0
	var experience := content.get_node("ExperienceRow/ExperienceBar") as ProgressBar
	experience.custom_minimum_size.y = 8.0
	var equipment := content.get_node("EquipmentLabel") as Label
	var weapon := content.get_node("WeaponRuntimeLabel") as Label
	detail_row = HBoxContainer.new()
	detail_row.name = "TacticalDetailRow"
	detail_row.add_theme_constant_override("separation", 12)
	content.add_child(detail_row)
	equipment.reparent(detail_row)
	weapon.reparent(detail_row)
	for label in [equipment, weapon]:
		label.custom_minimum_size = Vector2(0.0, 24.0)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 10)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var footer := content.get_node("FooterRow") as HBoxContainer
	content.move_child(detail_row, content.get_children().find(footer))
	var hint := footer.get_node("Hint") as Label
	hint.add_theme_font_size_override("font_size", 10)
	var status := footer.get_node("StatusLabel") as Label
	status.add_theme_font_size_override("font_size", 10)
	return true


func get_snapshot(hud: Control) -> Dictionary:
	return {
		&"installed": detail_row != null,
		&"size": hud.size if hud != null else Vector2.ZERO,
		&"minimum_size": hud.get_combined_minimum_size() if hud != null else Vector2.ZERO,
		&"details_side_by_side": detail_row != null and detail_row.get_child_count() == 2,
	}


func _style_box(background: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	return box
