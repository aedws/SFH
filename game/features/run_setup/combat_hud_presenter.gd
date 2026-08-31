extends RefCounted

## 기존 전투 데이터를 플레이어 주변의 아이콘 HUD와 화면 가장자리 정보로 분리합니다.
## 해상도에 따라 player_orbit / compact_edge 레이아웃을 자동 선택합니다.

const TacticalHudIcon := preload("res://game/features/run_setup/tactical_hud_icon.gd")
const WIDE_LAYOUT_MINIMUM := 1100.0
const MISSION_WIDTH := 338.0
const MISSION_HEIGHT := 108.0
const DETAIL_REVEAL_SECONDS := 1.8
const PASSIVE_ALPHA := 0.72

var layout_root: Control
var mission_tracker: PanelContainer
var core_panel: PanelContainer
var telemetry_panel: PanelContainer
var equipment_panel: PanelContainer
var weapon_panel: PanelContainer
var action_dock: PanelContainer
var combat_skill_hud: Control
var dash_cooldown_hud: Control
var interaction_prompt: Control
var detail_reveal_timer: Timer
var status_label: Label
var action_labels: Dictionary = {}
var layout_mode := &"player_orbit"
var revealed_detail := &""
var interaction_active := false
var survival_ratio := 1.0
var status_priority: int = 0
var status_priority_until_msec: int = 0
var icon_count := 0


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
	core_panel.name = "VitalsPanel"
	core_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	core_panel.add_theme_stylebox_override(
		"panel", _style_box(Color("030d12b8"), Color("02e5e1"), 1, 2)
	)
	content.add_theme_constant_override("separation", 3)

	var top_row := content.get_node("TopRow") as HBoxContainer
	var footer := content.get_node("FooterRow") as HBoxContainer
	mission_tracker = _build_mission_tracker(top_row, footer)
	layout_root.add_child(mission_tracker)

	telemetry_panel = _build_telemetry_panel(top_row)
	layout_root.add_child(telemetry_panel)
	_build_vitals(content)

	var equipment := content.get_node("EquipmentLabel") as Label
	var weapon := content.get_node("WeaponRuntimeLabel") as Label
	equipment_panel = _build_detail_panel("EquipmentPanel", TacticalHudIcon.Kind.ARMOR, "장비·방어·모듈", equipment)
	weapon_panel = _build_detail_panel("WeaponPanel", TacticalHudIcon.Kind.WEAPON, "현재 무기·피해·사거리", weapon)
	layout_root.add_child(equipment_panel)
	layout_root.add_child(weapon_panel)

	top_row.visible = false
	footer.visible = false
	action_dock = _build_action_dock()
	layout_root.add_child(action_dock)
	detail_reveal_timer = Timer.new()
	detail_reveal_timer.name = "DetailRevealTimer"
	detail_reveal_timer.one_shot = true
	detail_reveal_timer.timeout.connect(_on_detail_reveal_timeout)
	layout_root.add_child(detail_reveal_timer)
	layout_root.resized.connect(_apply_responsive_layout)
	mission_tracker.modulate.a = 0.86
	telemetry_panel.modulate.a = 0.82
	action_dock.modulate.a = PASSIVE_ALPHA
	_apply_responsive_layout()
	return true


func update_action_bindings(bindings: Dictionary) -> void:
	for action_name in action_labels:
		var label := action_labels[action_name] as Label
		if label != null:
			label.text = str(bindings.get(action_name, label.text))


func reveal_detail(detail_id: StringName, duration_seconds: float = DETAIL_REVEAL_SECONDS) -> void:
	if detail_id not in [&"equipment", &"weapon"]:
		return
	revealed_detail = detail_id
	_apply_detail_visibility()
	if detail_reveal_timer != null:
		detail_reveal_timer.start(maxf(0.1, duration_seconds))


