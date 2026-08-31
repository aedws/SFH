extends RefCounted

## 작전 계약 데이터를 계산하지 않고, 기존 설정 Control을 브리핑 중심 화면으로 재배치합니다.

const OPERATION_PREVIEW_SCRIPT := preload("res://game/features/run_setup/operation_preview.gd")

var launch_button: Button
var mission_title: Label
var mission_code: Label
var mission_intel: Label
var reward_summary: Label
var risk_summary: Label
var selection_summary: Label
var preview: Control
var tier_buttons: Dictionary = {}
var root_panel: PanelContainer
var left_column: Control
var right_column: Control


func install(overlay: Control) -> Dictionary:
	if overlay == null:
		return {}
	var content := overlay.get_node_or_null("Center/Panel/Margin/Content") as VBoxContainer
	if content == null:
		return {}
	if content.has_node("MainColumns"):
		return {&"launch_button": launch_button}

	var panel := overlay.get_node("Center/Panel") as PanelContainer
	root_panel = panel
	panel.custom_minimum_size = Vector2(1180.0, 660.0)
	panel.add_theme_stylebox_override("panel", _style_box(Color("071018f7"), Color("247e7a"), 12, 2))
	var margin := overlay.get_node("Center/Panel/Margin") as MarginContainer
	for side in [&"margin_left", &"margin_top", &"margin_right", &"margin_bottom"]:
		margin.add_theme_constant_override(side, 20)
	content.alignment = BoxContainer.ALIGNMENT_BEGIN
	content.add_theme_constant_override("separation", 10)

	var columns := HBoxContainer.new()
	columns.name = "MainColumns"
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 14)
	content.add_child(columns)
	content.move_child(columns, 0)

	var left_panel := PanelContainer.new()
	left_column = left_panel
	left_panel.name = "MissionBriefingPanel"
	left_panel.custom_minimum_size = Vector2(548.0, 0.0)
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_panel.add_theme_stylebox_override("panel", _style_box(Color("091722e6"), Color("295b63"), 8, 1))
	columns.add_child(left_panel)
	var left_margin := _margin_container(18, 16, 18, 16)
	left_panel.add_child(left_margin)
	var left := VBoxContainer.new()
	left.name = "BriefingContent"
	left.add_theme_constant_override("separation", 8)
	left_margin.add_child(left)

	var right_panel := PanelContainer.new()
	right_column = right_panel
	right_panel.name = "ContractConfigurationPanel"
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_theme_stylebox_override("panel", _style_box(Color("07131ce8"), Color("254a55"), 8, 1))
	columns.add_child(right_panel)
	var right_margin := _margin_container(18, 14, 18, 14)
	right_panel.add_child(right_margin)
	var right := VBoxContainer.new()
	right.name = "ConfigurationContent"
	right.add_theme_constant_override("separation", 7)
	right_margin.add_child(right)

	var context := content.get_node("Context") as Label
	var title := content.get_node("Title") as Label
	var subtitle := content.get_node("Subtitle") as Label
	_move(context, left)
	_move(title, left)
	_move(subtitle, left)
	context.text = "OPERATION BRIEF // TACTICAL INSERTION"
	context.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	context.add_theme_color_override("font_color", Color("42ddc3"))
	title.text = "작전 브리핑"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.add_theme_font_size_override("font_size", 28)
	subtitle.text = "투입 조건과 회수 기대값을 확인하고 작전 계약을 확정하세요."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	subtitle.add_theme_font_size_override("font_size", 13)

	mission_title = _label("폐허 도시 · 소형 작전", 22, Color("f1f7f8"))
	left.add_child(mission_title)
	mission_code = _label("RAID / STANDARD / RECOVERY", 11, Color("75aeb7"))
	left.add_child(mission_code)
	preview = OPERATION_PREVIEW_SCRIPT.new()
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(preview)
	var preview_badge := _label("LIVE TACTICAL PROJECTION  ·  START → EXTRACTION", 11, Color("a9eee2"))
	preview_badge.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	preview_badge.offset_left = 12.0
	preview_badge.offset_top = -30.0
	preview_badge.offset_right = -12.0
	preview_badge.offset_bottom = -8.0
	preview_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	preview.add_child(preview_badge)

	left.add_child(_section_title("작전 정보"))
	mission_intel = _label("탐색 데이터 계산 중...", 13, Color("bed1d5"))
	mission_intel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(mission_intel)
	left.add_child(_section_title("예상 회수"))
	reward_summary = _label("회수 계약 계산 중...", 13, Color("ffd579"))
	reward_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(reward_summary)

	right.add_child(_section_title("작전 조건 선택"))
	var contract_section := content.get_node("ContractSection") as VBoxContainer
	_move(contract_section, right)
	contract_section.add_theme_constant_override("separation", 6)
	var selectors := contract_section.get_node("Selectors") as HBoxContainer
	selectors.alignment = BoxContainer.ALIGNMENT_BEGIN
	for button in selectors.get_children():
		if button is Button:
			(button as Button).custom_minimum_size = Vector2(0.0, 36.0)
			(button as Button).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var meta_actions := contract_section.get_node("MetaActions") as HBoxContainer
	meta_actions.alignment = BoxContainer.ALIGNMENT_BEGIN
	for button in meta_actions.get_children():
		if button is Button:
			(button as Button).custom_minimum_size = Vector2(0.0, 30.0)
			(button as Button).size_flags_horizontal = Control.SIZE_EXPAND_FILL

	right.add_child(_section_title("작전 규모"))
	var tiers := content.get_node("TierButtons") as HBoxContainer
	_move(tiers, right)
	tiers.alignment = BoxContainer.ALIGNMENT_BEGIN
	for button in tiers.get_children():
		if button is Button:
			(button as Button).custom_minimum_size = Vector2(0.0, 82.0)
			(button as Button).size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tier_buttons[_tier_id_from_button(button)] = button

	var balance := content.get_node("BalanceModeSection") as VBoxContainer
	_move(balance, right)
	(balance.get_node("Title") as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	(balance.get_node("Buttons") as HBoxContainer).alignment = BoxContainer.ALIGNMENT_BEGIN
	for button in balance.get_node("Buttons").get_children():
		if button is Button:
			(button as Button).custom_minimum_size = Vector2(0.0, 34.0)
			(button as Button).size_flags_horizontal = Control.SIZE_EXPAND_FILL

	risk_summary = _label("위험도 계산 중...", 12, Color("ffbf84"))
	risk_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(risk_summary)
	selection_summary = _label("계약 선택 대기", 12, Color("8de6d5"))
	selection_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(selection_summary)
	var launch_spacer := Control.new()
	launch_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(launch_spacer)
	launch_button = Button.new()
	launch_button.name = "OperationLaunchButton"
	launch_button.custom_minimum_size = Vector2(0.0, 52.0)
	launch_button.add_theme_font_size_override("font_size", 18)
	launch_button.add_theme_stylebox_override("normal", _style_box(Color("0f493f"), Color("32d9b9"), 5, 2))
	launch_button.add_theme_stylebox_override("hover", _style_box(Color("176455"), Color("7ff5dc"), 5, 2))
	launch_button.add_theme_stylebox_override("pressed", _style_box(Color("0a332d"), Color("29ad98"), 5, 2))
	right.add_child(launch_button)

	var footer := content.get_node("Footer") as Label
	footer.text = "ESC  전초기지 복귀   ·   투입 시 비용과 장착 소모품이 실제 차감됩니다"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	content.move_child(footer, content.get_child_count() - 1)
	return {&"launch_button": launch_button}


func update(payload: Dictionary) -> void:
	if launch_button == null:
		return
	var tier_id := StringName(payload.get(&"tier_id", &"small"))
	var region_id := StringName(payload.get(&"region_id", &"ruined_city"))
	var difficulty_id := StringName(payload.get(&"difficulty_id", &"standard"))
	var quote: Dictionary = payload.get(&"quote", {})
	var map_data: Dictionary = payload.get(&"map", {})
	var spawn_data: Dictionary = payload.get(&"spawn", {})
	var penalty_names: PackedStringArray = payload.get(&"penalty_names", PackedStringArray())
	var region_name := String(payload.get(&"region_name", "기본 지역"))
	var difficulty_name := String(payload.get(&"difficulty_name", "표준"))
	var tier_name := String(map_data.get(&"display_name", tier_id))
	mission_title.text = "%s  ·  %s" % [region_name, tier_name]
	mission_code.text = "%s / %s / %s" % [String(region_id).to_upper(), String(difficulty_id).to_upper(), String(tier_id).to_upper()]
	mission_intel.text = "목표 %d분  ·  방 %d~%d개  ·  동시 적 %d~%d명\n핵심 루프  침투 → 탐색·교전 → 자원 회수 → 탈출 방어" % [
		roundi(float(map_data.get(&"target_seconds", 600.0)) / 60.0),
		int(map_data.get(&"minimum_rooms", 0)), int(map_data.get(&"maximum_rooms", 0)),
		int(spawn_data.get(&"minimum_enemies", 0)), int(spawn_data.get(&"maximum_enemies", 0)),
	]
	reward_summary.text = "투입 %d C  ·  회수 ×%.2f  ·  고등급 ×%.2f  ·  %s" % [
		int(quote.get(&"entry_cost", 0)), float(quote.get(&"reward_multiplier", 1.0)),
		float(quote.get(&"high_grade_drop_multiplier", 1.0)),
		"보스 출현 확정" if bool(quote.get(&"boss_spawn_guaranteed", false)) else "일반 보스 확률",
	]
	var enemy: Dictionary = quote.get(&"enemy_modifiers", {})
	risk_summary.text = "위험 보정  HP ×%.2f · 공격 ×%.2f · 방어 ×%.2f · 이동 ×%.2f\n페널티  %s" % [
		float(enemy.get(&"health_multiplier", 1.0)), float(enemy.get(&"damage_multiplier", 1.0)),
		float(enemy.get(&"armor_multiplier", 1.0)), float(enemy.get(&"speed_multiplier", 1.0)),
		"없음" if penalty_names.is_empty() else ", ".join(penalty_names),
	]
	selection_summary.text = "현재 계약  %s · %s · %s  |  소모품 %s" % [
		region_name, difficulty_name, tier_name, String(payload.get(&"loadout", "비어 있음")),
	]
	launch_button.text = "작전 투입  ·  %d C" % int(quote.get(&"entry_cost", 0))
	launch_button.disabled = not bool(payload.get(&"can_launch", true))
	for id in tier_buttons:
		_style_tier_button(tier_buttons[id], id == tier_id)
	if preview != null:
		preview.call(&"update_context", region_id, tier_id, difficulty_id)


func get_snapshot() -> Dictionary:
	var panel_rect := root_panel.get_global_rect() if root_panel != null else Rect2()
	var launch_rect := launch_button.get_global_rect() if launch_button != null else Rect2()
	return {
		&"installed": launch_button != null,
		&"launch_visible": launch_button != null and launch_button.is_visible_in_tree(),
		&"layout_fits": (
			root_panel != null
			and launch_button != null
			and panel_rect.encloses(launch_rect)
			and left_column.size.x >= 500.0
			and right_column.size.x >= 500.0
		),
		&"panel_size": root_panel.size if root_panel != null else Vector2.ZERO,
		&"mission_title": mission_title.text if mission_title != null else "",
		&"selection_summary": selection_summary.text if selection_summary != null else "",
		&"selected_tiers": tier_buttons.keys().filter(
			func(id): return bool((tier_buttons[id] as Button).get_meta(&"selected", false))
		),
	}


func _style_tier_button(button: Button, selected: bool) -> void:
	button.set_meta(&"selected", selected)
	button.add_theme_stylebox_override("normal", _style_box(
		Color("123e38") if selected else Color("111b22"),
		Color("38dfbf") if selected else Color("324852"), 4, 2 if selected else 1
	))
	button.add_theme_color_override("font_color", Color("baffef") if selected else Color("c2ced1"))


func _tier_id_from_button(button: Node) -> StringName:
	return {
		"SmallMapButton": &"small", "MediumMapButton": &"medium", "LargeMapButton": &"large",
	}.get(button.name, &"")


func _move(node: Control, parent: Control) -> void:
	node.reparent(parent)


func _label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _section_title(text_value: String) -> Label:
	var label := _label("▌ %s" % text_value, 14, Color("e6f5f5"))
	label.custom_minimum_size.y = 24.0
	return label


func _margin_container(left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_bottom", bottom)
	return margin


func _style_box(background: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	return box
