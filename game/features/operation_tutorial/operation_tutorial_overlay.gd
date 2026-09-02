class_name OperationTutorialOverlay
extends Control

signal tutorial_shown
signal tutorial_dismissed

const STEP_TITLES := ["이동과 회피", "전투와 자원", "방 확보", "탈출"]

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
	visible = false


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
	return {
		&"visible": visible,
		&"shown_this_session": shown_this_session,
		&"step_index": current_step,
		&"step_count": STEP_TITLES.size(),
		&"title": title_label.text if is_instance_valid(title_label) else "",
		&"non_blocking": true,
		&"touch_target_height": (
			minf(previous_button.custom_minimum_size.y, next_button.custom_minimum_size.y)
			if is_instance_valid(previous_button) and is_instance_valid(next_button) else 0.0
		),
	}


func _refresh() -> void:
	if not is_instance_valid(step_label):
		return
	var move_keys := String(bindings.get(&"move", "WASD"))
	var dash_key := String(bindings.get(&"dash", "Space"))
	var attack_key := String(bindings.get(&"attack", "마우스 1"))
	var interact_key := String(bindings.get(&"interact", "F"))
	var map_key := String(bindings.get(&"map", "M"))
	var bodies := [
		"%s로 이동하고 %s로 점멸합니다. 점멸 경로는 적에게 피해를 줍니다." % [move_keys, dash_key],
		"%s 기본기와 1·2·3 스킬을 사용합니다. 하단 에너지와 쿨타임을 먼저 확인하세요." % attack_key,
		"방에 진입하면 문이 봉쇄되고 적 무리가 생성됩니다. 모두 처치한 뒤 %s로 보상 상자를 회수하세요." % interact_key,
		"모든 전투 방을 확보하면 조기 탈출할 수 있습니다. %s 전술 지도에서 출구를 확인하고 탈출 지점에서 %s를 누르세요." % [map_key, interact_key],
	]
	step_label.text = "FIELD GUIDE  %d / %d" % [current_step + 1, STEP_TITLES.size()]
	title_label.text = STEP_TITLES[current_step]
	body_label.text = bodies[current_step]
	previous_button.disabled = current_step == 0
	next_button.text = "완료" if current_step == STEP_TITLES.size() - 1 else "다음 →"
