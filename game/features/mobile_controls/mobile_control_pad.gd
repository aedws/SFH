class_name MobileControlPad
extends Control

## 터치 입력을 기존 InputMap Action으로 변환하는 선택형 브라우저/모바일 키패드입니다.
## 게임 규칙과 키보드 바인딩을 알지 못하며 semantic Action만 누르고 뗍니다.

const ACCENT := Color("02e5e1")
const ACTIONS := [
	[&"move_up", "▲", "위로 이동"], [&"move_left", "◀", "왼쪽 이동"],
	[&"move_down", "▼", "아래로 이동"], [&"move_right", "▶", "오른쪽 이동"],
	[&"primary_attack", "ATK", "기본 공격"], [&"dash", "DASH", "대시"],
	[&"combat_skill_1", "1", "스킬 1"], [&"combat_skill_2", "2", "스킬 2"],
	[&"combat_skill_3", "3", "스킬 3"], [&"interact", "F", "상호작용"],
	[&"switch_weapon", "Q", "무기 교체"], [&"toggle_map", "M", "전술 지도"],
	[&"toggle_inventory", "I", "가방"], [&"toggle_equipment", "U", "장비"],
	[&"toggle_modification", "E", "모듈·파츠"],
	[&"toggle_key_mapping", "K", "설정"],
]

var settings_provider: Node
var action_buttons: Dictionary = {}
var pressed_actions: Dictionary = {}
var touchscreen_override: Variant = null
var movement_group: Control
var combat_group: Control
var menu_group: Control
var context_enabled := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()
	resized.connect(_apply_layout)
	_apply_layout()
	visible = false


func configure(new_settings_provider: Node, force_touchscreen: Variant = null) -> bool:
	if (
		new_settings_provider == null
		or not new_settings_provider.has_method(&"should_show_mobile_controls")
		or not new_settings_provider.has_method(&"get_snapshot")
	):
		return false
	settings_provider = new_settings_provider
	touchscreen_override = force_touchscreen
	if settings_provider.has_signal(&"settings_changed"):
		var callback := Callable(self, &"_on_settings_changed")
		if not settings_provider.is_connected(&"settings_changed", callback):
			settings_provider.connect(&"settings_changed", callback)
	_refresh_visibility()
	return true


func simulate_action(action_id: StringName, pressed: bool) -> bool:
	if not action_buttons.has(action_id):
		return false
	_set_action_pressed(action_id, pressed)
	return true


func release_all() -> void:
	for action_id: StringName in pressed_actions.keys():
		Input.action_release(action_id)
	pressed_actions.clear()


func set_context_enabled(enabled: bool) -> void:
	context_enabled = enabled
	_refresh_visibility()


func get_snapshot() -> Dictionary:
	return {
		&"configured": settings_provider != null,
		&"visible": visible,
		&"touchscreen_available": _touchscreen_available(),
		&"action_count": action_buttons.size(),
		&"pressed_actions": pressed_actions.keys(),
		&"movement_rect": movement_group.get_global_rect() if movement_group != null else Rect2(),
		&"combat_rect": combat_group.get_global_rect() if combat_group != null else Rect2(),
		&"menu_rect": menu_group.get_global_rect() if menu_group != null else Rect2(),
		&"semantic_actions": true,
		&"multi_touch_ready": true,
		&"context_enabled": context_enabled,
	}


func _exit_tree() -> void:
	release_all()


