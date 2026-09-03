class_name BossWarningHud
extends Control

const Tracker := preload("res://game/features/boss_warning/boss_threat_tracker.gd")
const EdgeProjection := preload("res://game/features/boss_warning/boss_edge_projection.gd")

@export var style: Resource

var tracker := Tracker.new()
var player: Node2D
var combat_context: CanvasItem
var warning_remaining := 0.0
var warning_text := ""
var warning_count := 0
var indicators: Array[Dictionary] = []
var active_boss_count := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	# Keep only visibility responsive while paused; warning lifetime stays frozen.
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tracker.boss_appeared.connect(_on_boss_appeared)
	hide()


func configure(spawner: Node, actor: Node2D, context: CanvasItem) -> bool:
	if not is_instance_valid(actor) or not is_instance_valid(context) \
		or style == null or not style.has_method(&"is_valid") or not style.call(&"is_valid"):
		return false
	player = actor
	combat_context = context
	warning_remaining = 0.0
	warning_count = 0
	indicators.clear()
	return tracker.configure(spawner)


func _exit_tree() -> void:
	tracker.reset()


func _process(delta: float) -> void:
	if not is_instance_valid(player) or not is_instance_valid(combat_context) \
		or not combat_context.is_visible_in_tree() or get_tree().paused:
		hide()
		return
	var threats := tracker.get_threats()
	active_boss_count = threats.size()
	if threats.is_empty():
		warning_remaining = 0.0
	warning_remaining = maxf(0.0, warning_remaining - delta)
	indicators.clear()
	var world_to_ui := get_global_transform_with_canvas().affine_inverse() * player.get_canvas_transform()
	for threat in threats:
		var marker := EdgeProjection.project(world_to_ui * threat[&"world_position"], size, float(style.get("edge_inset")))
		if not marker.is_empty():
			marker[&"id"] = threat[&"id"]
			indicators.append(marker)
	visible = warning_remaining > 0.0 or not indicators.is_empty()
	if visible:
		queue_redraw()


func get_snapshot() -> Dictionary:
	return {
		&"visible": is_visible_in_tree(), &"warning_visible": is_visible_in_tree() and warning_remaining > 0.0,
		&"warning_remaining": warning_remaining, &"warning_text": warning_text,
		&"warning_count": warning_count, &"active_boss_count": active_boss_count,
		&"indicators": indicators.duplicate(true), &"viewport_size": size,
		&"input_passthrough": mouse_filter == Control.MOUSE_FILTER_IGNORE,
	}


func _on_boss_appeared(pursuer: bool) -> void:
	warning_remaining = float(style.get("warning_seconds"))
	warning_count += 1
	warning_text = "보스 등장 · 문을 넘어 추격 중" if pursuer else "보스 등장 · 교전 주의"


func _draw() -> void:
	var color: Color = style.get("warning_color")
	var background: Color = style.get("background_color")
	var radius := float(style.get("arrow_radius"))
	for marker in indicators:
		var point: Vector2 = marker[&"position"]
		draw_circle(point, radius + 4.0, background)
		var arrow := PackedVector2Array()
		for vertex in [Vector2(-0.7, -0.8), Vector2(1, 0), Vector2(-0.7, 0.8), Vector2(-0.25, 0)]:
			arrow.append(point + (vertex * radius).rotated(float(marker[&"angle"])))
		draw_colored_polygon(arrow, color)
	if warning_remaining <= 0.0:
		return
	# Short, static banner: no full-screen flashes, emoji glyphs or large blackout.
	var width := minf(320.0, size.x - 48.0)
	var banner := Rect2(Vector2((size.x - width) * 0.5, 42.0), Vector2(width, 34.0))
	draw_style_box(_banner_style(background, color), banner)
	var font := get_theme_default_font()
	var font_size := 16 if size.x >= 600.0 else 12
	var text_width := font.get_string_size(warning_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, Vector2((size.x - text_width) * 0.5, banner.position.y + 23.0), warning_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _banner_style(background: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = border
	box.set_border_width_all(1)
	return box
