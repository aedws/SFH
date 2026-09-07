extends RefCounted
signal honor_requested
signal hub_edit_requested

## 작전 계약 데이터를 계산하지 않고, 기존 설정 Control을 브리핑 중심 화면으로 재배치합니다.

const OPERATION_PREVIEW_SCRIPT := preload("res://game/features/run_setup/operation_preview.gd")
const STEP_FLOW_SCRIPT := preload("res://game/features/run_setup/operation_setup_step_flow.gd")

var launch_button: Button
var mission_title: Label
var mission_code: Label
var mission_intel: Label
var reward_summary: Label
var target_farming_summary: Label
var risk_summary: Label
var selection_summary: Label
var season_summary: Label
var season_history_button: Button
var season_history_dialog: AcceptDialog
var season_history_content: RichTextLabel
var season_honor_button: Button
var character_button: Button
var character_summary: Label
var main_weapon_button: Button
var secondary_weapon_button: Button
var skill_buttons: Array[Button] = []
var loadout_investment_summary: Label
var p5_progression_summary: Label
var preview: Control
var tier_buttons: Dictionary = {}
var selected_tier_detail: Label
var root_panel: PanelContainer
var left_column: Control
var right_column: Control
var step_flow := STEP_FLOW_SCRIPT.new()
var step_pages: Array[Control] = []
var step_heading: Label
var step_progress: HBoxContainer
var previous_button: Button
var next_button: Button
var step_dots: Array[Label] = []
var overlay_root: Control
var main_columns: HBoxContainer
var outer_margin: MarginContainer
var responsive_mode := &"wide"
var equipped_summary: Label
var advanced_details_button: Button
var advanced_details: VBoxContainer


func take_hub_preparation_content() -> Control:
	var controls := VBoxContainer.new()
	controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_theme_constant_override("separation", 8)
	for child in step_pages[1].get_children():
		child.reparent(controls)
	# Weapon editing belongs to the item inventory, never the rental catalog.
	main_weapon_button.get_parent().hide()
	var meta_actions := controls.find_child("MetaActions", true, false) as GridContainer
	if meta_actions != null: meta_actions.columns = 2
	var readiness_title := _label("출격 체크 · 읽기 전용", 13, Color("02e5e1"))
	step_pages[1].add_child(readiness_title)
	equipped_summary = _label("로비 장비 확인 중...", 16, Color("d2fffe"))
	_wrap_label(equipped_summary)
	step_pages[1].add_child(equipped_summary)
	var hint := _label("이 단계는 장비를 바꾸는 화면이 아닙니다. 아래 준비 상태를 확인한 뒤 다음으로 진행하세요.\n무기·방어구·모듈·파츠는 로비 I/U/E에서 저장한 그대로 출격하며 다시 청구하지 않습니다.\n스킬 태그가 맞지 않으면 해당 스킬만 비활성화됩니다.", 13, Color("9fc7cf"))
	_wrap_label(hint)
	step_pages[1].add_child(hint)
	var back := _compact_selection_button("ReturnToHubPreparation")
	back.text = "로비로 돌아가 세팅 변경"
	back.custom_minimum_size.y = 44
	back.pressed.connect(func(): hub_edit_requested.emit())
	step_pages[1].add_child(back)
	return controls


