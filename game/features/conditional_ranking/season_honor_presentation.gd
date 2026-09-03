class_name SeasonHonorPresentation
extends Node2D
var profile: Node
var aura_color := Color.TRANSPARENT
var title_label: Label


func configure(source: Node, show_title: bool) -> void:
	profile = source
	z_index = -1
	title_label = Label.new()
	title_label.position = Vector2(-100, -60)
	title_label.size.x = 200
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 12)
	title_label.visible = show_title
	add_child(title_label)
	profile.changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	var state: Dictionary = profile.call(&"get_snapshot")
	var owned: Dictionary = state.get("owned", {})
	var selected: Dictionary = state.get("equipped", {})
	var aura: Dictionary = owned.get(selected.get("aura", ""), {})
	aura_color = Color(String(aura.get("color", "00000000")))
	title_label.text = String(owned.get(selected.get("title", ""), {}).get("display_name", ""))
	queue_redraw()


func _draw() -> void:
	if aura_color.a > 0:
		draw_arc(Vector2.ZERO, 27, 0, TAU, 32, Color(aura_color, 0.5), 2, true)
		draw_arc(Vector2.ZERO, 31, 0, PI, 16, Color(aura_color, 0.24), 1, true)
