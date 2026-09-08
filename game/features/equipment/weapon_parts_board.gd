class_name WeaponPartsBoard
extends Control

## 무기 정의의 실제 파츠 소켓과 장착 상태를 코드 기반 도식으로 표시합니다.
## 파츠 장착 판정이나 상태 변경은 수행하지 않습니다.

signal socket_selected(socket_id: StringName)

const SOCKET_LABELS := {
	&"optic": "광학",
	&"muzzle": "총구",
	&"magazine": "탄창",
	&"blade": "칼날",
	&"grip": "손잡이",
}
const ACCENT := Color("02e5e1")

var equipment_state
var selected_socket_id: StringName = &""
var socket_rects: Dictionary = {}
var inventory_card_mode := false
var socket_buttons: Dictionary = {}

func get_socket_label(socket_id: StringName) -> String:
	return String(SOCKET_LABELS.get(socket_id, socket_id))


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	resized.connect(queue_redraw)
	resized.connect(_sync_socket_controls)


func configure(new_state, new_selected_socket_id: StringName = &"") -> void:
	equipment_state = new_state
	selected_socket_id = new_selected_socket_id
	_sync_socket_controls()
	queue_redraw()


func _sync_socket_controls() -> void:
	if not inventory_card_mode:
		return
	for button in socket_buttons.values():
		remove_child(button)
		button.queue_free()
	socket_buttons.clear()
	if equipment_state == null or not equipment_state.is_weapon():
		return
	var sockets: Array[StringName] = equipment_state.definition.part_socket_ids
	var lower_count := sockets.size() - (1 if &"optic" in sockets else 0)
	var per_row := maxi(1, floori((maxf(size.x, 280) - 16) / 58.0))
	custom_minimum_size.y = 174 + maxi(0, ceili(float(lower_count) / per_row) - 1) * 54
	for index in sockets.size():
		var socket := sockets[index]
		var button := Button.new()
		button.name = "Socket_" + String(socket)
		var rect := _socket_rect(socket, index, sockets.size())
		button.position = rect.position
		button.size = rect.size
		button.tooltip_text = "%s · %s\n클릭 / Enter: 호환 파츠 선택·해제" % [SOCKET_LABELS.get(socket, socket), _installed_part_for_socket(socket).display_name if _installed_part_for_socket(socket) != null else "빈 슬롯"]
		for style_name in ["normal", "hover", "pressed", "disabled"]:
			button.add_theme_stylebox_override(style_name, StyleBoxEmpty.new())
		var focus := StyleBoxFlat.new()
		focus.bg_color = Color(ACCENT, 0.12)
		focus.border_color = Color.WHITE
		focus.set_border_width_all(2)
		button.add_theme_stylebox_override("focus", focus)
		button.pressed.connect(func(): socket_selected.emit(socket))
		add_child(button)
		socket_buttons[socket] = button


func get_snapshot() -> Dictionary:
	var weapon_mode: bool = equipment_state != null and equipment_state.is_weapon()
	var definition: Resource = equipment_state.definition if weapon_mode else null
	var installed_count := 0
	if weapon_mode:
		installed_count = equipment_state.installed_parts.size()
	return {
		&"weapon_mode": weapon_mode,
		&"weapon_name": definition.display_name if weapon_mode else "",
		&"minor_tag": definition.tags.minor_tag if weapon_mode else &"",
		&"socket_count": definition.part_socket_ids.size() if weapon_mode else 0,
		&"installed_socket_count": installed_count,
		&"selected_socket_id": selected_socket_id,
		&"board_size": size,
	}


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return
	for socket_id in socket_rects:
		if (socket_rects[socket_id] as Rect2).has_point(mouse_event.position):
			selected_socket_id = socket_id
			queue_redraw()
			socket_selected.emit(socket_id)
			accept_event()
			return


func _draw() -> void:
	socket_rects.clear()
	_draw_background()
	if equipment_state == null or not equipment_state.is_weapon():
		_draw_centered_text("빈 무기 슬롯 · 가방에서 무기를 장착하세요" if inventory_card_mode else "방어구는 고유 파츠를 장착하지 않습니다.", size.y * 0.52, 12)
		return
	var weapon = equipment_state.definition
	var font := get_theme_default_font()
	draw_string(
		font, Vector2(10, 18),
		"G%d  %s" % [weapon.grade, weapon.display_name],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.9, 0.95, 0.97)
	)
	draw_string(
		font, Vector2(size.x - 112, 18), weapon.tags.minor_label,
		HORIZONTAL_ALIGNMENT_RIGHT, 102, 11, ACCENT
	)
	_draw_weapon_schematic(weapon.tags.minor_tag)
	var sockets: Array[StringName] = weapon.part_socket_ids
	for index in sockets.size():
		var socket_id := sockets[index]
		var rect := _socket_rect(socket_id, index, sockets.size())
		socket_rects[socket_id] = rect
		_draw_socket_card(socket_id, rect)


