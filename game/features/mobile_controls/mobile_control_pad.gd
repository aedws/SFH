class_name MobileControlPad
extends Control

## 터치 입력을 기존 InputMap Action으로 변환하는 선택형 브라우저/모바일 키패드입니다.
## 게임 규칙과 키보드 바인딩을 알지 못하며 semantic Action만 누르고 뗍니다.

const ACCENT := Color("02e5e1")
const Joystick := preload("res://game/features/mobile_controls/virtual_joystick.gd")
const ViewportPolicy := preload("res://game/features/mobile_controls/mobile_viewport_policy.gd")
@export var adapt_viewport := true
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
var emitted_actions: Dictionary = {}
var touchscreen_override: Variant = null
var movement_group: Control
var combat_group: Control
var menu_group: Control
var context_enabled := true
var joystick: Control
var touch_actions: Dictionary = {}
var skill_provider: Node
var movement_provider: Node
var energy_label: Label
var refresh_elapsed := 0.0
var original_mouse_emulation := true
var focus_available := true
var original_scale_size := Vector2i.ZERO
var managed_mobile_scale := false
var layout_policy := preload("res://game/features/mobile_controls/mobile_pad_layout.gd").new()
var effective_ui_scale := 1.0
var landscape_requested := false
const OrientationPolicy := preload("res://game/features/mobile_controls/mobile_orientation_policy.gd")
var gui_bridge := preload("res://game/features/mobile_controls/touch_gui_bridge.gd").new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()
	resized.connect(_apply_layout)
	visibility_changed.connect(_on_visibility_changed)
	get_window().size_changed.connect(func(): _resize_viewport.call_deferred())
	original_mouse_emulation = Input.emulate_mouse_from_touch
	original_scale_size = Vector2i(1280, 720) if get_window().has_meta(&"sfh_control_entry") else get_window().content_scale_size
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
	_resize_viewport()
	return true


func simulate_action(action_id: StringName, pressed: bool) -> bool:
	if not action_buttons.has(action_id):
		return false
	_set_action_pressed(action_id, pressed)
	return true


func release_all() -> void:
	if is_inside_tree():
		gui_bridge.release(get_viewport(), true)
	if joystick != null:
		joystick.release()
	touch_actions.clear()
	for action_id: StringName in pressed_actions.keys():
		_send_action(action_id, false)
		(action_buttons[action_id] as Button).set_pressed_no_signal(false)
	pressed_actions.clear()
	emitted_actions.clear()


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
		&"effective_ui_scale": effective_ui_scale,
		&"preferred_orientation": &"landscape",
		&"portrait_fallback": OrientationPolicy.is_portrait(size),
		&"joystick_direction": joystick.direction,
		&"touch_count": touch_actions.size() + int(joystick.finger >= 0),
		&"viewport_coverage_ratio": _viewport_coverage_ratio(),
	}


func _exit_tree() -> void:
	release_all()
	Input.emulate_mouse_from_touch = original_mouse_emulation


func configure_runtime(skills: Node, movement: Node) -> bool:
	if skills != null and not skills.has_method(&"get_skill_states"):
		return false
	if movement != null and not movement.has_method(&"get_movement_snapshot"):
		return false
	skill_provider = skills
	movement_provider = movement
	_refresh_status()
	return true


func _process(delta: float) -> void:
	# 모달이 Game의 컨텍스트 신호보다 먼저 일시정지하더라도 입력을 즉시 해제합니다.
	var allowed := focus_available and not get_tree().paused
	var show_mobile := settings_provider != null and bool(settings_provider.call(&"should_show_mobile_controls", _touchscreen_available()))
	var desired := allowed and context_enabled and show_mobile
	if visible != desired:
		visible = desired
	if not visible:
		return
	refresh_elapsed += delta
	if refresh_elapsed >= 0.1:
		refresh_elapsed = 0
		_refresh_status()


func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT]:
		focus_available = false
		release_all()
	elif what in [NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_WM_WINDOW_FOCUS_IN]:
		focus_available = true


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or get_tree().paused:
		return
	if event is InputEventScreenTouch:
		if event.pressed and not event.canceled:
			if joystick.begin(event.index, event.position):
				get_viewport().set_input_as_handled()
				return
			for action_id in action_buttons:
				var button := action_buttons[action_id] as Button
				if button.is_visible_in_tree() and button.get_global_rect().has_point(event.position):
					touch_actions[event.index] = action_id
					get_viewport().set_input_as_handled()
					_set_action_pressed(action_id, true)
					return
			gui_bridge.handle(event, get_viewport())
			get_viewport().set_input_as_handled()
		else:
			if event.index == joystick.finger:
				joystick.release(event.index)
				get_viewport().set_input_as_handled()
			if touch_actions.has(event.index):
				var action: StringName = touch_actions[event.index]
				touch_actions.erase(event.index)
				if not touch_actions.values().has(action):
					_set_action_pressed(action, false)
				get_viewport().set_input_as_handled()
			gui_bridge.handle(event, get_viewport())
	elif event is InputEventScreenDrag:
		if event.index == joystick.finger:
			joystick.drag(event.index, event.position)
			get_viewport().set_input_as_handled()
		elif touch_actions.has(event.index):
			get_viewport().set_input_as_handled()
		else:
			gui_bridge.handle(event, get_viewport())
			get_viewport().set_input_as_handled()


