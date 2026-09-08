class_name OperationTutorialOverlay
extends Control

signal tutorial_shown
signal tutorial_dismissed

const STEP_TITLES := ["이동과 회피", "전투와 자원", "방 확보", "탈출"]

@export var maximum_panel_width := 338.0
@export var edge_margin := 10.0

@onready var panel: PanelContainer = $Panel

@onready var step_label: Label = %StepLabel
@onready var title_label: Label = %TitleLabel
@onready var body_label: Label = %BodyLabel
@onready var previous_button: Button = %PreviousButton
@onready var next_button: Button = %NextButton
@onready var dismiss_button: Button = %DismissButton

var current_step: int = 0
var shown_this_session := false
var bindings: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	previous_button.pressed.connect(previous_step)
	next_button.pressed.connect(next_step)
	dismiss_button.pressed.connect(dismiss)
	resized.connect(_layout_panel)
	panel.minimum_size_changed.connect(_queue_height_fit)
	visible = false
	_layout_panel()


func configure(binding_labels: Dictionary = {}) -> bool:
	bindings = binding_labels.duplicate(true)
	_refresh()
	return true


func show_first_operation() -> bool:
	if shown_this_session:
		return false
	shown_this_session = true
	current_step = 0
	visible = true
	_refresh()
	tutorial_shown.emit()
	return true


func previous_step() -> void:
	current_step = maxi(0, current_step - 1)
	_refresh()


func next_step() -> void:
	if current_step >= STEP_TITLES.size() - 1:
		dismiss()
		return
	current_step += 1
	_refresh()


func dismiss() -> void:
	if not visible:
		return
	visible = false
	tutorial_dismissed.emit()


func get_snapshot() -> Dictionary:
	var panel_rect := panel.get_global_rect()
	var viewport_rect := Rect2(global_position, size)
	var controls_fit := true
	var button_rects: Array[Rect2] = []
	for button in [previous_button, next_button, dismiss_button]:
		var rect: Rect2 = button.get_global_rect()
		controls_fit = controls_fit and panel_rect.encloses(rect) and viewport_rect.encloses(rect)
		for other in button_rects:
			controls_fit = controls_fit and not rect.intersects(other)
		button_rects.append(rect)
	return {
		&"visible": visible,
		&"shown_this_session": shown_this_session,
		&"step_index": current_step,
		&"step_count": STEP_TITLES.size(),
		&"title": title_label.text if is_instance_valid(title_label) else "",
		&"body": body_label.text,
		&"panel_rect": panel_rect,
		&"panel_inside_viewport": viewport_rect.encloses(panel_rect),
		&"buttons_accessible": controls_fit,
		&"body_inside_panel": panel_rect.encloses(body_label.get_global_rect()),
		&"panel_area_ratio": panel_rect.get_area() / maxf(1.0, size.x * size.y),
		&"non_blocking": mouse_filter == Control.MOUSE_FILTER_IGNORE and not get_tree().paused,
		&"touch_target_height": (
			minf(previous_button.custom_minimum_size.y, next_button.custom_minimum_size.y)
			if is_instance_valid(previous_button) and is_instance_valid(next_button) else 0.0
		),
	}


func _layout_panel() -> void:
	if not is_instance_valid(panel):
		return
	# A single corner anchor prevents adding the viewport width to the panel.
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(edge_margin, edge_margin + float(bindings.get(&"top_clearance", 0.0)))
	panel.size = Vector2(minf(maximum_panel_width, maxf(1.0, size.x - edge_margin * 2.0)), 0.0)
	_queue_height_fit()


func _queue_height_fit() -> void:
	_fit_panel_height.call_deferred()


func _fit_panel_height() -> void:
	if is_instance_valid(panel):
		panel.size.y = panel.get_combined_minimum_size().y


func _refresh() -> void:
	if not is_instance_valid(step_label):
		return
	var move_keys := String(bindings.get(&"move", "WASD"))
	var dash_key := String(bindings.get(&"dash", "Space"))
	var attack_key := String(bindings.get(&"attack", "마우스 1"))
	var interact_key := String(bindings.get(&"interact", "F"))
	var map_key := String(bindings.get(&"map", "M"))
	var skill_keys := String(bindings.get(&"skills", "1/2/3"))
	var bodies := [
		"%s 이동 · %s 대시\n점멸은 별도 스킬이며 경로의 적에게 피해를 줍니다." % [move_keys, dash_key],
		"%s 기본기 · %s 스킬\n하단 에너지와 재사용 시간을 확인하세요." % [attack_key, skill_keys],
		"일반 시설은 적을 피해 후퇴할 수 있습니다.\n금고 단말에서 %s를 누르면 봉쇄 전투·추가 보상." % interact_key,
		"시간·전체 클리어 대기 없이 탈출 가능합니다.\n%s 지도에서 두 출구 확인 → 현장에서 %s로 방어 시작." % [map_key, interact_key],
	]
	step_label.text = "%d/%d" % [current_step + 1, STEP_TITLES.size()]
	title_label.text = STEP_TITLES[current_step]
	body_label.text = bodies[current_step]
	previous_button.disabled = current_step == 0
	next_button.text = "완료" if current_step == STEP_TITLES.size() - 1 else "→"
	next_button.tooltip_text = "안내 완료" if current_step == STEP_TITLES.size() - 1 else "다음 안내"
	_layout_panel()