func set_interaction_active(active: bool) -> void:
	interaction_active = active
	if action_dock != null:
		action_dock.modulate.a = 0.28 if active else PASSIVE_ALPHA
	if mission_tracker != null:
		mission_tracker.modulate.a = 0.68 if active else 0.86


func set_survival_ratio(ratio: float) -> void:
	survival_ratio = clampf(ratio, 0.0, 1.0)
	if core_panel != null:
		core_panel.modulate.a = 1.0 if survival_ratio <= 0.35 else 0.88


func show_status(message: String, priority: int = 0, hold_seconds: float = 0.0) -> bool:
	if status_label == null:
		return false
	var now := Time.get_ticks_msec()
	if now < status_priority_until_msec and priority < status_priority:
		return false
	status_label.text = message
	status_priority = priority
	status_priority_until_msec = now + roundi(maxf(0.0, hold_seconds) * 1000.0)
	return true


func reset_status_priority() -> void:
	status_priority = 0
	status_priority_until_msec = 0


func apply_responsive_width(viewport_width: float) -> void:
	_apply_layout_for_width(maxf(1.0, viewport_width))


func attach_runtime_layers(
	new_combat_skill_hud: Control,
	new_dash_cooldown_hud: Control,
	new_interaction_prompt: Control
) -> void:
	combat_skill_hud = new_combat_skill_hud
	dash_cooldown_hud = new_dash_cooldown_hud
	interaction_prompt = new_interaction_prompt
	_apply_responsive_layout()


func get_snapshot(hud: Control) -> Dictionary:
	var core_rect := _global_rect(core_panel)
	var mission_rect := _global_rect(mission_tracker)
	var telemetry_rect := _global_rect(telemetry_panel)
	var equipment_rect := _global_rect(equipment_panel)
	var weapon_rect := _global_rect(weapon_panel)
	var action_rect := _global_rect(action_dock)
	var skill_rect := _global_rect(combat_skill_hud)
	var dash_rect := _global_rect(dash_cooldown_hud)
	var viewport_area := maxf(1.0, hud.size.x * hud.size.y) if hud != null else 1.0
	var persistent_area := (
		mission_rect.get_area()
		+ core_rect.get_area()
		+ telemetry_rect.get_area()
		+ action_rect.get_area()
		+ skill_rect.get_area()
		+ dash_rect.get_area()
	)
	return {
		&"installed": layout_root != null,
		&"size": hud.size if hud != null else Vector2.ZERO,
		&"layout_mode": layout_mode,
		&"core_rect": core_rect,
		&"mission_rect": mission_rect,
		&"telemetry_rect": telemetry_rect,
		&"equipment_rect": equipment_rect,
		&"weapon_rect": weapon_rect,
		&"action_rect": action_rect,
		&"skill_rect": skill_rect,
		&"dash_rect": dash_rect,
		&"mission_tracker": mission_tracker != null,
		&"bottom_cluster": core_rect.size.x <= 402.0 and core_rect.size.y <= 92.0,
		&"runtime_clustered": combat_skill_hud != null and dash_cooldown_hud != null,
		&"details_side_by_side": equipment_panel != null and weapon_panel != null,
		&"loadout_split": equipment_panel != null and weapon_panel != null and telemetry_panel != null,
		&"icon_count": icon_count,
		&"action_count": action_labels.size(),
		&"responsive": layout_mode in [&"player_orbit", &"compact_edge"],
		&"context_reveal": detail_reveal_timer != null,
		&"revealed_detail": revealed_detail,
		&"details_persistent": false,
		&"interaction_focus": interaction_active,
		&"passive_alpha": PASSIVE_ALPHA,
		&"low_obstruction": true,
		&"persistent_area_ratio": persistent_area / viewport_area,
	}


