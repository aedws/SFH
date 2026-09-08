class_name MobileTutorialPopup
extends Control

## 조작 안내와 확인만 담당합니다. 표시 이력·Scene 전환은 호출자가 소유합니다.
signal acknowledged
signal scale_requested(value: float)
var confirm_button: Button
var scale_buttons: Array[Button] = []
var error_label: Label
var panel: PanelContainer
var body: VBoxContainer
var orientation_button: Button

func _ready() -> void:
	z_index = 100
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color("020b10f5")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("062026")
	style.border_color = Color("02e5e1")
	style.set_border_width_all(2)
	style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	scroll.add_child(body)
	var ui = preload("res://game/features/presentation_theme/game_ui.gd")
	ui.header(body, "터치 전투 준비", "처음 한 번만 안내합니다 · 가로로 돌려주세요", "move")
	orientation_button = Button.new()
	orientation_button.text = "전체화면 · 가로 전환 요청"
	orientation_button.custom_minimum_size.y = 48
	orientation_button.add_theme_font_size_override("font_size", 18)
	orientation_button.pressed.connect(func(): preload("res://game/features/mobile_controls/mobile_orientation_policy.gd").request_landscape(true))
	body.add_child(orientation_button)
	ui.header(body, "01  왼손은 이동", "좌하단 조이스틱 · 손을 떼면 정지", "move")
	ui.header(body, "02  오른손은 전투", "우하단 공격을 누른 채 이동 · 스킬은 에너지와 대기시간 확인", "skill")
	ui.header(body, "03  준비되면 출격", "상단 가방에서 장비 준비 → 동쪽 게이트에서 사용", "gear")
	_text("버튼·글자 크기 선택", 20, Color("02e5e1"))
	var sizes := HBoxContainer.new()
	sizes.add_theme_constant_override("separation", 8)
	body.add_child(sizes)
	for value in [1.0, 1.25, 1.5]:
		var button := Button.new()
		button.text = "%d%%" % roundi(value * 100)
		button.custom_minimum_size = Vector2(0, 52)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 20)
		button.toggle_mode = true
		button.pressed.connect(func(): scale_requested.emit(value))
		sizes.add_child(button)
		scale_buttons.append(button)
	_text("기본 125% · 설정 → HUD·모바일에서 다시 변경할 수 있습니다. 좁은 화면은 안전하게 맞춥니다.", 18)
	error_label = Label.new()
	error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	error_label.add_theme_color_override("font_color", Color("ffce85"))
	column.add_child(error_label)
	confirm_button = Button.new()
	confirm_button.text = "확인하고 로비로 이동"
	confirm_button.custom_minimum_size.y = 56
	ui.action(confirm_button, "move", true)
	confirm_button.add_theme_font_size_override("font_size", 22)
	confirm_button.pressed.connect(func(): acknowledged.emit())
	column.add_child(confirm_button)
	resized.connect(_layout)
	_layout()
	confirm_button.grab_focus()

func _text(value: String, font_size: int, color := Color("e5f6f7")) -> void:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	body.add_child(label)

func set_scale_value(value: float) -> void:
	for index in scale_buttons.size():
		scale_buttons[index].set_pressed_no_signal(is_equal_approx(value, [1.0, 1.25, 1.5][index]))

func show_error(message: String) -> void:
	error_label.text = message

func _layout() -> void:
	if panel == null: return
	orientation_button.visible = size.y > size.x
	panel.size = Vector2(minf(620, size.x - 32), minf(700, size.y - 32))
	panel.position = (size - panel.size) * 0.5
