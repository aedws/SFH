extends Control

## 앱 시작에서만 실행되는 선택 화면. Game 재조립·작전 설정에는 관여하지 않습니다.
signal mode_selected(mode: StringName)
@export var launch_game := true
@export var settings_path := "user://sfh_presentation_settings.json"
var settings: Node
var card: VBoxContainer
var pc_button: Button
var mobile_button: Button
var status: Label
var choosing := false
const ViewportPolicy := preload("res://game/features/mobile_controls/mobile_viewport_policy.gd")

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var manifest: Resource = load("res://game/core/feature_manifest.tres")
	if launch_game and (not manifest.mobile_controls_enabled or not manifest.presentation_settings_enabled):
		_enter_game()
		return
	if launch_game:
		settings_path = manifest.presentation_settings_storage_path
	settings = load("res://game/features/presentation_settings/presentation_settings_service.tscn").instantiate()
	add_child(settings)
	settings.call(&"configure", settings_path, true)
	var background := ColorRect.new()
	background.color = Color("031116")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	card = VBoxContainer.new()
	card.add_theme_constant_override("separation", 18)
	add_child(card)
	_label("SFH // CONTROL LINK", 24, Color("02e5e1"))
	_label("조작 방식을 선택하세요", 30, Color("e5f6f7"))
	_label("선택 후 로비에서 준비하고 작전 게이트로 이동합니다.", 16, Color("adc5cb"))
	pc_button = _button("PC · 키보드 / 마우스", &"off")
	mobile_button = _button("모바일 · 조이스틱 / 터치", &"on")
	_label("모바일: 왼쪽 이동 · 오른쪽 공격 / 스킬\n설정(K 또는 화면의 설정 버튼)에서 다시 변경할 수 있습니다.", 16, Color("adc5cb"))
	status = _label("", 15, Color("ffce85"))
	resized.connect(_layout)
	if launch_game:
		get_window().size_changed.connect(_resize_viewport)
		_resize_viewport()
	_layout()
	if settings.call(&"get_snapshot").get(&"mobile_controls_mode") == &"on":
		mobile_button.grab_focus()
	else:
		pc_button.grab_focus()

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	card.add_child(label)
	return label

func _button(text: String, mode: StringName) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 68
	button.pressed.connect(select_mode.bind(mode))
	card.add_child(button)
	return button

func _resize_viewport() -> void:
	get_window().content_scale_size = ViewportPolicy.logical_size(get_window().size, true)

func _layout() -> void:
	if card == null:
		return
	card.size.x = minf(560, size.x - 40)
	card.position = Vector2((size.x - card.size.x) * 0.5, maxf(20, (size.y - card.get_combined_minimum_size().y) * 0.5))

func select_mode(mode: StringName) -> void:
	if choosing or mode not in [&"on", &"off"]:
		return
	if not settings.call(&"set_mobile_controls_mode", mode):
		status.text = "조작 설정을 저장하지 못했습니다. 저장 권한을 확인하고 다시 선택해 주세요."
		return
	choosing = true
	mode_selected.emit(mode)
	if launch_game:
		get_window().size_changed.disconnect(_resize_viewport)
		get_window().content_scale_size = ViewportPolicy.logical_size(get_window().size, mode == &"on")
		_enter_game()

func _enter_game() -> void:
	var error := get_tree().change_scene_to_file("res://game/scenes/game.tscn")
	if error != OK:
		choosing = false
		if status != null:
			status.text = "로비를 불러오지 못했습니다. 다시 시도해 주세요. (%s)" % error
