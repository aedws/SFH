class_name GameUI
extends RefCounted
## Opt-in presentation primitives. No inventory, payment, input binding or save ownership.
const ACCENT := Color("02e5e1")
const GOLD := Color("efbf73")
const INK := Color("0d151e")
const TEXT := Color("e1e8ed")
static var icons: Dictionary = {}

static func surface(accent := ACCENT, emphasis := false) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = INK
	box.border_color = accent if emphasis else Color("344550")
	box.set_border_width_all(1)
	box.border_width_left = 3 if emphasis else 1
	box.corner_radius_top_right = 10
	box.corner_radius_bottom_left = 10
	box.set_content_margin_all(14)
	return box

static func icon(kind: String) -> Texture2D:
	if icons.has(kind): return icons[kind]
	var paths := {
		"gear": "M5 8H25V24H5Z M9 8V4H21V8 M11 16H19 M15 12V20",
		"weapon": "M3 12H27V17H17L20 26H14L11 17H3Z M22 8V12",
		"skill": "M17 2L5 18H14L11 29L26 12H17Z",
		"craft": "M5 5L24 24 M21 4L27 10L10 27L4 21Z",
		"codex": "M4 5H14L16 7L18 5H28V26H18L16 28L14 26H4Z M16 7V28",
		"credit": "M16 3L28 10V23L16 30L4 23V10Z M21 11H12V22H21",
		"training": "M16 3V29 M3 16H29 M8 8H24V24H8Z",
		"move": "M6 5H22V27H6Z M11 16H29 M23 10L29 16L23 22",
		"honor": "M9 3H23L26 16L16 24L6 16Z M10 23L8 30L16 27L24 30L22 23",
		"settings": "M4 8H28 M4 16H28 M4 24H28 M10 4V12 M23 12V20 M15 20V28",
	}
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32"><path d="%s" fill="none" stroke="#dce8ed" stroke-width="2" stroke-linejoin="round"/></svg>' % paths.get(kind, paths.gear)
	var bitmap := Image.new()
	bitmap.load_svg_from_string(svg)
	var texture := ImageTexture.create_from_image(bitmap)
	icons[kind] = texture
	return texture

static func action(button: Button, kind: String, primary := false) -> void:
	button.icon = icon(kind)
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", 28)
	button.add_theme_constant_override("h_separation", 12)
	button.add_theme_stylebox_override("normal", surface(ACCENT, primary))
	button.add_theme_stylebox_override("hover", surface(Color("99fff5"), true))
	button.add_theme_stylebox_override("focus", surface(GOLD, true))
	button.add_theme_color_override("font_color", TEXT)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.custom_minimum_size.y = maxf(44, button.custom_minimum_size.y)

static func header(parent: Control, title: String, subtitle: String, kind := "gear") -> Label:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	parent.add_child(row)
	var emblem := TextureRect.new()
	emblem.texture = icon(kind)
	emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	emblem.custom_minimum_size = Vector2(42, 42)
	emblem.modulate = ACCENT
	emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(emblem)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(column)
	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size", 26)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(heading)
	var help := Label.new()
	help.text = subtitle
	help.add_theme_color_override("font_color", Color("a4b7c5"))
	help.add_theme_font_size_override("font_size", 13)
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(help)
	return heading

static func fold(parent: Control, caption: String, content: Control) -> Button:
	var toggle := Button.new()
	toggle.text = caption + "  +"
	toggle.toggle_mode = true
	toggle.custom_minimum_size.y = 36
	parent.add_child(toggle)
	if content.get_parent() != null: content.reparent(parent)
	else: parent.add_child(content)
	content.hide()
	toggle.toggled.connect(func(open: bool):
		content.visible = open
		toggle.text = caption + ("  −" if open else "  +"))
	return toggle