func _draw_background() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.004, 0.018, 0.024, 0.98), true)
	draw_rect(Rect2(Vector2.ZERO, size), Color(ACCENT, 0.52), false, 1.0)
	for x in range(12, int(size.x), 24):
		draw_line(Vector2(x, 26), Vector2(x, size.y - 8), Color(ACCENT, 0.055), 1.0)
	for y in range(28, int(size.y), 8):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(ACCENT, 0.018), 1.0)


func _draw_weapon_schematic(minor_tag: StringName) -> void:
	var center := Vector2(size.x * 0.5, size.y * 0.54)
	if inventory_card_mode:
		center.y = 94
		var scale_factor := minf((size.x - 48.0) / 200.0, 1.8)
		draw_set_transform(center, 0.0, Vector2(scale_factor, scale_factor))
		center = Vector2.ZERO
	var steel := Color(0.28, 0.34, 0.37, 0.9)
	var edge := Color(ACCENT, 0.78)
	if minor_tag == &"pistol":
		draw_rect(Rect2(center + Vector2(-45, -12), Vector2(86, 18)), steel, true)
		draw_polygon(PackedVector2Array([
			center + Vector2(2, 6), center + Vector2(26, 6),
			center + Vector2(17, 37), center + Vector2(-2, 37),
		]), PackedColorArray([steel]))
		draw_line(center + Vector2(-52, -6), center + Vector2(43, -6), edge, 2.0)
		if inventory_card_mode:
			draw_rect(Rect2(center + Vector2(-43, -10), Vector2(76, 7)), Color("9db0b3"))
			for x in range(15, 33, 4):
				draw_line(center + Vector2(x, -10), center + Vector2(x, 3), Color("253b40"), 2)
			draw_circle(center + Vector2(0, 13), 7, Color("8b9e9f"), false, 2)
			for y in range(14, 33, 5):
				draw_line(center + Vector2(7, y), center + Vector2(18, y), Color("253b40"), 2)
	elif minor_tag in [&"dagger", &"greatsword"]:
		var length := 118.0 if minor_tag == &"greatsword" else 82.0
		draw_polygon(PackedVector2Array([
			center + Vector2(-length * 0.5, -8), center + Vector2(length * 0.48, -5),
			center + Vector2(length * 0.58, 0), center + Vector2(length * 0.48, 5),
			center + Vector2(-length * 0.5, 8),
		]), PackedColorArray([steel]))
		draw_line(center + Vector2(-length * 0.56, -17), center + Vector2(-length * 0.56, 17), edge, 4.0)
	else:
		draw_polygon(PackedVector2Array([
			center + Vector2(-62, -13), center + Vector2(45, -13),
			center + Vector2(62, -5), center + Vector2(49, 11),
			center + Vector2(-56, 11), center + Vector2(-70, 2),
		]), PackedColorArray([steel]))
		draw_rect(Rect2(center + Vector2(-101, -6), Vector2(40, 6)), steel, true)
		draw_polygon(PackedVector2Array([
			center + Vector2(0, 11), center + Vector2(24, 11),
			center + Vector2(16, 42), center + Vector2(-1, 42),
		]), PackedColorArray([steel]))
		draw_polygon(PackedVector2Array([
			center + Vector2(49, -9), center + Vector2(82, -4),
			center + Vector2(78, 16), center + Vector2(52, 10),
		]), PackedColorArray([steel]))
		draw_line(center + Vector2(-101, -7), center + Vector2(82, -7), edge, 2.0)
		if inventory_card_mode:
			draw_rect(Rect2(center + Vector2(-57,-9), Vector2(94, 13)), Color("647b7e"))
			draw_rect(Rect2(center + Vector2(-99,-5), Vector2(37, 4)), Color("a4b4b5"))
			draw_rect(Rect2(center + Vector2(-30,-16), Vector2(56, 3)), Color("344d50"))
			for x in range(-53, -17, 7):
				draw_rect(Rect2(center + Vector2(x,-6), Vector2(4, 6)), Color("24363a"))
			for x in [-9, 22, 34]:
				draw_circle(center + Vector2(x, 0), 2, Color("a7b8b9"))
			for y in range(17, 37, 5):
				draw_line(center + Vector2(4, y), center + Vector2(17, y), Color("253b40"), 2)
			draw_polyline(PackedVector2Array([center + Vector2(40,-5), center + Vector2(72,-1), center + Vector2(68,8), center + Vector2(44,5)]), Color("829a9d"), 2)
			draw_circle(center + Vector2(33, 13), 6, Color("829a9d"), false, 2)
	draw_set_transform(Vector2.ZERO)