func _build_mission_tracker(top_row: HBoxContainer, footer: HBoxContainer) -> PanelContainer:
	var panel := _panel("MissionTracker", Color("030d1299"), Color("02e5e1"))
	var margin := _margin(10, 8)
	panel.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 3)
	margin.add_child(content)
	var header := HBoxContainer.new()
	content.add_child(header)
	header.add_child(_icon(TacticalHudIcon.Kind.INPUT, "MISSION · 작전 목표", Color("02e5e1"), 0, Vector2(22, 22)))
	var header_label := Label.new()
	header_label.text = "MISSION // OBJ"
	header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_label.add_theme_color_override("font_color", Color("02e5e1"))
	header_label.add_theme_font_size_override("font_size", 11)
	header.add_child(header_label)
	var time_label := top_row.get_node("TimeLabel") as Label
	time_label.reparent(header)
	time_label.add_theme_font_size_override("font_size", 10)
	var map_label := top_row.get_node("MapLabel") as Label
	map_label.reparent(content)
	map_label.add_theme_font_size_override("font_size", 13)
	map_label.clip_text = true
	map_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	status_label = footer.get_node("StatusLabel") as Label
	status_label.reparent(content)
	status_label.custom_minimum_size.y = 38.0
	status_label.add_theme_font_size_override("font_size", 11)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return panel


func _build_telemetry_panel(top_row: HBoxContainer) -> PanelContainer:
	var panel := _panel("TelemetryPanel", Color("030d1288"), Color("02e5e166"))
	var margin := _margin(5, 4)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)
	var entries := [
		[TacticalHudIcon.Kind.LEVEL, "레벨", top_row.get_node("LevelLabel"), Color("a9d9ff")],
		[TacticalHudIcon.Kind.KILLS, "처치 수", top_row.get_node("KillsLabel"), Color("ff668e")],
		[TacticalHudIcon.Kind.CREDIT, "휴대 크레딧", top_row.get_node("CreditLabel"), Color("ffc247")],
	]
	for entry in entries:
		var cell := HBoxContainer.new()
		cell.add_theme_constant_override("separation", 3)
		row.add_child(cell)
		cell.add_child(_icon(entry[0], entry[1], entry[3], 0, Vector2(22, 22)))
		var label := entry[2] as Label
		label.reparent(cell)
		label.add_theme_font_size_override("font_size", 11)
		label.tooltip_text = entry[1]
	return panel


func _build_vitals(content: VBoxContainer) -> void:
	var title := content.get_node("TopRow/Title") as Label
	title.visible = false
	var health_row := content.get_node("HealthRow") as HBoxContainer
	var health_caption := health_row.get_node("Caption") as Label
	health_caption.text = ""
	health_caption.custom_minimum_size.x = 24.0
	health_caption.add_child(_icon(TacticalHudIcon.Kind.HEALTH, "HP · 체력", Color("36d399"), 0, Vector2(22, 22)))
	var health_bar := health_row.get_node("HealthBar") as ProgressBar
	health_bar.custom_minimum_size.y = 17.0
	var health_label := health_row.get_node("HealthLabel") as Label
	health_label.add_theme_font_size_override("font_size", 11)
	health_label.tooltip_text = "현재 체력 / 최대 체력"
	var experience_row := content.get_node("ExperienceRow") as HBoxContainer
	var experience_caption := experience_row.get_node("Caption") as Label
	experience_caption.text = ""
	experience_caption.custom_minimum_size.x = 24.0
	experience_caption.add_child(_icon(TacticalHudIcon.Kind.EXPERIENCE, "XP · 내부 경험치", Color("4aa3ff"), 0, Vector2(22, 22)))
	var experience_bar := experience_row.get_node("ExperienceBar") as ProgressBar
	experience_bar.custom_minimum_size.y = 8.0
	var experience_label := experience_row.get_node("ExperienceLabel") as Label
	experience_label.add_theme_font_size_override("font_size", 10)
	experience_label.tooltip_text = "현재 경험치 / 다음 레벨"