func install(overlay: Control) -> Dictionary:
	if overlay == null:
		return {}
	var content := overlay.get_node_or_null("Center/Panel/Margin/Content") as VBoxContainer
	if content == null:
		return {}
	if content.has_node("MainColumns"):
		return _control_contract()

	var panel := overlay.get_node("Center/Panel") as PanelContainer
	overlay_root = overlay
	root_panel = panel
	panel.custom_minimum_size = Vector2(0.0, 620.0)
	panel.clip_contents = true
	panel.add_theme_stylebox_override("panel", _style_box(Color("030d12f7"), Color("02e5e1"), 2, 2))
	var margin := overlay.get_node("Center/Panel/Margin") as MarginContainer
	outer_margin = margin
	for side in [&"margin_left", &"margin_top", &"margin_right", &"margin_bottom"]:
		margin.add_theme_constant_override(side, 20)
	content.alignment = BoxContainer.ALIGNMENT_BEGIN
	content.add_theme_constant_override("separation", 10)

	var columns := HBoxContainer.new()
	main_columns = columns
	columns.name = "MainColumns"
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 14)
	content.add_child(columns)
	content.move_child(columns, 0)

	var left_panel := PanelContainer.new()
	left_column = left_panel
	left_panel.name = "MissionBriefingPanel"
	left_panel.custom_minimum_size = Vector2(420.0, 0.0)
	left_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_panel.add_theme_stylebox_override("panel", _style_box(Color("06151be6"), Color("087b7a"), 2, 1))
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
	right_panel.add_theme_stylebox_override("panel", _style_box(Color("041116e8"), Color("07615f"), 2, 1))
	columns.add_child(right_panel)
	var right_margin := _margin_container(18, 14, 18, 14)
	right_panel.add_child(right_margin)
	var right := VBoxContainer.new()
	right.name = "ConfigurationContent"
	right.add_theme_constant_override("separation", 7)
	right_margin.add_child(right)
	step_heading = _label("STEP 1 / 3 · 지역·작전", 17, Color("d2fffe"))
	step_heading.custom_minimum_size.y = 30.0
	right.add_child(step_heading)
	step_progress = HBoxContainer.new()
	step_progress.name = "StepProgress"
	step_progress.add_theme_constant_override("separation", 8)
	right.add_child(step_progress)
	for index in STEP_FLOW_SCRIPT.STEP_LABELS.size():
		var dot := _label("%d  %s" % [index + 1, STEP_FLOW_SCRIPT.STEP_LABELS[index]], 11, Color("6d8990"))
		dot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		step_dots.append(dot)
		step_progress.add_child(dot)
	for page_name in ["MissionStep", "LoadoutStep", "ConfirmStep"]:
		var page := VBoxContainer.new()
		page.name = page_name
		page.size_flags_vertical = Control.SIZE_EXPAND_FILL
		page.add_theme_constant_override("separation", 7)
		step_pages.append(page)
		right.add_child(page)
	var mission_step := step_pages[0] as VBoxContainer
	var loadout_step := step_pages[1] as VBoxContainer
	var confirm_step := step_pages[2] as VBoxContainer

	var context := content.get_node("Context") as Label
	var title := content.get_node("Title") as Label
	var subtitle := content.get_node("Subtitle") as Label
	_move(context, left)
	_move(title, left)
	_move(subtitle, left)
	context.text = "OPERATION BRIEF // TACTICAL INSERTION"
	context.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	context.add_theme_color_override("font_color", Color("02e5e1"))
	title.text = "작전 브리핑"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.add_theme_font_size_override("font_size", 28)
	subtitle.text = "투입 조건과 회수 기대값을 확인하고 작전 계약을 확정하세요."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	subtitle.add_theme_font_size_override("font_size", 13)
	for label in [context, title, subtitle]:
		_fit_label(label)

	mission_title = _label("폐허 도시 · 소형 작전", 22, Color("f1f7f8"))
	left.add_child(mission_title)
	mission_code = _label("RAID / STANDARD / RECOVERY", 11, Color("75aeb7"))
	_fit_label(mission_title)
	_fit_label(mission_code)
	left.add_child(mission_code)
	preview = OPERATION_PREVIEW_SCRIPT.new()
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(preview)
	var preview_badge := _label("LIVE TACTICAL PROJECTION  ·  START → EXTRACTION", 11, Color("8ffffc"))
	preview_badge.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	preview_badge.offset_left = 12.0
	preview_badge.offset_top = -30.0
	preview_badge.offset_right = -12.0
	preview_badge.offset_bottom = -8.0
	preview_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	preview.add_child(preview_badge)

	left.add_child(_section_title("작전 정보"))
	mission_intel = _label("탐색 데이터 계산 중...", 13, Color("bed1d5"))
	_wrap_label(mission_intel)
	left.add_child(mission_intel)
	left.add_child(_section_title("예상 회수"))
	reward_summary = _label("회수 계약 계산 중...", 13, Color("ffd579"))
	_wrap_label(reward_summary)
	left.add_child(reward_summary)
	target_farming_summary = _label("타겟 파밍 표 계산 중...", 12, Color("8ffffc"))
	_wrap_label(target_farming_summary)
	left.add_child(target_farming_summary)

	loadout_step.add_child(_section_title("요원 선택"))
	character_button = Button.new()
	character_button.name = "CharacterSelectionButton"
	character_button.custom_minimum_size = Vector2(0.0, 38.0)
	character_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	loadout_step.add_child(character_button)
	character_summary = _label("패시브 데이터 계산 중...", 12, Color("8ffffc"))
	_wrap_label(character_summary)
	loadout_step.add_child(character_summary)
	loadout_step.add_child(_section_title("스킬 설정 · 무기/방어구는 I/U에서 장착"))
	var weapon_row := HBoxContainer.new()
	weapon_row.add_theme_constant_override("separation", 6)
	loadout_step.add_child(weapon_row)
	main_weapon_button = _compact_selection_button("MainWeaponInvestmentButton")
	secondary_weapon_button = _compact_selection_button("SecondaryWeaponInvestmentButton")
	weapon_row.add_child(main_weapon_button)
	weapon_row.add_child(secondary_weapon_button)
	var skill_row := HBoxContainer.new()
	skill_row.add_theme_constant_override("separation", 6)
	loadout_step.add_child(skill_row)
	for index in 3:
		var button := _compact_selection_button("SkillInvestmentButton%d" % index)
		button.set_meta(&"skill_slot_index", index)
		skill_buttons.append(button)
		skill_row.add_child(button)
	loadout_investment_summary = _label("장비 투자 데이터 계산 중...", 11, Color("8ffffc"))
	_wrap_label(loadout_investment_summary)
	loadout_step.add_child(loadout_investment_summary)
	p5_progression_summary = _label("P5 거점 데이터 계산 중...", 11, Color("9fc7cf"))
	_wrap_label(p5_progression_summary)
	loadout_step.add_child(p5_progression_summary)
	mission_step.add_child(_section_title("작전 조건 선택"))
	var contract_section := content.get_node("ContractSection") as VBoxContainer
	var selectors := contract_section.get_node("Selectors") as HBoxContainer
	_move(selectors, mission_step)
	selectors.alignment = BoxContainer.ALIGNMENT_BEGIN
	for button in selectors.get_children():
		if button is Button:
			(button as Button).custom_minimum_size = Vector2(0.0, 36.0)
			(button as Button).size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_fit_button(button as Button)
	var meta_actions := contract_section.get_node("MetaActions") as GridContainer
	loadout_step.add_child(_section_title("거점 준비 도구"))
	_move(meta_actions, loadout_step)
	meta_actions.columns = 3
	for button in meta_actions.get_children():
		if button is Button:
			(button as Button).custom_minimum_size = Vector2(0.0, 30.0)
			(button as Button).size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_fit_button(button as Button)

	var profile := contract_section.get_node("ProfileSummary") as Label
	_move(profile, loadout_step)
	loadout_step.move_child(profile, 0)
	var contract_result := contract_section.get_node("ContractSummary") as Label
	_fit_label(profile)
	_fit_label(contract_result)
	_move(contract_result, confirm_step)
	contract_section.queue_free()

	mission_step.add_child(_section_title("작전 규모"))
	var tiers := content.get_node("TierButtons") as HBoxContainer
	_move(tiers, mission_step)
	tiers.alignment = BoxContainer.ALIGNMENT_BEGIN
	for button in tiers.get_children():
		if button is Button:
			(button as Button).custom_minimum_size = Vector2(0.0, 82.0)
			(button as Button).size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_fit_button(button as Button)
			(button as Button).add_theme_font_size_override("font_size", 14)
			tier_buttons[_tier_id_from_button(button)] = button
	selected_tier_detail = _label("규모를 선택하면 상세 조건이 표시됩니다", 13, Color("a9bdc0"))
	selected_tier_detail.name = "SelectedTierDetail"
	_wrap_label(selected_tier_detail, 280.0)
	mission_step.add_child(selected_tier_detail)

	var balance := content.get_node("BalanceModeSection") as VBoxContainer
	(balance.get_node("Title") as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	(balance.get_node("Buttons") as HBoxContainer).alignment = BoxContainer.ALIGNMENT_BEGIN
	for button in balance.get_node("Buttons").get_children():
		if button is Button:
			(button as Button).custom_minimum_size = Vector2(0.0, 34.0)
			(button as Button).size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_fit_button(button as Button)
	_fit_label(balance.get_node("BalanceModeDescription") as Label)

	risk_summary = _label("위험도 계산 중...", 12, Color("ffbf84"))
	_wrap_label(risk_summary)
	confirm_step.add_child(_section_title("최종 위험·보상"))
	confirm_step.add_child(risk_summary)
	selection_summary = _label("계약 선택 대기", 12, Color("02e5e1"))
	_wrap_label(selection_summary)
	confirm_step.add_child(selection_summary)
	advanced_details_button = Button.new()
	advanced_details_button.name = "AdvancedDetailsButton"
	advanced_details_button.text = "테스트·시즌 세부 정보 펼치기  +"
	advanced_details_button.custom_minimum_size.y = 34.0
	advanced_details_button.tooltip_text = "밸런스 데이터 소스와 조건부 랭킹 기록을 확인합니다. 일반 출격에는 변경이 필요하지 않습니다."
	advanced_details_button.pressed.connect(_toggle_advanced_details)
	confirm_step.add_child(advanced_details_button)
	advanced_details = VBoxContainer.new()
	advanced_details.name = "AdvancedDetails"
	advanced_details.add_theme_constant_override("separation", 5)
	confirm_step.add_child(advanced_details)
	advanced_details.add_child(_section_title("고급 테스트·시즌 정보"))
	_move(balance, advanced_details)
	season_summary = _label("", 11, Color("b6d8dd"))
	season_summary.name = "SeasonSummary"
	_wrap_label(season_summary)
	advanced_details.add_child(season_summary)
	season_history_button = Button.new()
	season_history_button.text = "시즌 기록 · 읽기 전용"
	season_history_button.custom_minimum_size.y = 28
	_fit_button(season_history_button)
	advanced_details.add_child(season_history_button)
	season_honor_button = Button.new()
	season_honor_button.text = "시즌 보상 · 칭호 / 오라"
	_fit_button(season_honor_button)
	season_honor_button.pressed.connect(func(): honor_requested.emit())
	advanced_details.add_child(season_honor_button)
	season_history_dialog = AcceptDialog.new()
	season_history_dialog.title = "시즌 기록 · 로컬 테스트"
	season_history_dialog.dialog_hide_on_ok = true
	season_history_dialog.get_ok_button().text = "닫기"
	overlay.add_child(season_history_dialog)
	season_history_content = RichTextLabel.new()
	season_history_content.bbcode_enabled = false
	season_history_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	season_history_content.offset_left = 12
	season_history_content.offset_top = 12
	season_history_content.offset_right = -12
	season_history_content.offset_bottom = -52
	season_history_dialog.add_child(season_history_content)
	season_history_button.pressed.connect(func(): season_history_dialog.popup_centered(Vector2i(mini(640, int(overlay.size.x) - 32), mini(440, int(overlay.size.y) - 48))))
	_set_advanced_details_visible(false)
	var launch_spacer := Control.new()
	launch_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	confirm_step.add_child(launch_spacer)
	launch_button = Button.new()
	launch_button.name = "OperationLaunchButton"
	launch_button.custom_minimum_size = Vector2(0.0, 52.0)
	launch_button.add_theme_font_size_override("font_size", 18)
	launch_button.add_theme_stylebox_override("normal", _style_box(Color("063332"), Color("02e5e1"), 1, 2))
	launch_button.add_theme_stylebox_override("hover", _style_box(Color("07504f"), Color("8ffffc"), 1, 2))
	launch_button.add_theme_stylebox_override("pressed", _style_box(Color("02e5e1"), Color("c8fffe"), 1, 2))
	confirm_step.add_child(launch_button)

	var navigation := HBoxContainer.new()
	navigation.name = "StepNavigation"
	navigation.add_theme_constant_override("separation", 10)
	right.add_child(navigation)
	previous_button = Button.new()
	previous_button.name = "PreviousStepButton"
	previous_button.text = "← 이전"
	previous_button.custom_minimum_size = Vector2(140.0, 44.0)
	previous_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	previous_button.pressed.connect(step_relative.bind(-1))
	navigation.add_child(previous_button)
	next_button = Button.new()
	next_button.name = "NextStepButton"
	next_button.text = "다음 →"
	next_button.custom_minimum_size = Vector2(140.0, 44.0)
	next_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next_button.pressed.connect(step_relative.bind(1))
	navigation.add_child(next_button)
	step_flow.step_changed.connect(_on_step_changed)
	step_flow.reset()

	var footer := content.get_node("Footer") as Label
	footer.text = "ESC  전초기지 복귀   ·   투입 시 비용과 장착 소모품이 실제 차감됩니다"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_fit_label(footer)
	content.move_child(footer, content.get_child_count() - 1)
	if not overlay.resized.is_connected(_apply_responsive_layout):
		overlay.resized.connect(_apply_responsive_layout)
	_apply_responsive_layout()
	overlay.call_deferred(&"queue_redraw")
	return _control_contract()


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
	var character: Dictionary = payload.get(&"character", {})
	character_button.text = "요원 · %s · 추가 %d C" % [
		String(character.get(&"display_name", "기본 요원")),
		int(character.get(&"entry_cost", 0)),
	]
	character_summary.text = "PASSIVE  %s  ·  %s" % [
		String(character.get(&"passive_name", "없음")),
		String(character.get(&"passive_description", "적용 효과 없음")),
	]
	_update_loadout_investment(payload.get(&"loadout_investment", {}))
	_update_p5_progression(payload.get(&"p5_progression", {}))
	if equipped_summary != null:
		var equipped: Dictionary = payload.get(&"equipped", {})
		equipped_summary.text = "READY · 현재 로비 세팅\n[01] MAIN · %s\n[02] SUB · %s\n[03] 방어구 %d개 · 활성 무기 %s\n[04] 요원 · %s\n[05] 소모품 · %s\n%s" % [
			equipped.get(&"main_weapon_name", "비어 있음"),
			equipped.get(&"secondary_weapon_name", "비어 있음"),
			int(equipped.get(&"armor_count", 0)), equipped.get(&"active_weapon_name", "비어 있음"),
			character.get(&"display_name", "기본 요원"), _consumable_summary(payload),
			loadout_investment_summary.text]
	mission_title.text = "%s  ·  %s" % [region_name, tier_name]
	mission_code.text = "%s / %s / %s" % [String(region_id).to_upper(), String(difficulty_id).to_upper(), String(tier_id).to_upper()]
	mission_intel.text = "목표 %d분  ·  방 %d~%d개  ·  동시 적 %d~%d명\n핵심 루프  침투 → 탐색·교전 → 자원 회수 → 탈출 방어" % [
		roundi(float(map_data.get(&"target_seconds", 600.0)) / 60.0),
		int(map_data.get(&"minimum_rooms", 0)), int(map_data.get(&"maximum_rooms", 0)),
		int(spawn_data.get(&"minimum_enemies", 0)), int(spawn_data.get(&"maximum_enemies", 0)),
	]
	var reward_multiplier := maxf(0.01, float(quote.get(&"reward_multiplier", 1.0)))
	selected_tier_detail.text = "선택 · %s  |  방 %d~%d개\n동시 적 %d~%d명  ·  회수 ×%.2f" % [
		tier_name, int(map_data.get(&"minimum_rooms", 0)), int(map_data.get(&"maximum_rooms", 0)),
		int(spawn_data.get(&"minimum_enemies", 0)), int(spawn_data.get(&"maximum_enemies", 0)), reward_multiplier,
	]
	var break_even := ceili(float(quote.get(&"entry_cost", 0)) / reward_multiplier)
	reward_summary.text = "투입 %d C  ·  BEP %d C  ·  회수 ×%.2f  ·  고등급 ×%.2f  ·  %s" % [
		int(quote.get(&"entry_cost", 0)), break_even, reward_multiplier,
		float(quote.get(&"high_grade_drop_multiplier", 1.0)),
		"보스 출현 확정" if bool(quote.get(&"boss_spawn_guaranteed", false)) else "일반 보스 확률",
	]
	var loot_briefing: Dictionary = payload.get(&"loot_briefing", {})
	var target_labels: PackedStringArray = loot_briefing.get(&"target_item_labels", PackedStringArray())
	target_farming_summary.text = "TARGET LOOT  ·  %s  ·  최고 G%d  ·  후보 %d개" % [
		" / ".join(target_labels) if not target_labels.is_empty() else "드랍 표 없음",
		int(loot_briefing.get(&"highest_grade", 0)),
		int(loot_briefing.get(&"candidate_count", 0)),
	]
	var enemy: Dictionary = quote.get(&"enemy_modifiers", {})
	risk_summary.text = "위험 보정  HP ×%.2f · 공격 ×%.2f · 방어 ×%.2f · 이동 ×%.2f\n페널티  %s" % [
		float(enemy.get(&"health_multiplier", 1.0)), float(enemy.get(&"damage_multiplier", 1.0)),
		float(enemy.get(&"armor_multiplier", 1.0)), float(enemy.get(&"speed_multiplier", 1.0)),
		"없음" if penalty_names.is_empty() else ", ".join(penalty_names),
	]
	selection_summary.text = "현재 계약  %s · %s · %s  |  소모품 %s" % [
		region_name, difficulty_name, tier_name, _consumable_summary(payload),
	]
	season_summary.text = String(payload.get(&"season", {}).get(&"text", ""))
	season_summary.visible = not season_summary.text.is_empty()
	season_history_button.visible = season_summary.visible
	season_honor_button.visible = bool(payload.get(&"season", {}).get(&"honors_available", false))
	season_history_content.text = String(payload.get(&"season", {}).get(&"history_text", ""))
	launch_button.text = "작전 투입  ·  %d C" % int(quote.get(&"entry_cost", 0))
	launch_button.disabled = not bool(payload.get(&"can_launch", true))
	for id in tier_buttons:
		_style_tier_button(tier_buttons[id], id == tier_id)
	if preview != null:
		preview.call(&"update_context", region_id, tier_id, difficulty_id)
	_on_step_changed(step_flow.get_snapshot())


func reset_steps() -> Dictionary:
	return step_flow.reset()


func _consumable_summary(payload: Dictionary) -> String:
	var labels := PackedStringArray()
	var warehouse := String(payload.get(&"loadout", "비어 있음"))
	if warehouse != "비어 있음" and not warehouse.is_empty(): labels.append(warehouse)
	var utility: Dictionary = payload.get(&"p5_progression", {}).get(&"utility", {})
	for item in utility.get(&"investment", {}).get(&"utilities", []):
		if item.get(&"utility_type", &"") == &"bag": continue
		labels.append("%s ×%d" % [item.get(&"display_name", "유틸리티"), int(item.get(&"quantity", 0))])
	return " / ".join(labels) if not labels.is_empty() else "비어 있음"


func step_relative(direction: int) -> Dictionary:
	return step_flow.move(direction)


func show_step(index: int) -> Dictionary:
	return step_flow.go_to(index)


func get_snapshot() -> Dictionary:
	var panel_rect := root_panel.get_global_rect() if root_panel != null else Rect2()
	var launch_rect := launch_button.get_global_rect() if launch_button != null else Rect2()
	var overlay_rect := overlay_root.get_global_rect() if overlay_root != null else Rect2()
	var overflow_nodes := _visible_overflow_nodes()
	return {
		&"installed": launch_button != null,
		&"launch_visible": launch_button != null and launch_button.is_visible_in_tree(),
		&"layout_fits": (
			root_panel != null
			and launch_button != null
			and panel_rect.encloses(launch_rect)
			and overlay_rect.encloses(panel_rect)
			and overflow_nodes.is_empty()
			and (not left_column.visible or left_column.size.x >= 320.0)
			and right_column.size.x >= 280.0
		),
		&"panel_size": root_panel.size if root_panel != null else Vector2.ZERO,
		&"panel_inside_viewport": overlay_rect.encloses(panel_rect),
		&"responsive_mode": responsive_mode,
		&"left_column_visible": left_column.visible if left_column != null else false,
		&"overflow_nodes": overflow_nodes,
		&"largest_minimums": _largest_minimum_sizes(),
		&"mission_title": mission_title.text if mission_title != null else "",
		&"selection_summary": selection_summary.text if selection_summary != null else "",
		&"season_summary": season_summary.text if season_summary != null else "",
		&"season_history_visible": season_history_dialog.visible if season_history_dialog != null else false,
		&"advanced_details_visible": advanced_details.visible if advanced_details != null else false,
		&"target_farming_summary": target_farming_summary.text if target_farming_summary != null else "",
		&"character_summary": character_summary.text if character_summary != null else "",
		&"loadout_investment_summary": (
			loadout_investment_summary.text if loadout_investment_summary != null else ""
		),
		&"p5_progression_summary": p5_progression_summary.text if p5_progression_summary != null else "",
		&"main_weapon_text": main_weapon_button.text if main_weapon_button != null else "",
		&"secondary_weapon_text": secondary_weapon_button.text if secondary_weapon_button != null else "",
		&"skill_button_texts": skill_buttons.map(func(button): return button.text),
		&"selected_tiers": tier_buttons.keys().filter(
			func(id): return bool((tier_buttons[id] as Button).get_meta(&"selected", false))
		),
		&"step_index": int(step_flow.get_snapshot().get(&"step_index", 0)),
		&"step_count": step_pages.size(),
		&"step_id": step_flow.get_snapshot().get(&"step_id", &""),
		&"visible_page_count": step_pages.filter(func(page): return page.visible).size(),
		&"previous_enabled": previous_button != null and not previous_button.disabled,
		&"next_visible": next_button != null and next_button.visible,
		&"launch_on_confirmation": (
			launch_button != null
			and launch_button.is_visible_in_tree()
			and bool(step_flow.get_snapshot().get(&"is_confirmation", false))
		),
		&"navigation_touch_height": (
			minf(previous_button.custom_minimum_size.y, next_button.custom_minimum_size.y)
			if previous_button != null and next_button != null else 0.0
		),
	}


func _toggle_advanced_details() -> void:
	_set_advanced_details_visible(not advanced_details.visible)


func _set_advanced_details_visible(is_visible: bool) -> void:
	if advanced_details == null or advanced_details_button == null:
		return
	advanced_details.visible = is_visible
	advanced_details_button.text = (
		"테스트·시즌 세부 정보 접기  −"
		if is_visible else "테스트·시즌 세부 정보 펼치기  +"
	)


func _update_loadout_investment(snapshot: Dictionary) -> void:
	if main_weapon_button == null:
		return
	main_weapon_button.get_parent().visible = not bool(snapshot.get(&"equipped_weapons_only", false))
	var weapons: Dictionary = snapshot.get(&"weapons", {})
	_update_investment_button(main_weapon_button, "MAIN", weapons.get(&"main", {}))
	_update_investment_button(secondary_weapon_button, "SUB", weapons.get(&"secondary", {}))
	var skills: Array = snapshot.get(&"skills", [])
	for index in skill_buttons.size():
		_update_investment_button(
			skill_buttons[index], "S%d" % (index + 1),
			skills[index] if index < skills.size() else {}
		)
	var errors: PackedStringArray = snapshot.get(&"selection_errors", PackedStringArray())
	loadout_investment_summary.text = "LOADOUT  추가 %d C · %s" % [
		int(snapshot.get(&"additional_entry_cost", 0)),
		"투입 가능" if bool(snapshot.get(&"selection_ready", true)) else " / ".join(errors),
	]
	loadout_investment_summary.add_theme_color_override(
		"font_color", Color("8ffffc") if errors.is_empty() else Color("ff9e80")
	)


func _update_p5_progression(snapshot: Dictionary) -> void:
	if p5_progression_summary == null:
		return
	var utility: Dictionary = snapshot.get(&"utility", {})
	var investment: Dictionary = utility.get(&"investment", {})
	var shop: Dictionary = snapshot.get(&"shop", {})
	var codex: Dictionary = snapshot.get(&"codex", {})
	p5_progression_summary.text = "UTILITY +%d C · SHOP Q%d · CODEX %d/%d" % [
		int(investment.get(&"additional_entry_cost", 0)),
		int(shop.get(&"quality_count", 0)),
		int(codex.get(&"completed_count", 0)), int(codex.get(&"entry_count", 0)),
	]


func _update_investment_button(button: Button, prefix: String, item: Dictionary) -> void:
	var name := String(item.get(&"display_name", "비어 있음"))
	var state := String(item.get(&"state_label", "상태 확인"))
	var price := int(item.get(&"run_investment_price", 0))
	button.text = "%s · %s\n%s%s" % [
		prefix, name, state,
		" %d C" % price if price > 0 and not bool(item.get(&"default_owned", false)) else "",
	]
	button.tooltip_text = "%s · %s" % [state, "임시 기획값" if item.get(&"source_status", &"temporary") == &"temporary" else "기획 확정"]
	button.add_theme_color_override(
		"font_color", Color("ff9e80") if item.get(&"state", &"") == &"locked" else Color("d2fffe")
	)


func _compact_selection_button(node_name: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.custom_minimum_size = Vector2(0.0, 38.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 11)
	_fit_button(button)
	return button


func _apply_responsive_layout() -> void:
	if overlay_root == null or root_panel == null or left_column == null:
		return
	var viewport_size := overlay_root.size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var is_single_column := viewport_size.x < 840.0
	var is_compact := viewport_size.x < 1120.0
	responsive_mode = &"single" if is_single_column else (&"compact" if is_compact else &"wide")
	var edge_gap := 12.0 if is_single_column else (20.0 if is_compact else 32.0)
	root_panel.custom_minimum_size = Vector2(
		maxf(280.0, minf(1160.0, viewport_size.x - edge_gap * 2.0)),
		maxf(520.0, minf(620.0, viewport_size.y - 20.0))
	)
	var content_margin := 10 if is_single_column else (14 if is_compact else 20)
	for side in [&"margin_left", &"margin_top", &"margin_right", &"margin_bottom"]:
		outer_margin.add_theme_constant_override(side, content_margin)
	left_column.visible = not is_single_column
	left_column.custom_minimum_size.x = 340.0 if is_compact else 420.0
	main_columns.add_theme_constant_override("separation", 10 if is_compact else 14)
	root_panel.queue_sort()
	main_columns.queue_sort()


func get_width_contract(viewport_width: float) -> Dictionary:
	var mode := &"single" if viewport_width < 840.0 else (&"compact" if viewport_width < 1120.0 else &"wide")
	var edge_gap := 12.0 if mode == &"single" else (20.0 if mode == &"compact" else 32.0)
	var panel_width := maxf(280.0, minf(1160.0, viewport_width - edge_gap * 2.0))
	return {
		&"mode": mode,
		&"viewport_width": viewport_width,
		&"panel_width": panel_width,
		&"inside_viewport": panel_width <= viewport_width,
		&"left_column_visible": mode != &"single",
		&"minimum_touch_width": 280.0,
	}


func _visible_overflow_nodes() -> PackedStringArray:
	var result := PackedStringArray()
	if root_panel == null:
		return result
	var panel_rect := root_panel.get_global_rect().grow(1.0)
	for node in root_panel.find_children("*", "Control", true, false):
		var control := node as Control
		if control == null or not control.is_visible_in_tree() or control.size.x <= 0.0:
			continue
		if not panel_rect.encloses(control.get_global_rect()):
			result.append(String(root_panel.get_path_to(control)))
	return result


func _largest_minimum_sizes() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if root_panel == null:
		return result
	for node in root_panel.find_children("*", "Control", true, false):
		var control := node as Control
		if control == null or not control.is_visible_in_tree():
			continue
		var minimum := control.get_combined_minimum_size()
		if minimum.y > 100.0 or minimum.x > 500.0:
			result.append({
				&"path": String(root_panel.get_path_to(control)),
				&"minimum": minimum,
				&"size": control.size,
			})
	result.sort_custom(func(a, b): return (a as Dictionary).get(&"minimum", Vector2.ZERO).y > (b as Dictionary).get(&"minimum", Vector2.ZERO).y)
	if result.size() > 12:
		result.resize(12)
	return result


func _fit_label(label: Label) -> void:
	if label == null:
		return
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS


func _fit_button(button: Button) -> void:
	if button == null:
		return
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS


func _wrap_label(label: Label, minimum_width: float = 280.0) -> void:
	if label == null:
		return
	label.custom_minimum_size.x = minimum_width
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _control_contract() -> Dictionary:
	return {
		&"launch_button": launch_button, &"character_button": character_button,
		&"main_weapon_button": main_weapon_button,
		&"secondary_weapon_button": secondary_weapon_button,
		&"skill_buttons": skill_buttons,
		&"previous_step_button": previous_button,
		&"next_step_button": next_button,
	}


func _on_step_changed(snapshot: Dictionary) -> void:
	if step_pages.is_empty():
		return
	var index := int(snapshot.get(&"step_index", 0))
	for page_index in step_pages.size():
		step_pages[page_index].visible = page_index == index
	step_heading.text = "STEP %d / %d · %s" % [
		index + 1, int(snapshot.get(&"step_count", step_pages.size())),
		String(snapshot.get(&"step_label", "작전 설정")),
	]
	previous_button.disabled = not bool(snapshot.get(&"can_go_previous", false))
	next_button.visible = bool(snapshot.get(&"can_go_next", false))
	for dot_index in step_dots.size():
		step_dots[dot_index].add_theme_color_override(
			"font_color", Color("02e5e1") if dot_index == index else Color("6d8990")
		)


func _style_tier_button(button: Button, selected: bool) -> void:
	button.set_meta(&"selected", selected)
	button.add_theme_stylebox_override("normal", _style_box(
		Color("053332") if selected else Color("081419"),
		Color("02e5e1") if selected else Color("21434a"), 1, 2 if selected else 1
	))
	button.add_theme_color_override("font_color", Color("d2fffe") if selected else Color("a9bdc0"))


func present_tier_card(button: Button, data: Dictionary) -> void:
	# The assembly supplies a quote; this presenter owns its compact, touch-readable copy.
	button.text = "%s · %d분\n%d C" % [data.display_name, data.minutes, data.entry_cost]
	button.tooltip_text = "%s · 투입 %d C · 회수 ×%.2f · 방 %d~%d%s" % [
		data.display_name, data.entry_cost, data.reward_multiplier,
		data.minimum_rooms, data.maximum_rooms, data.enemy_range,
	]


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