func _on_direction_changed(direction: Vector2) -> void:
	var values := {&"move_left": maxf(0, -direction.x), &"move_right": maxf(0, direction.x), &"move_up": maxf(0, -direction.y), &"move_down": maxf(0, direction.y)}
	for action: StringName in values:
		var strength: float = values[action]
		if strength > 0:
			pressed_actions[action] = true
			Input.action_press(action, strength)
		elif pressed_actions.erase(action):
			Input.action_release(action)


func _refresh_status() -> void:
	var states: Array = skill_provider.call(&"get_skill_states") if is_instance_valid(skill_provider) else []
	energy_label.text = "EN --"
	for index in range(3):
		var button := action_buttons[StringName("combat_skill_%d" % (index + 1))] as Button
		button.text = "%d\n--" % (index + 1)
		if index >= states.size():
			continue
		var state: Dictionary = states[index]
		var remaining := float(state.get(&"cooldown_remaining", 0))
		var label := "READY" if bool(state.get(&"ready", false)) else ("%.1fs" % remaining if remaining > 0 else "WAIT")
		if remaining <= 0 and not bool(state.get(&"resource_ready", true)):
			var recovery := float(state.get(&"charge_recovery_remaining", 0))
			label = "%.1fs" % recovery if int(state.get(&"current_charges", -1)) == 0 else "EN 부족"
		if not bool(state.get(&"weapon_tags_ready", true)):
			label = "LOCK"
		button.text = "%s\n%s" % [String(state.get(&"display_name", str(index + 1))).left(4), label]
		button.tooltip_text = "스킬 %d · %s · EN %d · 충전 %d/%d" % [index + 1, state.get(&"display_name", ""), state.get(&"energy_cost", 0), state.get(&"current_charges", 0), state.get(&"maximum_charges", 0)]
		energy_label.text = "EN %d / %d" % [state.get(&"energy_current", 0), state.get(&"energy_maximum", 0)]
	if OrientationPolicy.is_portrait(size):
		energy_label.text = "가로 권장 · " + energy_label.text
	energy_label.tooltip_text = OrientationPolicy.guidance(size)
	var dash := action_buttons[&"dash"] as Button
	dash.text = "대시"
	if is_instance_valid(movement_provider):
		var movement: Dictionary = movement_provider.call(&"get_movement_snapshot")
		if not bool(movement.get(&"dash_ready", true)):
			dash.text = "%.1fs" % float(movement.get(&"dash_cooldown_remaining", 0))


func _resize_viewport() -> void:
	if not adapt_viewport or settings_provider == null:
		return
	var mobile := bool(settings_provider.call(&"should_show_mobile_controls", _touchscreen_available()))
	if mobile != landscape_requested:
		landscape_requested = mobile
		if mobile:
			OrientationPolicy.request_landscape()
		else:
			OrientationPolicy.release_lock()
	# 기존 PC/테스트 호스트의 해상도 정책에는 관여하지 않습니다.
	if not mobile and not managed_mobile_scale:
		return
	var target := ViewportPolicy.logical_size(get_window().size, true) if mobile else original_scale_size
	managed_mobile_scale = mobile
	if get_window().content_scale_size != target:
		release_all()
		get_window().content_scale_size = target


func _on_visibility_changed() -> void:
	if not visible:
		release_all()
	# 월드에서는 첫 터치가 마우스 공격으로 중복 변환되지 않게 합니다.
	# 모달에서는 Godot 기본 터치→GUI 클릭 변환을 복구합니다.
	Input.emulate_mouse_from_touch = false if visible else original_mouse_emulation


func _build_ui() -> void:
	movement_group = Control.new()
	movement_group.name = "MovementPad"
	movement_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(movement_group)
	joystick = Joystick.new()
	joystick.tooltip_text = "이동 조이스틱 · 손가락을 드래그하여 방향과 속도 조절"
	joystick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick.direction_changed.connect(_on_direction_changed)
	movement_group.add_child(joystick)
	combat_group = Control.new()
	combat_group.name = "CombatPad"
	combat_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(combat_group)
	energy_label = Label.new()
	energy_label.add_theme_font_size_override("font_size", 14)
	energy_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	combat_group.add_child(energy_label)
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
			button.hide()
		elif action_id in [&"primary_attack", &"dash", &"combat_skill_1", &"combat_skill_2", &"combat_skill_3", &"interact"]:
			combat_group.add_child(button)
		else:
			(menu_group as HBoxContainer).add_child(button)


