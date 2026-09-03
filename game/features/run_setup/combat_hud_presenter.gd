extends RefCounted

## 기존 전투 데이터를 플레이어 주변의 아이콘 HUD와 화면 가장자리 정보로 분리합니다.
## 해상도에 따라 player_orbit / compact_edge 레이아웃을 자동 선택합니다.

const TacticalHudIcon := preload("res://game/features/run_setup/tactical_hud_icon.gd")
const WIDE_LAYOUT_MINIMUM := 1100.0
const NARROW_LAYOUT_MAXIMUM := 720.0
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
var session_socket_hud: Control
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
var hud_anchor: StringName = &"bottom_left"
var key_label_format: StringName = &"compact"
var raw_action_bindings: Dictionary = {}
var avoid_mobile_controls := false
var tutorial_overlay: Control
var hub_view: Control
var hub_hint: Label
var hub_objective: Label
var hub_objective_text := ""


func attach_hub(view: Control) -> void:
	hub_view = view
	hub_hint = view.get_node_or_null("Panel/Margin/Content/Controls") as Label
	hub_objective = view.get_node_or_null("Panel/Margin/Content/Objective") as Label
	if hub_objective != null:
		hub_objective_text = hub_objective.text
		hub_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if hub_hint != null:
		hub_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_responsive_layout()


func attach_tutorial(overlay: Control) -> void:
	tutorial_overlay = overlay
	if tutorial_overlay != null:
		tutorial_overlay.visibility_changed.connect(_sync_tutorial_visibility)
	_sync_tutorial_visibility()


func _sync_tutorial_visibility() -> void:
	_set_visible(mission_tracker, tutorial_overlay == null or not tutorial_overlay.is_visible_in_tree())


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
	raw_action_bindings = bindings.duplicate(true)
	for action_name in action_labels:
		var label := action_labels[action_name] as Label
		if label != null:
			label.text = _format_key_label(str(bindings.get(action_name, label.text)))


