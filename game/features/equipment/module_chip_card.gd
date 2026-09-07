class_name ModuleChipCard
extends Button
## Native focus/click semantics with SFH code-drawn chipset artwork.
var caption := ""
var detail := ""
var cost := ""
var tint := Color("02e5e1")
var empty := false
var glyph: StringName = &""

func _ready() -> void:
	custom_minimum_size = Vector2(104, 142)
	for mode in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("082b30") if mode == "pressed" else Color("071215")
		style.border_color = tint if mode != "normal" else Color(tint, 0.35)
		style.set_border_width_all(2 if mode == "focus" else 1)
		add_theme_stylebox_override(mode, style)
	add_theme_color_override("font_pressed_color", Color("e1f8fa"))
	size_flags_horizontal = SIZE_EXPAND_FILL
	tooltip_text = caption + "\n" + detail
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 6
	box.offset_right = -6
	box.offset_top = 6
	box.offset_bottom = -6
	add_child(box)
	for line in [cost, "", caption, detail]:
		var label := Label.new()
		label.text = line
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 12)
		if line.is_empty(): label.custom_minimum_size.y = 42
		box.add_child(label)

func _draw() -> void:
	var frame := Rect2(Vector2(3, 3), size - Vector2(6, 6))
	draw_rect(frame, Color(tint, 0.035), true)
	draw_rect(frame, Color(tint, 0.75 if button_pressed else 0.3), false, 2)
	for offset in [9, 14, 19]:
		draw_polyline(PackedVector2Array([Vector2(offset, 28), Vector2(offset, size.y - 25), Vector2(offset + 12, size.y - 9)]), Color(tint, 0.13), 1)
	var center := Vector2(size.x * 0.5, 51)
	draw_rect(Rect2(center - Vector2(14, 14), Vector2(28, 28)), Color(tint, 0.65), false, 2)
	for x in [-1, 1]:
		for y in [-8, 0, 8]: draw_line(center + Vector2(x * 15, y), center + Vector2(x * 23, y), Color(tint, 0.45), 2)
	if glyph == &"defense":
		draw_polyline(PackedVector2Array([center + Vector2(-9,-9), center + Vector2(9,-9), center + Vector2(7,5), center + Vector2(0,11), center + Vector2(-7,5), center + Vector2(-9,-9)]), tint, 2)
	elif glyph == &"ballistic":
		draw_polyline(PackedVector2Array([center + Vector2(5,-11), center + Vector2(-7,2), center + Vector2(4,0), center + Vector2(-5,11)]), tint, 3)
	elif glyph == &"mobility":
		for x in [-5, 4]: draw_polyline(PackedVector2Array([center + Vector2(x-4,-8), center + Vector2(x+4,0), center + Vector2(x-4,8)]), tint, 2)
	else:
		draw_line(center - Vector2(8, 0), center + Vector2(8, 0), tint, 3)
		draw_line(center - Vector2(0, 8), center + Vector2(0, 8), tint, 3)
