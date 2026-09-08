class_name RunBuffChoiceCard
extends Button

const ACCENT := Color("02e5e1")
const TEXT_PRIMARY := Color("d9ffff")
const TEXT_SECONDARY := Color("7eaaaf")
const SURFACE := Color("031015f7")
const SURFACE_ACTIVE := Color("06252aef")

var choice_index := 0
var choice: Dictionary = {}
var category_id: StringName = &"character"
var category_label := "CHARACTER"
var icon_code := "AUG"

var index_label: Label
var icon_label: Label
var category_chip: Label
var title_label: Label
var stack_label: Label
var description_label: Label
var footer_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	custom_minimum_size = Vector2(244.0, 360.0)
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	clip_contents = true
	flat = true
	text = ""
	add_theme_stylebox_override(&"normal", StyleBoxEmpty.new())
	add_theme_stylebox_override(&"hover", StyleBoxEmpty.new())
	add_theme_stylebox_override(&"pressed", StyleBoxEmpty.new())
	add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())
	_build_labels()
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	resized.connect(queue_redraw)


func configure(index: int, run_level: int, new_choice: Dictionary) -> void:
	choice_index = index
	choice = new_choice.duplicate(true)
	category_id = StringName(choice.get(&"meta_target", &"character"))
	category_label = _category_name(category_id)
	icon_code = _icon_code(StringName(choice.get(&"buff_id", &"")), category_id)
	index_label.text = "AUGMENT // %02d" % (choice_index + 1)
	icon_label.text = icon_code
	category_chip.text = "%s  ·  작전 한정" % category_label
	title_label.text = String(choice.get(&"display_name", "미확인 증강"))
	var current_stacks := int(choice.get(&"current_stacks", 0))
	var maximum_stacks := maxi(1, int(choice.get(&"maximum_stacks", 1)))
	stack_label.text = "RUN LV.%02d  |  STACK %d/%d" % [
		run_level, current_stacks, maximum_stacks,
	]
	description_label.text = String(choice.get(&"description", "효과 정보 없음"))
	footer_label.text = "[%d]  이 증강 선택" % (choice_index + 1)
	tooltip_text = "%s · %s" % [title_label.text, description_label.text]
	queue_redraw()


func get_snapshot() -> Dictionary:
	return {
		&"choice_index": choice_index,
		&"buff_id": choice.get(&"buff_id", &""),
		&"title": title_label.text if title_label != null else "",
		&"description": description_label.text if description_label != null else "",
		&"category": category_label,
		&"icon_code": icon_code,
		&"focused": has_focus(),
		&"visible": is_visible_in_tree(),
		&"rect": get_global_rect(),
	}


func _build_labels() -> void:
	index_label = _make_label(12, TEXT_SECONDARY, HORIZONTAL_ALIGNMENT_LEFT)
	_layout(index_label, 18.0, 14.0, -18.0, 34.0)

	icon_label = _make_label(25, TEXT_PRIMARY, HORIZONTAL_ALIGNMENT_CENTER)
	icon_label.add_theme_constant_override(&"outline_size", 4)
	icon_label.add_theme_color_override(&"font_outline_color", Color("02090d"))
	_layout(icon_label, 0.0, 59.0, 0.0, 96.0)

	category_chip = _make_label(11, ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
	_layout(category_chip, 16.0, 127.0, -16.0, 151.0)

	title_label = _make_label(21, TEXT_PRIMARY, HORIZONTAL_ALIGNMENT_CENTER)
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_layout(title_label, 15.0, 160.0, -15.0, 194.0)

	stack_label = _make_label(10, TEXT_SECONDARY, HORIZONTAL_ALIGNMENT_CENTER)
	_layout(stack_label, 12.0, 198.0, -12.0, 220.0)

	description_label = _make_label(14, Color("b7d4d7"), HORIZONTAL_ALIGNMENT_CENTER)
	description_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.max_lines_visible = 4
	description_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_layout(description_label, 22.0, 235.0, -22.0, -54.0)

	footer_label = _make_label(12, ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
	_layout(footer_label, 14.0, -43.0, -14.0, -15.0)


func _make_label(font_size: int, color: Color, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	label.horizontal_alignment = alignment
	add_child(label)
	return label


func _layout(control: Control, left: float, top: float, right: float, bottom: float) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	control.offset_left = left
	control.offset_top = top
	control.offset_right = right
	control.offset_bottom = bottom


func _draw() -> void:
	var card_size := size
	if card_size.x < 8.0 or card_size.y < 8.0:
		return
	var active := is_hovered() or has_focus() or button_pressed
	var edge := ACCENT if active else ACCENT.darkened(0.48)
	var background := SURFACE_ACTIVE if active else SURFACE
	var cut := 14.0
	var polygon := PackedVector2Array([
		Vector2(cut, 0.0), Vector2(card_size.x - cut, 0.0),
		Vector2(card_size.x, cut), Vector2(card_size.x, card_size.y - cut),
		Vector2(card_size.x - cut, card_size.y), Vector2(cut, card_size.y),
		Vector2(0.0, card_size.y - cut), Vector2(0.0, cut),
	])
	draw_colored_polygon(polygon, background)
	draw_polyline(polygon + PackedVector2Array([polygon[0]]), edge, 2.0 if active else 1.0, true)

	# Reference-inspired augment core, rendered locally so no third-party card art is copied.
	var center := Vector2(card_size.x * 0.5, 84.0)
	draw_circle(center, 39.0, Color("02090dc0"))
	draw_arc(center, 39.0, -2.82, 0.35, 18, edge, 3.0, true)
	draw_arc(center, 39.0, 0.32, 3.48, 18, edge, 3.0, true)
	draw_arc(center, 29.0, 0.0, TAU, 24, Color(edge, 0.42), 1.0, true)
	icon_label.hide()
	var emblem_kind := "gear" if category_id == &"armor" else "weapon" if category_id == &"weapon" else "skill"
	draw_texture_rect(GameUI.icon(emblem_kind), Rect2(center - Vector2(20, 20), Vector2(40, 40)), false, TEXT_PRIMARY)
	for spoke_index in range(4):
		var angle := PI * 0.25 + float(spoke_index) * PI * 0.5
		var from := center + Vector2.from_angle(angle) * 33.0
		var to := center + Vector2.from_angle(angle) * 43.0
		draw_line(from, to, edge, 2.0, true)

	draw_line(Vector2(17.0, 224.0), Vector2(card_size.x - 17.0, 224.0), Color(edge, 0.38), 1.0)
	draw_line(Vector2(17.0, card_size.y - 50.0), Vector2(card_size.x - 17.0, card_size.y - 50.0), Color(edge, 0.38), 1.0)
	draw_line(Vector2(7.0, 36.0), Vector2(7.0, 96.0), edge, 2.0)
	draw_line(Vector2(card_size.x - 7.0, card_size.y - 96.0), Vector2(card_size.x - 7.0, card_size.y - 36.0), edge, 2.0)


func _category_name(target_id: StringName) -> String:
	match target_id:
		&"weapon":
			return "WEAPON"
		&"armor":
			return "ARMOR"
		_:
			return "CHARACTER"


func _icon_code(buff_id: StringName, target_id: StringName) -> String:
	match buff_id:
		&"vitality":
			return "VIT"
		&"mobility":
			return "MOV"
		&"overclock":
			return "DMG"
		&"rapid_cycle":
			return "RATE"
		&"plating":
			return "ARM"
	match target_id:
		&"weapon":
			return "WPN"
		&"armor":
			return "DEF"
		_:
			return "AUG"
