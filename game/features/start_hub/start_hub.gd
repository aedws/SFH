class_name StartHub
extends Node2D

signal operation_requested
signal interaction_availability_changed(available: bool, prompt: String)

@export var room_size := Vector2(1800.0, 1040.0)
@export var spawn_position := Vector2(-560.0, 0.0)
@export var operation_position := Vector2(690.0, 0.0)
@export_range(64.0, 180.0, 4.0) var interaction_radius: float = 120.0
@export var interaction_action: StringName = &"interact"

@onready var operation_gate: Area2D = $OperationGate

var nearby_player: Node2D


func _ready() -> void:
	operation_gate.position = operation_position
	operation_gate.body_entered.connect(_on_body_entered)
	operation_gate.body_exited.connect(_on_body_exited)
	_build_boundary_collisions()
	queue_redraw()


func get_spawn_position() -> Vector2:
	return spawn_position


func get_operation_position() -> Vector2:
	return operation_position


func get_room_rect() -> Rect2:
	return Rect2(-room_size * 0.5, room_size)


func get_snapshot() -> Dictionary:
	return {
		&"room_count": 1,
		&"room_size": room_size,
		&"spawn_position": spawn_position,
		&"operation_position": operation_position,
		&"player_near_gate": is_instance_valid(nearby_player),
	}


func request_operation(actor: Node2D) -> bool:
	if not is_instance_valid(actor) or not actor.is_in_group(&"player"):
		return false
	# 프롬프트를 보여 준 Area 중첩을 실제 요청에서도 같은 판정으로 사용합니다.
	if actor != nearby_player and actor.global_position.distance_to(operation_gate.global_position) > interaction_radius:
		return false
	operation_requested.emit()
	return true


func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(nearby_player):
		return
	if event.is_action_pressed(interaction_action) and request_operation(nearby_player):
		get_viewport().set_input_as_handled()


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(&"player"):
		return
	nearby_player = body
	interaction_availability_changed.emit(true, "F · 작전 게이트 접속")


func _on_body_exited(body: Node2D) -> void:
	if body != nearby_player:
		return
	nearby_player = null
	interaction_availability_changed.emit(false, "")


func _build_boundary_collisions() -> void:
	var half := room_size * 0.5
	_add_wall(Vector2(0.0, -half.y - 20.0), Vector2(room_size.x + 80.0, 40.0))
	_add_wall(Vector2(0.0, half.y + 20.0), Vector2(room_size.x + 80.0, 40.0))
	_add_wall(Vector2(-half.x - 20.0, 0.0), Vector2(40.0, room_size.y + 80.0))
	_add_wall(Vector2(half.x + 20.0, 0.0), Vector2(40.0, room_size.y + 80.0))


func _add_wall(center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 16
	body.collision_mask = 0
	body.position = center
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)


func _draw() -> void:
	var room_rect := get_room_rect()
	draw_rect(room_rect, Color("101a24"), true)
	for x in range(int(room_rect.position.x), int(room_rect.end.x) + 1, 64):
		draw_line(
			Vector2(x, room_rect.position.y),
			Vector2(x, room_rect.end.y),
			Color(0.12, 0.2, 0.27, 0.42),
			1.0
		)
	for y in range(int(room_rect.position.y), int(room_rect.end.y) + 1, 64):
		draw_line(
			Vector2(room_rect.position.x, y),
			Vector2(room_rect.end.x, y),
			Color(0.12, 0.2, 0.27, 0.42),
			1.0
		)
	draw_rect(room_rect, Color(0.22, 0.45, 0.52, 0.9), false, 10.0)
	_draw_station_zone(Rect2(Vector2(-760.0, -380.0), Vector2(360.0, 270.0)), Color("24404a"))
	_draw_station_zone(Rect2(Vector2(-760.0, 110.0), Vector2(360.0, 270.0)), Color("273747"))
	_draw_station_zone(Rect2(Vector2(-120.0, -390.0), Vector2(430.0, 180.0)), Color("1d3440"))
	var gate_color := Color(0.2, 0.88, 0.78, 1.0)
	draw_circle(operation_position, 96.0, Color(gate_color, 0.12))
	draw_arc(operation_position, 96.0, 0.0, TAU, 64, gate_color, 7.0)
	draw_arc(operation_position, 70.0, 0.0, TAU, 64, Color(gate_color, 0.55), 3.0)
	draw_line(operation_position + Vector2(-34.0, 0.0), operation_position + Vector2(34.0, 0.0), gate_color, 6.0)
	draw_line(operation_position + Vector2(8.0, -24.0), operation_position + Vector2(34.0, 0.0), gate_color, 6.0)
	draw_line(operation_position + Vector2(8.0, 24.0), operation_position + Vector2(34.0, 0.0), gate_color, 6.0)


func _draw_station_zone(rect: Rect2, color: Color) -> void:
	draw_rect(rect, color, true)
	draw_rect(rect, Color(0.3, 0.56, 0.62, 0.72), false, 4.0)
	for offset in [36.0, 98.0, 160.0]:
		draw_line(
			Vector2(rect.position.x + offset, rect.position.y + 22.0),
			Vector2(rect.position.x + offset, rect.end.y - 22.0),
			Color(0.34, 0.52, 0.58, 0.35),
			2.0
		)
