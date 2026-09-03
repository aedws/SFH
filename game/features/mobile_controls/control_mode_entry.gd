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
var tutorial: Control
var orientation_hint: Label
var orientation_button: Button
const ViewportPolicy := preload("res://game/features/mobile_controls/mobile_viewport_policy.gd")
const OrientationPolicy := preload("res://game/features/mobile_controls/mobile_orientation_policy.gd")

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
	mobile_button = _button("모바일 · 가로 플레이", &"on")
	orientation_hint = _label("", 16, Color("adc5cb"))
	orientation_button = Button.new()
	orientation_button.text = "전체화면 · 가로 전환 요청"
	orientation_button.custom_minimum_size.y = 44
	orientation_button.add_theme_font_size_override("font_size", 18)
	orientation_button.pressed.connect(func(): OrientationPolicy.request_landscape(true))
	card.add_child(orientation_button)
	status = _label("", 15, Color("ffce85"))
	resized.connect(_layout)
	if launch_game:
		get_window().size_changed.connect(_queue_resize)
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

func _queue_resize() -> void:
	_resize_viewport.call_deferred()

func _layout() -> void:
	if card == null:
		return
	if orientation_hint != null:
		orientation_hint.text = OrientationPolicy.guidance(size)
		orientation_button.visible = OrientationPolicy.is_portrait(size)
	card.size.x = minf(560, size.x - 40)
	card.position = Vector2((size.x - card.size.x) * 0.5, maxf(20, (size.y - card.get_combined_minimum_size().y) * 0.5))

func select_mode(mode: StringName) -> void:
	if choosing or mode not in [&"on", &"off"]:
		return
	if not settings.call(&"set_mobile_controls_mode", mode):
		status.text = "조작 설정을 저장하지 못했습니다. 저장 권한을 확인하고 다시 선택해 주세요."
		return
	choosing = true
	if mode == &"on":
		OrientationPolicy.request_landscape()
	else:
		OrientationPolicy.release_lock()
	if mode == &"on" and not bool(settings.call(&"get_snapshot").get(&"mobile_tutorial_seen", false)):
		card.hide()
		tutorial = preload("res://game/features/mobile_controls/mobile_tutorial_popup.gd").new()
		add_child(tutorial)
		tutorial.set_scale_value(settings.call(&"get_snapshot").mobile_ui_scale)
		tutorial.acknowledged.connect(_acknowledge_tutorial)
		tutorial.scale_requested.connect(_set_tutorial_scale)
		return
	_finish_selection(mode)

func _set_tutorial_scale(value: float) -> void:
	if not settings.call(&"set_mobile_ui_scale", value):
		tutorial.show_error("크기 설정을 저장하지 못했습니다. 다시 선택해 주세요.")
	tutorial.set_scale_value(settings.call(&"get_snapshot").mobile_ui_scale)

func _acknowledge_tutorial() -> void:
	if not settings.call(&"complete_mobile_tutorial"):
		tutorial.show_error("안내 완료를 저장하지 못했습니다. 저장 권한을 확인하고 다시 눌러 주세요.")
		return
	tutorial.hide()
	_finish_selection(&"on")

func _finish_selection(mode: StringName) -> void:
	mode_selected.emit(mode)
	if launch_game:
		get_window().size_changed.disconnect(_queue_resize)
		get_window().set_meta(&"sfh_control_entry", true)
		get_window().content_scale_size = ViewportPolicy.logical_size(get_window().size, mode == &"on")
		_enter_game()

func _enter_game() -> void:
	var error := get_tree().change_scene_to_file("res://game/scenes/game.tscn")
	if error != OK:
		choosing = false
		if status != null:
			status.text = "로비를 불러오지 못했습니다. 다시 시도해 주세요. (%s)" % error