func _build_ui() -> void:
	movement_group = Control.new()
	movement_group.name = "MovementPad"
	movement_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(movement_group)
	combat_group = Control.new()
	combat_group.name = "CombatPad"
	combat_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(combat_group)
	menu_group = HBoxContainer.new()
	menu_group.name = "MenuPad"
	menu_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(menu_group as HBoxContainer).add_theme_constant_override("separation", 6)
	add_child(menu_group)
	for entry in ACTIONS:
		var action_id: StringName = entry[0]
		var button := Button.new()
		button.name = String(action_id).to_pascal_case()
		button.text = entry[1]
		button.tooltip_text = entry[2]
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.modulate = Color(1, 1, 1, 0.78)
		button.add_theme_color_override("font_color", Color("d8fbff"))
		button.add_theme_color_override("font_hover_color", Color.WHITE)
		button.add_theme_color_override("font_pressed_color", Color.WHITE)
		button.add_theme_font_size_override("font_size", 12)
		button.add_theme_stylebox_override("normal", _button_style(Color("03141acc"), ACCENT, 1))
		button.add_theme_stylebox_override("pressed", _button_style(Color("027b78e6"), Color.WHITE, 2))
		button.add_theme_stylebox_override("hover", _button_style(Color("07343add"), ACCENT, 1))
		button.button_down.connect(_set_action_pressed.bind(action_id, true))
		button.button_up.connect(_set_action_pressed.bind(action_id, false))
		action_buttons[action_id] = button
		if action_id in [&"move_up", &"move_left", &"move_down", &"move_right"]:
			movement_group.add_child(button)
		elif action_id in [&"primary_attack", &"dash", &"combat_skill_1", &"combat_skill_2", &"combat_skill_3", &"interact"]:
			combat_group.add_child(button)
		else:
			(menu_group as HBoxContainer).add_child(button)


func _apply_layout() -> void:
	if movement_group == null:
		return
	var compact := size.x < 720.0
	var button_size := 54.0 if compact else 62.0
	var gap := 5.0
	movement_group.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	movement_group.position = Vector2(14, -(button_size * 3.0 + gap * 2.0 + 16.0))
	movement_group.size = Vector2(button_size * 3.0 + gap * 2.0, button_size * 3.0 + gap * 2.0)
	_place_button(&"move_up", button_size + gap, 0, button_size)
	_place_button(&"move_left", 0, button_size + gap, button_size)
	_place_button(&"move_down", button_size + gap, button_size + gap, button_size)
	_place_button(&"move_right", (button_size + gap) * 2.0, button_size + gap, button_size)
	combat_group.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	combat_group.position = Vector2(-(button_size * 3.0 + gap * 2.0 + 14.0), -(button_size * 3.0 + gap * 2.0 + 16.0))
	combat_group.size = movement_group.size
	_place_combat_button(&"combat_skill_1", 0, 0, button_size)
	_place_combat_button(&"combat_skill_2", button_size + gap, 0, button_size)
	_place_combat_button(&"combat_skill_3", (button_size + gap) * 2.0, 0, button_size)
	_place_combat_button(&"dash", 0, button_size + gap, button_size)
	_place_combat_button(&"primary_attack", button_size + gap, button_size + gap, button_size)
	_place_combat_button(&"interact", (button_size + gap) * 2.0, button_size + gap, button_size)
	menu_group.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	menu_group.position = Vector2(-minf(430.0, size.x - 24.0), 12)
	menu_group.size = Vector2(minf(418.0, size.x - 24.0), 44)
	for child in menu_group.get_children():
		(child as Button).custom_minimum_size = Vector2(44, 44)


func _place_button(action_id: StringName, x: float, y: float, button_size: float) -> void:
	var button := action_buttons[action_id] as Button
	button.position = Vector2(x, y)
	button.size = Vector2(button_size, button_size)


func _place_combat_button(action_id: StringName, x: float, y: float, button_size: float) -> void:
	_place_button(action_id, x, y, button_size)


func _set_action_pressed(action_id: StringName, pressed: bool) -> void:
	if pressed:
		pressed_actions[action_id] = true
		Input.action_press(action_id)
	else:
		pressed_actions.erase(action_id)
		Input.action_release(action_id)


func _on_settings_changed(_snapshot: Dictionary) -> void:
	_refresh_visibility()


func _refresh_visibility() -> void:
	var should_show := (
		bool(settings_provider.call(&"should_show_mobile_controls", _touchscreen_available()))
		if settings_provider != null else false
	)
	if visible and (not should_show or not context_enabled):
		release_all()
	visible = should_show and context_enabled


func _touchscreen_available() -> bool:
	if touchscreen_override != null:
		return bool(touchscreen_override)
	return DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")


func _button_style(background: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	return style