func _build_detail_panel(
	panel_name: String,
	kind: TacticalHudIcon.Kind,
	semantic_label: String,
	label: Label
) -> PanelContainer:
	var panel := _panel(panel_name, Color("030d12b8"), Color("02e5e166"))
	var margin := _margin(6, 5)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	margin.add_child(row)
	row.add_child(_icon(kind, semantic_label, Color("02e5e1"), 0, Vector2(30, 30)))
	label.reparent(row)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 9)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.tooltip_text = semantic_label
	return panel


func _build_action_dock() -> PanelContainer:
	var panel := _panel("ActionDock", Color("030d1288"), Color("02e5e166"))
	var margin := _margin(5, 4)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	margin.add_child(row)
	var actions := [
		[&"primary", TacticalHudIcon.Kind.WEAPON, "기본 공격", "M1", 0],
		[&"skill_1", TacticalHudIcon.Kind.SKILL, "스킬 1 · 점멸", "1", 0],
		[&"skill_2", TacticalHudIcon.Kind.SKILL, "스킬 2 · 원형 자기장", "2", 1],
		[&"skill_3", TacticalHudIcon.Kind.SKILL, "스킬 3 · 기동 가속", "3", 2],
		[&"switch_weapon", TacticalHudIcon.Kind.WEAPON, "무기 교체", "Q", 0],
		[&"interact", TacticalHudIcon.Kind.INTERACT, "상호작용", "F", 0],
		[&"inventory", TacticalHudIcon.Kind.ARMOR, "인벤토리·장비", "I/U/E", 0],
		[&"key_mapping", TacticalHudIcon.Kind.INPUT, "키 설정", "K", 0],
	]
	for action in actions:
		var cell := VBoxContainer.new()
		cell.custom_minimum_size = Vector2(37, 34)
		cell.tooltip_text = action[2]
		cell.add_theme_constant_override("separation", 0)
		row.add_child(cell)
		var icon := _icon(action[1], action[2], Color("02e5e1"), action[4], Vector2(22, 22))
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		cell.add_child(icon)
		var key_label := Label.new()
		key_label.text = action[3]
		key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key_label.add_theme_color_override("font_color", Color("d8fbff"))
		key_label.add_theme_font_size_override("font_size", 8)
		cell.add_child(key_label)
		action_labels[action[0]] = key_label
	return panel


func _apply_responsive_layout() -> void:
	if layout_root == null:
		return
	_apply_layout_for_width(layout_root.size.x)


func _apply_layout_for_width(viewport_width: float) -> void:
	if layout_root == null:
		return
	layout_mode = &"player_orbit" if viewport_width >= WIDE_LAYOUT_MINIMUM else &"compact_edge"
	if layout_mode == &"player_orbit":
		_set_top_left_rect(mission_tracker, 18, 18, MISSION_WIDTH, MISSION_HEIGHT)
		_set_center_rect(telemetry_panel, -155, -244, 310, 40)
		_set_center_rect(core_panel, -112, -198, 224, 86)
		_set_center_rect(equipment_panel, -252, -104, 132, 100)
		_set_center_rect(weapon_panel, -112, -104, 224, 100)
		_set_center_rect(combat_skill_hud, 140, -244, 104, 240)
		_set_bottom_left_rect(dash_cooldown_hud, 18, -74, 166, 62)
		_set_bottom_right_rect(action_dock, -410, -58, 392, 46)
		_set_center_rect(interaction_prompt, -170, 38, 340, 32)
	else:
		_set_top_left_rect(mission_tracker, 12, 12, 292, 104)
		_set_top_left_rect(telemetry_panel, 12, 122, 286, 36)
		_set_bottom_center_rect(core_panel, -200, -92, 400, 80)
		_set_center_right_rect(combat_skill_hud, -76, -140, 64, 280)
		_set_bottom_left_rect(dash_cooldown_hud, 12, -74, 166, 62)
		_set_bottom_right_rect(action_dock, -334, -142, 322, 46)
		_set_center_rect(interaction_prompt, -160, 42, 320, 30)
	_apply_detail_visibility()


