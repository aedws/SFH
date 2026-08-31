extends RefCounted

## 기존 HUD 데이터 노드를 유지하면서 임무 추적기와 하단 전투 클러스터로 재배치합니다.

const CORE_WIDTH := 600.0
const CORE_HEIGHT := 142.0
const MISSION_WIDTH := 338.0
const MISSION_HEIGHT := 108.0

var layout_root: Control
var mission_tracker: PanelContainer
var core_panel: PanelContainer
var detail_row: HBoxContainer
var combat_skill_hud: Control
var dash_cooldown_hud: Control
var interaction_prompt: Control


func install(hud: Control) -> bool:
	if hud == null:
		return false
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	core_panel = hud.get_node_or_null("Panel") as PanelContainer
	var content := hud.get_node_or_null("Panel/Margin/Content") as VBoxContainer
	if core_panel == null or content == null:
		return false

	layout_root = Control.new()
	layout_root.name = "TacticalHudLayout"
	layout_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(layout_root)
	core_panel.reparent(layout_root)
	_position_bottom_core(core_panel)
	core_panel.add_theme_stylebox_override(
		"panel", _style_box(Color("061018e8"), Color("247d78"), 7, 1)
	)
	content.add_theme_constant_override("separation", 2)

	var top_row := content.get_node("TopRow") as HBoxContainer
	var title := top_row.get_node("Title") as Label
	title.text = "ACTIVE LOADOUT"
	title.add_theme_color_override("font_color", Color("7ce7d5"))
	title.add_theme_font_size_override("font_size", 13)
	for label_path in ["LevelLabel", "KillsLabel", "CreditLabel"]:
		(top_row.get_node(label_path) as Label).add_theme_font_size_override("font_size", 10)

	(content.get_node("HealthRow/Caption") as Label).text = "HP"
	(content.get_node("ExperienceRow/Caption") as Label).text = "XP"
	var health := content.get_node("HealthRow/HealthBar") as ProgressBar
	health.custom_minimum_size.y = 16.0
	var experience := content.get_node("ExperienceRow/ExperienceBar") as ProgressBar
	experience.custom_minimum_size.y = 7.0

	var equipment := content.get_node("EquipmentLabel") as Label
	var weapon := content.get_node("WeaponRuntimeLabel") as Label
	detail_row = HBoxContainer.new()
	detail_row.name = "TacticalDetailRow"
	detail_row.add_theme_constant_override("separation", 10)
	content.add_child(detail_row)
	equipment.reparent(detail_row)
	weapon.reparent(detail_row)
	for label in [equipment, weapon]:
		label.custom_minimum_size = Vector2(0.0, 32.0)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 9)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var footer := content.get_node("FooterRow") as HBoxContainer
	content.move_child(detail_row, content.get_children().find(footer))
	var hint := footer.get_node("Hint") as Label
	hint.text = "LMB 기본기 · Q 무기 · F 상호작용 · K 설정"
	hint.add_theme_font_size_override("font_size", 9)

	mission_tracker = _build_mission_tracker(top_row, footer)
	layout_root.add_child(mission_tracker)
	_position_mission_tracker(mission_tracker)
	return true


func attach_runtime_layers(
	new_combat_skill_hud: Control,
	new_dash_cooldown_hud: Control,
	new_interaction_prompt: Control
) -> void:
	combat_skill_hud = new_combat_skill_hud
	dash_cooldown_hud = new_dash_cooldown_hud
	interaction_prompt = new_interaction_prompt
	if combat_skill_hud != null:
		_set_bottom_center_rect(combat_skill_hud, -258.0, -102.0, 258.0, -10.0)
	if dash_cooldown_hud != null:
		_set_bottom_center_rect(dash_cooldown_hud, -446.0, -72.0, -268.0, -10.0)
	if interaction_prompt != null:
		_set_bottom_center_rect(interaction_prompt, -190.0, -294.0, 190.0, -264.0)


func get_snapshot(hud: Control) -> Dictionary:
	var core_rect := core_panel.get_global_rect() if core_panel != null else Rect2()
	var mission_rect := mission_tracker.get_global_rect() if mission_tracker != null else Rect2()
	var skill_rect := combat_skill_hud.get_global_rect() if combat_skill_hud != null else Rect2()
	var dash_rect := dash_cooldown_hud.get_global_rect() if dash_cooldown_hud != null else Rect2()
	return {
		&"installed": layout_root != null,
		&"size": hud.size if hud != null else Vector2.ZERO,
		&"core_rect": core_rect,
		&"mission_rect": mission_rect,
		&"skill_rect": skill_rect,
		&"dash_rect": dash_rect,
		&"mission_tracker": mission_tracker != null,
		&"bottom_cluster": core_rect.size.x <= CORE_WIDTH + 1.0 and core_rect.size.y <= CORE_HEIGHT + 1.0,
		&"runtime_clustered": (
			combat_skill_hud != null
			and dash_cooldown_hud != null
			and not skill_rect.intersects(dash_rect)
			and skill_rect.position.y > core_rect.position.y
		),
		&"details_side_by_side": detail_row != null and detail_row.get_child_count() == 2,
	}


func _build_mission_tracker(
	top_row: HBoxContainer,
	footer: HBoxContainer
) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "MissionTracker"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override(
		"panel", _style_box(Color("071018dc"), Color("815ee8"), 5, 1)
	)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	var mission_content := VBoxContainer.new()
	mission_content.add_theme_constant_override("separation", 3)
	margin.add_child(mission_content)
	var header := HBoxContainer.new()
	mission_content.add_child(header)
	var header_label := Label.new()
	header_label.text = "MISSION // TACTICAL OBJECTIVE"
	header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_label.add_theme_color_override("font_color", Color("b39aff"))
	header_label.add_theme_font_size_override("font_size", 11)
	header.add_child(header_label)
	var time_label := top_row.get_node("TimeLabel") as Label
	time_label.reparent(header)
	time_label.add_theme_font_size_override("font_size", 10)
	var map_label := top_row.get_node("MapLabel") as Label
	map_label.reparent(mission_content)
	map_label.add_theme_font_size_override("font_size", 13)
	var status := footer.get_node("StatusLabel") as Label
	status.reparent(mission_content)
	status.custom_minimum_size.y = 38.0
	status.add_theme_font_size_override("font_size", 11)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return panel


func _position_bottom_core(panel: Control) -> void:
	_set_bottom_center_rect(
		panel,
		-CORE_WIDTH * 0.5,
		-254.0,
		CORE_WIDTH * 0.5,
		-254.0 + CORE_HEIGHT
	)


func _position_mission_tracker(panel: Control) -> void:
	panel.set_anchor(SIDE_LEFT, 0.0)
	panel.set_anchor(SIDE_TOP, 0.0)
	panel.set_anchor(SIDE_RIGHT, 0.0)
	panel.set_anchor(SIDE_BOTTOM, 0.0)
	panel.offset_left = 18.0
	panel.offset_top = 18.0
	panel.offset_right = 18.0 + MISSION_WIDTH
	panel.offset_bottom = 18.0 + MISSION_HEIGHT


func _set_bottom_center_rect(
	control: Control,
	left: float,
	top: float,
	right: float,
	bottom: float
) -> void:
	control.set_anchor(SIDE_LEFT, 0.5)
	control.set_anchor(SIDE_TOP, 1.0)
	control.set_anchor(SIDE_RIGHT, 0.5)
	control.set_anchor(SIDE_BOTTOM, 1.0)
	control.offset_left = left
	control.offset_top = top
	control.offset_right = right
	control.offset_bottom = bottom


func _style_box(background: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	return box
