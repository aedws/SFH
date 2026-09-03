class_name CyberpunkOverlay
extends CanvasLayer

## 사이버펑크 표현 계층입니다. 스캔 효과는 입력을 가로채지 않으며,
## 이동하는 스캔 바와 점멸 상태만 매 프레임 갱신합니다.

@onready var screen_fx: CyberpunkScreenFX = $ScreenFX
@onready var sweep_line: ColorRect = $ScreenFX/SweepLine
@onready var pulse_dot: ColorRect = $ScreenFX/Status/Pulse
@onready var status_label: Label = $ScreenFX/Status/Label

var motion_enabled: bool = true
var elapsed: float = 0.0


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	status_label.text = "SYS // LINKED"


func configure(new_motion_enabled: bool, new_noise_enabled: bool) -> bool:
	motion_enabled = new_motion_enabled
	screen_fx.configure(new_noise_enabled)
	sweep_line.visible = motion_enabled
	pulse_dot.modulate.a = 1.0
	set_process(motion_enabled)
	return true


func get_snapshot() -> Dictionary:
	var fx_snapshot := screen_fx.get_snapshot()
	fx_snapshot[&"installed"] = true
	fx_snapshot[&"motion_enabled"] = motion_enabled
	fx_snapshot[&"layer"] = layer
	fx_snapshot[&"status_text"] = status_label.text
	return fx_snapshot


func set_mobile_layout(enabled: bool) -> void:
	# 터치 메뉴 위에 장식 상태 문구를 중첩하지 않습니다.
	status_label.get_parent().visible = not enabled


func _process(delta: float) -> void:
	elapsed += delta
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size.y > 1.0:
		sweep_line.position.y = fmod(elapsed * 22.0, viewport_size.y)
	pulse_dot.modulate.a = 0.42 + 0.58 * (0.5 + 0.5 * sin(elapsed * 4.4))
