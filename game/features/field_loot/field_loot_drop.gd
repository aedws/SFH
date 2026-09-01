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
	proximity_changed.emit(self, player_nearby)


func _draw() -> void:
	var accent := Color("02e5e1")
	var pulse := 0.82 + sin(elapsed * 4.5) * 0.12
	var points := PackedVector2Array([
		Vector2(0, -15), Vector2(15, 0), Vector2(0, 15), Vector2(-15, 0),
	])
	draw_colored_polygon(points, Color(0.01, 0.09, 0.11, 0.92))
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), accent * pulse, 2.0, true)
	draw_circle(Vector2.ZERO, 4.0, accent * pulse)
	draw_arc(Vector2.ZERO, 23.0 + sin(elapsed * 3.0) * 2.0, 0.0, TAU, 32, Color(accent, 0.35), 1.0, true)


func _create_label() -> void:
	label = Label.new()
	label.name = "LootCode"
	label.text = "LOOT · G%d" % int(candidate.get(&"grade", 1))
	label.position = Vector2(-48.0, -43.0)
	label.size = Vector2(96.0, 20.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("02e5e1"))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.add_theme_font_size_override("font_size", 12)
	add_child(label)
