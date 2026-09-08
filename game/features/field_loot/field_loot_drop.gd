class_name FieldLootDrop
extends Node2D

signal proximity_changed(drop: Node2D, available: bool)

@export_range(32.0, 160.0, 4.0) var interaction_radius := 76.0

var player: Node2D
var candidate: Dictionary = {}
var comparison: Dictionary = {}
var player_nearby := false
var elapsed := 0.0
var label: Label
const UI = preload("res://game/features/presentation_theme/game_ui.gd")
var loot_icon: Texture2D
var loot_accent := UI.ACCENT


func configure(
	new_player: Node2D,
	new_candidate: Dictionary,
	new_comparison: Dictionary
) -> bool:
	if not is_instance_valid(new_player) or new_candidate.is_empty() or new_comparison.is_empty():
		return false
	player = new_player
	candidate = new_candidate.duplicate(true)
	comparison = new_comparison.duplicate(true)
	var type := String(comparison.get(&"item_type", ""))
	loot_icon = UI.icon({"weapon": "weapon", "armor": "gear", "part": "craft", "module": "skill", "skill": "skill", "rune": "skill", "core": "skill", "artifact": "honor"}.get(type, "gear"))
	var palette := [Color("a8b8c4"), Color("71cca7"), Color("68b9ec"), Color("b998ea"), UI.GOLD]
	loot_accent = palette[clampi(int(candidate.get(&"grade", 1)) - 1, 0, palette.size() - 1)]
	add_to_group(&"field_loot_drop")
	_create_label()
	queue_redraw()
	return true


func get_snapshot() -> Dictionary:
	return {
		&"item_id": candidate.get(&"item_id", &""),
		&"quantity": candidate.get(&"quantity", 1),
		&"grade": candidate.get(&"grade", 1),
		&"player_nearby": player_nearby,
		&"interaction_radius": interaction_radius,
		&"comparison_ready": not comparison.is_empty(),
	}


func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()
	if not is_instance_valid(player):
		return
	var is_near := player.global_position.distance_to(global_position) <= interaction_radius
	if is_near == player_nearby:
		return
	player_nearby = is_near
	label.text = String(comparison.get(&"display_name", "전리품")) if is_near else "G%d" % int(candidate.get(&"grade", 1))
	proximity_changed.emit(self, player_nearby)


func _draw() -> void:
	var accent := loot_accent
	var pulse := 0.82 + sin(elapsed * 4.5) * 0.12
	var points := PackedVector2Array([
		Vector2(0, -15), Vector2(15, 0), Vector2(0, 15), Vector2(-15, 0),
	])
	draw_colored_polygon(points, Color(0.01, 0.09, 0.11, 0.92))
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), accent * pulse, 2.0, true)
	if loot_icon != null: draw_texture_rect(loot_icon, Rect2(-11, -11, 22, 22), false, accent)
	draw_arc(Vector2.ZERO, 23.0 + sin(elapsed * 3.0) * 2.0, 0.0, TAU, 32, Color(accent, 0.35), 1.0, true)


func _create_label() -> void:
	label = Label.new()
	label.name = "LootCode"
	label.text = "G%d" % int(candidate.get(&"grade", 1))
	label.position = Vector2(-100.0, -43.0)
	label.size = Vector2(200.0, 20.0)
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", loot_accent)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.add_theme_font_size_override("font_size", 12)
	add_child(label)