func apply_user_preferences(snapshot: Dictionary) -> bool:
	var new_anchor := StringName(snapshot.get(&"hud_anchor", &"bottom_left"))
	var new_format := StringName(snapshot.get(&"key_label_format", &"compact"))
	if new_anchor not in [&"bottom_left", &"bottom_center", &"bottom_right"]:
		return false
	if new_format not in [&"compact", &"boxed", &"hidden"]:
		return false
	hud_anchor = new_anchor
	key_label_format = new_format
	avoid_mobile_controls = bool(snapshot.get(&"mobile_controls_visible", false))
	if not raw_action_bindings.is_empty():
		update_action_bindings(raw_action_bindings)
	_apply_responsive_layout()
	return true


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
	new_interaction_prompt: Control,
	new_session_socket_hud: Control = null
) -> void:
	combat_skill_hud = new_combat_skill_hud
	dash_cooldown_hud = new_dash_cooldown_hud
	interaction_prompt = new_interaction_prompt
	session_socket_hud = new_session_socket_hud
	if session_socket_hud != null and session_socket_hud.has_method(&"set_managed_layout"):
		session_socket_hud.call(&"set_managed_layout", true)
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
	var socket_rect := _global_rect(session_socket_hud)
	var tutorial_rect := Rect2()
	if is_instance_valid(tutorial_overlay) and tutorial_overlay.is_visible_in_tree():
		tutorial_rect = tutorial_overlay.call(&"get_snapshot").get(&"panel_rect", Rect2())
	var viewport_area := maxf(1.0, hud.size.x * hud.size.y) if hud != null else 1.0
	var central_safe_rect := _central_safe_rect(hud.size) if hud != null else Rect2()
	var persistent_area := (
		mission_rect.get_area()
		+ core_rect.get_area()
		+ telemetry_rect.get_area()
		+ action_rect.get_area()
		+ skill_rect.get_area()
		+ dash_rect.get_area()
		+ socket_rect.get_area()
		+ tutorial_rect.get_area()
	)
	var persistent_rects := [mission_rect, core_rect, telemetry_rect, action_rect, skill_rect, dash_rect, socket_rect, tutorial_rect]
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
		&"socket_rect": socket_rect,
		&"tutorial_rect": tutorial_rect,
		&"session_socket_inside_viewport": session_socket_hud == null or not session_socket_hud.is_visible_in_tree() or _rect_inside_viewport(socket_rect, hud.size),
		&"central_safe_rect": central_safe_rect,
		&"central_safe_clear": _rects_clear_zone(persistent_rects, central_safe_rect),
		&"mission_tracker": mission_tracker != null,
		&"bottom_cluster": core_rect.size.x <= 402.0 and core_rect.size.y <= 92.0,
		&"runtime_clustered": combat_skill_hud != null and dash_cooldown_hud != null,
		&"session_socket_managed": session_socket_hud == null or session_socket_hud.has_method(&"set_managed_layout"),
		&"details_side_by_side": equipment_panel != null and weapon_panel != null,
		&"loadout_split": equipment_panel != null and weapon_panel != null and telemetry_panel != null,
		&"icon_count": icon_count,
		&"action_count": action_labels.size(),
		&"responsive": layout_mode in [&"player_orbit", &"compact_edge", &"minimal_edge", &"mobile_touch"],
		&"context_reveal": detail_reveal_timer != null,
		&"revealed_detail": revealed_detail,
		&"details_persistent": false,
		&"interaction_focus": interaction_active,
		&"passive_alpha": PASSIVE_ALPHA,
		&"low_obstruction": true,
		&"persistent_area_ratio": persistent_area / viewport_area,
		&"hud_anchor": hud_anchor,
		&"key_label_format": key_label_format,
		&"avoids_mobile_controls": avoid_mobile_controls,
		&"player_status_lower_edge": core_rect.end.y >= hud.size.y - 210.0 if hud != null else false,
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
	if is_instance_valid(hub_view):
		_set_top_left_rect(hub_view, 18, 58 if avoid_mobile_controls else 16, minf(420 if avoid_mobile_controls else 596, viewport_width - 36), 116)
		if hub_hint != null:
			hub_hint.visible = not avoid_mobile_controls
		if hub_objective != null:
			hub_objective.text = "동쪽 작전 게이트에서 ‘사용’을 누르세요." if avoid_mobile_controls else hub_objective_text
	# 모바일은 패드 자체에 에너지·스킬/대시 대기를 표시합니다. PC용 중복 HUD를 제거합니다.
	_set_visible(combat_skill_hud, not avoid_mobile_controls)
	_set_visible(dash_cooldown_hud, not avoid_mobile_controls)
	if avoid_mobile_controls:
		layout_mode = &"mobile_touch"
		_set_top_left_rect(mission_tracker, 18, 58, viewport_width - 36 if viewport_width < 720 else 334, 94)
		_set_top_left_rect(core_panel, 18, 158, 260, 72)
		_set_top_left_rect(telemetry_panel, 18, 234, 260, 32)
		_set_visible(action_dock, false)
		_set_visible(equipment_panel, false)
		_set_visible(weapon_panel, false)
		if viewport_width < 720:
			_set_top_left_rect(session_socket_hud, 18, 272, viewport_width - 36, 62)
		else:
			_set_top_left_rect(session_socket_hud, 368, 58, minf(360, viewport_width - 536), 62)
		_set_center_rect(interaction_prompt, -140, 38, 280, 30)
		return
	if viewport_width >= WIDE_LAYOUT_MINIMUM:
		layout_mode = &"player_orbit"
	elif viewport_width <= NARROW_LAYOUT_MAXIMUM:
		layout_mode = &"minimal_edge"
	else:
		layout_mode = &"compact_edge"
	if layout_mode == &"player_orbit":
		_set_top_left_rect(mission_tracker, 18, 18, MISSION_WIDTH, MISSION_HEIGHT)
		_set_center_rect(equipment_panel, -252, -104, 132, 100)
		_set_center_rect(weapon_panel, -112, -104, 224, 100)
		_set_bottom_right_rect(combat_skill_hud, -458, -148, 440, 82)
		_set_bottom_right_rect(action_dock, -410, -58, 392, 46)
		_set_bottom_center_rect(session_socket_hud, -226, -70, 440, 62)
		_set_center_rect(interaction_prompt, -170, 38, 340, 32)
	elif layout_mode == &"compact_edge":
		_set_top_left_rect(mission_tracker, 12, 12, 292, 104)
		_set_bottom_right_rect(combat_skill_hud, -312, -230, 300, 82)
		_set_bottom_right_rect(action_dock, -334, -142, 322, 46)
		_set_bottom_center_rect(session_socket_hud, -190, -70, 380, 62)
		_set_center_rect(interaction_prompt, -160, 42, 320, 30)
	else:
		_set_top_left_rect(mission_tracker, 10, 10, 260, 92)
		_set_bottom_right_rect(combat_skill_hud, -280, -192, 270, 80)
		_set_visible(action_dock, false)
		_set_bottom_center_rect(session_socket_hud, -150, -70, 300, 62)
		_set_center_rect(interaction_prompt, -140, 36, 280, 30)
	if layout_mode != &"minimal_edge":
		_set_visible(action_dock, true)
	_place_player_status_cluster(viewport_width)
	_apply_detail_visibility()


