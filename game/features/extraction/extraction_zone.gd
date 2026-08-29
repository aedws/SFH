class_name ExtractionZone
extends Area2D

signal extraction_completed(actor: Node2D)
signal interaction_availability_changed(available: bool, prompt: String)

@export var interaction_action: StringName = &"interact"
@export_range(32.0, 160.0, 4.0) var interaction_radius: float = 72.0
@export var fill_color := Color(1.0, 0.48, 0.12, 0.22)
@export var ring_color := Color(1.0, 0.67, 0.25, 0.95)

var nearby_player: Node2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	queue_redraw()


func configure(world_position: Vector2) -> void:
	global_position = world_position


func request_extraction(actor: Node2D) -> bool:
	if not is_instance_valid(actor) or not actor.is_in_group(&"player"):
		return false
	if actor.global_position.distance_to(global_position) > interaction_radius:
		return false

	extraction_completed.emit(actor)
	return true


func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(nearby_player):
		return
	if event.is_action_pressed(interaction_action) and request_extraction(nearby_player):
		get_viewport().set_input_as_handled()


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(&"player"):
		return
	nearby_player = body
	interaction_availability_changed.emit(true, "F · 작전 지역에서 탈출")


func _on_body_exited(body: Node2D) -> void:
	if body != nearby_player:
		return
	nearby_player = null
	interaction_availability_changed.emit(false, "")


func _draw() -> void:
	draw_circle(Vector2.ZERO, 42.0, fill_color)
	draw_arc(Vector2.ZERO, 42.0, 0.0, TAU, 48, ring_color, 4.0)
	draw_arc(Vector2.ZERO, 31.0, 0.0, TAU, 48, Color(ring_color, 0.6), 2.0)
	var arrow := PackedVector2Array([
		Vector2(-9.0, 8.0),
		Vector2(0.0, -10.0),
		Vector2(9.0, 8.0),
	])
	draw_polyline(arrow, ring_color, 4.0)
