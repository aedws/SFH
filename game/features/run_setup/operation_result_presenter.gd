class_name OperationResultPresenter
extends RefCounted
## Read-only view: never settles, persists or awards anything.
const ICON := preload("res://game/features/run_setup/tactical_hud_icon.gd")
var host: Control
var panel: PanelContainer
var title_label: Label
var summary_label: Label
var return_button: Button
var details_button: Button
var mission_label: Label
var next_label: Label
var metrics: GridContainer
var rewards: GridContainer
var scroll: ScrollContainer
var payload: Dictionary = {}


func install(overlay: Control, title: Label, summary: Label, action: Button) -> void:
	host = overlay
	title_label = title
	summary_label = summary
	return_button = action
	# Keep the actual controls and their signals, replacing only their layout.
	var previous_layout := title.get_parent().get_parent().get_parent().get_parent()
	panel = PanelContainer.new()
	panel.name = "ResultDashboard"
	host.add_child(panel)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("07151c")
	style.border_color = Color("02e5e1")
	style.set_border_width_all(1)
	style.border_width_top = 3
	style.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	title_label.reparent(column)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mission_label = _label("", 14, Color("93b3bf"))
	column.add_child(mission_label)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	column.add_child(scroll)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	scroll.add_child(body)
	metrics = _grid(body)
	rewards = _grid(body)
	next_label = _label("", 15, Color("c8dce3"))
	body.add_child(next_label)
	details_button = Button.new()
	details_button.text = "정산 상세 펼치기"
	details_button.toggle_mode = true
	details_button.custom_minimum_size.y = 40
	details_button.toggled.connect(_toggle_details)
	body.add_child(details_button)
	summary_label.reparent(body)
	summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_label.add_theme_font_size_override("font_size", 14)
	summary_label.add_theme_color_override("font_color", Color("a6bcc7"))
	summary_label.hide()
	return_button.reparent(column)
	return_button.custom_minimum_size.y = 48
	preload("res://game/features/presentation_theme/game_ui.gd").action(return_button, "move", true)
	previous_layout.queue_free()
	host.resized.connect(_layout)
	_layout()


func render(result: Dictionary, title: String, transcript: String) -> void:
	payload = result.duplicate(true)
	title_label.text = title
	summary_label.text = transcript
	details_button.set_pressed_no_signal(false)
	_toggle_details(false)
	scroll.scroll_vertical = 0
	for grid in [metrics, rewards]:
		for child in grid.get_children():
			grid.remove_child(child)
			child.queue_free()
	var extracted := bool(result.get(&"extracted", false))
	var accent := Color("02e5e1") if extracted else Color("ffab86")
	title_label.add_theme_color_override("font_color", accent)
	if result.is_empty():
		mission_label.text = "통신 복구 필요"
		next_label.text = "재시도해도 실패하면 아래 내용을 확인해 주세요."
		details_button.button_pressed = true
	else:
		mission_label.text = "%s / %s" % ["EXTRACTED" if extracted else "SIGNAL LOST", result.get(&"map_name", "작전 종료")]
		var seconds := maxi(0, int(result.get(&"elapsed_seconds", 0)))
		_metric(metrics, "생존 시간", "%02d:%02d" % [seconds / 60, seconds % 60], ICON.Kind.INPUT, Color("9ac7d4"))
		_metric(metrics, "적 처치", str(result.get(&"kills", 0)), ICON.Kind.KILLS, Color("9ac7d4"))
		_metric(metrics, "보스 처치", str(result.get(&"boss_kills", 0)), ICON.Kind.WEAPON, Color("9ac7d4"))
		_metric(rewards, "작전 정산" if extracted else "분실 크레딧", "%d C" % int(result.get(&"operation_credits", 0)), ICON.Kind.CREDIT, accent)
		var loot: Dictionary = result.get(&"loot", {})
		if bool(loot.get(&"success", false)):
			if extracted:
				_metric(rewards, "전리품 환전", "%d C" % (int(loot.get(&"converted_credits", 0)) + int(loot.get(&"wallet_credits", 0))), ICON.Kind.CREDIT, accent)
				_metric(rewards, "창고 보관", "%d종" % (loot.get(&"warehouse_items", {}) as Dictionary).size(), ICON.Kind.INTERACT, accent)
				_metric(rewards, "영구 해금", "%d종" % (loot.get(&"permanent_unlocks", {}) as Dictionary).size(), ICON.Kind.LEVEL, accent)
			else:
				var lost: Dictionary = loot.get(&"lost_items", {})
				var quantity := 0
				for count in lost.values(): quantity += int(count)
				_metric(rewards, "전리품 소실", "%d개 / %d종" % [quantity, lost.size()], ICON.Kind.INTERACT, accent)
		if extracted:
			_metric(rewards, "회수 고철", str(result.get(&"salvage", 0)), ICON.Kind.ARMOR, accent)
		next_label.text = "회수 완료 · 거점에서 전리품과 다음 작전 장비를 확인하세요." if extracted else "이번 런 획득물과 장착 로드아웃을 잃었습니다. 거점에서 다시 준비하세요."
	_layout()


func _toggle_details(expanded: bool) -> void:
	summary_label.visible = expanded
	details_button.text = "정산 상세 접기" if expanded else "정산 상세 펼치기"


func _layout() -> void:
	if not is_instance_valid(panel): return
	var target := Vector2(minf(900, maxf(0, host.size.x - 24)), minf(660, maxf(0, host.size.y - 24)))
	panel.size = target
	panel.position = (host.size - target) * 0.5
	metrics.columns = 1 if target.x < 480 else 3
	rewards.columns = 1 if target.x < 480 else 3
	title_label.add_theme_font_size_override("font_size", 24 if target.x < 480 else 32)


func get_snapshot() -> Dictionary:
	return {&"payload": payload.duplicate(true), &"details_visible": summary_label.visible,
		&"panel_rect": panel.get_global_rect(), &"return_rect": return_button.get_global_rect(),
		&"reward_count": rewards.get_child_count(), &"columns": rewards.columns}


func _grid(parent: Control) -> GridContainer:
	var grid := GridContainer.new()
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	parent.add_child(grid)
	return grid


func _metric(parent: GridContainer, caption: String, value: String, kind: int, accent: Color) -> void:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("10252d")
	style.border_color = accent.darkened(0.55)
	style.border_width_left = 2
	style.set_content_margin_all(12)
	card.add_theme_stylebox_override("panel", style)
	parent.add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)
	var icon := ICON.new()
	icon.configure(kind, caption, accent)
	icon.custom_minimum_size = Vector2(30, 30)
	row.add_child(icon)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	text.add_child(_label(caption, 13, Color("b0c5cf")))
	text.add_child(_label(value, 24, accent))


func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