func _place_player_status_cluster(viewport_width: float) -> void:
	var compact := viewport_width < WIDE_LAYOUT_MINIMUM
	var narrow := viewport_width <= NARROW_LAYOUT_MAXIMUM
	var core_width := 244.0 if narrow else (286.0 if compact else 360.0)
	var core_height := 72.0 if narrow else (80.0 if compact else 86.0)
	var telemetry_width := core_width
	var telemetry_height := 32.0 if narrow else 36.0
	var core_y := -154.0 if narrow else (-270.0 if compact else -148.0)
	if avoid_mobile_controls and hud_anchor in [&"bottom_left", &"bottom_right"]:
		core_y = -244.0 if narrow else -290.0
	var telemetry_y := core_y - telemetry_height - 6.0
	var dash_y := minf(core_y + core_height + 6.0, -68.0)
	match hud_anchor:
		&"bottom_center":
			_set_bottom_center_rect(core_panel, -core_width * 0.5, core_y, core_width, core_height)
			_set_bottom_center_rect(telemetry_panel, -telemetry_width * 0.5, telemetry_y, telemetry_width, telemetry_height)
			_set_bottom_center_rect(dash_cooldown_hud, -83, dash_y, 166, 62)
		&"bottom_right":
			_set_bottom_right_rect(core_panel, -core_width - 18, core_y, core_width, core_height)
			_set_bottom_right_rect(telemetry_panel, -telemetry_width - 18, telemetry_y, telemetry_width, telemetry_height)
			_set_bottom_right_rect(dash_cooldown_hud, -184, dash_y, 166, 62)
		_:
			_set_bottom_left_rect(core_panel, 18, core_y, core_width, core_height)
			_set_bottom_left_rect(telemetry_panel, 18, telemetry_y, telemetry_width, telemetry_height)
			_set_bottom_left_rect(dash_cooldown_hud, 18, dash_y, 166, 62)


func _format_key_label(label: String) -> String:
	match key_label_format:
		&"boxed":
			return "[%s]" % label
		&"hidden":
			return ""
	return label


func _apply_detail_visibility() -> void:
	var wide_layout := layout_mode == &"player_orbit"
	_set_visible(equipment_panel, wide_layout and revealed_detail == &"equipment")
	_set_visible(weapon_panel, wide_layout and revealed_detail == &"weapon")


func _central_safe_rect(viewport_size: Vector2) -> Rect2:
	var safe_height_ratio := 0.42 if viewport_size.x <= NARROW_LAYOUT_MAXIMUM else 0.54
	return Rect2(
		Vector2(viewport_size.x * 0.22, viewport_size.y * 0.18),
		Vector2(viewport_size.x * 0.56, viewport_size.y * safe_height_ratio)
	)


func _rects_clear_zone(rects: Array, zone: Rect2) -> bool:
	for rect in rects:
		if rect is Rect2 and (rect as Rect2).get_area() > 0.0 and (rect as Rect2).intersects(zone):
			return false
	return true


func _rect_inside_viewport(rect: Rect2, viewport_size: Vector2) -> bool:
	if rect.get_area() <= 0.0:
		return true
	return Rect2(Vector2.ZERO, viewport_size).encloses(rect)


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