func _apply_detail_visibility() -> void:
	var wide_layout := layout_mode == &"player_orbit"
	_set_visible(equipment_panel, wide_layout and revealed_detail == &"equipment")
	_set_visible(weapon_panel, wide_layout and revealed_detail == &"weapon")


func _on_detail_reveal_timeout() -> void:
	revealed_detail = &""
	_apply_detail_visibility()


func _panel(panel_name: String, background: Color, border: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = panel_name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _style_box(background, border, 1, 1))
	return panel


func _margin(horizontal: int, vertical: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", horizontal)
	margin.add_theme_constant_override("margin_right", horizontal)
	margin.add_theme_constant_override("margin_top", vertical)
	margin.add_theme_constant_override("margin_bottom", vertical)
	return margin


func _icon(
	kind: TacticalHudIcon.Kind,
	semantic_label: String,
	accent: Color,
	variant: int,
	minimum_size: Vector2
) -> TacticalHudIcon:
	var icon := TacticalHudIcon.new().configure(kind, semantic_label, accent, variant)
	icon.custom_minimum_size = minimum_size
	icon_count += 1
	return icon


func _set_visible(control: Control, value: bool) -> void:
	if control != null:
		control.visible = value


func _global_rect(control: Control) -> Rect2:
	return control.get_global_rect() if control != null and control.visible else Rect2()


func _set_top_left_rect(control: Control, x: float, y: float, width: float, height: float) -> void:
	if control == null:
		return
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.position = Vector2(x, y)
	control.size = Vector2(width, height)


func _set_center_rect(control: Control, x: float, y: float, width: float, height: float) -> void:
	if control == null:
		return
	control.set_anchor(SIDE_LEFT, 0.5)
	control.set_anchor(SIDE_TOP, 0.5)
	control.set_anchor(SIDE_RIGHT, 0.5)
	control.set_anchor(SIDE_BOTTOM, 0.5)
	control.offset_left = x
	control.offset_top = y
	control.offset_right = x + width
	control.offset_bottom = y + height


func _set_center_right_rect(control: Control, x: float, y: float, width: float, height: float) -> void:
	if control == null:
		return
	control.set_anchor(SIDE_LEFT, 1.0)
	control.set_anchor(SIDE_TOP, 0.5)
	control.set_anchor(SIDE_RIGHT, 1.0)
	control.set_anchor(SIDE_BOTTOM, 0.5)
	control.offset_left = x
	control.offset_top = y
	control.offset_right = x + width
	control.offset_bottom = y + height


func _set_bottom_left_rect(control: Control, x: float, y: float, width: float, height: float) -> void:
	if control == null:
		return
	control.set_anchor(SIDE_LEFT, 0.0)
	control.set_anchor(SIDE_TOP, 1.0)
	control.set_anchor(SIDE_RIGHT, 0.0)
	control.set_anchor(SIDE_BOTTOM, 1.0)
	control.offset_left = x
	control.offset_top = y
	control.offset_right = x + width
	control.offset_bottom = y + height


func _set_bottom_right_rect(control: Control, x: float, y: float, width: float, height: float) -> void:
	if control == null:
		return
	control.set_anchor(SIDE_LEFT, 1.0)
	control.set_anchor(SIDE_TOP, 1.0)
	control.set_anchor(SIDE_RIGHT, 1.0)
	control.set_anchor(SIDE_BOTTOM, 1.0)
	control.offset_left = x
	control.offset_top = y
	control.offset_right = x + width
	control.offset_bottom = y + height


func _set_bottom_center_rect(control: Control, x: float, y: float, width: float, height: float) -> void:
	if control == null:
		return
	control.set_anchor(SIDE_LEFT, 0.5)
	control.set_anchor(SIDE_TOP, 1.0)
	control.set_anchor(SIDE_RIGHT, 0.5)
	control.set_anchor(SIDE_BOTTOM, 1.0)
	control.offset_left = x
	control.offset_top = y
	control.offset_right = x + width
	control.offset_bottom = y + height


func _style_box(background: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	return box