func _socket_rect(socket_id: StringName, index: int, socket_count: int) -> Rect2:
	if inventory_card_mode:
		var extent := 48.0
		if socket_id == &"optic":
			return Rect2(Vector2(size.x * 0.52, 27), Vector2(extent, extent))
		var lower: Array[StringName] = equipment_state.definition.part_socket_ids.duplicate()
		lower.erase(&"optic")
		var column := lower.find(socket_id)
		var per_row := maxi(1, floori((size.x - 16) / 58.0))
		var rows := maxi(1, ceili(float(lower.size()) / per_row))
		return Rect2(Vector2(8 + (column % per_row) * 58, size.y - 54 * rows + floori(float(column) / per_row) * 54), Vector2(extent, extent))
	var card_size := Vector2(78, 34)
	match socket_id:
		&"optic":
			return Rect2(Vector2(size.x * 0.5 - 39, 26), card_size)
		&"muzzle":
			return Rect2(Vector2(8, size.y - 42), card_size)
		&"magazine":
			return Rect2(Vector2(size.x * 0.5 - 39, size.y - 42), card_size)
		&"blade":
			return Rect2(Vector2(size.x - 86, size.y - 42), card_size)
	var spacing := maxf(4.0, (size.x - card_size.x * socket_count) / float(socket_count + 1))
	return Rect2(Vector2(spacing + index * (card_size.x + spacing), size.y - 42), card_size)


func _draw_socket_card(socket_id: StringName, rect: Rect2) -> void:
	var installed_part = _installed_part_for_socket(socket_id)
	var installed := installed_part != null
	var selected := selected_socket_id == socket_id
	var fill := Color(0.08, 0.16, 0.16, 0.96) if installed else Color(0.055, 0.065, 0.075, 0.92)
	var border := Color("a0fffc") if selected else ACCENT if installed else Color(0.18, 0.3, 0.32)
	draw_rect(rect, fill, true)
	draw_rect(rect, border, false, 2.0 if selected else 1.0)
	var anchor := Vector2(rect.get_center().x, rect.position.y)
	var weapon_anchor := Vector2(size.x * 0.5, size.y * 0.54)
	if inventory_card_mode:
		weapon_anchor.y = 94
		if socket_id == &"muzzle": weapon_anchor.x -= size.x * 0.34
		if socket_id == &"magazine": weapon_anchor += Vector2(10, 27)
		if socket_id == &"optic": weapon_anchor.y -= 18
	draw_line(anchor, weapon_anchor, Color(border, 0.38), 1.0)
	var socket_label := String(SOCKET_LABELS.get(socket_id, String(socket_id)))
	var value := _short_name(installed_part.display_name, 8) if installed else "비어 있음"
	var font := get_theme_default_font()
	if inventory_card_mode:
		var c := rect.get_center() - Vector2(0, 5)
		var icon := border if installed else Color("688387")
		match socket_id:
			&"optic":
				draw_circle(c, 9, icon, false, 2)
				draw_line(c - Vector2(13, 0), c + Vector2(13, 0), icon, 1)
				draw_line(c - Vector2(0, 13), c + Vector2(0, 13), icon, 1)
			&"muzzle":
				draw_rect(Rect2(c - Vector2(13, 5), Vector2(26, 10)), icon, false, 2)
			&"magazine":
				draw_polyline(PackedVector2Array([c + Vector2(-6,-12), c + Vector2(7,-12), c + Vector2(4,10), c + Vector2(-8,10), c + Vector2(-6,-12)]), icon, 2)
			_:
				draw_line(c - Vector2(9, 9), c + Vector2(9, 9), icon, 4)
		draw_string(font, rect.position + Vector2(2, 44), socket_label, HORIZONTAL_ALIGNMENT_CENTER, 44, 10, icon)
		if installed:
			draw_circle(rect.position + Vector2(42, 6), 3, ACCENT)
		return
	draw_string(font, rect.position + Vector2(5, 13), socket_label, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 10, 10, border)
	draw_string(font, rect.position + Vector2(5, 27), value, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 10, 10, Color(0.82, 0.88, 0.9) if installed else Color(0.42, 0.48, 0.51))


func _installed_part_for_socket(socket_id: StringName):
	if equipment_state == null:
		return null
	for part in equipment_state.installed_parts:
		if part.socket_id == socket_id:
			return part
	return null


func _draw_centered_text(text: String, y: float, font_size: int) -> void:
	draw_string(
		get_theme_default_font(), Vector2(10, y), text,
		HORIZONTAL_ALIGNMENT_CENTER, size.x - 20, font_size, Color(0.5, 0.58, 0.62)
	)


func _short_name(text: String, maximum_length: int) -> String:
	return text if text.length() <= maximum_length else "%s…" % text.left(maximum_length - 1)