func _apply_layout() -> void:
	if movement_group == null:
		return
	release_all()
	var settings: Dictionary = settings_provider.call(&"get_snapshot") if is_instance_valid(settings_provider) else {}
	var layout: Dictionary = layout_policy.calculate(size, float(settings.get(&"mobile_ui_scale", 1.25)))
	var button_size: float = layout.button_size
	var gap: float = layout.button_gap
	var energy_height: float = layout.energy_height
	effective_ui_scale = layout.effective_scale
	movement_group.size = layout.movement_rect.size
	movement_group.position = layout.movement_rect.position
	joystick.size = movement_group.size
	joystick.queue_redraw()
	combat_group.size = layout.combat_rect.size
	combat_group.position = layout.combat_rect.position
	energy_label.position = Vector2.ZERO
	energy_label.add_theme_font_size_override("font_size", roundi(16 * effective_ui_scale))
	for child: Control in combat_group.get_children():
		if child is Button:
			child.add_theme_font_size_override("font_size", roundi(14 * effective_ui_scale))
			child.modulate.a = 0.84
	for index in range(3):
		_place_combat_button(StringName("combat_skill_%d" % (index + 1)), index * (button_size + gap), energy_height, button_size)
	_place_combat_button(&"dash", 0, button_size + gap + energy_height, button_size)
	_place_combat_button(&"primary_attack", button_size + gap, button_size + gap + energy_height, button_size)
	_place_combat_button(&"interact", (button_size + gap) * 2, button_size + gap + energy_height, button_size)
	action_buttons[&"primary_attack"].text = "공격"
	action_buttons[&"interact"].text = "사용"
	var menu_width := minf(388.0, size.x - 36.0)
	menu_group.position = Vector2((size.x - menu_width) * 0.5, 8)
	menu_group.size = Vector2(menu_width, 44)
	for child in menu_group.get_children():
		(child as Button).add_theme_font_size_override("font_size", 15)
		(child as Button).modulate.a = 0.84
		(child as Button).custom_minimum_size = Vector2(44, 44)
		(child as Button).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_buttons[&"toggle_key_mapping"].text = "설정"
	for entry in [[&"switch_weapon", "무기"], [&"toggle_map", "지도"], [&"toggle_inventory", "가방"], [&"toggle_equipment", "장비"], [&"toggle_modification", "모듈"]]:
		action_buttons[entry[0]].text = entry[1]


func _viewport_coverage_ratio() -> float:
	if size.x <= 0.0 or size.y <= 0.0:
		return 0.0
	var occupied := 0.0
	for group in [movement_group, combat_group, menu_group]:
		if group != null:
			var rect: Rect2 = group.get_global_rect()
			occupied += rect.size.x * rect.size.y
	return occupied / (size.x * size.y)


func _place_button(action_id: StringName, x: float, y: float, button_size: float) -> void:
	var button := action_buttons[action_id] as Button
	button.position = Vector2(x, y)
	button.size = Vector2(button_size, button_size)


func _place_combat_button(action_id: StringName, x: float, y: float, button_size: float) -> void:
	_place_button(action_id, x, y, button_size)


func _set_action_pressed(action_id: StringName, pressed: bool) -> void:
	if pressed and (not is_visible_in_tree() or get_tree().paused):
		return
	if pressed == pressed_actions.has(action_id):
		return
	if pressed:
		pressed_actions[action_id] = true
	else:
		pressed_actions.erase(action_id)
	(action_buttons[action_id] as Button).set_pressed_no_signal(pressed)
	_send_action(action_id, pressed)


func _send_action(action_id: StringName, pressed: bool) -> void:
	# action_press만 사용하면 _unhandled_input 기반 가방/지도/설정이 열리지 않습니다.
	var resolved: StringName = emitted_actions.get(action_id, action_id)
	if pressed:
		# 화면 슬롯은 현재 스킬을 뜻합니다. K에서 Action을 옮겨도 동일한 스킬을 누릅니다.
		if String(action_id).begins_with("combat_skill_") and is_instance_valid(skill_provider):
			var index := int(String(action_id).trim_prefix("combat_skill_")) - 1
			var states: Array = skill_provider.call(&"get_skill_states")
			if index >= 0 and index < states.size():
				resolved = StringName(states[index].get(&"input_action", action_id))
		emitted_actions[action_id] = resolved
	else:
		emitted_actions.erase(action_id)
	var event := InputEventAction.new()
	event.action = resolved
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _on_settings_changed(_snapshot: Dictionary) -> void:
	_refresh_visibility()
	_resize_viewport()
	_apply_layout()


func _refresh_visibility() -> void:
	var should_show := (
		bool(settings_provider.call(&"should_show_mobile_controls", _touchscreen_available()))
		if settings_provider != null else false
	)
	if visible and (not should_show or not context_enabled):
		release_all()
	visible = should_show and context_enabled and not get_tree().paused and focus_available


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
